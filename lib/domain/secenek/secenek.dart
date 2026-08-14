import '../../core/metin/turkce.dart' as turkce;
import '../ortak/harita.dart';
import 'secenek_tipi.dart';

/// Tür, çeşit ya da anaç listesinin tek satırı: `Elma`, `Scarlet`, `M9`.
///
/// Kayıt yalnızca bir ad taşır — fiyatı, kimliği, geçmişi yok. Fatura kalemi
/// listeden seçilen satırın **kimliğini değil metnini** kopyalar
/// (bkz. `IslemKalemi`); kalem, kaydedildiği andaki adı kendi içinde taşır.
/// Bu yüzden listeden bir satır silmek geçmiş faturaları bozmaz ve muhasebe
/// kaydı sayılmaz — silme gerekçesi `SecenekRepository.sil`'de.
class Secenek {
  const Secenek({
    required this.id,
    required this.tip,
    required this.ad,
    this.olusturmaTarihi,
    this.guncellemeTarihi,
  });

  /// Henüz kaydedilmemiş satır. Kimliği Firestore belge oluşturulurken atanır.
  const Secenek.yeni(SecenekTipi tip) : this(id: '', tip: tip, ad: '');

  /// Firestore belgesinden okur.
  ///
  /// [tip] belgeden değil okunduğu **koleksiyondan** gelir; gerekçesi
  /// [SecenekTipi.koleksiyon]'da.
  factory Secenek.fromMap(
    String id,
    SecenekTipi tip,
    Map<String, Object?> veri,
  ) => Secenek(
    id: id,
    tip: tip,
    ad: haritaMetin(veri, alanAd),
    olusturmaTarihi: haritaTarih(veri, alanOlusturmaTarihi),
    guncellemeTarihi: haritaTarih(veri, alanGuncellemeTarihi),
  );

  static const String alanAd = 'ad';
  static const String alanAramaAnahtari = 'aramaAnahtari';
  static const String alanOlusturmaTarihi = 'olusturmaTarihi';
  static const String alanGuncellemeTarihi = 'guncellemeTarihi';

  /// Firestore belge kimliği. Kaydedilmemiş satır için boştur.
  final String id;

  final SecenekTipi tip;

  /// Kullanıcının gördüğü ve faturaya düşen metin: `M9`, `Scarlet`, `Elma`.
  /// Kullanıcı verisi olduğu için tam Türkçe yazılır (KURALLAR.md §2.2).
  final String ad;

  final DateTime? olusturmaTarihi;
  final DateTime? guncellemeTarihi;

  bool get yeniMi => id.isEmpty;

  /// Firestore'a yazılan normalize anahtar: `m9`. Hem sıralama hem arama
  /// bundan okunur (bkz. `turkce.aramaAnahtari`).
  String get aramaAnahtari => turkce.aramaAnahtari(ad);

  /// Boş ada kayıt açılmaz: liste, dokunulunca kutuya hiçbir şey yazmayan bir
  /// satır göstermemeli.
  bool get gecerliMi => aramaAnahtari.isNotEmpty;

  /// İki satır aynı şeyi mi söylüyor? `M9` ile `m9` aynı sayılır.
  ///
  /// Liste zamanla aynı adın büyük/küçük harfli ikizleriyle dolmasın diye
  /// ekleme sırasında sorulur (bkz. `Urun.ayniUrunMu`).
  bool ayniMi(Secenek digeri) =>
      tip == digeri.tip && aramaAnahtari == digeri.aramaAnahtari;

  /// Kullanıcının düzenleyebildiği alanlar. Zaman damgalarını yalnızca sistem
  /// yazar (bkz. `Urun.duzenlenebilirAlanlar`).
  Map<String, Object?> duzenlenebilirAlanlar() => <String, Object?>{
    alanAd: ad,
    alanAramaAnahtari: aramaAnahtari,
  };

  Map<String, Object?> toMap() => <String, Object?>{
    ...duzenlenebilirAlanlar(),
    alanOlusturmaTarihi: olusturmaTarihi,
    alanGuncellemeTarihi: guncellemeTarihi,
  };

  Secenek kopyala({String? id, String? ad}) => Secenek(
    id: id ?? this.id,
    tip: tip,
    ad: ad ?? this.ad,
    olusturmaTarihi: olusturmaTarihi,
    guncellemeTarihi: guncellemeTarihi,
  );

  @override
  bool operator ==(Object other) =>
      other is Secenek &&
      other.id == id &&
      other.tip == tip &&
      other.ad == ad &&
      other.olusturmaTarihi == olusturmaTarihi &&
      other.guncellemeTarihi == guncellemeTarihi;

  @override
  int get hashCode =>
      Object.hash(id, tip, ad, olusturmaTarihi, guncellemeTarihi);

  @override
  String toString() => 'Secenek($id, ${tip.anahtar}, $ad)';
}
