import '../ortak/harita.dart';
import 'iban.dart';

/// İşletmenin ekstre alt bilgisinde basılan banka hesabı.
///
/// Referans ekstrede beş ayrı hesap yan yana duruyor; bu yüzden hesaplar
/// işletme belgesi içinde dizi olarak tutulur, ayrı koleksiyon açılmaz.
/// Sayı bir avuçtur ve her zaman işletme bilgisiyle birlikte okunur.
class BankaHesabi {
  const BankaHesabi({
    required this.banka,
    required this.iban,
    this.hesapNo,
    this.paraBirimi = varsayilanParaBirimi,
  });

  factory BankaHesabi.fromMap(Map<String, Object?> veri) => BankaHesabi(
    banka: haritaMetin(veri, alanBanka),
    iban: Iban.normalize(haritaMetin(veri, alanIban)),
    hesapNo: haritaMetinOpsiyonel(veri, alanHesapNo),
    paraBirimi: haritaMetin(
      veri,
      alanParaBirimi,
      varsayilan: varsayilanParaBirimi,
    ),
  );

  static const String varsayilanParaBirimi = 'TRY';

  /// Uygulamada seçilebilen para birimleri. Fidan alım satımı ağırlıklı TL,
  /// ihracatta döviz hesabı da kullanılıyor.
  static const List<String> paraBirimleri = <String>['TRY', 'USD', 'EUR'];

  static const String alanBanka = 'banka';
  static const String alanIban = 'iban';
  static const String alanHesapNo = 'hesapNo';
  static const String alanParaBirimi = 'paraBirimi';

  final String banka;

  /// Normalize edilmiş (boşluksuz, büyük harf) IBAN.
  final String iban;

  final String? hesapNo;
  final String paraBirimi;

  /// Ekranda ve ekstrede gösterilen dörtlü gruplanmış biçim.
  String get ibanBicimli => Iban.bicimle(iban);

  bool get ibanGecerliMi => Iban.gecerliMi(iban);

  Map<String, Object?> toMap() => <String, Object?>{
    alanBanka: banka,
    alanIban: iban,
    alanHesapNo: hesapNo,
    alanParaBirimi: paraBirimi,
  };

  @override
  bool operator ==(Object other) =>
      other is BankaHesabi &&
      other.banka == banka &&
      other.iban == iban &&
      other.hesapNo == hesapNo &&
      other.paraBirimi == paraBirimi;

  @override
  int get hashCode => Object.hash(banka, iban, hesapNo, paraBirimi);

  @override
  String toString() => 'BankaHesabi($banka, $iban)';
}
