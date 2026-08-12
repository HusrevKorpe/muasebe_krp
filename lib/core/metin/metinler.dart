/// Kullanıcıya görünen tüm metinler.
///
/// Metin widget içine gömülmez; hepsi buradan gelir (bkz. KURALLAR.md §6).
/// Uygulama tek dilli olduğu sürece sabit dosya yeterli — çok dil gerekirse
/// bu sınıfın alanları `l10n` anahtarlarına birebir taşınır.
///
/// Dosya 500 satırı zorlamaya başladığında özellik başına bölünür.
abstract final class Metinler {
  // ─── Ortak ───────────────────────────────────────────────────────────────
  static const String uygulamaAdi = 'FidanCari';
  static const String uygulamaTanimi = 'Cari hesap ve ön muhasebe takibi';

  static const String kaydet = 'Kaydet';
  static const String iptal = 'İptal';
  static const String vazgec = 'Vazgeç';
  static const String tamam = 'Tamam';
  static const String ekle = 'Ekle';
  static const String duzenle = 'Düzenle';
  static const String sil = 'Sil';
  static const String yenidenDene = 'Yeniden dene';
  static const String temizle = 'Temizle';
  static const String beklenmeyenHata = 'Beklenmeyen bir hata oluştu.';
  static const String kaydedildi = 'Kaydedildi.';

  // ─── Kimlik ──────────────────────────────────────────────────────────────
  static const String ePosta = 'E-posta';
  static const String sifre = 'Şifre';
  static const String sifreTekrari = 'Şifre (tekrar)';
  static const String sifreyiGoster = 'Şifreyi göster';
  static const String sifreyiGizle = 'Şifreyi gizle';
  static const String girisYap = 'Giriş Yap';
  static const String kayitOl = 'Kayıt Ol';
  static const String hesapOlustur = 'Hesap Oluştur';
  static const String sifremiUnuttum = 'Şifremi unuttum';
  static const String hesabinizYokMu = 'Hesabınız yok mu?';
  static const String kayitOlun = 'Kayıt olun';
  static const String zatenHesabinizVarMi = 'Zaten hesabınız var mı?';
  static const String girisYapin = 'Giriş yapın';
  static const String cikisYap = 'Çıkış yap';
  static const String kayitAciklama =
      'Verileriniz bu hesaba bağlanır. Telefonunuzu değiştirseniz bile aynı '
      'e-posta ile giriş yaparak cari kayıtlarınıza ulaşırsınız.';
  static const String sifreOncePosta =
      'Şifre sıfırlamak için önce e-posta adresinizi girin.';
  static const String sifreBaglantisiGonderildi =
      'Şifre sıfırlama bağlantısı e-postanıza gönderildi.';

  // ─── Kurulum ─────────────────────────────────────────────────────────────
  static const String kurulumBaslik = 'İşletme Bilgileri';
  static const String kurulumHosGeldiniz = 'Hoş geldiniz';
  static const String kurulumAciklama =
      'Bu bilgiler müşterilerinize göndereceğiniz ekstrenin başlığında '
      'görünecek. Sonradan değiştirebilirsiniz.';
  static const String kurulumTamamla = 'Kurulumu Tamamla';

  // ─── İşletme ─────────────────────────────────────────────────────────────
  static const String isletmeBaslik = 'İşletme Bilgileri';
  static const String isletmeMenu = 'İşletme bilgileri';
  static const String isletmeAdi = 'İşletme adı';
  static const String isletmeAdiIpucu = 'Favori Fidancılık';
  static const String isletmeUnvan = 'Ünvan';
  static const String isletmeUnvanIpucu = 'Tar.Taş.Hay.Ltd.Şti';
  static const String adres = 'Adres';
  static const String telefon = 'Telefon';
  static const String faks = 'Faks';
  static const String vergiDairesi = 'Vergi dairesi';
  static const String vergiNo = 'Vergi no / T.C. kimlik no';
  static const String istegeBagli = 'isteğe bağlı';

  static const String bankaHesaplari = 'Banka Hesapları';
  static const String bankaHesabiEkle = 'Banka hesabı ekle';
  static const String bankaHesabiYok = 'Henüz banka hesabı eklenmedi.';
  static const String bankaAdi = 'Banka';
  static const String bankaAdiIpucu = 'Ziraat Bankası';
  static const String hesapNo = 'Hesap no';
  static const String iban = 'IBAN';
  static const String paraBirimi = 'Para birimi';
  static const String bankaHesabiSilOnay =
      'Bu banka hesabı silinsin mi? Ekstrede artık görünmeyecek.';

  // ─── Cari listesi ────────────────────────────────────────────────────────
  static const String cariler = 'Cariler';
  static const String cariAra = 'Cari ara';
  static const String cariEkle = 'Cari Ekle';
  static const String cariDuzenle = 'Cariyi Düzenle';
  static const String siralama = 'Sıralama';
  static const String cariYokBaslik = 'Henüz cari yok';
  static const String cariYokAciklama =
      'Müşteri veya tedarikçilerinizi ekleyerek başlayın.';
  static const String aramaSonucuYokBaslik = 'Sonuç bulunamadı';
  static const String aramaSonucuYokAciklama =
      'Farklı bir ad ile aramayı deneyin.';
  static const String listeYuklenemedi = 'Cari listesi yüklenemedi.';
  static const String dahaFazlaYuklenemedi =
      'Sonraki kayıtlar yüklenemedi. Dokunup tekrar deneyin.';
  static const String kaydedilmedi = 'Kaydedilmedi';
  static const String kaydedilmediAciklama =
      'İnternet bağlantısı gelince gönderilecek.';

  // ─── Cari formu ──────────────────────────────────────────────────────────
  static const String cariAdi = 'Cari adı';
  static const String cariAdiIpucu = 'Ahmet Koyuncu';
  static const String cariUnvan = 'Firma ünvanı';
  static const String sehir = 'Şehir';
  static const String sehirIpucu = 'Isparta';
  static const String notlar = 'Notlar';
  static const String cariPasifeAl = 'Pasife al';
  static const String cariPasifeAlOnay =
      'Cari listeden kaldırılsın mı? Kayıt silinmez, geçmiş işlemleri durur.';
  static const String cariPasifeAlindi = 'Cari pasife alındı.';
  static const String cariBulunamadi = 'Cari bulunamadı.';

  // ─── Cari detayı ─────────────────────────────────────────────────────────
  static const String bakiye = 'Bakiye';

  /// Pozitif bakiye: cari işletmeye borçlu.
  static const String bakiyeCariBorclu = 'Bu cari size borçlu';

  /// Negatif bakiye: işletme cariye borçlu.
  static const String bakiyeIsletmeBorclu = 'Siz bu cariye borçlusunuz';

  static const String bakiyeKapali = 'Hesap kapalı';
  static const String iletisim = 'İletişim';
  static const String vergiBilgileri = 'Vergi Bilgileri';
  static const String islemler = 'İşlemler';
  static const String islemYokBaslik = 'Henüz işlem yok';
  static const String islemYokAciklama =
      'Fatura ve tahsilat girişi bir sonraki sürümde açılacak.';
  static const String sonIslem = 'Son işlem';
}
