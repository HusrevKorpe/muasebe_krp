import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/log/log.dart';
import '../../../data/fidan/fidan_kaydi.dart';
import '../../../data/fidan/fidan_repository.dart';
import 'fidan_listesi_durumu.dart';

/// Fidan katalogunun arama ve sayfalama mantığı.
///
/// Sıralama seçeneği yok: katalog her zaman `tür → çeşit → anaç` sırasında
/// gelir ve ekran aynı türü tek başlık altında toplar.
class FidanListesiViewModel extends AsyncNotifier<FidanListesiDurumu> {
  /// Her tuşa basışta sorgu atmamak için beklenen süre — Firestore okuma
  /// başına ücretlendirir (bkz. `CariListesiViewModel`).
  static const Duration _aramaGecikmesi = Duration(milliseconds: 300);

  Timer? _aramaZamanlayici;
  String _arama = '';

  @override
  Future<FidanListesiDurumu> build() async {
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
    state = const AsyncValue<FidanListesiDurumu>.loading();
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

    state = AsyncValue<FidanListesiDurumu>.data(
      mevcut.kopyala(dahaYukleniyor: true, hatayiTemizle: true),
    );

    try {
      final sayfa = await ref
          .read(fidanRepositorySaglayici)
          .listele(arama: _arama, sonrasindan: mevcut.kayitlar.last);

      state = AsyncValue<FidanListesiDurumu>.data(
        mevcut.kopyala(
          kayitlar: <FidanKaydi>[
            ...mevcut.kayitlar,
            ...sayfa.kayitlar,
          ].toList(growable: false),
          dahaVar: sayfa.dahaVar,
          dahaYukleniyor: false,
          hatayiTemizle: true,
        ),
      );
    } on UygulamaHatasi catch (hata) {
      Log.uyari('Sonraki fidan sayfası yüklenemedi: ${hata.mesaj}');
      state = AsyncValue<FidanListesiDurumu>.data(
        mevcut.kopyala(dahaYukleniyor: false, sayfaHatasi: hata.mesaj),
      );
    }
  }

  Future<FidanListesiDurumu> _ilkSayfa() async {
    final sayfa = await ref
        .read(fidanRepositorySaglayici)
        .listele(arama: _arama);

    return FidanListesiDurumu(
      kayitlar: sayfa.kayitlar,
      arama: _arama,
      dahaVar: sayfa.dahaVar,
    );
  }
}

final fidanListesiViewModelSaglayici =
    AsyncNotifierProvider<FidanListesiViewModel, FidanListesiDurumu>(
      FidanListesiViewModel.new,
    );
