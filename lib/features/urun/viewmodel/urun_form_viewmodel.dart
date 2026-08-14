import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../data/urun/urun_repository.dart';
import '../../../domain/urun/urun.dart';
import '../../ortak/viewmodel/islem_viewmodel.dart';

/// Ürün ekleme, düzenleme ve listeden kaldırma işlemleri.
///
/// Kaydettikten sonra liste **tazelenmez**: `UrunListesiViewModel` Firestore'u
/// canlı dinliyor ve yerel yazmayı anında yayıyor. Düzenleme ekranı da
/// `urunSaglayici` akışını okur.
class UrunFormViewModel extends IslemViewModel {
  /// Yeni ürün ise ekler, mevcut ürün ise günceller.
  ///
  /// Kaydetmeden önce listede **aynı adlı** bir ürün var mı diye bakılır; aynı
  /// şey ikinci kez eklenemez. Listenin zamanla çöplüğe dönmesinin başlıca
  /// yolu bu (bkz. Faz 3 kabul kriteri 7).
  ///
  /// Kontrol her tuşa basışta değil yalnızca kaydederken yapılıyor: canlı
  /// kontrol her harf için bir Firestore okuması demekti (KURALLAR.md §4.3).
  /// Kontrolün kendisi de yalnızca önbellekte koşar, sunucuya sorulmaz —
  /// kaydetme düğmesi ağa bağlanmamalı (bkz. [UrunRepository.benzerleriBul]).
  Future<bool> kaydet(Urun urun) => calistir(() async {
    final repository = ref.read(urunRepositorySaglayici);

    final benzerler = await repository.benzerleriBul(urun);
    if (benzerler.any(urun.ayniUrunMu)) {
      throw const DogrulamaHatasi(Metinler.urunMukerrer);
    }

    if (urun.yeniMi) {
      await repository.ekle(urun);
    } else {
      await repository.guncelle(urun);
    }
  }, etiket: 'Ürün kaydı');

  /// Ürünü listeden kaldırır. Kayıt silinmez, pasife alınır
  /// (bkz. KURALLAR.md §4.2).
  Future<bool> pasifeAl(String urunId) => calistir(() async {
    await ref
        .read(urunRepositorySaglayici)
        .aktifligiDegistir(urunId, aktif: false);
  }, etiket: 'Ürün listeden kaldırma');
}

final urunFormViewModelSaglayici =
    AsyncNotifierProvider<UrunFormViewModel, void>(
      UrunFormViewModel.new,
      isAutoDispose: true,
    );
