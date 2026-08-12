import '../../core/metin/metinler.dart';
import '../../core/metin/turkce.dart' as turkce;
import '../../core/para/kurus.dart';
import '../ortak/harita.dart';
import 'kok_tipi.dart';

/// Katalogdaki bir fidan: `Elma / Scarlet / M9 · 2 Yaş · Tüplü`.
///
/// Kullanıcı fidanı üç seviyeyle tarif ediyor — tür, çeşit, anaç — ama referans
/// ekstredeki kalemlerde iki alan daha görünüyor (`Hachiya Tüplü`,
/// `zeytin gemlik 2 Yaş`). Bu yüzden model beş alanlı, son üçü isteğe bağlı.
///
/// Katalog **zorunlu değildir**: faturaya "nakliye" gibi serbest metin kalemler
/// de girilebilir (bkz. `fazlar/faz-3-katalog.md`).
class Fidan {
  const Fidan({
    required this.id,
    required this.tur,
    required this.cesit,
    this.anac,
    this.yas,
    this.kokTipi,
    this.varsayilanFiyat = Kurus.sifir,
    this.aktif = true,
    this.olusturmaTarihi,
    this.guncellemeTarihi,
  });

  /// Henüz kaydedilmemiş fidan. Kimliği Firestore belge oluşturulurken atanır.
  const Fidan.yeni() : this(id: '', tur: '', cesit: '');

  factory Fidan.fromMap(String id, Map<String, Object?> veri) => Fidan(
    id: id,
    tur: haritaMetin(veri, alanTur),
    cesit: haritaMetin(veri, alanCesit),
    anac: haritaMetinOpsiyonel(veri, alanAnac),
    yas: haritaTamSayiOpsiyonel(veri, alanYas),
    kokTipi: KokTipi.anahtardan(haritaMetinOpsiyonel(veri, alanKokTipi)),
    varsayilanFiyat: Kurus(haritaTamSayi(veri, alanVarsayilanFiyatKurus)),
    aktif: haritaMantiksal(veri, alanAktif, varsayilan: true),
    olusturmaTarihi: haritaTarih(veri, alanOlusturmaTarihi),
    guncellemeTarihi: haritaTarih(veri, alanGuncellemeTarihi),
  );

  static const String koleksiyon = 'fidanlar';

  static const String alanTur = 'tur';
  static const String alanCesit = 'cesit';
  static const String alanAnac = 'anac';
  static const String alanYas = 'yas';
  static const String alanKokTipi = 'kokTipi';
  static const String alanVarsayilanFiyatKurus = 'varsayilanFiyatKurus';
  static const String alanAramaAnahtari = 'aramaAnahtari';
  static const String alanTurAnahtari = 'turAnahtari';
  static const String alanAnacAnahtari = 'anacAnahtari';
  static const String alanAktif = 'aktif';
  static const String alanOlusturmaTarihi = 'olusturmaTarihi';
  static const String alanGuncellemeTarihi = 'guncellemeTarihi';

  /// Görünen adda tür/çeşit/anaç arasındaki ayraç.
  static const String bolumAyraci = ' / ';

  /// Yaş ve kök tipi eklerinin ayracı.
  static const String ekAyraci = ' · ';

  /// Firestore belge kimliği. Kaydedilmemiş fidan için boştur.
  final String id;

  final String tur;
  final String cesit;
  final String? anac;
  final int? yas;
  final KokTipi? kokTipi;

  /// Faturada kaleme ön dolgu olarak gelen birim fiyat. Kullanıcı orada
  /// değiştirebilir; fatura kaydına giren tutar bu alandan bağımsızdır
  /// (bkz. KURALLAR.md §3.2).
  final Kurus varsayilanFiyat;

  final bool aktif;
  final DateTime? olusturmaTarihi;
  final DateTime? guncellemeTarihi;

  bool get yeniMi => id.isEmpty;

