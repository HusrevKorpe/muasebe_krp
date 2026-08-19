/// İşlem tipi ve bakiyeye etkisinin yönü.
///
/// Fidancılıkta alım ve satım çoğu kez aynı kişiyle yapılır; bu yüzden tip
/// cariye değil işleme aittir. Yön tablosu (bkz. `fazlar/faz-2-islemler.md`):
///
/// | İşlem | Etki |
/// |---|---|
/// | Satış faturası | Borç — cari bize borçlanır |
/// | Tahsilat | Alacak — cari borcunu öder |
/// | Alış faturası | Alacak — biz cariye borçlanırız |
/// | Ödeme | Borç — biz cariye öderiz |
/// | Hesap görüldü | Kalan bakiyeyi kapatır, yönü bakiyenin işaretinden gelir |
enum IslemTipi {
  satisFaturasi(anahtar: 'satisFaturasi', borcMu: true, faturaMi: true),
  alisFaturasi(anahtar: 'alisFaturasi', borcMu: false, faturaMi: true),
  tahsilat(anahtar: 'tahsilat', borcMu: false, faturaMi: false),
  odeme(anahtar: 'odeme', borcMu: true, faturaMi: false),

  /// Alacağımızdan vazgeçtik: cari bize borçluydu, kalanı silindi.
  ///
  /// Kullanıcının deyişiyle "hesap görme": *"adamın bana 105.000 borcu var,
  /// 100.000'e düzlüyor; 100.000 aldıktan sonra hesap kapandı."* 100.000
  /// tahsilat olarak girilir, kalan 5.000 bu kayıtla kapanır. Para el
  /// değiştirmediği için tahsilat değildir; kayıt silinmediğinden
  /// (KURALLAR.md §4.2) fark ekstrede "Hesap görüldü" satırı olarak durur.
  hesapGorulduAlacak(
    anahtar: 'hesapGorulduAlacak',
    borcMu: false,
    faturaMi: false,
  ),

  /// Borcumuz silindi: biz cariye borçluyduk, kalandan vazgeçti.
  ///
  /// [hesapGorulduAlacak]'ın ters yönü. İki ayrı tip olmasının sebebi
  /// [borcMu]'nun tipin sabiti olması: yön bakiyenin işaretine bağlı ve tek bir
  /// tiple ifade edilemiyor. Kullanıcıya ikisi de "Hesap görüldü" diye görünür.
  hesapGorulduBorc(anahtar: 'hesapGorulduBorc', borcMu: true, faturaMi: false);

  const IslemTipi({
    required this.anahtar,
    required this.borcMu,
    required this.faturaMi,
  });

  /// Firestore'a yazılan değer.
  ///
  /// Enum'ın `name` alanı yerine açıkça yazılır: alan adı değiştirilirse
  /// veritabanındaki geçmiş kayıtlar sessizce okunamaz hâle gelirdi.
  final String anahtar;

  /// `true` ise işlem bakiyeyi artırır (borç), `false` ise azaltır (alacak).
  final bool borcMu;

  /// Fatura tipleri kalem ve vade tarihi taşır; tahsilat ve ödeme taşımaz.
  final bool faturaMi;

  bool get alacakMi => !borcMu;

  /// Kalan bakiyeyi kapatan kayıt mı — iki yönden biri.
  bool get hesapGormeMi =>
      this == hesapGorulduAlacak || this == hesapGorulduBorc;

  /// Kayıt sonradan düzenlenebilir mi.
  ///
  /// Hesap görme kaydının tutarı kaydedildiği andaki bakiyeden türetildi; elle
  /// değiştirilirse bakiye sıfırda kalmaz ve "hesap kapandı" yalanı olurdu.
  /// Yanlışlıkla kapatılan hesabın geri alma yolu **iptaldir**: iptal edilen
  /// kayıt bakiyeyi olduğu gibi geri getirir.
  bool get duzenlenebilirMi => !hesapGormeMi;

  /// Tutarın bakiyeye eklenirken alacağı işaret: borç `+1`, alacak `-1`.
  int get isaret => borcMu ? 1 : -1;

  /// Firestore'dan okunan değeri tipe çevirir.
  ///
  /// Tanınmayan değer için `null` döner; çağıran tarafın ne yapacağına karar
  /// vermesi gerekir (eski bir sürümün yazdığı tip olabilir).
  static IslemTipi? anahtardan(String? anahtar) {
    for (final tip in values) {
      if (tip.anahtar == anahtar) return tip;
    }
    return null;
  }

  /// Kullanıcının kişi sayfasındaki düğmelerden doğrudan girdiği tipler.
  ///
  /// Hesap görme burada yok: tutarı kullanıcıdan değil bakiyeden geliyor ve
  /// ayrı bir onay penceresinden kaydediliyor.
  static const List<IslemTipi> girisTipleri = <IslemTipi>[
    satisFaturasi,
    alisFaturasi,
    tahsilat,
    odeme,
  ];

  /// Fatura tipleri — form ekranının seçenek listesi.
  static const List<IslemTipi> faturalar = <IslemTipi>[
    satisFaturasi,
    alisFaturasi,
  ];

  /// Tahsilat ve ödeme — form ekranının seçenek listesi.
  static const List<IslemTipi> odemeler = <IslemTipi>[tahsilat, odeme];
}
