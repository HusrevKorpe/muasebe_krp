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
enum IslemTipi {
  satisFaturasi(anahtar: 'satisFaturasi', borcMu: true, faturaMi: true),
  alisFaturasi(anahtar: 'alisFaturasi', borcMu: false, faturaMi: true),
  tahsilat(anahtar: 'tahsilat', borcMu: false, faturaMi: false),
  odeme(anahtar: 'odeme', borcMu: true, faturaMi: false);

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

  /// Fatura tipleri kalem, KDV ve vade tarihi taşır; tahsilat ve ödeme taşımaz.
  final bool faturaMi;

  bool get alacakMi => !borcMu;

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

  /// Fatura tipleri — form ekranının seçenek listesi.
  static const List<IslemTipi> faturalar = <IslemTipi>[
    satisFaturasi,
    alisFaturasi,
  ];

  /// Tahsilat ve ödeme — form ekranının seçenek listesi.
  static const List<IslemTipi> odemeler = <IslemTipi>[tahsilat, odeme];
}
