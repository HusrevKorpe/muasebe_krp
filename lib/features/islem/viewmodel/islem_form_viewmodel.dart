import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/para/kurus.dart';
import '../../../data/islem/islem_repository.dart';
import '../../../domain/islem/islem.dart';
import '../../ortak/viewmodel/islem_viewmodel.dart';
import 'islem_listesi_viewmodel.dart';

/// İşlem kaydetme, iptal etme ve bakiye onarımı.
class IslemFormViewModel extends IslemViewModel {
  /// Yeni işlemi kaydeder ve cari bakiyesini aynı batch içinde günceller.
  Future<bool> kaydet({required String cariId, required Islem islem}) =>
      calistir(() async {
        await ref
            .read(islemRepositorySaglayici)
            .ekle(cariId: cariId, islem: islem);
        _listeyiTazele(cariId);
      }, etiket: 'İşlem kaydı');

  /// İşlemi iptal işaretler; kayıt silinmez (bkz. KURALLAR.md §4.2).
  Future<bool> iptalEt({
    required String cariId,
    required Islem islem,
    String? neden,
  }) => calistir(() async {
    await ref
        .read(islemRepositorySaglayici)
        .iptalEt(cariId: cariId, islem: islem, neden: neden);
    _listeyiTazele(cariId);
  }, etiket: 'İşlem iptali');

  /// Bakiyeyi tüm işlemlerden baştan hesaplar ve cari kaydına yazar.
  ///
  /// Sonuç dönerse onarım tamamlanmıştır; hata durumunda `null` döner ve mesaj
  /// `state.error` üzerinden okunur.
  Future<Kurus?> bakiyeyiYenidenHesapla(String cariId) async {
    Kurus? sonuc;
    await calistir(() async {
      sonuc = await ref
          .read(islemRepositorySaglayici)
          .bakiyeYenidenHesapla(cariId);
      _listeyiTazele(cariId);
    }, etiket: 'Bakiye onarımı');
    return sonuc;
  }

  /// İşlem listesi `get()` ile sayfalandığı için kendiliğinden tazelenmiyor.
  ///
  /// Firestore yerel yazmayı sorgu sonucuna karıştırdığından, çevrimdışı
  /// girilen işlem de bu tazelemede listede görünür.
  void _listeyiTazele(String cariId) {
    ref.invalidate(islemListesiViewModelSaglayici(cariId));
  }
}

final islemFormViewModelSaglayici =
    AsyncNotifierProvider<IslemFormViewModel, void>(
      IslemFormViewModel.new,
      isAutoDispose: true,
    );
