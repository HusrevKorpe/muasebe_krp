import '../../core/para/kurus.dart';
import '../../core/para/yuvarlama.dart';
import '../ortak/harita.dart';
import '../urun/urun_adi.dart';

/// Fatura satırı: "Elma Scarlet M9 7.000 Adet × 7,00 ₺ = 49.000,00 ₺".
///
/// Fidan kimliği üç ayrı alanda tutulur — [tur], [cesit], [anac] — çünkü
/// kullanıcı satışı bu üç kutuya ayrı ayrı giriyor. Tek birleşik ad saklansaydı
/// kalem düzenlemeye açıldığında parçalarına geri ayrılamazdı. Yalnızca [tur]
/// zorunlu: "nakliye" gibi kalemlerin çeşidi ve anacı yok.
///
/// [tutar] ile [birimFiyat] birbirinden **türetilmez**; ikisi de saklanır.
/// Sebebi referans ekstredeki Hurma kalemidir: `1.650 Adet × 18,79 ₺` yazar ama
/// gerçek tutar `31.000,00 ₺`'dir — `1.650 × 18,79 = 31.003,50` değil. Birim
/// fiyat yuvarlanmış bir gösterim değeri, tutar ise faturanın esasıdır
/// (bkz. KURALLAR.md §3.2).
class IslemKalemi {
  const IslemKalemi({
    required this.tur,
    required this.miktar,
    required this.birimFiyat,
    required this.tutar,
    this.cesit = '',
    this.anac = '',
    this.urunId,
    this.birim = varsayilanBirim,
  });

  /// Kullanıcı birim fiyatı girdiğinde: tutar çarpımla bulunur.
  ///
  /// İki tam sayının çarpımı tamdır; burada yuvarlama olmaz.
  factory IslemKalemi.birimFiyattan({
    required String tur,
    required int miktar,
    required Kurus birimFiyat,
    String cesit = '',
    String anac = '',
    String? urunId,
    String birim = varsayilanBirim,
  }) => IslemKalemi(
    tur: tur,
    cesit: cesit,
    anac: anac,
    miktar: miktar,
    birimFiyat: birimFiyat,
    tutar: kalemTutari(miktar: miktar, birimFiyat: birimFiyat),
    urunId: urunId,
    birim: birim,
  );

  /// Kullanıcı toplam tutarı girdiğinde: birim fiyat geriye hesaplanır.
  ///
  /// Tutar **girilen değer olarak kalır**; yuvarlanmış birim fiyattan yeniden
  /// çarpılmaz. Aksi hâlde `31.000 ₺` girilen kalem `31.003,50 ₺` olarak
  /// kaydedilirdi.
  factory IslemKalemi.toplamdan({
    required String tur,
    required int miktar,
    required Kurus toplam,
    String cesit = '',
    String anac = '',
    String? urunId,
    String birim = varsayilanBirim,
  }) => IslemKalemi(
    tur: tur,
    cesit: cesit,
    anac: anac,
    miktar: miktar,
    birimFiyat: birimFiyatHesapla(toplam: toplam, miktar: miktar),
    tutar: toplam,
    urunId: urunId,
    birim: birim,
  );

  /// Kayıtlı kalemi okur. Kalem üç parçaya bölünmeden önce girilmiş faturalar
  /// yalnızca [alanAd] taşıyor; o metin olduğu gibi türe düşer.
  ///
  /// Geçmiş fatura **yeniden yazılmaz**: kalem adı kaydedildiği hâliyle kalır,
  /// biz onu yalnızca okurken türe yerleştiriyoruz (bkz. KURALLAR.md §3.2).
  factory IslemKalemi.fromMap(Map<String, Object?> veri) {
    final tur = haritaMetinOpsiyonel(veri, alanTur);

    return IslemKalemi(
      tur: tur ?? haritaMetin(veri, alanAd),
      cesit: tur == null ? '' : haritaMetin(veri, alanCesit),
      anac: tur == null ? '' : haritaMetin(veri, alanAnac),
      miktar: haritaTamSayi(veri, alanMiktar),
      birimFiyat: Kurus(haritaTamSayi(veri, alanBirimFiyatKurus)),
      tutar: Kurus(haritaTamSayi(veri, alanTutarKurus)),
      urunId: haritaMetinOpsiyonel(veri, alanUrunId),
      birim: haritaMetin(veri, alanBirim, varsayilan: varsayilanBirim),
    );
  }

