import '../../core/metin/turkce.dart' as turkce;
import '../../core/para/kurus.dart';
import '../ortak/harita.dart';
import 'eski_fidan_eki.dart';
import 'urun_adi.dart';

/// Sattığımız bir şey: `Elma Scarlet M9`, `nakliye`, `çam`.
///
/// Fidan kimliği üç parçadır — tür, çeşit, anaç — ve üçü **ayrı** saklanır:
/// kullanıcı katalogda da faturada da bunları ayrı kutulara giriyor, tek bir
/// serbest metne yapıştırılan ad ise düzenlemeye açılınca parçalarına
/// ayrılamıyordu.
///
/// Yalnızca [tur] zorunlu: `nakliye` gibi kalemlerin çeşidi ve anacı yok.
/// Faturaya yazılan [ad] üç parçadan türetilir.
///
/// Katalog **zorunlu değildir**: faturaya katalogda olmayan serbest metin
/// kalem de girilebilir (bkz. `fazlar/faz-3-katalog.md`).
class Urun {
  const Urun({
    required this.id,
    required this.tur,
    this.cesit = '',
    this.anac = '',
    this.fiyat = Kurus.sifir,
    this.aktif = true,
    this.olusturmaTarihi,
    this.guncellemeTarihi,
  });

  /// Henüz kaydedilmemiş ürün. Kimliği Firestore belge oluşturulurken atanır.
  const Urun.yeni() : this(id: '', tur: '');

  /// Firestore belgesinden okur — üç şemayı da tanır (bkz. [eskiFidanEki]).
  ///
  /// [alanTur] yoksa kayıt "tek serbest ad" şemasıyla yazılmıştır; ad olduğu
  /// gibi türe düşer ve kullanıcı ilk düzenlemede parçalarına ayırır. Bölmeyi
  /// tahminle yapmıyoruz: `Elma Scarlet M9` üç parça ama `asma anacı atasarısı`
  /// tek parça, boşluktan bölmek ikincisini bozardı.
  factory Urun.fromMap(String id, Map<String, Object?> veri) {
    final tur = haritaMetinOpsiyonel(veri, alanTur);

    return Urun(
      id: id,
      tur: tur ?? haritaMetin(veri, alanAd),
      cesit: tur == null ? '' : haritaMetin(veri, alanCesit),
      anac: tur == null ? '' : _anacOku(veri),
      fiyat: Kurus(_fiyatOku(veri)),
      aktif: haritaMantiksal(veri, alanAktif, varsayilan: true),
      olusturmaTarihi: haritaTarih(veri, alanOlusturmaTarihi),
      guncellemeTarihi: haritaTarih(veri, alanGuncellemeTarihi),
    );
  }

  /// Firestore koleksiyon adı **`fidanlar` olarak kaldı**.
  ///
  /// Model `Fidan`'dan `Urun`'e geçerken koleksiyon yeniden adlandırılsaydı
  /// belge kimlikleri de değişir, geçmiş fatura kalemlerinin [IslemKalemi]
  /// `fidanId` bağı boşa düşerdi. Ad eski, şema yeni.
  static const String koleksiyon = 'fidanlar';

  static const String alanTur = 'tur';
  static const String alanCesit = 'cesit';
  static const String alanAnac = 'anac';

  /// Türetilmiş [ad]'ın yazıldığı alan.
  ///
  /// Modelde saklanmaz ama Firestore'a **yazılır**: hem konsolda belgeyi
  /// okunur tutuyor hem de göç işaretidir — bu alan varsa kayıt bugünkü şemayla
  /// en az bir kez kaydedilmiş demektir (bkz. [_anacOku]).
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

  /// Fidanın türü: `Elma`. Serbest kalemlerde kalemin tamamı: `nakliye`.
  /// Tek zorunlu alan.
  final String tur;

  /// `Scarlet`. Girilmemişse boş.
  final String cesit;

  /// `M9`. Girilmemişse boş.
  final String anac;

  /// Faturaya yazılan ad. Katalogdan seçilen kalem bu metni taşır — aynı ürün
  /// her faturada aynı isimle geçer, katalogun asıl amacı budur.
  ///
  /// Parçalardan türetilir, saklanan bir kopyaya güvenilmez: tür değişip adın
  /// eski kalması mümkün olmasın (bkz. [aramaAnahtari]).
  String get ad => urunAdi(tur: tur, cesit: cesit, anac: anac);

  /// Faturada kaleme ön dolgu olarak gelen fiyat. Kullanıcı orada
  /// değiştirebilir; fatura kaydına giren tutar bu alandan bağımsızdır
  /// (bkz. KURALLAR.md §3.2).
  final Kurus fiyat;

  final bool aktif;
  final DateTime? olusturmaTarihi;
  final DateTime? guncellemeTarihi;

  bool get yeniMi => id.isEmpty;

  /// Firestore'a yazılan normalize arama anahtarı: `elma scarlet m9`.
  String get aramaAnahtari => turkce.aramaAnahtari(ad);

  /// İki kayıt aynı ürünü mü tarif ediyor? Katalogun çöplüğe dönmemesi için
  /// ekleme sırasında sorulur (bkz. Faz 3 kabul kriteri 7).
  bool ayniUrunMu(Urun digeri) => aramaAnahtari == digeri.aramaAnahtari;

  /// Kullanıcının düzenleyebildiği alanlar.
  ///
  /// Aktiflik ve zaman damgaları bilerek dışarıda: onları yalnızca sistem
  /// yazar (bkz. `Cari.duzenlenebilirAlanlar`).
  Map<String, Object?> duzenlenebilirAlanlar() => <String, Object?>{
    alanTur: tur,
    alanCesit: cesit,
    alanAnac: anac,
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

  Urun kopyala({
    String? id,
    String? tur,
    String? cesit,
    String? anac,
    Kurus? fiyat,
    bool? aktif,
  }) => Urun(
    id: id ?? this.id,
    tur: tur ?? this.tur,
    cesit: cesit ?? this.cesit,
    anac: anac ?? this.anac,
    fiyat: fiyat ?? this.fiyat,
    aktif: aktif ?? this.aktif,
    olusturmaTarihi: olusturmaTarihi,
    guncellemeTarihi: guncellemeTarihi,
  );

  /// İlk şemadan gelen anaç, yaş ve kök tipi ekiyle birlikte okunur.
  ///
  /// Ek yalnızca [alanAd] hiç yazılmamış belgelerde uygulanır. Aksi hâlde
  /// kullanıcı ekin bir kısmını silip kaydettiğinde silinen parça bir sonraki
  /// okumada geri gelirdi: `yas` ve `kokTipi` alanları belgede duruyor.
  static String _anacOku(Map<String, Object?> veri) {
    final anac = haritaMetin(veri, alanAnac);
    if (veri.containsKey(alanAd)) return anac;

    final ek = eskiFidanEki(veri);
    if (ek.isEmpty) return anac;
    return anac.isEmpty ? ek : '$anac $ek';
  }

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
      other.tur == tur &&
      other.cesit == cesit &&
      other.anac == anac &&
      other.fiyat == fiyat &&
      other.aktif == aktif &&
      other.olusturmaTarihi == olusturmaTarihi &&
      other.guncellemeTarihi == guncellemeTarihi;

  @override
  int get hashCode => Object.hash(
    id,
    tur,
    cesit,
    anac,
    fiyat,
    aktif,
    olusturmaTarihi,
    guncellemeTarihi,
  );

  @override
  String toString() => 'Urun($id, $ad)';
}
