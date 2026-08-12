# FidanCari — Gizlilik Politikası

**Son güncelleme:** 12 Ağustos 2026

Bu politika, **FidanCari** iOS uygulamasının hangi verileri işlediğini açıklar.
App Store Connect'te "Privacy Policy URL" alanına, bu metnin yayınlandığı adres
girilir (bkz. `docs/gizlilik.html`).

> **Doldurulacak alanlar:** `[İLETİŞİM E-POSTASI]` ve `[YAYIN ADRESİ]` yayına
> çıkmadan önce gerçek değerleriyle değiştirilmelidir.

---

## 1. Veri sorumlusu

FidanCari, Hüsrev Körpe tarafından geliştirilen bağımsız bir uygulamadır.
Sorularınız için: `[İLETİŞİM E-POSTASI]`

---

## 2. Toplanan veriler

Uygulama yalnızca çalışması için gereken veriyi işler. Reklam ağı, analiz
aracı ve üçüncü taraf izleyici **kullanılmaz**.

### 2.1 Hesap bilgisi

| Veri | Neden | Nerede saklanır |
|---|---|---|
| E-posta adresi | Giriş ve şifre sıfırlama | Firebase Authentication |
| Şifre | Girişin doğrulanması | Firebase Authentication (karma olarak; geliştirici göremez) |

### 2.2 Kullanıcı içeriği

Uygulamaya **kendi girdiğiniz** ön muhasebe kayıtları:

- İşletme bilgileriniz: ad, adres, telefon, vergi dairesi ve numarası,
  banka hesap bilgileri (IBAN)
- Cari (müşteri/tedarikçi) kayıtları: ad, telefon, adres, vergi bilgileri, not
- İşlemler: satış/alış faturaları, tahsilat ve ödemeler, fatura kalemleri
- Fidan katalogu: tür, çeşit, anaç, yaş, kök tipi, fiyat

Bu kayıtlar **yalnızca sizin hesabınıza bağlıdır**. Uygulama, verinizi başka
kullanıcılara göstermez; geliştirici de bu veriyi görüntülemez.

### 2.3 Toplanmayan veriler

- Konum
- Kişi rehberi, fotoğraflar, takvim
- Reklam kimliği (IDFA) — uygulamada reklam yoktur
- Kullanım analitiği, çökme takibi veya davranış izleme

Uygulama Apple'ın tanımladığı anlamda **"tracking" (izleme) yapmaz**; bu yüzden
App Tracking Transparency izni de istemez.

---

## 3. Verinin saklandığı yer

Veriler Google Firebase (Firebase Authentication ve Cloud Firestore) üzerinde
saklanır. Firebase, Google Ireland Limited / Google LLC tarafından işletilir ve
veri Google'ın sunucularında barındırılır. Google bu hizmette "veri işleyen"
sıfatıyla hareket eder.

Firebase güvenlik kuralları, her kullanıcının **yalnızca kendi verisine**
erişmesine izin verecek şekilde yapılandırılmıştır.

Uygulama çevrimdışı çalışabilmek için verinin bir kopyasını cihazınızda tutar.
Uygulamayı sildiğinizde bu yerel kopya da silinir.

---

## 4. Verinin paylaşılması

Veriniz satılmaz, kiralanmaz, pazarlama amacıyla paylaşılmaz.

Tek paylaşım yolu **sizin başlattığınız** paylaşımdır: bir cari için PDF ekstre
ürettiğinizde, bu dosyayı iOS paylaşım penceresi üzerinden seçtiğiniz kişiye ya
da uygulamaya siz gönderirsiniz. Bu dosya bizim sunucularımıza yüklenmez.

Yasal zorunluluk hâlinde (mahkeme kararı vb.) veri, yalnızca yasanın gerektirdiği
ölçüde yetkili makamlarla paylaşılabilir.

---

## 5. Saklama süresi ve hesap silme

Verileriniz, siz silene kadar saklanır.

Uygulama içinden **Menü → Hesap → Hesabı sil** yolunu izleyerek hesabınızı ve ona
bağlı tüm verileri kalıcı olarak silebilirsiniz. Silme işlemi şunları kapsar:

- Tüm cari kayıtları ve bunlara bağlı işlemler
- Fidan katalogu
- İşletme profili
- Firebase Authentication hesabınız

Bu işlem **geri alınamaz** ve yedeği tutulmaz.

---

## 6. Haklarınız

KVKK ve GDPR kapsamında; verilerinize erişme, düzeltme, silme ve taşıma
haklarınız vardır. Veriye erişim ve düzeltme uygulama içinden doğrudan
yapılabilir; silme için yukarıdaki hesap silme yolu kullanılır. Diğer talepleriniz
için `[İLETİŞİM E-POSTASI]` adresine yazabilirsiniz.

---

## 7. Çocukların gizliliği

FidanCari bir işletme uygulamasıdır ve 13 yaş altındaki çocuklara yönelik
değildir. Bilerek çocuklardan veri toplanmaz.

---

## 8. Değişiklikler

Bu politika değişirse, yeni sürüm `[YAYIN ADRESİ]` adresinde yayımlanır ve
yukarıdaki "Son güncelleme" tarihi güncellenir.

---

## 9. İletişim

`[İLETİŞİM E-POSTASI]`
