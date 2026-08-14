import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../data/secenek/secenek_repository.dart';
import '../../../domain/secenek/secenek.dart';
import '../../ortak/viewmodel/islem_viewmodel.dart';

/// Tür, çeşit ve anaç listelerine satır ekleme, düzeltme ve silme.
///
/// Kaydettikten sonra liste **tazelenmez**: `SecenekListesiViewModel`
/// Firestore'u canlı dinliyor ve yerel yazmayı anında yayıyor
/// (bkz. KURALLAR.md §4.3).
class SecenekFormViewModel extends IslemViewModel {
  /// Yeni satırsa ekler, mevcut satırsa adını günceller.
  ///
  /// Kaydetmeden önce listede **aynı adlı** bir satır var mı diye bakılır:
  /// `M9` ile `m9` aynı sayılır (bkz. [Secenek.ayniMi]). Bu listelerin tek işi
  /// tıklanacak temiz bir küme sunmak; ikizlerle dolarsa iş görmez.
  ///
  /// Kontrol yalnızca önbellekte koşar, sunucuya sorulmaz — kaydetme düğmesi
  /// ağa bağlanmamalı (bkz. [SecenekRepository.benzerleriBul]).
  Future<bool> kaydet(Secenek secenek) => calistir(() async {
    final repository = ref.read(secenekRepositorySaglayici);

    final benzerler = await repository.benzerleriBul(secenek);
    if (benzerler.any(secenek.ayniMi)) {
      throw const DogrulamaHatasi(Metinler.secenekMukerrer);
    }

    if (secenek.yeniMi) {
      await repository.ekle(secenek);
    } else {
      await repository.guncelle(secenek);
    }
  }, etiket: 'Liste satırı kaydı');

  /// Satırı listeden siler. Burada pasife alma yok, gerçek silme var; gerekçesi
  /// [SecenekRepository.sil]'de.
  Future<bool> sil(Secenek secenek) => calistir(() async {
    await ref.read(secenekRepositorySaglayici).sil(secenek);
  }, etiket: 'Liste satırı silme');
}

final secenekFormViewModelSaglayici =
    AsyncNotifierProvider<SecenekFormViewModel, void>(
      SecenekFormViewModel.new,
      isAutoDispose: true,
    );
