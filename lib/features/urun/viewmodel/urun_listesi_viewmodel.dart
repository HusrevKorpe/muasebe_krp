import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/log/log.dart';
import '../../../data/urun/urun_kaydi.dart';
import '../../../data/urun/urun_repository.dart';
import 'urun_listesi_durumu.dart';

/// Ürün listesinin arama ve sayfalama mantığı.
///
/// Sıralama seçeneği yok: liste her zaman ada göre alfabetik gelir.
class UrunListesiViewModel extends AsyncNotifier<UrunListesiDurumu> {
  /// Her tuşa basışta sorgu atmamak için beklenen süre — Firestore okuma
  /// başına ücretlendirir (bkz. `CariListesiViewModel`).
  static const Duration _aramaGecikmesi = Duration(milliseconds: 300);

  Timer? _aramaZamanlayici;
  String _arama = '';

  @override
  Future<UrunListesiDurumu> build() async {
    ref.onDispose(() => _aramaZamanlayici?.cancel());
    return _ilkSayfa();
  }

  /// Arama kutusundaki her değişiklikte çağrılır; sorgu gecikmeyle atılır.
  void aramayiDegistir(String metin) {
    if (metin == _arama) return;
    _arama = metin;
    _aramaZamanlayici?.cancel();
    _aramaZamanlayici = Timer(_aramaGecikmesi, () => unawaited(yenile()));
  }

  /// Listeyi baştan yükler.
  Future<void> yenile() async {
    state = const AsyncValue<UrunListesiDurumu>.loading();
    state = await AsyncValue.guard(_ilkSayfa);
  }

  /// Sonraki sayfayı yükleyip listenin sonuna ekler.
  Future<void> dahaYukle() async {
    final mevcut = state.value;
    if (mevcut == null ||
        !mevcut.dahaVar ||
        mevcut.dahaYukleniyor ||
        mevcut.bosMu) {
      return;
    }

    state = AsyncValue<UrunListesiDurumu>.data(
      mevcut.kopyala(dahaYukleniyor: true, hatayiTemizle: true),
    );

    try {
      final sayfa = await ref
          .read(urunRepositorySaglayici)
          .listele(arama: _arama, sonrasindan: mevcut.kayitlar.last);

      state = AsyncValue<UrunListesiDurumu>.data(
        mevcut.kopyala(
          kayitlar: <UrunKaydi>[
            ...mevcut.kayitlar,
            ...sayfa.kayitlar,
          ].toList(growable: false),
          dahaVar: sayfa.dahaVar,
          dahaYukleniyor: false,
          hatayiTemizle: true,
        ),
      );
    } on UygulamaHatasi catch (hata) {
      Log.uyari('Sonraki ürün sayfası yüklenemedi: ${hata.mesaj}');
      state = AsyncValue<UrunListesiDurumu>.data(
        mevcut.kopyala(dahaYukleniyor: false, sayfaHatasi: hata.mesaj),
      );
    }
  }

  Future<UrunListesiDurumu> _ilkSayfa() async {
    final sayfa = await ref
        .read(urunRepositorySaglayici)
        .listele(arama: _arama);

    return UrunListesiDurumu(
      kayitlar: sayfa.kayitlar,
      arama: _arama,
      dahaVar: sayfa.dahaVar,
    );
  }
}

final urunListesiViewModelSaglayici =
    AsyncNotifierProvider<UrunListesiViewModel, UrunListesiDurumu>(
      UrunListesiViewModel.new,
    );
