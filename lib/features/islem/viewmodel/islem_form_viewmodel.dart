import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/para/kurus.dart';
import '../../../data/islem/islem_repository.dart';
import '../../../domain/islem/islem.dart';
import '../../ortak/viewmodel/islem_viewmodel.dart';

/// İşlem kaydetme, düzenleme, iptal etme ve bakiye onarımı.
///
/// Kaydettikten sonra liste **tazelenmez**: `IslemListesiViewModel` Firestore'u
/// canlı dinliyor ve yerel yazmayı anında yayıyor — çevrimdışı girilen işlem de
/// listede "Kaydedilmedi" işaretiyle hemen görünür. Eskiden buradaki
/// `invalidate` çağrısı listeyi sunucudan yeniden çekiyordu; kayıt yerel
/// önbelleğe milisaniyede düşse de ekran o ağ turunu bekliyordu.
class IslemFormViewModel extends IslemViewModel {
  /// Yeni işlemi kaydeder ve cari bakiyesini aynı batch içinde günceller.
  Future<bool> kaydet({required String cariId, required Islem islem}) =>
      calistir(() async {
        await ref
            .read(islemRepositorySaglayici)
            .ekle(cariId: cariId, islem: islem);
      }, etiket: 'İşlem kaydı');

  /// Kayıtlı işlemi günceller; bakiyeye yalnızca fark yazılır.
  ///
  /// [eski] kaydın düzenleme öncesi hâlidir ve bakiye farkı ondan hesaplanır —
  /// formun okuduğu akıştan gelir (bkz. [IslemRepository.guncelle]).
  Future<bool> guncelle({
    required String cariId,
    required Islem eski,
    required Islem yeni,
  }) => calistir(() async {
    await ref
        .read(islemRepositorySaglayici)
        .guncelle(cariId: cariId, eski: eski, yeni: yeni);
  }, etiket: 'İşlem güncelleme');

  /// İşlemi iptal işaretler; kayıt silinmez (bkz. KURALLAR.md §4.2).
  Future<bool> iptalEt({
    required String cariId,
    required Islem islem,
    String? neden,
  }) => calistir(() async {
    await ref
        .read(islemRepositorySaglayici)
        .iptalEt(cariId: cariId, islem: islem, neden: neden);
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
    }, etiket: 'Bakiye onarımı');
    return sonuc;
  }
}

final islemFormViewModelSaglayici =
    AsyncNotifierProvider<IslemFormViewModel, void>(
      IslemFormViewModel.new,
      isAutoDispose: true,
    );
