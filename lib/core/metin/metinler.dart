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

  // ─── Giriş ───────────────────────────────────────────────────────────────
  static const String girisAciklama =
      'Devam etmek için e-posta ve şifrenizi girin.';
  static const String ePosta = 'E-posta';
  static const String sifre = 'Şifre';
  static const String sifreyiGoster = 'Şifreyi göster';
  static const String sifreyiGizle = 'Şifreyi gizle';
  static const String girisYap = 'Giriş yap';
  static const String cikisYap = 'Çıkış yap';
  static const String cikisOnay =
      'Çıkış yapılsın mı? Kayıtlar silinmez; yeniden giriş yapınca hepsi '
      'yerinde durur.';

  // ─── Ayarlar ─────────────────────────────────────────────────────────────
  static const String ayarlar = 'Ayarlar';
  static const String isletmeAyarAciklama =
      'Hesap dökümünün başlığında görünen ad, adres ve banka hesapları.';
  static const String hesap = 'Hesap';

  // ─── İşletme ─────────────────────────────────────────────────────────────
  static const String isletmeBaslik = 'İşletme Bilgileri';
  static const String isletmeMenu = 'İşletme bilgileri';

  /// Alanların hiçbiri zorunlu değil; formun başında bunu söylüyoruz ki
  /// kullanıcı doldurmak zorunda sanmasın.
  static const String isletmeFormAciklama =
      'Tamamı isteğe bağlı. Doldurursanız müşterilerinize göndereceğiniz '
      'hesap dökümünün başlığında görünür.';
  static const String isletmeAdi = 'İşletme adı';
  static const String isletmeAdiIpucu = 'Favori Fidancılık';
  static const String isletmeUnvan = 'Ünvan';
  static const String isletmeUnvanIpucu = 'Tar.Taş.Hay.Ltd.Şti';
  static const String adres = 'Adres';
  static const String telefon = 'Telefon';
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

  // ─── Kişi listesi ────────────────────────────────────────────────────────
  //
  // Kod tarafında model adı `Cari` kalıyor (bkz. KURALLAR.md, domain terimleri);
  // ekranda görünen sözcük "kişi". Uygulama tek kişinin kendi defteri, muhasebe
  // yazılımı değil.
  static const String cariler = 'Kişiler';
  static const String cariAra = 'Kişi ara';
  static const String cariEkle = 'Kişi Ekle';
  static const String cariDuzenle = 'Kişiyi Düzenle';
  static const String cariYokBaslik = 'Henüz kimse yok';
  static const String cariYokAciklama =
      'Alışveriş yaptığın kişileri ekleyerek başla.';
  static const String aramaSonucuYokBaslik = 'Sonuç bulunamadı';
  static const String aramaSonucuYokAciklama =
      'Farklı bir ad ile aramayı deneyin.';
  static const String listeYuklenemedi = 'Kişi listesi yüklenemedi.';
  static const String dahaFazlaYuklenemedi =
      'Sonraki kayıtlar yüklenemedi. Dokunup tekrar deneyin.';
  static const String kaydedilmedi = 'Kaydedilmedi';
  static const String kaydedilmediAciklama =
      'İnternet bağlantısı gelince gönderilecek.';

  // ─── Kişi formu ──────────────────────────────────────────────────────────
  static const String cariAdi = 'Adı';
  static const String cariAdiIpucu = 'Ahmet Koyuncu';
  static const String cariUnvan = 'Firma adı';
  static const String sehir = 'Şehir';
  static const String sehirIpucu = 'Isparta';
  static const String notlar = 'Notlar';
  static const String cariPasifeAl = 'Listeden kaldır';
  static const String cariPasifeAlOnay =
      'Kişi listeden kaldırılsın mı? Kayıt silinmez, geçmiş kayıtları durur.';
  static const String cariPasifeAlindi = 'Kişi listeden kaldırıldı.';
  static const String cariBulunamadi = 'Kişi bulunamadı.';

  // ─── Cari detayı ─────────────────────────────────────────────────────────
  static const String bakiye = 'Bakiye';

  /// Pozitif bakiye: kişi işletmeye borçlu.
  static const String bakiyeCariBorclu = 'Sana borcu var';

  /// Negatif bakiye: işletme kişiye borçlu.
  static const String bakiyeIsletmeBorclu = 'Ona borcun var';

  static const String bakiyeKapali = 'Hesap kapalı';
  static const String iletisim = 'İletişim';
  static const String islemler = 'Hareketler';
  static const String islemYokBaslik = 'Henüz hareket yok';
  static const String islemYokAciklama =
      'Aşağıdaki düğmelerle ilk satışı ya da ödemeyi gir.';
  static const String sonIslem = 'Son hareket';

  // ─── İşlem tipleri ───────────────────────────────────────────────────────
  //
  // İki ad var. Ekranda günlük dil kullanılıyor — uygulama kişinin kendi
  // defteri. PDF hesap dökümü ise müşteriye gidiyor; orada belge dili duruyor.
  static const String sattim = 'Sattım';
  static const String aldim = 'Aldım';
  static const String paraAldim = 'Para aldım';
  static const String paraVerdim = 'Para verdim';

  static const String satisFaturasi = 'Satış Faturası';
  static const String alisFaturasi = 'Alış Faturası';
  static const String tahsilat = 'Tahsilat';
  static const String odeme = 'Ödeme';

  /// Hesap dökümünde tahsilat satırının açıklaması.
  static const String musteridenTahsilat = 'Müşteriden Tahsilat';
  static const String cariyeOdeme = 'Ödeme';

  // ─── İşlem listesi ───────────────────────────────────────────────────────
  static const String islemDetayi = 'Hareket';
  static const String sonrakiIslemlerYuklenemedi =
      'Sonraki işlemler yüklenemedi. Dokunup tekrar deneyin.';
  static const String borc = 'Borç';
  static const String alacak = 'Alacak';
  static const String iptalEdildi = 'İptal edildi';

  // ─── Giriş formu ─────────────────────────────────────────────────────────
  static const String aciklama = 'Açıklama';
  static const String aciklamaIpucu = 'Zeytin-Hurma';

  /// Açıklama zorunlu değil; boş bırakılırsa kalem adlarından üretilir.
  static const String aciklamaAciklamasi =
      'Boş bırakırsan aşağıdaki satırlardan yazılır.';
  static const String islemTarihi = 'Tarih';
  static const String tutar = 'Tutar';

  static const String kalemler = 'Neler';
  static const String kalemEkle = 'Satır ekle';
  static const String kalemDuzenle = 'Satırı düzenle';
  static const String kalemYok = 'Henüz satır yok.';
  static const String kalemYokAciklama =
      'Kaydetmek için en az bir satır ekle.';
  static const String kalemAdi = 'Ne';
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

  static const String genelToplam = 'Genel toplam';

  // ─── İşlem detayı ────────────────────────────────────────────────────────
  static const String islemiIptalEt = 'Bu kaydı iptal et';
  static const String islemIptalOnay =
      'Bu kayıt iptal edilsin mi? Kayıt silinmez, listede üstü çizili kalır ve '
      'bakiyeye katkısı geri alınır.';
  static const String iptalNedeni = 'İptal nedeni';
  static const String islemIptalEdildi = 'Kayıt iptal edildi.';
  static const String iptalliIslemUyarisi =
      'Bu kayıt iptal edilmiştir; bakiyeye katılmaz.';
  static const String bakiyeYenidenHesapla = 'Bakiyeyi yeniden hesapla';
  static const String bakiyeYenidenHesaplandi = 'Bakiye yeniden hesaplandı.';

  // ─── Ürünler ─────────────────────────────────────────────────────────────
  static const String urunler = 'Ürünler';
  static const String urunAra = 'Ürün ara';
  static const String urunEkle = 'Ürün Ekle';
  static const String urunDuzenle = 'Ürünü Düzenle';
  static const String urunSec = 'Ürün Seç';
  static const String urunBulunamadi = 'Ürün bulunamadı.';
  static const String urunYokBaslik = 'Liste boş';
  static const String urunYokAciklama =
      'Sattığınız şeyleri ekleyin; satış girerken listeden seçersiniz.';
  static const String urunPasifeAl = 'Listeden kaldır';
  static const String urunPasifeAlOnay =
      'Ürün listeden kaldırılsın mı? Kayıt silinmez, geçmiş kayıtlar olduğu '
      'gibi kalır.';
  static const String urunPasifeAlindi = 'Ürün listeden kaldırıldı.';

  // ─── Ürün alanları ───────────────────────────────────────────────────────
  static const String urunAdi = 'Ürün adı';
  static const String urunAdiIpucu = 'Elma Scarlet M9 2 yaş tüplü';
  static const String urunFiyati = 'Fiyat';
  static const String urunFiyatiAciklama =
      'İsteğe bağlı. Satış girerken ön dolgu gelir, orada değiştirebilirsiniz.';
  static const String fiyatYok = 'Fiyat girilmedi';

  static const String urunMukerrer =
      'Bu ürün listede zaten kayıtlı. Aynı kaydı ikinci kez eklemek yerine '
      'mevcut kaydı düzenleyin.';

  // ─── Ürün ↔ fatura kalemi ────────────────────────────────────────────────
  static const String urundenSec = 'Üründen seç';
  static const String urunBagi = 'Ürün';
  static const String urunBaginiKaldir = 'Ürün bağını kaldır';
  static const String urunSerbestMetinAciklama =
      'Listeden seçmek zorunlu değil: "nakliye" gibi kalemleri elle '
      'yazabilirsiniz.';

  // ─── Hesap dökümü ────────────────────────────────────────────────────────
  //
  // Ekranda "hesap dökümü" deniyor; müşteriye giden PDF'in başlığı ise
  // "İŞLEM DÖKÜMÜ" olarak kalıyor — belge dili ayrı (bkz. [ekstreBaslik]).
  static const String ekstre = 'Hesap Dökümü';
  static const String ekstreAl = 'Hesap dökümü';
  static const String ekstrePaylas = 'Paylaş';
  static const String ekstreUretiliyor = 'Hazırlanıyor…';
  static const String ekstreUretilemedi = 'Hesap dökümü hazırlanamadı.';
  static const String ekstreBosBaslik = 'Bu aralıkta hareket yok';
  static const String ekstreBosAciklama =
      'Döküm yine de üretilir; tabloda yalnızca devreden bakiye görünür.';

  /// Tablo ile toplamlar tutmuyorsa PDF üretilmez — referans yazılımın
  /// düştüğü hataya düşmemek için (bkz. `fazlar/faz-4-ekstre.md`).
  static const String ekstreTutarsiz =
      'Döküm toplamları tutmuyor. Bakiyeyi yeniden hesaplayıp tekrar deneyin.';

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

  /// `SAYFA 1 / 2` — ilk parça kalın basılır, ikincisi soluk.
  static String ekstreSayfa(int sayfa) => 'SAYFA $sayfa';
  static String ekstreSayfaToplami(int toplam) => ' / $toplam';

  // ─── İşlem doğrulama ─────────────────────────────────────────────────────
  static const String kalemGerekli = 'En az bir satır ekle.';
  static const String kalemAdiGerekli = 'Ne olduğunu yaz.';
  static const String miktarGerekli = 'Miktar gerekli.';
  static const String miktarGecersiz = 'Miktar sıfırdan büyük olmalı.';
  static const String tutarGerekli = 'Tutar gerekli.';
  static const String tutarGecersiz = 'Geçerli bir tutar yazın: 31.000,00';
  static const String tutarSifirOlamaz = 'Tutar sıfırdan büyük olmalı.';
}