  /// Kullanıcıya ve faturaya giden ad: `Elma / Scarlet / M9 · 2 Yaş · Tüplü`.
  ///
  /// Opsiyonel alanlar boşken ayraç sarkmaz: anaç yoksa `Elma / Scarlet`.
  /// Fatura kalemine bu metin yazılır — böylece aynı fidan her faturada aynı
  /// isimle geçer, katalogun asıl amacı budur.
  String get goruntuAdi {
    final bolumler = <String>[
      tur.trim(),
      cesit.trim(),
      if (anac != null) anac!.trim(),
    ].where((bolum) => bolum.isNotEmpty);

    final ekler = <String>[
      if (yas != null) '$yas ${Metinler.yasSoneki}',
      if (kokTipi != null) kokTipi!.ad,
    ];

    final govde = bolumler.join(bolumAyraci);
    return ekler.isEmpty ? govde : '$govde$ekAyraci${ekler.join(ekAyraci)}';
  }

  /// Firestore'a yazılan normalize arama anahtarı: `elma scarlet m9`.
  ///
  /// Her zaman alanlardan türetilir, saklanan bir kopyaya güvenilmez — böylece
  /// çeşit değişip anahtar eski kalması mümkün olmaz. Yaş ve kök tipi
  /// anahtara girmez: kullanıcı "elma scarlet" yazıp iki yaşlısını da bulmalı.
  String get aramaAnahtari =>
      turkce.aramaAnahtari('$tur $cesit ${anac ?? ''}');

  /// Tür önerisi sorgusunun süzdüğü alan: `elma`
  String get turAnahtari => turkce.aramaAnahtari(tur);

  /// Anaç önerisi sorgusunun süzdüğü alan. Anaç girilmemişse `null` yazılır ve
  /// kayıt öneri sorgusunun aralık süzgecine hiç girmez.
  String? get anacAnahtari {
    final deger = anac;
    if (deger == null) return null;
    final anahtar = turkce.aramaAnahtari(deger);
    return anahtar.isEmpty ? null : anahtar;
  }

  /// Mükerrer kaydı belirleyen kimlik.
  ///
  /// [aramaAnahtari]'ndan farkı yaş ve kök tipini de kapsaması: "Elma / Scarlet
  /// / M9 · 1 Yaş" ile "… · 2 Yaş" ayrı fidanlardır, aynı kaydın tekrarı değil.
  String get tekillikAnahtari =>
      '$aramaAnahtari|${yas ?? ''}|${kokTipi?.anahtar ?? ''}';

  /// İki kayıt aynı fidanı mı tarif ediyor? Katalogun çöplüğe dönmemesi için
  /// ekleme sırasında sorulur (bkz. Faz 3 kabul kriteri 7).
  bool ayniFidanMi(Fidan digeri) =>
      tekillikAnahtari == digeri.tekillikAnahtari;

  /// Kullanıcının düzenleyebildiği alanlar.
  ///
  /// Aktiflik ve zaman damgaları bilerek dışarıda: onları yalnızca sistem
  /// yazar (bkz. `Cari.duzenlenebilirAlanlar`).
  Map<String, Object?> duzenlenebilirAlanlar() => <String, Object?>{
    alanTur: tur,
    alanCesit: cesit,
    alanAnac: anac,
    alanYas: yas,
    alanKokTipi: kokTipi?.anahtar,
    alanVarsayilanFiyatKurus: varsayilanFiyat.deger,
    alanAramaAnahtari: aramaAnahtari,
    alanTurAnahtari: turAnahtari,
    alanAnacAnahtari: anacAnahtari,
  };

  Map<String, Object?> toMap() => <String, Object?>{
    ...duzenlenebilirAlanlar(),
    alanAktif: aktif,
    alanOlusturmaTarihi: olusturmaTarihi,
    alanGuncellemeTarihi: guncellemeTarihi,
  };

  @override
  bool operator ==(Object other) =>
      other is Fidan &&
      other.id == id &&
      other.tur == tur &&
      other.cesit == cesit &&
      other.anac == anac &&
      other.yas == yas &&
      other.kokTipi == kokTipi &&
      other.varsayilanFiyat == varsayilanFiyat &&
      other.aktif == aktif &&
      other.olusturmaTarihi == olusturmaTarihi &&
      other.guncellemeTarihi == guncellemeTarihi;

  @override
  int get hashCode => Object.hash(
    id,
    tur,
    cesit,
    anac,
    yas,
    kokTipi,
    varsayilanFiyat,
    aktif,
    olusturmaTarihi,
    guncellemeTarihi,
  );

  @override
  String toString() => 'Fidan($id, $goruntuAdi)';
}
