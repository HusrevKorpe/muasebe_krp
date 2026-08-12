import '../../core/para/kurus.dart';
import 'bakiye_dokumu.dart';
import 'bakiye_satiri.dart';
import 'islem.dart';
import 'islem_siralamasi.dart';

/// Yürüyen bakiyeyi hesaplar — uygulamanın tek asıl işi.
///
/// `bakiye = toplam borç − toplam alacak`. Pozitif bakiye carinin işletmeye,
/// negatif bakiye işletmenin cariye borçlu olduğunu gösterir (KURALLAR.md §3.4).
/// Hesap kuruş tam sayıları üzerinde yürür; hiçbir adımda `double` yoktur.
abstract final class BakiyeHesaplayici {
  /// Eskiden yeniye yürür — ekstrenin doğal yönü.
  ///
  /// [islemler] sırasız verilebilir; burada [islemKarsilastir] ile sıralanır.
  /// [devir], seçilen tarih aralığından önceki bakiyedir.
  static BakiyeDokumu ileri({
    required List<Islem> islemler,
    Kurus devir = Kurus.sifir,
  }) {
    final sirali = eskidenYeniye(islemler);

    final satirlar = <BakiyeSatiri>[];
    var yuruyen = devir;
    for (final islem in sirali) {
      yuruyen += islem.bakiyeEtkisi;
      satirlar.add(BakiyeSatiri(islem: islem, yuruyenBakiye: yuruyen));
    }

    return _dokum(satirlar: satirlar, devir: devir, bakiye: yuruyen);
  }

  /// Yeniden eskiye yürür — ekranda son işlem en üstte durur.
  ///
  /// Cari kaydındaki önbelleklenmiş bakiyeden geriye doğru sayar; böylece bir
  /// sayfa işlem göstermek için carinin **tüm** geçmişini çekmek gerekmez
  /// (bkz. KURALLAR.md §4.3). Her satır, o işlemden sonraki bakiyeyi taşır:
  /// en üstteki satırın bakiyesi [sonBakiye]'dir.
  ///
  /// Önbelleklenmiş bakiye bozuksa bütün kolon kayar; onarımı
  /// `IslemRepository.bakiyeYenidenHesapla` yapar.
  static BakiyeDokumu geriye({
    required List<Islem> islemler,
    required Kurus sonBakiye,
  }) {
    final sirali = yenidenEskiye(islemler);

    final satirlar = <BakiyeSatiri>[];
    var yuruyen = sonBakiye;
    for (final islem in sirali) {
      satirlar.add(BakiyeSatiri(islem: islem, yuruyenBakiye: yuruyen));
      // Bir üstteki satırın bakiyesi, bu işlemin etkisi geri alınmış hâlidir.
      yuruyen -= islem.bakiyeEtkisi;
    }

    return _dokum(satirlar: satirlar, devir: yuruyen, bakiye: sonBakiye);
  }

  /// İşlemlerden bakiyeyi baştan hesaplar — önbellek onarımının ve testin ölçütü.
  static Kurus bakiye(Iterable<Islem> islemler) => islemler.fold(
    Kurus.sifir,
    (toplam, islem) => toplam + islem.bakiyeEtkisi,
  );

  static BakiyeDokumu _dokum({
    required List<BakiyeSatiri> satirlar,
    required Kurus devir,
    required Kurus bakiye,
  }) {
    var borc = Kurus.sifir;
    var alacak = Kurus.sifir;
    for (final satir in satirlar) {
      borc += satir.islem.borc;
      alacak += satir.islem.alacak;
    }

    return BakiyeDokumu(
      satirlar: List<BakiyeSatiri>.unmodifiable(satirlar),
      devir: devir,
      toplamBorc: borc,
      toplamAlacak: alacak,
      bakiye: bakiye,
    );
  }
}
