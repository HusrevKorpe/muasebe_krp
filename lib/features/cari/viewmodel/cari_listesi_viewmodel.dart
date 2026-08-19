import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/metin/metinler.dart';
import '../../../data/cari/cari_repository.dart';
import '../../../data/cari/cari_sayfasi.dart';
import '../../../domain/cari/cari_suzgeci.dart';
import '../../ortak/viewmodel/akis_listesi_viewmodel.dart';
import 'cari_listesi_durumu.dart';

/// Cari listesinin arama ve sayfalama mantığı.
///
/// Liste Firestore'u `snapshots()` ile dinler; gerekçesi
/// [AkisListesiViewModel]'de.
///
/// Her süzgecin kendi örneği var: Kişiler ekranındaki üç sekme aynı anda
/// ağaçta duruyor ve her biri kendi sorgusunu, kendi sayfa sınırını taşıyor.
/// Sekme değiştirmek listeyi baştan kurmuyor.
class CariListesiViewModel
    extends AkisListesiViewModel<CariListesiDurumu, CariSayfasi> {
  CariListesiViewModel(this.suzgec);

  /// Her tuşa basışta sorgu atmamak için beklenen süre. Firestore okuma başına
  /// ücretlendirir; "Ahmet" yazmak 5 sorgu değil 1 sorgu olmalı.
  static const Duration _aramaGecikmesi = Duration(milliseconds: 300);

  /// Listede kimlerin görüneceği: müşteriler, fidancılar ya da açık hesaplar.
  /// Açık hesap sekmesinde arama kutusu yok — gerekçesi
  /// `CariRepository.listeyiIzle`'de.
  final CariSuzgeci suzgec;

  Timer? _aramaZamanlayici;
  String _arama = '';

  @override
  int get sayfaBoyu => switch (suzgec) {
    CariSuzgeci.musteriler ||
    CariSuzgeci.fidancilar => CariRepository.varsayilanSayfaBoyu,
    CariSuzgeci.acikHesap => CariRepository.acikHesapSayfaBoyu,
  };

  @override
  Future<CariListesiDurumu> build() {
    ref.onDispose(() => _aramaZamanlayici?.cancel());
    return ilkBaglanti();
  }

  @override
  Stream<CariSayfasi> akisKur(int sinir) => ref
      .read(cariRepositorySaglayici)
      .listeyiIzle(suzgec: suzgec, arama: _arama, sinir: sinir);

  @override
  CariListesiDurumu durumaCevir(CariSayfasi sayfa) => CariListesiDurumu(
    kayitlar: sayfa.kayitlar,
    arama: _arama,
    dahaVar: sayfa.dahaVar,
  );

  @override
  CariListesiDurumu hataliDurum(CariListesiDurumu mevcut, Object hata) =>
      mevcut.kopyala(
        dahaYukleniyor: false,
        sayfaHatasi: Metinler.dahaFazlaYuklenemedi,
      );

  /// Arama kutusundaki her değişiklikte çağrılır; sorgu gecikmeyle atılır.
  void aramayiDegistir(String metin) {
    if (metin == _arama) return;
    _arama = metin;
    _aramaZamanlayici?.cancel();
    _aramaZamanlayici = Timer(
      _aramaGecikmesi,
      () => unawaited(durumaYaz(bastanBagla)),
    );
  }

  /// Akışı baştan kurar — aşağı çekerek yenilemede çağrılır.
  ///
  /// Canlı akışta tazelenecek bir şey yok; bu çağrının işi bağlantı takılıp
  /// kalmışsa Firestore'u yeniden denemeye zorlamak. Liste ekrandan **silinmez**.
  Future<void> yenile() => durumaYaz(bastanBagla);

  /// Sonraki sayfayı da akışa dahil eder. Eldeki kayıtlar ekranda kalır,
  /// altta yalnızca bir gösterge döner.
  ///
  /// Ölçüt yalnızca [CariListesiDurumu.dahaVar]: liste **boşken de** devamı
  /// istenebilmeli. Müşteri sekmesinde sunucudan gelen sayfanın fidancıları
  /// elde ayıklanıyor (`CariSuzgeci.kayitGirerMi`) ve ilk sayfanın tamamı
  /// fidancıysa geriye hiç satır kalmaz; "boşsa yükleme" kuralı o hâlde listeyi
  /// kalıcı olarak boş gösterirdi.
  Future<void> dahaYukle() async {
    final mevcut = state.value;
    if (mevcut == null || !mevcut.dahaVar || mevcut.dahaYukleniyor) return;

    state = AsyncValue<CariListesiDurumu>.data(
      mevcut.kopyala(dahaYukleniyor: true, hatayiTemizle: true),
    );
    await durumaYaz(sayfaEkle);
  }
}

final cariListesiViewModelSaglayici =
    AsyncNotifierProvider.family<
      CariListesiViewModel,
      CariListesiDurumu,
      CariSuzgeci
    >(CariListesiViewModel.new);
