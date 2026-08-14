import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/metin/metinler.dart';
import '../../../data/urun/urun_repository.dart';
import '../../../data/urun/urun_sayfasi.dart';
import '../../ortak/viewmodel/akis_listesi_viewmodel.dart';
import 'urun_listesi_durumu.dart';

/// Ürün listesinin arama ve sayfalama mantığı.
///
/// Sıralama seçeneği yok: liste her zaman ada göre alfabetik gelir. Liste
/// Firestore'u `snapshots()` ile dinler; gerekçesi [AkisListesiViewModel]'de.
class UrunListesiViewModel
    extends AkisListesiViewModel<UrunListesiDurumu, UrunSayfasi> {
  /// Her tuşa basışta sorgu atmamak için beklenen süre — Firestore okuma
  /// başına ücretlendirir (bkz. `CariListesiViewModel`).
  static const Duration _aramaGecikmesi = Duration(milliseconds: 300);

  Timer? _aramaZamanlayici;
  String _arama = '';

  @override
  int get sayfaBoyu => UrunRepository.varsayilanSayfaBoyu;

  @override
  Future<UrunListesiDurumu> build() {
    ref.onDispose(() => _aramaZamanlayici?.cancel());
    return ilkBaglanti();
  }

  @override
  Stream<UrunSayfasi> akisKur(int sinir) =>
      ref.read(urunRepositorySaglayici).listeyiIzle(arama: _arama, sinir: sinir);

  @override
  UrunListesiDurumu durumaCevir(UrunSayfasi sayfa) => UrunListesiDurumu(
    kayitlar: sayfa.kayitlar,
    arama: _arama,
    dahaVar: sayfa.dahaVar,
  );

  @override
  UrunListesiDurumu hataliDurum(UrunListesiDurumu mevcut, Object hata) =>
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

  /// Akışı baştan kurar — aşağı çekerek yenilemede çağrılır. Liste ekrandan
  /// **silinmez**; canlı akışta tazelenecek bir şey yok, bu çağrı yalnızca
  /// takılı bir bağlantıyı yeniden denemeye zorlar.
  Future<void> yenile() => durumaYaz(bastanBagla);

  /// Sonraki sayfayı da akışa dahil eder. Eldeki kayıtlar ekranda kalır,
  /// altta yalnızca bir gösterge döner.
  Future<void> dahaYukle() async {
    final mevcut = state.value;
    if (mevcut == null ||
        !mevcut.dahaVar ||
        mevcut.dahaYukleniyor ||
        mevcut.bosMu) {
      return;
    }

    state = AsyncValue<UrunListesiDurumu>.data(
      mevcut.kopyala(dahaYukleniyor: true, hatayiTemizle: true),
    );
    await durumaYaz(sayfaEkle);
  }
}

final urunListesiViewModelSaglayici =
    AsyncNotifierProvider<UrunListesiViewModel, UrunListesiDurumu>(
      UrunListesiViewModel.new,
    );
