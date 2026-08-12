import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/log/log.dart';
import '../../../data/cari/cari_kaydi.dart';
import '../../../data/cari/cari_repository.dart';
import '../../../domain/cari/cari_siralamasi.dart';
import 'cari_listesi_durumu.dart';

/// Cari listesinin arama, sıralama ve sayfalama mantığı.
class CariListesiViewModel extends AsyncNotifier<CariListesiDurumu> {
  /// Her tuşa basışta sorgu atmamak için beklenen süre. Firestore okuma başına
  /// ücretlendirir; "Ahmet" yazmak 5 sorgu değil 1 sorgu olmalı.
  static const Duration _aramaGecikmesi = Duration(milliseconds: 300);

  Timer? _aramaZamanlayici;
  String _arama = '';
  CariSiralamasi _siralama = CariSiralamasi.ad;

  @override
  Future<CariListesiDurumu> build() async {
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

  Future<void> siralamayiDegistir(CariSiralamasi siralama) async {
    if (siralama == _siralama) return;
    _siralama = siralama;
    await yenile();
  }

  /// Listeyi baştan yükler. Arama ve sıralama değişikliklerinde, aşağı çekerek
  /// yenilemede ve kayıt eklendikten sonra çağrılır.
  Future<void> yenile() async {
    state = const AsyncValue<CariListesiDurumu>.loading();
    state = await AsyncValue.guard(_ilkSayfa);
  }

  /// Sonraki sayfayı yükleyip listenin sonuna ekler.
  ///
  /// İlk yüklemeden farklı olarak durum `loading`'e düşmez: eldeki kayıtlar
  /// ekranda kalır, altta yalnızca bir gösterge döner.
  Future<void> dahaYukle() async {
    final mevcut = state.value;
    if (mevcut == null ||
        !mevcut.dahaVar ||
        mevcut.dahaYukleniyor ||
        mevcut.bosMu) {
      return;
    }

    state = AsyncValue<CariListesiDurumu>.data(
      mevcut.kopyala(dahaYukleniyor: true, hatayiTemizle: true),
    );

    try {
      final sayfa = await ref
          .read(cariRepositorySaglayici)
          .listele(
            siralama: _siralama,
            arama: _arama,
            sonrasindan: mevcut.kayitlar.last,
          );

      state = AsyncValue<CariListesiDurumu>.data(
        mevcut.kopyala(
          kayitlar: <CariKaydi>[
            ...mevcut.kayitlar,
            ...sayfa.kayitlar,
          ].toList(growable: false),
          dahaVar: sayfa.dahaVar,
          dahaYukleniyor: false,
          hatayiTemizle: true,
        ),
      );
    } on UygulamaHatasi catch (hata) {
      Log.uyari('Sonraki cari sayfası yüklenemedi: ${hata.mesaj}');
      state = AsyncValue<CariListesiDurumu>.data(
        mevcut.kopyala(dahaYukleniyor: false, sayfaHatasi: hata.mesaj),
      );
    }
  }

  Future<CariListesiDurumu> _ilkSayfa() async {
    final sayfa = await ref
        .read(cariRepositorySaglayici)
        .listele(siralama: _siralama, arama: _arama);

    return CariListesiDurumu(
      kayitlar: sayfa.kayitlar,
      arama: _arama,
      siralama: _siralama,
      dahaVar: sayfa.dahaVar,
    );
  }
}

final cariListesiViewModelSaglayici =
    AsyncNotifierProvider<CariListesiViewModel, CariListesiDurumu>(
      CariListesiViewModel.new,
    );
