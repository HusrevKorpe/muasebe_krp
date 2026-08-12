import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../data/fidan/fidan_repository.dart';
import '../../../domain/fidan/fidan.dart';
import '../../ortak/viewmodel/islem_viewmodel.dart';
import 'fidan_listesi_viewmodel.dart';

/// Fidan ekleme, düzenleme ve katalogdan kaldırma işlemleri.
class FidanFormViewModel extends IslemViewModel {
  /// Yeni fidan ise ekler, mevcut fidan ise günceller.
  ///
  /// Kaydetmeden önce katalogda **aynı** fidan var mı diye bakılır: aynı
  /// tür/çeşit/anaç/yaş/kök tipi ikinci kez eklenemez. Katalogun zamanla
  /// çöplüğe dönmesinin başlıca yolu bu (bkz. Faz 3 kabul kriteri 7).
  ///
  /// Kontrol her tuşa basışta değil yalnızca kaydederken yapılıyor: canlı
  /// kontrol her harf için bir Firestore okuması demekti (KURALLAR.md §4.3).
  Future<bool> kaydet(Fidan fidan) => calistir(() async {
    final repository = ref.read(fidanRepositorySaglayici);

    final benzerler = await repository.benzerleriBul(fidan);
    if (benzerler.any(fidan.ayniFidanMi)) {
      throw const DogrulamaHatasi(Metinler.fidanMukerrer);
    }

    // Düzenlemede ayrıca bir tazeleme gerekmiyor: `fidanSaglayici` belgeyi
    // `snapshots()` ile izliyor ve yerel yazmayı anında yayıyor.
    if (fidan.yeniMi) {
      await repository.ekle(fidan);
    } else {
      await repository.guncelle(fidan);
    }
    // Liste `get()` ile sayfalandığı için kendiliğinden tazelenmiyor.
    ref.invalidate(fidanListesiViewModelSaglayici);
  }, etiket: 'Fidan kaydı');

  /// Fidanı katalogdan kaldırır. Kayıt silinmez, pasife alınır
  /// (bkz. KURALLAR.md §4.2).
  Future<bool> pasifeAl(String fidanId) => calistir(() async {
    await ref
        .read(fidanRepositorySaglayici)
        .aktifligiDegistir(fidanId, aktif: false);
    ref.invalidate(fidanListesiViewModelSaglayici);
  }, etiket: 'Fidan katalogdan kaldırma');
}

final fidanFormViewModelSaglayici =
    AsyncNotifierProvider<FidanFormViewModel, void>(
      FidanFormViewModel.new,
      isAutoDispose: true,
    );
