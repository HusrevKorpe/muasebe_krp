import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/metin/metinler.dart';
import '../../../data/islem/islem_repository.dart';
import '../../../data/islem/islem_sayfasi.dart';
import '../../ortak/viewmodel/akis_listesi_viewmodel.dart';
import '../../ortak/viewmodel/saglayici_onbellegi.dart';
import 'islem_listesi_durumu.dart';

/// Bir carinin işlem listesi — canlı akış ve sayfalama.
///
/// Liste Firestore'u `snapshots()` ile dinler: kaydedilen işlem ağ beklemeden
/// listede belirir, ortak defterin öteki telefonundan girilen kayıt da
/// kendiliğinden düşer. Gerekçesi [AkisListesiViewModel]'de.
///
/// Yürüyen bakiye burada hesaplanmaz; liste yalnızca kayıtları taşır. Bakiye
/// kolonu `islemDokumuSaglayici` içinde, carinin önbelleklenmiş bakiyesiyle
/// birleştirilerek üretilir. Bu ayrım sayesinde carinin adı değiştiğinde
/// işlem listesi baştan kurulmaz.
class IslemListesiViewModel
    extends AkisListesiViewModel<IslemListesiDurumu, IslemSayfasi> {
  IslemListesiViewModel(this.cariId);

  final String cariId;

  @override
  int get sayfaBoyu => IslemRepository.varsayilanSayfaBoyu;

  @override
  Future<IslemListesiDurumu> build() {
    // Cari detayına her girişte liste sıfırdan kurulmasın: kullanıcı listeyle
    // işlem detayı arasında sürekli gidip geliyor.
    birSureSakla(ref);
    return ilkBaglanti();
  }

  @override
  Stream<IslemSayfasi> akisKur(int sinir) => ref
      .read(islemRepositorySaglayici)
      .listeyiIzle(cariId: cariId, sinir: sinir);

  @override
  IslemListesiDurumu durumaCevir(IslemSayfasi sayfa) =>
      IslemListesiDurumu(kayitlar: sayfa.kayitlar, dahaVar: sayfa.dahaVar);

  @override
  IslemListesiDurumu hataliDurum(IslemListesiDurumu mevcut, Object hata) =>
      mevcut.kopyala(
        dahaYukleniyor: false,
        sayfaHatasi: Metinler.sonrakiIslemlerYuklenemedi,
      );

  /// Akışı baştan kurar — aşağı çekerek yenilemede çağrılır.
  ///
  /// Canlı akışta tazelenecek bir şey yok; bu çağrının işi bağlantı takılıp
  /// kalmışsa Firestore'u yeniden denemeye zorlamak. Liste ekrandan **silinmez**.
  Future<void> yenile() => durumaYaz(bastanBagla);

  /// Sonraki (daha eski) sayfayı da akışa dahil eder.
  ///
  /// Eldeki kayıtlar ekranda kalır, altta yalnızca bir gösterge döner.
  Future<void> dahaYukle() async {
    final mevcut = state.value;
    if (mevcut == null ||
        !mevcut.dahaVar ||
        mevcut.dahaYukleniyor ||
        mevcut.bosMu) {
      return;
    }

    state = AsyncValue<IslemListesiDurumu>.data(
      mevcut.kopyala(dahaYukleniyor: true, hatayiTemizle: true),
    );
    await durumaYaz(sayfaEkle);
  }
}

final islemListesiViewModelSaglayici =
    AsyncNotifierProvider.family<
      IslemListesiViewModel,
      IslemListesiDurumu,
      String
    >(IslemListesiViewModel.new, isAutoDispose: true);
