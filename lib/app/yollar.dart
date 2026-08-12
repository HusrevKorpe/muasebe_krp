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

  /// Yol parametresinin adı.
  static const String cariIdParametresi = 'cariId';

  static String cariDetayYolu(String cariId) => '/cari/$cariId';

  static String cariDuzenleYolu(String cariId) => '/cari/$cariId/duzenle';

  /// Kimlik doğrulaması gerektirmeyen yollar.
  static const Set<String> kimliksizYollar = {acilis, giris, kayit};
}
