import '../../core/para/kurus.dart';
import '../ortak/harita.dart';
import 'fatura_hesaplayici.dart';
import 'fatura_toplami.dart';
import 'islem_durumu.dart';
import 'islem_kalemi.dart';
import 'islem_tipi.dart';

/// Bir cariye işlenen fatura, tahsilat veya ödeme.
///
/// Tutarlar kaydedildiği hâliyle saklanır ve okunurken **yeniden hesaplanmaz**:
/// bugün kalem listesinden türetilen toplam, yarın yuvarlama kuralı değişirse
/// başka çıkabilir ve geçmiş ekstre bozulurdu (bkz. KURALLAR.md §3.2).
/// Hesaplama yalnızca kayıt oluşturulurken, [Islem.fatura] ve [Islem.odeme]
/// fabrikalarında yapılır.
class Islem {
  const Islem({
    required this.id,
    required this.tip,
    required this.baslik,
    required this.islemTarihi,
    required this.araToplam,
    required this.toplam,
    this.vadeTarihi,
    this.durum = IslemDurumu.beklemede,
    this.kalemler = const <IslemKalemi>[],
    this.kdvOrani = FaturaHesaplayici.kdvsiz,
    this.kdv = Kurus.sifir,
    this.iptal = false,
    this.iptalNedeni,
    this.olusturmaTarihi,
  });

  /// Kalemlerinden toplamı hesaplanmış yeni fatura.
  factory Islem.fatura({
    required IslemTipi tip,
    required String baslik,
    required DateTime islemTarihi,
    required List<IslemKalemi> kalemler,
    DateTime? vadeTarihi,
    IslemDurumu durum = IslemDurumu.beklemede,
    int kdvOrani = FaturaHesaplayici.kdvsiz,
    String id = '',
  }) {
    final hesap = FaturaHesaplayici.hesapla(
      kalemler: kalemler,
      kdvOrani: kdvOrani,
    );
    return Islem(
      id: id,
      tip: tip,
      baslik: baslik,
      islemTarihi: islemTarihi,
      vadeTarihi: vadeTarihi,
      durum: durum,
      kalemler: List<IslemKalemi>.unmodifiable(kalemler),
      araToplam: hesap.araToplam,
      kdvOrani: hesap.kdvOrani,
      kdv: hesap.kdv,
      toplam: hesap.toplam,
    );
  }

  /// Tahsilat veya ödeme. Kalemi, KDV'si ve vadesi yoktur.
  factory Islem.odeme({
    required IslemTipi tip,
    required String baslik,
    required DateTime islemTarihi,
    required Kurus tutar,
    String id = '',
  }) => Islem(
    id: id,
    tip: tip,
    baslik: baslik,
    islemTarihi: islemTarihi,
    araToplam: tutar,
    toplam: tutar,
  );

  /// Firestore belgesinden okur.
  ///
  /// Tanınmayan bir tip gelirse (eski sürümün yazdığı kayıt) belge atlanmaz;
  /// [tip] `satisFaturasi` varsayılır ve tutar zaten saklanan değerdir. Kayıt
  /// kaybetmek, tipini yanlış göstermekten kötüdür.
  factory Islem.fromMap(String id, Map<String, Object?> veri) {
    final durum = IslemDurumu.anahtardan(
      haritaMetinOpsiyonel(veri, alanDurum),
    );
    return Islem(
      id: id,
      tip:
          IslemTipi.anahtardan(haritaMetinOpsiyonel(veri, alanTip)) ??
          IslemTipi.satisFaturasi,
      baslik: haritaMetin(veri, alanBaslik),
      islemTarihi: haritaTarih(veri, alanIslemTarihi) ?? DateTime(0),
      vadeTarihi: haritaTarih(veri, alanVadeTarihi),
      durum: durum,
      kalemler: haritaListesi(veri, alanKalemler)
          .map(IslemKalemi.fromMap)
          .toList(growable: false),
      araToplam: Kurus(haritaTamSayi(veri, alanAraToplamKurus)),
      kdvOrani: haritaTamSayi(veri, alanKdvOrani),
      kdv: Kurus(haritaTamSayi(veri, alanKdvKurus)),
      toplam: Kurus(haritaTamSayi(veri, alanToplamKurus)),
      iptal: haritaMantiksal(veri, alanIptal) || durum == IslemDurumu.iptal,
      iptalNedeni: haritaMetinOpsiyonel(veri, alanIptalNedeni),
      olusturmaTarihi: haritaTarih(veri, alanOlusturmaTarihi),
    );
  }

  static const String koleksiyon = 'islemler';

  static const String alanTip = 'tip';
  static const String alanBaslik = 'baslik';
  static const String alanIslemTarihi = 'islemTarihi';
  static const String alanVadeTarihi = 'vadeTarihi';
  static const String alanDurum = 'durum';
  static const String alanKalemler = 'kalemler';
  static const String alanAraToplamKurus = 'araToplamKurus';
  static const String alanKdvOrani = 'kdvOrani';
  static const String alanKdvKurus = 'kdvKurus';
  static const String alanToplamKurus = 'toplamKurus';
  static const String alanIptal = 'iptal';
  static const String alanIptalNedeni = 'iptalNedeni';
  static const String alanOlusturmaTarihi = 'olusturmaTarihi';

