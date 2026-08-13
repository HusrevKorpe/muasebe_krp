import '../ortak/harita.dart';
import 'banka_hesabi.dart';

/// Kullanıcının kendi işletmesi. Ekstre başlığını bu belge üretir.
///
/// Belge kimliği sabittir: [ortakId]. Uygulamayı birden fazla kişi kullanıyor
/// ve hepsi **aynı defteri** görüyor, yani veri kişiye değil ortak deftere
/// bağlı. Kimin gireceğini `firestore.rules` içindeki izin listesi belirler.
///
/// Profil boş bırakılabilir: doldurulmazsa ekstre başlığı yalnızca sade kalır,
/// uygulamanın hiçbir yeri kilitlenmez.
class Isletme {
  const Isletme({
    required this.id,
    required this.ad,
    this.unvan = '',
    this.adres = '',
    this.telefon = '',
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
    logoUrl: haritaMetinOpsiyonel(veri, alanLogoUrl),
    bankaHesaplari: haritaListesi(veri, alanBankaHesaplari)
        .map(BankaHesabi.fromMap)
        .toList(growable: false),
    olusturmaTarihi: haritaTarih(veri, alanOlusturmaTarihi),
    guncellemeTarihi: haritaTarih(veri, alanGuncellemeTarihi),
  );

  /// Henüz doldurulmamış profilin yerine geçen boş kayıt.
  ///
  /// Ekstre profil olmadan da üretilebilmeli; başlık sade çıkar.
  static const Isletme bos = Isletme(id: ortakId, ad: '');

  static const String koleksiyon = 'isletmeler';

  /// Ortak defterin belge kimliği.
  ///
  /// Eskiden burada oturum açan hesabın `uid` değeri vardı; uygulamayı iki kişi
  /// kullanmaya başlayınca sabitlendi, çünkü iki ayrı hesabın **aynı** veriyi
  /// görmesi gerekiyor. Değiştirilirse uygulama başka bir deftere bakar ve
  /// mevcut kayıtlar görünmez olur.
  static const String ortakId = 'ortak';

  static const String alanAd = 'ad';
  static const String alanUnvan = 'unvan';
  static const String alanAdres = 'adres';
  static const String alanTelefon = 'telefon';
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
    List<BankaHesabi>? bankaHesaplari,
  }) => Isletme(
    id: id,
    ad: ad ?? this.ad,
    unvan: unvan ?? this.unvan,
    adres: adres ?? this.adres,
    telefon: telefon ?? this.telefon,
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
