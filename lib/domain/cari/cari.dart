import '../../core/metin/turkce.dart' as turkce;
import '../../core/para/kurus.dart';
import '../ortak/harita.dart';

/// Cari hesap — müşteri ya da tedarikçi.
///
/// Fidancılıkta alım ve satım çoğu kez aynı kişiyle yapılır; bu yüzden ayrı
/// "müşteri" ve "tedarikçi" tipi yoktur. Yön bakiyenin işaretinden okunur:
/// pozitif bakiye carinin işletmeye, negatif bakiye işletmenin cariye borçlu
/// olduğunu gösterir (bkz. KURALLAR.md §3.4).
class Cari {
  const Cari({
    required this.id,
    required this.ad,
    this.unvan,
    this.sehir,
    this.telefon,
    this.adres,
    this.notlar,
    this.bakiye = Kurus.sifir,
    this.sonIslemTarihi,
    this.aktif = true,
    this.olusturmaTarihi,
    this.guncellemeTarihi,
  });

  /// Henüz kaydedilmemiş yeni cari. Kimliği Firestore belge oluşturulurken atanır.
  const Cari.yeni() : this(id: '', ad: '');

  factory Cari.fromMap(String id, Map<String, Object?> veri) => Cari(
    id: id,
    ad: haritaMetin(veri, alanAd),
    unvan: haritaMetinOpsiyonel(veri, alanUnvan),
    sehir: haritaMetinOpsiyonel(veri, alanSehir),
    telefon: haritaMetinOpsiyonel(veri, alanTelefon),
    adres: haritaMetinOpsiyonel(veri, alanAdres),
    notlar: haritaMetinOpsiyonel(veri, alanNotlar),
    bakiye: Kurus(haritaTamSayi(veri, alanBakiyeKurus)),
    sonIslemTarihi: haritaTarih(veri, alanSonIslemTarihi),
    aktif: haritaMantiksal(veri, alanAktif, varsayilan: true),
    olusturmaTarihi: haritaTarih(veri, alanOlusturmaTarihi),
    guncellemeTarihi: haritaTarih(veri, alanGuncellemeTarihi),
  );

  static const String koleksiyon = 'cariler';

  static const String alanAd = 'ad';
  static const String alanUnvan = 'unvan';
  static const String alanSehir = 'sehir';
  static const String alanTelefon = 'telefon';
  static const String alanAdres = 'adres';
  static const String alanNotlar = 'notlar';
  static const String alanBakiyeKurus = 'bakiyeKurus';
  static const String alanSonIslemTarihi = 'sonIslemTarihi';
  static const String alanAramaAnahtari = 'aramaAnahtari';
  static const String alanAktif = 'aktif';
  static const String alanOlusturmaTarihi = 'olusturmaTarihi';
  static const String alanGuncellemeTarihi = 'guncellemeTarihi';

  /// Firestore belge kimliği. Kaydedilmemiş cari için boştur.
  final String id;

  final String ad;
  final String? unvan;
  final String? sehir;
  final String? telefon;
  final String? adres;
  final String? notlar;

  /// Önbelleklenmiş bakiye. Faz 1'de daima sıfırdır; Faz 2'de işlem kaydıyla
  /// birlikte transaction içinde güncellenir (bkz. KURALLAR.md §4.2).
  final Kurus bakiye;

  final DateTime? sonIslemTarihi;
  final bool aktif;
  final DateTime? olusturmaTarihi;
  final DateTime? guncellemeTarihi;

  bool get yeniMi => id.isEmpty;

  /// Firestore'a yazılan normalize arama anahtarı.
  ///
  /// Her zaman [ad]'dan türetilir, ayrıca saklanan bir kopyaya güvenilmez —
  /// böylece ad değişip anahtar eski kalması mümkün olmaz.
  /// `'İstanbul Fidancılık'` → `'istanbul fidancilik'`
  String get aramaAnahtari => turkce.aramaAnahtari(ad);

  /// Listede ve detayda gösterilen ikinci satır: ünvan varsa o, yoksa şehir.
  String? get altBaslik => unvan ?? sehir;

  /// Kullanıcının düzenleyebildiği alanlar.
  ///
  /// Bakiye, aktiflik ve zaman damgaları bilerek dışarıda: onları yalnızca
  /// sistem yazar. Cari düzenlenirken bu harita olduğu gibi gönderilir, böylece
  /// Faz 2'de bir işlem kaydının güncellediği bakiye form kaydıyla ezilmez.
  Map<String, Object?> duzenlenebilirAlanlar() => <String, Object?>{
    alanAd: ad,
    alanUnvan: unvan,
    alanSehir: sehir,
    alanTelefon: telefon,
    alanAdres: adres,
    alanNotlar: notlar,
    alanAramaAnahtari: aramaAnahtari,
  };

  Map<String, Object?> toMap() => <String, Object?>{
    ...duzenlenebilirAlanlar(),
    alanBakiyeKurus: bakiye.deger,
    alanSonIslemTarihi: sonIslemTarihi,
    alanAktif: aktif,
    alanOlusturmaTarihi: olusturmaTarihi,
    alanGuncellemeTarihi: guncellemeTarihi,
  };

  @override
  bool operator ==(Object other) =>
      other is Cari &&
      other.id == id &&
      other.ad == ad &&
      other.unvan == unvan &&
      other.sehir == sehir &&
      other.telefon == telefon &&
      other.adres == adres &&
      other.notlar == notlar &&
      other.bakiye == bakiye &&
      other.sonIslemTarihi == sonIslemTarihi &&
      other.aktif == aktif &&
      other.olusturmaTarihi == olusturmaTarihi &&
      other.guncellemeTarihi == guncellemeTarihi;

  @override
  int get hashCode => Object.hash(
    id,
    ad,
    unvan,
    sehir,
    telefon,
    adres,
    notlar,
    bakiye,
    sonIslemTarihi,
    aktif,
    olusturmaTarihi,
    guncellemeTarihi,
  );

  @override
  String toString() => 'Cari($id, $ad, ${bakiye.deger})';
}