  /// Firestore belge kimliği. Kaydedilmemiş işlem için boştur.
  final String id;

  final IslemTipi tip;

  /// Ekstrede açıklama olarak görünen metin: "Zeytin-Hurma".
  final String baslik;

  /// Kullanıcının seçtiği işlem tarihi. Sıralamanın birincil ölçütüdür.
  final DateTime islemTarihi;

  /// Yalnızca faturalarda dolu.
  final DateTime? vadeTarihi;

  final IslemDurumu durum;
  final List<IslemKalemi> kalemler;
  final Kurus araToplam;

  /// Yüzde olarak saklanır; oran yarın değişse bile geçmiş fatura etkilenmez
  /// (bkz. KURALLAR.md §3.3).
  final int kdvOrani;

  final Kurus kdv;
  final Kurus toplam;

  final bool iptal;
  final String? iptalNedeni;

  /// `serverTimestamp()` ile yazılır. Sunucu onaylayana kadar `null` okunur;
  /// bu yüzden sıralamada kullanılmaz, yalnızca kayıt izidir.
  final DateTime? olusturmaTarihi;

  bool get yeniMi => id.isEmpty;

  /// İptal edilmiş kayıt bakiyeye katılmaz ve listede üstü çizili görünür.
  ///
  /// Hem [iptal] bayrağına hem [durum] alanına bakar: ikisi ayrı alan olduğu
  /// için biri yazılıp diğeri yazılmamış bir kaydın bakiyeye sızması mümkün
  /// olmamalı.
  bool get iptalMi => iptal || durum == IslemDurumu.iptal;

  bool get teslimEdildiMi => durum == IslemDurumu.teslimEdildi;

  /// Bakiyeye katkısı. Borç işlemleri artırır, alacak işlemleri azaltır.
  /// İptal edilmiş işlem sıfır katkı verir.
  Kurus get bakiyeEtkisi =>
      iptalMi ? Kurus.sifir : Kurus(toplam.deger * tip.isaret);

  /// Ekstrenin borç kolonu — bu işlem alacaksa boş kalır.
  Kurus get borc => !iptalMi && tip.borcMu ? toplam : Kurus.sifir;

  /// Ekstrenin alacak kolonu.
  Kurus get alacak => !iptalMi && tip.alacakMi ? toplam : Kurus.sifir;

  FaturaToplami get faturaToplami => FaturaToplami(
    araToplam: araToplam,
    kdvOrani: kdvOrani,
    kdv: kdv,
    toplam: toplam,
  );

  /// Firestore'a yazılan alanlar.
  ///
  /// `olusturmaTarihi` bilerek dışarıda: onu repository `serverTimestamp()` ile
  /// yazar (bkz. KURALLAR.md §4.2). İptal alanları da dışarıda — iptal ayrı bir
  /// yazma yoludur ve form kaydı bir kaydı yanlışlıkla iptalden çıkaramamalı.
  Map<String, Object?> yazilabilirAlanlar() => <String, Object?>{
    alanTip: tip.anahtar,
    alanBaslik: baslik,
    alanIslemTarihi: islemTarihi,
    alanVadeTarihi: vadeTarihi,
    alanDurum: durum.anahtar,
    alanKalemler: kalemler
        .map((kalem) => kalem.toMap())
        .toList(growable: false),
    alanAraToplamKurus: araToplam.deger,
    alanKdvOrani: kdvOrani,
    alanKdvKurus: kdv.deger,
    alanToplamKurus: toplam.deger,
  };

  Map<String, Object?> toMap() => <String, Object?>{
    ...yazilabilirAlanlar(),
    alanIptal: iptal,
    alanIptalNedeni: iptalNedeni,
    alanOlusturmaTarihi: olusturmaTarihi,
  };

  Islem kopyala({
    String? id,
    IslemTipi? tip,
    String? baslik,
    DateTime? islemTarihi,
    DateTime? vadeTarihi,
    IslemDurumu? durum,
    List<IslemKalemi>? kalemler,
    Kurus? araToplam,
    int? kdvOrani,
    Kurus? kdv,
    Kurus? toplam,
    bool? iptal,
    String? iptalNedeni,
    DateTime? olusturmaTarihi,
  }) => Islem(
    id: id ?? this.id,
    tip: tip ?? this.tip,
    baslik: baslik ?? this.baslik,
    islemTarihi: islemTarihi ?? this.islemTarihi,
    vadeTarihi: vadeTarihi ?? this.vadeTarihi,
    durum: durum ?? this.durum,
    kalemler: kalemler ?? this.kalemler,
    araToplam: araToplam ?? this.araToplam,
    kdvOrani: kdvOrani ?? this.kdvOrani,
    kdv: kdv ?? this.kdv,
    toplam: toplam ?? this.toplam,
    iptal: iptal ?? this.iptal,
    iptalNedeni: iptalNedeni ?? this.iptalNedeni,
    olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
  );

  @override
  String toString() =>
      'Islem($id, ${tip.anahtar}, ${toplam.deger}${iptalMi ? ', iptal' : ''})';
}
