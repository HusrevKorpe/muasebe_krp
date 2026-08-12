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
      'Bu cariye ilk faturayı veya tahsilatı ekleyin.';
  static const String sonIslem = 'Son işlem';

  // ─── İşlem tipleri ───────────────────────────────────────────────────────
  static const String satisFaturasi = 'Satış Faturası';
  static const String alisFaturasi = 'Alış Faturası';
  static const String tahsilat = 'Tahsilat';
  static const String odeme = 'Ödeme';

  /// Ekstrede tahsilat satırının açıklaması.
  static const String musteridenTahsilat = 'Müşteriden Tahsilat';
  static const String cariyeOdeme = 'Cariye Ödeme';

  // ─── İşlem listesi ───────────────────────────────────────────────────────
  static const String islemEkle = 'İşlem ekle';
  static const String islemDetayi = 'İşlem Detayı';
  static const String sonrakiIslemlerYuklenemedi =
      'Sonraki işlemler yüklenemedi. Dokunup tekrar deneyin.';
  static const String borc = 'Borç';
  static const String alacak = 'Alacak';
  static const String iptalEdildi = 'İptal edildi';
  static const String teslimEdildi = 'Teslim edildi';
  static const String beklemede = 'Beklemede';

  // ─── Fatura formu ────────────────────────────────────────────────────────
  static const String yeniSatisFaturasi = 'Yeni Satış Faturası';
  static const String yeniAlisFaturasi = 'Yeni Alış Faturası';
  static const String yeniTahsilat = 'Yeni Tahsilat';
  static const String yeniOdeme = 'Yeni Ödeme';
  static const String islemTipi = 'İşlem tipi';
  static const String aciklama = 'Açıklama';
  static const String aciklamaIpucu = 'Zeytin-Hurma';
  static const String islemTarihi = 'İşlem tarihi';
  static const String vadeTarihi = 'Vade tarihi';
  static const String vadeYok = 'Vade tarihi yok';
  static const String tutar = 'Tutar';

  static const String kalemler = 'Kalemler';
  static const String kalemEkle = 'Kalem ekle';
  static const String kalemDuzenle = 'Kalemi düzenle';
  static const String kalemYok = 'Henüz kalem eklenmedi.';
  static const String kalemYokAciklama =
      'Faturayı kaydetmek için en az bir kalem ekleyin.';
  static const String kalemAdi = 'Kalem adı';
  static const String kalemAdiIpucu = 'zeytin';
  static const String miktar = 'Miktar';
  static const String birimFiyat = 'Birim fiyat';

  static const String girisModu = 'Giriş şekli';
  static const String birimFiyatGir = 'Birim fiyat';
  static const String toplamGir = 'Toplam tutar';
  static const String toplamGirAciklama =
      'Toplamı yazın, birim fiyat hesaplansın.';
  static const String birimFiyatGirAciklama =
      'Birim fiyatı yazın, tutar hesaplansın.';

  /// Birim fiyat, toplamdan geri hesaplandığı için yuvarlanmış olabilir.
  static const String birimFiyatYaklasik =
      'Birim fiyat yuvarlanmıştır; fatura tutarı girdiğiniz toplamdır.';

  static const String araToplam = 'Ara toplam';
  static const String kdv = 'KDV';
  static const String kdvUygula = 'KDV uygula (%1)';
  static const String genelToplam = 'Genel toplam';

  // ─── İşlem detayı ────────────────────────────────────────────────────────
  static const String islemiIptalEt = 'İşlemi iptal et';
  static const String islemIptalOnay =
      'Bu işlem iptal edilsin mi? Kayıt silinmez, listede üstü çizili kalır ve '
      'bakiyeye katkısı geri alınır.';
  static const String iptalNedeni = 'İptal nedeni';
  static const String islemIptalEdildi = 'İşlem iptal edildi.';
  static const String iptalliIslemUyarisi =
      'Bu işlem iptal edilmiştir; bakiyeye katılmaz.';
  static const String bakiyeYenidenHesapla = 'Bakiyeyi yeniden hesapla';
  static const String bakiyeYenidenHesaplandi = 'Bakiye yeniden hesaplandı.';

  // ─── Fidan katalogu ──────────────────────────────────────────────────────
  static const String fidanKatalogu = 'Fidan Katalogu';
  static const String fidanKatalogMenu = 'Fidan katalogu';
  static const String fidanAra = 'Fidan ara';
  static const String fidanEkle = 'Fidan Ekle';
  static const String fidanDuzenle = 'Fidanı Düzenle';
  static const String fidanSec = 'Fidan Seç';
  static const String fidanBulunamadi = 'Fidan bulunamadı.';
  static const String fidanYokBaslik = 'Katalog boş';
  static const String fidanYokAciklama =
      'Sattığınız fidanları ekleyin; fatura keserken listeden seçersiniz.';
  static const String fidanPasifeAl = 'Katalogdan kaldır';
  static const String fidanPasifeAlOnay =
      'Fidan katalogdan kaldırılsın mı? Kayıt silinmez, geçmiş faturalar '
      'olduğu gibi kalır.';
  static const String fidanPasifeAlindi = 'Fidan katalogdan kaldırıldı.';

  // ─── Fidan alanları ──────────────────────────────────────────────────────
  static const String tur = 'Tür';
  static const String turIpucu = 'Elma';
  static const String cesit = 'Çeşit';
  static const String cesitIpucu = 'Scarlet';
  static const String anac = 'Anaç';
  static const String anacIpucu = 'M9';
  static const String yas = 'Yaş';
  static const String yasIpucu = '2';

  /// Görünen adın sonundaki yaş eki: `… · 2 Yaş`
  static const String yasSoneki = 'Yaş';

  static const String kokTipi = 'Kök tipi';
  static const String kokTipiTuplu = 'Tüplü';
  static const String kokTipiCiplakKok = 'Çıplak Kök';
  static const String kokTipiYok = 'Belirtilmedi';
  static const String fidanOnizlemeBaslik = 'Faturada görünecek ad';
  static const String fidanOnizlemeBos =
      'Tür ve çeşit yazınca burada görünür.';
  static const String varsayilanFiyat = 'Varsayılan fiyat';
  static const String varsayilanFiyatAciklama =
      'Faturada ön dolgu olarak gelir; orada değiştirebilirsiniz.';
  static const String fiyatYok = 'Fiyat girilmedi';
  static const String oneriler = 'Öneriler';

  /// Mükerrer kayıt uyarısı — aynı tür/çeşit/anaç/yaş/kök tipi.
  static const String fidanMukerrer =
      'Bu fidan katalogda zaten kayıtlı. Aynı kaydı ikinci kez eklemek yerine '
      'mevcut kaydı düzenleyin.';

  // ─── Katalog ↔ fatura kalemi ─────────────────────────────────────────────
  static const String katalogdanSec = 'Katalogdan seç';
  static const String katalogBagi = 'Katalog';
  static const String katalogBaginiKaldir = 'Katalog bağını kaldır';
  static const String katalogSerbestMetinAciklama =
      'Katalog zorunlu değil: "nakliye" gibi kalemleri elle yazabilirsiniz.';

  // ─── Ekstre ──────────────────────────────────────────────────────────────
  static const String ekstre = 'Ekstre';
  static const String ekstreAl = 'Ekstre Al';
  static const String ekstrePaylas = 'Paylaş';
  static const String ekstreUretiliyor = 'Ekstre hazırlanıyor…';
  static const String ekstreUretilemedi = 'Ekstre hazırlanamadı.';
  static const String ekstreBosBaslik = 'Bu aralıkta işlem yok';
  static const String ekstreBosAciklama =
      'Ekstre yine de üretilir; tabloda yalnızca devreden bakiye görünür.';

  /// Tablo ile toplamlar tutmuyorsa PDF üretilmez — referans yazılımın
  /// düştüğü hataya düşmemek için (bkz. `fazlar/faz-4-ekstre.md`).
  static const String ekstreTutarsiz =
      'Ekstre toplamları tutmuyor. Bakiyeyi yeniden hesaplayıp tekrar deneyin.';

  // Hazır tarih aralıkları
  static const String aralikBuAy = 'Bu ay';
  static const String aralikBuYil = 'Bu yıl';
  static const String aralikTumu = 'Tümü';
  static const String aralikOzel = 'Özel aralık';
  static const String aralikBaslangic = 'Başlangıç';
  static const String aralikBitis = 'Bitiş';

  // ─── Ekstre PDF'i ────────────────────────────────────────────────────────
  static const String ekstreBaslik = 'İŞLEM DÖKÜMÜ';
  static const String ekstreIlgiliFirma = 'İLGİLİ FİRMA';
  static const String ekstreKolonIslemTarihi = 'İŞLEM TARİHİ';
  static const String ekstreKolonAciklama = 'AÇIKLAMA';
  static const String ekstreKolonVadeTarihi = 'VADE TARİHİ';
  static const String ekstreKolonBorc = 'BORÇ';
  static const String ekstreKolonAlacak = 'ALACAK';
  static const String ekstreKolonBakiye = 'BAKİYE ₺';
  static const String ekstreDevreden = 'Devreden bakiye';
  static const String ekstreToplamBorc = 'TOPLAM BORÇ';
  static const String ekstreToplamAlacak = 'TOPLAM ALACAK';
  static const String ekstreBakiye = 'BAKİYE';
  static const String ekstreBankaBilgileri = 'Banka Hesap Bilgileri';
  static const String ekstreHesapNo = 'HESAP NO';
  static const String ekstreIban = 'IBAN';
  static const String ekstreTelefon = 'TEL';
  static const String ekstreFaks = 'FAX';
  static const String ekstreVergiDairesi = 'VD';
  static const String ekstreVergiNo = 'VKN';

  /// `SAYFA 1 / 2` — ilk parça kalın basılır, ikincisi soluk.
  static String ekstreSayfa(int sayfa) => 'SAYFA $sayfa';
  static String ekstreSayfaToplami(int toplam) => ' / $toplam';

  // ─── İşlem doğrulama ─────────────────────────────────────────────────────
  static const String aciklamaGerekli = 'Açıklama gerekli.';
  static const String kalemGerekli = 'En az bir kalem ekleyin.';
  static const String kalemAdiGerekli = 'Kalem adı gerekli.';
  static const String miktarGerekli = 'Miktar gerekli.';
  static const String miktarGecersiz = 'Miktar sıfırdan büyük olmalı.';
  static const String tutarGerekli = 'Tutar gerekli.';
  static const String tutarGecersiz = 'Geçerli bir tutar yazın: 31.000,00';
  static const String tutarSifirOlamaz = 'Tutar sıfırdan büyük olmalı.';
}
