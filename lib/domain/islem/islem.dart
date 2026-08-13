import '../../core/para/kurus.dart';
import '../ortak/harita.dart';
import 'fatura_hesaplayici.dart';
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
    required this.toplam,
    this.kalemler = const <IslemKalemi>[],
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
    String id = '',
  }) => Islem(
    id: id,
    tip: tip,
    baslik: baslik,
    islemTarihi: islemTarihi,
    kalemler: List<IslemKalemi>.unmodifiable(kalemler),
    toplam: FaturaHesaplayici.hesapla(kalemler: kalemler),
  );

  /// Tahsilat veya ödeme. Kalemi yoktur.
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
    toplam: tutar,
  );

  /// Firestore belgesinden okur.
  ///
  /// Tanınmayan bir tip gelirse (eski sürümün yazdığı kayıt) belge atlanmaz;
  /// [tip] `satisFaturasi` varsayılır ve tutar zaten saklanan değerdir. Kayıt
  /// kaybetmek, tipini yanlış göstermekten kötüdür.
  factory Islem.fromMap(String id, Map<String, Object?> veri) => Islem(
    id: id,
    tip:
        IslemTipi.anahtardan(haritaMetinOpsiyonel(veri, alanTip)) ??
        IslemTipi.satisFaturasi,
    baslik: haritaMetin(veri, alanBaslik),
    islemTarihi: haritaTarih(veri, alanIslemTarihi) ?? DateTime(0),
    kalemler: haritaListesi(veri, alanKalemler)
        .map(IslemKalemi.fromMap)
        .toList(growable: false),
    toplam: Kurus(haritaTamSayi(veri, alanToplamKurus)),
    iptal: haritaMantiksal(veri, alanIptal) || _eskisiIptalMi(veri),
    iptalNedeni: haritaMetinOpsiyonel(veri, alanIptalNedeni),
    olusturmaTarihi: haritaTarih(veri, alanOlusturmaTarihi),
  );

  /// Eski sürüm iptali `durum: 'iptal'` olarak yazıyordu, ayrı bir [alanIptal]
  /// bayrağı her zaman yoktu. Alan modelden kalktı ama okuması kalmalı: aksi
  /// hâlde geçmişte iptal edilmiş kayıtlar bakiyeye geri sızardı.
  static bool _eskisiIptalMi(Map<String, Object?> veri) =>
      haritaMetinOpsiyonel(veri, alanEskiDurum) == eskiDurumIptal;

  static const String koleksiyon = 'islemler';

  static const String alanTip = 'tip';
  static const String alanBaslik = 'baslik';
  static const String alanIslemTarihi = 'islemTarihi';
  static const String alanKalemler = 'kalemler';
  static const String alanToplamKurus = 'toplamKurus';
  static const String alanIptal = 'iptal';
  static const String alanIptalNedeni = 'iptalNedeni';
  static const String alanOlusturmaTarihi = 'olusturmaTarihi';

  /// Artık yazılmayan, yalnızca okunan alan — bkz. [_eskisiIptalMi].
  static const String alanEskiDurum = 'durum';
  static const String eskiDurumIptal = 'iptal';

  /// Firestore belge kimliği. Kaydedilmemiş işlem için boştur.
  final String id;

  final IslemTipi tip;

  /// Ekstrede açıklama olarak görünen metin: "Zeytin-Hurma".
  final String baslik;

  /// Kullanıcının seçtiği işlem tarihi. Sıralamanın birincil ölçütüdür.
  final DateTime islemTarihi;

  final List<IslemKalemi> kalemler;

  /// Faturada kalem tutarlarının toplamı, tahsilat ve ödemede girilen tutar.
  /// Kaydedildikten sonra **saklanan tutar esastır**, geçmişe dönük yeniden
  /// hesaplanmaz (bkz. KURALLAR.md §3.2).
  final Kurus toplam;

  final bool iptal;
  final String? iptalNedeni;

  /// `serverTimestamp()` ile yazılır. Sunucu onaylayana kadar `null` okunur;
  /// bu yüzden sıralamada kullanılmaz, yalnızca kayıt izidir.
  final DateTime? olusturmaTarihi;

  bool get yeniMi => id.isEmpty;

  /// İptal edilmiş kayıt bakiyeye katılmaz ve listede üstü çizili görünür.
  bool get iptalMi => iptal;

  /// Bakiyeye katkısı. Borç işlemleri artırır, alacak işlemleri azaltır.
  /// İptal edilmiş işlem sıfır katkı verir.
  Kurus get bakiyeEtkisi =>
      iptalMi ? Kurus.sifir : Kurus(toplam.deger * tip.isaret);

  /// Ekstrenin borç kolonu — bu işlem alacaksa boş kalır.
  Kurus get borc => !iptalMi && tip.borcMu ? toplam : Kurus.sifir;

  /// Ekstrenin alacak kolonu.
  Kurus get alacak => !iptalMi && tip.alacakMi ? toplam : Kurus.sifir;

  /// Firestore'a yazılan alanlar.
  ///
  /// `olusturmaTarihi` bilerek dışarıda: onu repository `serverTimestamp()` ile
  /// yazar (bkz. KURALLAR.md §4.2). İptal alanları da dışarıda — iptal ayrı bir
  /// yazma yoludur ve form kaydı bir kaydı yanlışlıkla iptalden çıkaramamalı.
  Map<String, Object?> yazilabilirAlanlar() => <String, Object?>{
    alanTip: tip.anahtar,
    alanBaslik: baslik,
    alanIslemTarihi: islemTarihi,
    alanKalemler: kalemler
        .map((kalem) => kalem.toMap())
        .toList(growable: false),
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
    List<IslemKalemi>? kalemler,
    Kurus? toplam,
    bool? iptal,
    String? iptalNedeni,
    DateTime? olusturmaTarihi,
  }) => Islem(
    id: id ?? this.id,
    tip: tip ?? this.tip,
    baslik: baslik ?? this.baslik,
    islemTarihi: islemTarihi ?? this.islemTarihi,
    kalemler: kalemler ?? this.kalemler,
    toplam: toplam ?? this.toplam,
    iptal: iptal ?? this.iptal,
    iptalNedeni: iptalNedeni ?? this.iptalNedeni,
    olusturmaTarihi: olusturmaTarihi ?? this.olusturmaTarihi,
  );

  @override
  String toString() =>
      'Islem($id, ${tip.anahtar}, ${toplam.deger}${iptalMi ? ', iptal' : ''})';
}