  static const String varsayilanBirim = 'adet';

  static const String alanTur = 'tur';
  static const String alanCesit = 'cesit';
  static const String alanAnac = 'anac';

  /// Türetilmiş [ad]'ın yazıldığı alan.
  ///
  /// Modelde saklanmaz ama Firestore'a yazılır: kalem üçe bölünmeden önceki
  /// kayıtlar bu alandan okunuyor ve belgeyi konsolda okunur tutuyor.
  static const String alanAd = 'ad';

  /// Firestore alan adı `fidanId` olarak **kaldı**: katalog `Fidan`'dan
  /// `Urun`'e geçerken alan yeniden adlandırılsaydı geçmiş fatura kalemlerinin
  /// ürün bağı sessizce kopardı (bkz. `Urun.koleksiyon`).
  static const String alanUrunId = 'fidanId';
  static const String alanMiktar = 'miktar';
  static const String alanBirim = 'birim';
  static const String alanBirimFiyatKurus = 'birimFiyatKurus';
  static const String alanTutarKurus = 'tutarKurus';

  /// Kalemin türü: `Elma`. Serbest kalemlerde kalemin tamamı: `nakliye`.
  final String tur;

  /// `Scarlet`. Girilmemişse boş.
  final String cesit;

  /// `M9`. Girilmemişse boş.
  final String anac;

  final int miktar;

  /// Gösterim değeri: en yakın kuruşa yuvarlanmış olabilir.
  final Kurus birimFiyat;

  /// Faturanın esası. Fatura toplamı bu alanlardan toplanır.
  final Kurus tutar;

  /// Katalogdan seçilen ürünün kimliği. Serbest metin kalemlerde boş.
  final String? urunId;

  final String birim;

  /// Faturaya ve ekstreye basılan ad: `Elma Scarlet M9`.
  String get ad => urunAdi(tur: tur, cesit: cesit, anac: anac);

  /// Yuvarlanmış birim fiyattan çarpım, saklanan tutarı vermiyor mu?
  ///
  /// Hurma kalemi gibi "toplamdan girilmiş" satırlarda `true` döner. Ekranda
  /// birim fiyatın yanına yaklaşıklık işareti koymak için kullanılır — kullanıcı
  /// çarpımı elle denediğinde tutmamasının sebebini görmeli.
  bool get birimFiyatYuvarlanmisMi =>
      miktar > 0 && birimFiyat * miktar != tutar;

  Map<String, Object?> toMap() => <String, Object?>{
    alanTur: tur,
    alanCesit: cesit,
    alanAnac: anac,
    alanAd: ad,
    alanUrunId: urunId,
    alanMiktar: miktar,
    alanBirim: birim,
    alanBirimFiyatKurus: birimFiyat.deger,
    alanTutarKurus: tutar.deger,
  };

  IslemKalemi kopyala({
    String? tur,
    String? cesit,
    String? anac,
    int? miktar,
    Kurus? birimFiyat,
    Kurus? tutar,
    String? urunId,
    String? birim,
  }) => IslemKalemi(
    tur: tur ?? this.tur,
    cesit: cesit ?? this.cesit,
    anac: anac ?? this.anac,
    miktar: miktar ?? this.miktar,
    birimFiyat: birimFiyat ?? this.birimFiyat,
    tutar: tutar ?? this.tutar,
    urunId: urunId ?? this.urunId,
    birim: birim ?? this.birim,
  );

  @override
  bool operator ==(Object other) =>
      other is IslemKalemi &&
      other.tur == tur &&
      other.cesit == cesit &&
      other.anac == anac &&
      other.miktar == miktar &&
      other.birimFiyat == birimFiyat &&
      other.tutar == tutar &&
      other.urunId == urunId &&
      other.birim == birim;

  @override
  int get hashCode =>
      Object.hash(tur, cesit, anac, miktar, birimFiyat, tutar, urunId, birim);

  @override
  String toString() => 'IslemKalemi($ad, $miktar $birim, ${tutar.deger})';
}
