import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/metin/metinler.dart';
import '../../../data/secenek/secenek_repository.dart';
import '../../../data/secenek/secenek_sayfasi.dart';
import '../../../domain/secenek/secenek_tipi.dart';
import '../../ortak/viewmodel/akis_listesi_viewmodel.dart';
import '../../ortak/viewmodel/saglayici_onbellegi.dart';
import 'secenek_listesi_durumu.dart';

/// Tek bir listenin (türler, çeşitler ya da anaçlar) arama ve sayfalama
/// mantığı.
///
/// Liste her zaman ada göre alfabetik gelir; sıralama seçeneği yok. Firestore
/// `snapshots()` ile dinlenir — gerekçesi [AkisListesiViewModel]'de.
class SecenekListesiViewModel
    extends AkisListesiViewModel<SecenekListesiDurumu, SecenekSayfasi> {
  SecenekListesiViewModel(this.tip);

  /// Her tuşa basışta sorgu atmamak için beklenen süre — Firestore okuma
  /// başına ücretlendirir (bkz. `UrunListesiViewModel`).
  static const Duration _aramaGecikmesi = Duration(milliseconds: 300);

  final SecenekTipi tip;

  Timer? _aramaZamanlayici;
  String _arama = '';

  @override
  int get sayfaBoyu => SecenekRepository.varsayilanSayfaBoyu;

  @override
  Future<SecenekListesiDurumu> build() {
    // Kullanıcı kalem kutusundan seçim sayfasına girip çıkıyor, üstelik üç kutu
    // için art arda. Sağlayıcı her çıkışta atılsaydı her giriş yeniden bir
    // Firestore dinleyicisi kurar ve ekran spinner'a düşerdi.
    birSureSakla(ref);
    ref.onDispose(() => _aramaZamanlayici?.cancel());
    return ilkBaglanti();
  }

  @override
  Stream<SecenekSayfasi> akisKur(int sinir) => ref
      .read(secenekRepositorySaglayici)
      .listeyiIzle(tip, arama: _arama, sinir: sinir);

  @override
  SecenekListesiDurumu durumaCevir(SecenekSayfasi sayfa) =>
      SecenekListesiDurumu(
        kayitlar: sayfa.kayitlar,
        arama: _arama,
        dahaVar: sayfa.dahaVar,
      );

  @override
  SecenekListesiDurumu hataliDurum(
    SecenekListesiDurumu mevcut,
    Object hata,
  ) => mevcut.kopyala(
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
  /// **silinmez**; bu çağrı yalnızca takılı bir bağlantıyı yeniden dener.
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

    state = AsyncValue<SecenekListesiDurumu>.data(
      mevcut.kopyala(dahaYukleniyor: true, hatayiTemizle: true),
    );
    await durumaYaz(sayfaEkle);
  }
}

/// Tip başına bir sağlayıcı.
///
/// `family` yerine sabit bir eşleme kullanılıyor: [AkisListesiViewModel] düz
/// `AsyncNotifier`'dan türüyor, `family` ise `FamilyAsyncNotifier` isterdi ve
/// ortak taban üç ekranda birden bozulurdu. Eşleme [SecenekTipi.values]
/// üzerinden kurulduğu için tipi atlamak mümkün değil.
final _saglayicilar =
    <
      SecenekTipi,
      AsyncNotifierProvider<SecenekListesiViewModel, SecenekListesiDurumu>
    >{
      for (final tip in SecenekTipi.values)
        tip:
            AsyncNotifierProvider<
              SecenekListesiViewModel,
              SecenekListesiDurumu
            >(() => SecenekListesiViewModel(tip), isAutoDispose: true),
    };

/// [tip] listesinin ViewModel sağlayıcısı.
AsyncNotifierProvider<SecenekListesiViewModel, SecenekListesiDurumu>
secenekListesiSaglayici(SecenekTipi tip) => _saglayicilar[tip]!;
