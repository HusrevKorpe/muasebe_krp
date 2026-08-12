import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/cari/cari_repository.dart';
import '../../../domain/cari/cari.dart';
import '../../ortak/viewmodel/islem_viewmodel.dart';
import 'cari_listesi_viewmodel.dart';

/// Cari ekleme, düzenleme ve pasife alma işlemleri.
class CariFormViewModel extends IslemViewModel {
  /// Yeni cari ise ekler, mevcut cari ise günceller.
  Future<bool> kaydet(Cari cari) => calistir(() async {
    final repository = ref.read(cariRepositorySaglayici);
    if (cari.yeniMi) {
      await repository.ekle(cari);
    } else {
      await repository.guncelle(cari);
    }
    // Liste `get()` ile sayfalandığı için kendiliğinden tazelenmiyor.
    // Firestore yerel yazmayı sorgu sonucuna karıştırdığından, çevrimdışı
    // eklenen cari de bu tazelemede listede görünür.
    ref.invalidate(cariListesiViewModelSaglayici);
  }, etiket: 'Cari kaydı');

  /// Cariyi listeden kaldırır. Kayıt silinmez, yalnızca pasife alınır
  /// (bkz. KURALLAR.md §4.2).
  Future<bool> pasifeAl(String cariId) => calistir(() async {
    await ref
        .read(cariRepositorySaglayici)
        .aktifligiDegistir(cariId, aktif: false);
    ref.invalidate(cariListesiViewModelSaglayici);
  }, etiket: 'Cari pasife alma');
}

final cariFormViewModelSaglayici =
    AsyncNotifierProvider<CariFormViewModel, void>(
      CariFormViewModel.new,
      isAutoDispose: true,
    );
