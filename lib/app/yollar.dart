import '../domain/islem/islem_tipi.dart';

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

  /// Yeni işlem formu: `/cari/{cariId}/islem/yeni/{tip}`
  static const String islemYeni = '/cari/:cariId/islem/yeni/:tip';

  /// İşlem detayı: `/cari/{cariId}/islem/{islemId}`
  static const String islemDetay = '/cari/:cariId/islem/:islemId';

  /// Fidan katalogu.
  static const String fidanlar = '/fidanlar';
  static const String fidanYeni = '/fidanlar/yeni';

  /// Fidan düzenleme: `/fidanlar/{fidanId}` — [fidanDuzenleYolu] ile üretilir.
  static const String fidanDuzenle = '/fidanlar/:fidanId';

  /// Yol parametrelerinin adı.
  static const String cariIdParametresi = 'cariId';
  static const String islemIdParametresi = 'islemId';
  static const String fidanIdParametresi = 'fidanId';
  static const String tipParametresi = 'tip';

  static String cariDetayYolu(String cariId) => '/cari/$cariId';

  static String cariDuzenleYolu(String cariId) => '/cari/$cariId/duzenle';

  static String islemYeniYolu(String cariId, IslemTipi tip) =>
      '/cari/$cariId/islem/yeni/${tip.anahtar}';

  static String islemDetayYolu(String cariId, String islemId) =>
      '/cari/$cariId/islem/$islemId';

  static String fidanDuzenleYolu(String fidanId) => '/fidanlar/$fidanId';

  /// Kimlik doğrulaması gerektirmeyen yollar.
  static const Set<String> kimliksizYollar = {acilis, giris, kayit};
}
