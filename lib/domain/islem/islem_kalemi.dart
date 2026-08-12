import '../../core/para/kurus.dart';
import '../../core/para/yuvarlama.dart';
import '../ortak/harita.dart';

/// Fatura satırı: "zeytin 7.000 Adet × 7,00 ₺ = 49.000,00 ₺".
///
/// [tutar] ile [birimFiyat] birbirinden **türetilmez**; ikisi de saklanır.
/// Sebebi referans ekstredeki Hurma kalemidir: `1.650 Adet × 18,79 ₺` yazar ama
/// gerçek tutar `31.000,00 ₺`'dir — `1.650 × 18,79 = 31.003,50` değil. Birim
/// fiyat yuvarlanmış bir gösterim değeri, tutar ise faturanın esasıdır
/// (bkz. KURALLAR.md §3.2).
class IslemKalemi {
  const IslemKalemi({
    required this.ad,
    required this.miktar,
    required this.birimFiyat,
    required this.tutar,
    this.fidanId,
    this.birim = varsayilanBirim,
  });

  /// Kullanıcı birim fiyatı girdiğinde: tutar çarpımla bulunur.
  ///
  /// İki tam sayının çarpımı tamdır; burada yuvarlama olmaz.
  factory IslemKalemi.birimFiyattan({
    required String ad,
    required int miktar,
    required Kurus birimFiyat,
    String? fidanId,
    String birim = varsayilanBirim,
  }) => IslemKalemi(
    ad: ad,
    miktar: miktar,
    birimFiyat: birimFiyat,
    tutar: kalemTutari(miktar: miktar, birimFiyat: birimFiyat),
    fidanId: fidanId,
    birim: birim,
  );

  /// Kullanıcı toplam tutarı girdiğinde: birim fiyat geriye hesaplanır.
  ///
  /// Tutar **girilen değer olarak kalır**; yuvarlanmış birim fiyattan yeniden
  /// çarpılmaz. Aksi hâlde `31.000 ₺` girilen kalem `31.003,50 ₺` olarak
  /// kaydedilirdi.
  factory IslemKalemi.toplamdan({
    required String ad,
    required int miktar,
    required Kurus toplam,
    String? fidanId,
    String birim = varsayilanBirim,
  }) => IslemKalemi(
    ad: ad,
    miktar: miktar,
    birimFiyat: birimFiyatHesapla(toplam: toplam, miktar: miktar),
    tutar: toplam,
    fidanId: fidanId,
    birim: birim,
  );

  factory IslemKalemi.fromMap(Map<String, Object?> veri) => IslemKalemi(
    ad: haritaMetin(veri, alanAd),
    miktar: haritaTamSayi(veri, alanMiktar),
    birimFiyat: Kurus(haritaTamSayi(veri, alanBirimFiyatKurus)),
    tutar: Kurus(haritaTamSayi(veri, alanTutarKurus)),
    fidanId: haritaMetinOpsiyonel(veri, alanFidanId),
    birim: haritaMetin(veri, alanBirim, varsayilan: varsayilanBirim),
  );

  static const String varsayilanBirim = 'adet';

  static const String alanAd = 'ad';
  static const String alanFidanId = 'fidanId';
  static const String alanMiktar = 'miktar';
  static const String alanBirim = 'birim';
  static const String alanBirimFiyatKurus = 'birimFiyatKurus';
  static const String alanTutarKurus = 'tutarKurus';

  final String ad;
  final int miktar;

  /// Gösterim değeri: en yakın kuruşa yuvarlanmış olabilir.
  final Kurus birimFiyat;

  /// Faturanın esası. Ara toplam bu alanlardan toplanır.
  final Kurus tutar;

  /// Faz 3'te katalogdan seçilen fidanın kimliği. Serbest metin kalemlerde boş.
  final String? fidanId;

  final String birim;

  /// Yuvarlanmış birim fiyattan çarpım, saklanan tutarı vermiyor mu?
  ///
  /// Hurma kalemi gibi "toplamdan girilmiş" satırlarda `true` döner. Ekranda
  /// birim fiyatın yanına yaklaşıklık işareti koymak için kullanılır — kullanıcı
  /// çarpımı elle denediğinde tutmamasının sebebini görmeli.
  bool get birimFiyatYuvarlanmisMi =>
      miktar > 0 && birimFiyat * miktar != tutar;

  Map<String, Object?> toMap() => <String, Object?>{
    alanAd: ad,
    alanFidanId: fidanId,
    alanMiktar: miktar,
    alanBirim: birim,
    alanBirimFiyatKurus: birimFiyat.deger,
    alanTutarKurus: tutar.deger,
  };

  IslemKalemi kopyala({
    String? ad,
    int? miktar,
    Kurus? birimFiyat,
    Kurus? tutar,
    String? fidanId,
    String? birim,
  }) => IslemKalemi(
    ad: ad ?? this.ad,
    miktar: miktar ?? this.miktar,
    birimFiyat: birimFiyat ?? this.birimFiyat,
    tutar: tutar ?? this.tutar,
    fidanId: fidanId ?? this.fidanId,
    birim: birim ?? this.birim,
  );

  @override
  bool operator ==(Object other) =>
      other is IslemKalemi &&
      other.ad == ad &&
      other.miktar == miktar &&
      other.birimFiyat == birimFiyat &&
      other.tutar == tutar &&
      other.fidanId == fidanId &&
      other.birim == birim;

  @override
  int get hashCode =>
      Object.hash(ad, miktar, birimFiyat, tutar, fidanId, birim);

  @override
  String toString() =>
      'IslemKalemi($ad, $miktar $birim, ${tutar.deger})';
}
