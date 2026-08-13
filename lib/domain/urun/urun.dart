import '../../core/metin/turkce.dart' as turkce;
import '../../core/para/kurus.dart';
import '../ortak/harita.dart';
import 'eski_fidan_adi.dart';

/// Sattığımız bir şey: `Elma Scarlet M9 2 yaş tüplü`, `nakliye`, `çam`.
///
/// Tek bir serbest ad taşır. Önceki sürümde beş ayrı alan vardı — tür, çeşit,
/// anaç, yaş, kök tipi — ama referans ekstredeki kalemlerin çoğu o şemaya
/// girmiyor (`nakliye`, `asma anacı atasarısı`). Katalog artık ne satıldığını
/// olduğu gibi yazdığın bir liste.
///
/// Katalog **zorunlu değildir**: faturaya katalogda olmayan serbest metin
/// kalem de girilebilir (bkz. `fazlar/faz-3-katalog.md`).
class Urun {
  const Urun({
    required this.id,
    required this.ad,
    this.fiyat = Kurus.sifir,
    this.aktif = true,
    this.olusturmaTarihi,
    this.guncellemeTarihi,
  });

  /// Henüz kaydedilmemiş ürün. Kimliği Firestore belge oluşturulurken atanır.
  const Urun.yeni() : this(id: '', ad: '');

  /// Firestore belgesinden okur.
  ///
  /// Belgede [alanAd] yoksa kayıt eski şemayla yazılmıştır; ad o zamanki beş
  /// alandan birleştirilir (bkz. [eskiFidanAdi]). Böylece katalogdaki geçmiş
  /// kayıtlar göç scripti olmadan okunur ve ilk düzenlemede yeni şemaya geçer.
  factory Urun.fromMap(String id, Map<String, Object?> veri) => Urun(
    id: id,
    ad: haritaMetinOpsiyonel(veri, alanAd) ?? eskiFidanAdi(veri),
    fiyat: Kurus(_fiyatOku(veri)),
    aktif: haritaMantiksal(veri, alanAktif, varsayilan: true),
    olusturmaTarihi: haritaTarih(veri, alanOlusturmaTarihi),
    guncellemeTarihi: haritaTarih(veri, alanGuncellemeTarihi),
  );

  /// Firestore koleksiyon adı **`fidanlar` olarak kaldı**.
  ///
  /// Model `Fidan`'dan `Urun`'e geçerken koleksiyon yeniden adlandırılsaydı
  /// belge kimlikleri de değişir, geçmiş fatura kalemlerinin [IslemKalemi]
  /// `fidanId` bağı boşa düşerdi. Ad eski, şema yeni.
  static const String koleksiyon = 'fidanlar';

  static const String alanAd = 'ad';
  static const String alanFiyatKurus = 'fiyatKurus';
  static const String alanAramaAnahtari = 'aramaAnahtari';
  static const String alanAktif = 'aktif';
  static const String alanOlusturmaTarihi = 'olusturmaTarihi';
  static const String alanGuncellemeTarihi = 'guncellemeTarihi';

  /// Fiyatın eski alan adı. Yalnızca okunur — bkz. [_fiyatOku].
  static const String alanEskiFiyatKurus = 'varsayilanFiyatKurus';

  /// Firestore belge kimliği. Kaydedilmemiş ürün için boştur.
  final String id;

  /// Faturaya yazılan ad. Katalogdan seçilen kalem bu metni taşır — aynı ürün
  /// her faturada aynı isimle geçer, katalogun asıl amacı budur.
  final String ad;

  /// Faturada kaleme ön dolgu olarak gelen fiyat. Kullanıcı orada
  /// değiştirebilir; fatura kaydına giren tutar bu alandan bağımsızdır
  /// (bkz. KURALLAR.md §3.2).
  final Kurus fiyat;

  final bool aktif;
  final DateTime? olusturmaTarihi;
  final DateTime? guncellemeTarihi;

  bool get yeniMi => id.isEmpty;

  /// Firestore'a yazılan normalize arama anahtarı: `elma scarlet m9`.
  ///
  /// Her zaman [ad]'dan türetilir, saklanan bir kopyaya güvenilmez — böylece ad
  /// değişip anahtar eski kalması mümkün olmaz.
  String get aramaAnahtari => turkce.aramaAnahtari(ad);

  /// İki kayıt aynı ürünü mü tarif ediyor? Katalogun çöplüğe dönmemesi için
  /// ekleme sırasında sorulur (bkz. Faz 3 kabul kriteri 7).
  bool ayniUrunMu(Urun digeri) => aramaAnahtari == digeri.aramaAnahtari;

  /// Kullanıcının düzenleyebildiği alanlar.
  ///
  /// Aktiflik ve zaman damgaları bilerek dışarıda: onları yalnızca sistem
  /// yazar (bkz. `Cari.duzenlenebilirAlanlar`).
  Map<String, Object?> duzenlenebilirAlanlar() => <String, Object?>{
    alanAd: ad,
    alanFiyatKurus: fiyat.deger,
    alanAramaAnahtari: aramaAnahtari,
  };

  Map<String, Object?> toMap() => <String, Object?>{
    ...duzenlenebilirAlanlar(),
    alanAktif: aktif,
    alanOlusturmaTarihi: olusturmaTarihi,
    alanGuncellemeTarihi: guncellemeTarihi,
  };

  Urun kopyala({String? id, String? ad, Kurus? fiyat, bool? aktif}) => Urun(
    id: id ?? this.id,
    ad: ad ?? this.ad,
    fiyat: fiyat ?? this.fiyat,
    aktif: aktif ?? this.aktif,
    olusturmaTarihi: olusturmaTarihi,
    guncellemeTarihi: guncellemeTarihi,
  );

  /// Yeni alan adı yoksa eskisine bakar; ikisi de yoksa sıfır.
  static int _fiyatOku(Map<String, Object?> veri) {
    if (veri.containsKey(alanFiyatKurus)) {
      return haritaTamSayi(veri, alanFiyatKurus);
    }
    return haritaTamSayi(veri, alanEskiFiyatKurus);
  }

  @override
  bool operator ==(Object other) =>
      other is Urun &&
      other.id == id &&
      other.ad == ad &&
      other.fiyat == fiyat &&
      other.aktif == aktif &&
      other.olusturmaTarihi == olusturmaTarihi &&
      other.guncellemeTarihi == guncellemeTarihi;

  @override
  int get hashCode =>
      Object.hash(id, ad, fiyat, aktif, olusturmaTarihi, guncellemeTarihi);

  @override
  String toString() => 'Urun($id, $ad)';
}
