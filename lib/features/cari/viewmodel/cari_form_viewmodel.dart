import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/cari/cari_repository.dart';
import '../../../domain/cari/cari.dart';
import '../../ortak/viewmodel/islem_viewmodel.dart';
import 'cari_sayisi_saglayici.dart';

/// Cari ekleme, düzenleme, pasife alma ve geri alma işlemleri.
///
/// Kaydettikten sonra liste **tazelenmez**: `CariListesiViewModel` Firestore'u
/// canlı dinliyor ve yerel yazmayı anında yayıyor. Eskiden buradaki
/// `invalidate` çağrısı listeyi sunucudan yeniden çekiyordu; kayıt yerel
/// önbelleğe milisaniyede düşse de ekran o ağ turunu bekliyordu.
///
/// Listenin başındaki kişi sayısı ise canlı değil: tek seferlik bir toplama
/// sorgusundan geliyor ([cariSayisiSaglayici]). Kişi eklenip çıkarıldığında
/// sayı kendiliğinden değişmediği için o sağlayıcı burada düşürülüyor —
/// kullanıcının istediği tam olarak buydu: *"kaç kişi eklersek o kadar
/// göstersin."*
class CariFormViewModel extends IslemViewModel {
  /// Yeni cari ise ekler, mevcut cari ise günceller.
  Future<bool> kaydet(Cari cari) => calistir(() async {
    final repository = ref.read(cariRepositorySaglayici);
    if (cari.yeniMi) {
      await repository.ekle(cari);
    } else {
      await repository.guncelle(cari);
    }
    // Düzenlemede de gerekiyor: kişi müşteriden fidancıya geçtiğinde iki
    // sekmenin de sayısı kayar.
    _sayiyiDusur();
  }, etiket: 'Cari kaydı');

  /// Cariyi listeden kaldırır. Kayıt silinmez, yalnızca pasife alınır
  /// (bkz. KURALLAR.md §4.2).
  Future<bool> pasifeAl(String cariId) => calistir(() async {
    await ref
        .read(cariRepositorySaglayici)
        .aktifligiDegistir(cariId, aktif: false);
    _sayiyiDusur();
  }, etiket: 'Cari pasife alma');

  /// Kaldırılmış cariyi listeye geri alır — [pasifeAl]'ın tersi.
  ///
  /// Ayarlar → Kaldırılan Kişiler sayfasından çağrılıyor. Liste tazelenmez:
  /// kayıt aktifleşince pasif listenin sorgusundan kendiliğinden düşer.
  Future<bool> geriAl(String cariId) => calistir(() async {
    await ref
        .read(cariRepositorySaglayici)
        .aktifligiDegistir(cariId, aktif: true);
    _sayiyiDusur();
  }, etiket: 'Cari geri alma');

  /// Her sekmenin kişi sayısını yeniden sordurur.
  ///
  /// Süzgeç tek tek seçilmiyor: bir kayıt sekme değiştirebiliyor ve pasife
  /// alınan kişi hem kendi grubunun hem kaldırılanların sayısını oynatıyor.
  /// Sorgunun ücreti 1000 belge başına tek okuma.
  void _sayiyiDusur() => ref.invalidate(cariSayisiSaglayici);
}

final cariFormViewModelSaglayici =
    AsyncNotifierProvider<CariFormViewModel, void>(
      CariFormViewModel.new,
      isAutoDispose: true,
    );
