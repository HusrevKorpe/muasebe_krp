import '../../core/para/kurus.dart';

/// Açık hesapların toplamı: kaç hesap açık, ne kadar alacak, ne kadar borç.
///
/// Alacak ve borç ayrı toplanır, **netleştirilmez**. Birinde 10.000 alacak,
/// başkasında 10.000 borç varken net sıfır çıkar; oysa kapanmamış iki hesap
/// vardır ve kullanıcının görmesi gereken şey odur.
class AcikHesapOzeti {
  const AcikHesapOzeti({
    required this.adet,
    required this.alacak,
    required this.borc,
  });

  /// Bakiyeleri işaretine göre iki toplama ayırır.
  ///
  /// Sıfır bakiye ne sayıma ne toplama girer: kapalı hesap açık hesap
  /// listesinin konusu değil. Açık hesap sorgusu zaten sıfırları dışarıda
  /// bırakıyor; bu ayıklama, çağıranın süzgeçsiz bir listeyi de verebilmesi
  /// için burada tekrar yapılıyor.
  factory AcikHesapOzeti.hesapla(Iterable<Kurus> bakiyeler) {
    var adet = 0;
    var alacak = Kurus.sifir;
    var borc = Kurus.sifir;

    for (final bakiye in bakiyeler) {
      if (bakiye.sifirMi) continue;
      adet++;
      if (bakiye.pozitifMi) {
        alacak += bakiye;
      } else {
        borc += bakiye.mutlak;
      }
    }

    return AcikHesapOzeti(adet: adet, alacak: alacak, borc: borc);
  }

  static const AcikHesapOzeti bos = AcikHesapOzeti(
    adet: 0,
    alacak: Kurus.sifir,
    borc: Kurus.sifir,
  );

  /// Bakiyesi sıfır olmayan cari sayısı.
  final int adet;

  /// Carilerin işletmeye borcu — pozitif bakiyelerin toplamı.
  final Kurus alacak;

  /// İşletmenin carilere borcu — negatif bakiyelerin toplamı, işaretsiz.
  final Kurus borc;

  bool get bosMu => adet == 0;

  @override
  bool operator ==(Object other) =>
      other is AcikHesapOzeti &&
      other.adet == adet &&
      other.alacak == alacak &&
      other.borc == borc;

  @override
  int get hashCode => Object.hash(adet, alacak, borc);

  @override
  String toString() =>
      'AcikHesapOzeti($adet, ${alacak.deger}, ${borc.deger})';
}
