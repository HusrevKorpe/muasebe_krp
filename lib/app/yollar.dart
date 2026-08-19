import '../domain/cari/cari_grubu.dart';
import '../domain/islem/islem_tipi.dart';
import '../domain/secenek/secenek_tipi.dart';

/// Uygulama gezinme yolları. Metin sabitleri tek yerde tutulur.
abstract final class Yollar {
  /// Saklanan oturum yüklenene kadar beklenen ekran.
  static const String acilis = '/acilis';

  /// E-posta ve şifreyle giriş ekranı.
  static const String giris = '/giris';

  /// Ana ekran: kişi listesi. Alt sekmelerin ilki.
  static const String ana = '/';

  /// Ayarlar sekmesi ve altındaki işletme profili sayfası.
  static const String ayarlar = '/ayarlar';
  static const String isletme = '/isletme';

  static const String cariYeni = '/cari/yeni';

  /// Ayarlar'dan açılan "Kaldırılan Kişiler" sayfası. Kişi kalıplarıyla
  /// karışmasın diye çoğul kökte: `/cari/:cariId` ile eşleşmiyor.
  static const String pasifCariler = '/cariler/kaldirilan';

  /// Yeni kişi formunun grubunu ön dolduran sorgu parametresi.
  ///
  /// Fidancılar sekmesinden "Kişi Ekle"ye basan kullanıcı fidancı eklemek
  /// istiyor; form müşteri açılırsa kaydettiği kişi bulunduğu sekmeden kaybolur.
  static const String grupParametresi = 'grup';

  /// Yol kalıpları. Gezinirken doğrudan kullanılmaz; [cariDetayYolu] ve
  /// [cariDuzenleYolu] ile üretilir.
  static const String cariDetay = '/cari/:cariId';
  static const String cariDuzenle = '/cari/:cariId/duzenle';

  /// Yeni işlem formu: `/cari/{cariId}/islem/yeni/{tip}`
  static const String islemYeni = '/cari/:cariId/islem/yeni/:tip';

  /// İşlem detayı: `/cari/{cariId}/islem/{islemId}`
  static const String islemDetay = '/cari/:cariId/islem/:islemId';

  /// Kayıtlı işlemi düzenleme: `/cari/{cariId}/islem/{islemId}/duzenle`
  static const String islemDuzenle = '/cari/:cariId/islem/:islemId/duzenle';

  /// PDF ekstre: `/cari/{cariId}/ekstre`
  static const String ekstre = '/cari/:cariId/ekstre';

  /// Ürün listesi — sattığımız şeyler.
  static const String urunler = '/urunler';
  static const String urunYeni = '/urunler/yeni';

  /// Ürün düzenleme: `/urunler/{urunId}` — [urunDuzenleYolu] ile üretilir.
  static const String urunDuzenle = '/urunler/:urunId';

  /// Tür, çeşit ve anaç listeleri: `/listeler/{tip}` — [seceneklerYolu] ile
  /// üretilir. Ayarlar'dan açılır; fatura kalemindeki seçim sayfası bu yoldan
  /// değil doğrudan `Navigator` ile açılır, çünkü geriye bir değer döndürüyor.
  static const String secenekler = '/listeler/:tip';

  /// Yol parametrelerinin adı.
  static const String cariIdParametresi = 'cariId';
  static const String islemIdParametresi = 'islemId';
  static const String urunIdParametresi = 'urunId';
  static const String tipParametresi = 'tip';

  /// Yeni kişi formu, grubu seçili gelecek şekilde.
  static String cariYeniYolu(CariGrubu grup) =>
      '$cariYeni?$grupParametresi=${grup.anahtar}';

  static String cariDetayYolu(String cariId) => '/cari/$cariId';

  static String cariDuzenleYolu(String cariId) => '/cari/$cariId/duzenle';

  static String islemYeniYolu(String cariId, IslemTipi tip) =>
      '/cari/$cariId/islem/yeni/${tip.anahtar}';

  static String islemDetayYolu(String cariId, String islemId) =>
      '/cari/$cariId/islem/$islemId';

  static String islemDuzenleYolu(String cariId, String islemId) =>
      '/cari/$cariId/islem/$islemId/duzenle';

  static String ekstreYolu(String cariId) => '/cari/$cariId/ekstre';

  static String urunDuzenleYolu(String urunId) => '/urunler/$urunId';

  static String seceneklerYolu(SecenekTipi tip) => '/listeler/${tip.anahtar}';
}
