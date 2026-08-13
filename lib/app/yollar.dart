import '../domain/islem/islem_tipi.dart';

/// Uygulama gezinme yolları. Metin sabitleri tek yerde tutulur.
abstract final class Yollar {
  /// Saklanan oturum yüklenene kadar beklenen ekran.
  static const String acilis = '/acilis';

  /// Google ile giriş ekranı. Hesabın izin listesinde olmadığı da burada
  /// söylenir — bkz. `features/giris/view/giris_ekrani.dart`.
  static const String giris = '/giris';

  /// Ana ekran: kişi listesi. Alt sekmelerin ilki.
  static const String ana = '/';

  /// Ayarlar sekmesi ve altındaki işletme profili sayfası.
  static const String ayarlar = '/ayarlar';
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

  /// PDF ekstre: `/cari/{cariId}/ekstre`
  static const String ekstre = '/cari/:cariId/ekstre';

  /// Ürün listesi — sattığımız şeyler.
  static const String urunler = '/urunler';
  static const String urunYeni = '/urunler/yeni';

  /// Ürün düzenleme: `/urunler/{urunId}` — [urunDuzenleYolu] ile üretilir.
  static const String urunDuzenle = '/urunler/:urunId';

  /// Yol parametrelerinin adı.
  static const String cariIdParametresi = 'cariId';
  static const String islemIdParametresi = 'islemId';
  static const String urunIdParametresi = 'urunId';
  static const String tipParametresi = 'tip';

  static String cariDetayYolu(String cariId) => '/cari/$cariId';

  static String cariDuzenleYolu(String cariId) => '/cari/$cariId/duzenle';

  static String islemYeniYolu(String cariId, IslemTipi tip) =>
      '/cari/$cariId/islem/yeni/${tip.anahtar}';

  static String islemDetayYolu(String cariId, String islemId) =>
      '/cari/$cariId/islem/$islemId';

  static String ekstreYolu(String cariId) => '/cari/$cariId/ekstre';

  static String urunDuzenleYolu(String urunId) => '/urunler/$urunId';
}
