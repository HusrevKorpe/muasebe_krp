/// Uygulama gezinme yolları. Metin sabitleri tek yerde tutulur.
abstract final class Yollar {
  static const String acilis = '/acilis';
  static const String giris = '/giris';
  static const String kayit = '/kayit';

  /// İlk açılışta işletme bilgilerinin sorulduğu ekran.
  static const String kurulum = '/kurulum';

  /// Ana ekran: cari listesi.
  static const String ana = '/';

  static const String isletme = '/isletme';
  static const String cariYeni = '/cari/yeni';

  /// Yol kalıpları. Gezinirken doğrudan kullanılmaz; [cariDetayYolu] ve
  /// [cariDuzenleYolu] ile üretilir.
  static const String cariDetay = '/cari/:cariId';
  static const String cariDuzenle = '/cari/:cariId/duzenle';

  /// Fidan katalogu.
  static const String fidanlar = '/fidanlar';
  static const String fidanYeni = '/fidanlar/yeni';

  /// Fidan düzenleme: `/fidanlar/{fidanId}` — [fidanDuzenleYolu] ile üretilir.
  static const String fidanDuzenle = '/fidanlar/:fidanId';

  /// Yol parametrelerinin adı.
  static const String cariIdParametresi = 'cariId';
  static const String fidanIdParametresi = 'fidanId';

  static String cariDetayYolu(String cariId) => '/cari/$cariId';

  static String cariDuzenleYolu(String cariId) => '/cari/$cariId/duzenle';

  static String fidanDuzenleYolu(String fidanId) => '/fidanlar/$fidanId';

  /// Kimlik doğrulaması gerektirmeyen yollar.
  static const Set<String> kimliksizYollar = {acilis, giris, kayit};
}
