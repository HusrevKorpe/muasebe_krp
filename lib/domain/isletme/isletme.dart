import '../ortak/harita.dart';
import 'banka_hesabi.dart';

/// Kullanıcının kendi işletmesi. Ekstre başlığını bu belge üretir.
///
/// Belge kimliği Firebase Auth `uid` değeridir: tüm veri `isletmeler/{uid}`
/// altında yaşar ve güvenlik kuralı tek satırla kurulur (bkz. `firestore.rules`).
class Isletme {
  const Isletme({
    required this.id,
    required this.ad,
    this.unvan = '',
    this.adres = '',
    this.telefon = '',
    this.faks,
    this.vergiDairesi = '',
    this.vergiNo = '',
    this.logoUrl,
    this.bankaHesaplari = const <BankaHesabi>[],
    this.olusturmaTarihi,
    this.guncellemeTarihi,
  });

  factory Isletme.fromMap(String id, Map<String, Object?> veri) => Isletme(
    id: id,
    ad: haritaMetin(veri, alanAd),
    unvan: haritaMetin(veri, alanUnvan),
    adres: haritaMetin(veri, alanAdres),
    telefon: haritaMetin(veri, alanTelefon),
    faks: haritaMetinOpsiyonel(veri, alanFaks),
    vergiDairesi: haritaMetin(veri, alanVergiDairesi),
    vergiNo: haritaMetin(veri, alanVergiNo),
    logoUrl: haritaMetinOpsiyonel(veri, alanLogoUrl),
    bankaHesaplari: haritaListesi(veri, alanBankaHesaplari)
        .map(BankaHesabi.fromMap)
        .toList(growable: false),
    olusturmaTarihi: haritaTarih(veri, alanOlusturmaTarihi),
    guncellemeTarihi: haritaTarih(veri, alanGuncellemeTarihi),
  );

  static const String koleksiyon = 'isletmeler';

  static const String alanAd = 'ad';
  static const String alanUnvan = 'unvan';
  static const String alanAdres = 'adres';
  static const String alanTelefon = 'telefon';
  static const String alanFaks = 'faks';
  static const String alanVergiDairesi = 'vergiDairesi';
  static const String alanVergiNo = 'vergiNo';
  static const String alanLogoUrl = 'logoUrl';
  static const String alanBankaHesaplari = 'bankaHesaplari';
  static const String alanOlusturmaTarihi = 'olusturmaTarihi';
  static const String alanGuncellemeTarihi = 'guncellemeTarihi';

  final String id;

  /// Ticari ad: `Favori Fidancılık`
  final String ad;

  /// Resmî ünvan eki: `Tar.Taş.Hay.Ltd.Şti`
  final String unvan;

  /// Çok satırlı olabilir; ekstre başlığında olduğu gibi basılır.
  final String adres;

  final String telefon;
  final String? faks;
  final String vergiDairesi;
  final String vergiNo;

  /// Faz 4'te ekstre başlığına basılacak logo. Faz 1'de yalnızca alan durur.
  final String? logoUrl;

  final List<BankaHesabi> bankaHesaplari;
  final DateTime? olusturmaTarihi;
  final DateTime? guncellemeTarihi;

  /// Ekstre başlığında ad ve ünvan tek satır olarak basılır.
  String get tamAd => unvan.isEmpty ? ad : '$ad $unvan';

  /// Kullanıcının düzenleyebildiği alanlar.
  ///
  /// Zaman damgaları buraya girmez; onları yalnızca repository yazar
  /// (bkz. KURALLAR.md §4.2).
  Map<String, Object?> duzenlenebilirAlanlar() => <String, Object?>{
    alanAd: ad,
    alanUnvan: unvan,
    alanAdres: adres,
    alanTelefon: telefon,
    alanFaks: faks,
    alanVergiDairesi: vergiDairesi,
    alanVergiNo: vergiNo,
    alanLogoUrl: logoUrl,
    alanBankaHesaplari: bankaHesaplari
        .map((hesap) => hesap.toMap())
        .toList(growable: false),
  };

  Map<String, Object?> toMap() => <String, Object?>{
    ...duzenlenebilirAlanlar(),
    alanOlusturmaTarihi: olusturmaTarihi,
    alanGuncellemeTarihi: guncellemeTarihi,
  };

  Isletme kopyala({
    String? ad,
    String? unvan,
    String? adres,
    String? telefon,
    String? faks,
    String? vergiDairesi,
    String? vergiNo,
    List<BankaHesabi>? bankaHesaplari,
  }) => Isletme(
    id: id,
    ad: ad ?? this.ad,
    unvan: unvan ?? this.unvan,
    adres: adres ?? this.adres,
    telefon: telefon ?? this.telefon,
    faks: faks ?? this.faks,
    vergiDairesi: vergiDairesi ?? this.vergiDairesi,
    vergiNo: vergiNo ?? this.vergiNo,
    logoUrl: logoUrl,
    bankaHesaplari: bankaHesaplari ?? this.bankaHesaplari,
    olusturmaTarihi: olusturmaTarihi,
    guncellemeTarihi: guncellemeTarihi,
  );

  @override
  bool operator ==(Object other) =>
      other is Isletme &&
      other.id == id &&
      other.ad == ad &&
      other.unvan == unvan &&
      other.adres == adres &&
      other.telefon == telefon &&
      other.faks == faks &&
      other.vergiDairesi == vergiDairesi &&
      other.vergiNo == vergiNo &&
      other.logoUrl == logoUrl &&
      other.olusturmaTarihi == olusturmaTarihi &&
      other.guncellemeTarihi == guncellemeTarihi &&
      _listelerEsitMi(other.bankaHesaplari, bankaHesaplari);

  @override
  int get hashCode => Object.hash(
    id,
    ad,
    unvan,
    adres,
    telefon,
    faks,
    vergiDairesi,
    vergiNo,
    logoUrl,
    Object.hashAll(bankaHesaplari),
    olusturmaTarihi,
    guncellemeTarihi,
  );

  @override
  String toString() => 'Isletme($id, $ad)';

  static bool _listelerEsitMi(List<BankaHesabi> a, List<BankaHesabi> b) {
    if (a.length != b.length) return false;
    for (var sira = 0; sira < a.length; sira++) {
      if (a[sira] != b[sira]) return false;
    }
    return true;
  }
}
