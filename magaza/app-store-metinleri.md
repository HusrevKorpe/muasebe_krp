# App Store Connect — Doldurulacak Alanlar

Bu dosya, App Store Connect'teki zorunlu alanların hazır metinlerini tutar.
Panele elle yazmak yerine buradan kopyalanır; böylece metin repoda versiyonlanır
ve sonraki sürümde sıfırdan yazılmaz.

> `[...]` içindeki her şey yayına çıkmadan önce doldurulur.

> **Şu anki durum: TestFlight.** Aşağıdaki alanların çoğu App Store gönderiminde
> isteniyor. **İç** TestFlight testi için yalnızca uygulama kaydı, bundle ID ve
> build yeterli — ekran görüntüsü, açıklama ve örnek veri gerekmiyor.
> **Dış** teste geçilirse Beta App Review devreye girer; o zaman gizlilik
> politikası URL'si, beta açıklaması ve geri bildirim e-postası zorunlu olur.

## TestFlight — dış test açılırsa doldurulacaklar

| Alan | Değer |
|---|---|
| Beta App Description | `FidanCari, fidancılar için cari hesap ve ön muhasebe defteridir. Müşterilerinizi kaydedin, fatura ve tahsilat girin, yürüyen bakiyeyi izleyin, PDF ekstre üretip paylaşın.` |
| Feedback Email | `[İLETİŞİM E-POSTASI]` |
| Beta App Review — giriş bilgisi | **Gerekiyor** — giriş ekranı var. "Sign-in required" evet işaretlenir; konsoldan açılmış bir e-posta/şifre verilir |
| Gizlilik politikası URL'si | `[YAYIN ADRESİ]/gizlilik.html` |

---

---

## Kimlik

| Alan | Değer |
|---|---|
| Uygulama adı | `FidanCari` |
| Alt başlık (30 karakter) | `Cari hesap ve ekstre takibi` |
| Bundle ID | `com.husrevkorpe.fidancari` |
| Birincil kategori | İş (Business) |
| İkincil kategori | Finans (Finance) |
| Birincil dil | Türkçe |
| Yaş sınırı | 4+ (şiddet, kumar, kullanıcı arası içerik yok) |
| Fiyat | [Ücretsiz / ...] |
| Gizlilik politikası URL'si | `[YAYIN ADRESİ]/gizlilik.html` |
| Destek URL'si | `[YAYIN ADRESİ]/` |
| Pazarlama URL'si (opsiyonel) | — |

> Her iki URL de `docs/` klasöründeki sayfalardan gelir. GitHub Pages'i
> `Settings → Pages → Source: main / docs` ile açmak yeterli.

---

## Anahtar kelimeler (100 karakter sınırı)

```
fidan,fidancılık,cari,hesap,muhasebe,ekstre,fatura,tahsilat,bakiye,veresiye,defter,esnaf,tarım
```

Apple kelimeleri kendisi birleştirir; "cari hesap" gibi ikilileri ayrı ayrı
yazmak yer kazandırır. Uygulama adındaki kelimeler (`fidan`) zaten indekslenir
ama arama sıralamasında tekrar etmenin zararı yok.

---

## Tanıtım metni (170 karakter, sürüm çıkmadan değiştirilebilir)

```
Fidan satışında kim ne aldı, ne kadar ödedi, ne kadar borcu kaldı — telefonunuzdan izleyin. Tarih aralığı seçip PDF ekstre gönderin.
```

---

## Açıklama (4000 karakter)

```
FidanCari, fidan üretici ve satıcıları için yapılmış bir ön muhasebe ve cari
hesap defteridir. Kâğıt deftere yazdığınız hesabı telefonunuza taşır: kim ne
aldı, ne kadar ödedi, ne kadar borcu kaldı — hepsi tek ekranda.

CARİ HESAP TAKİBİ
• Müşteri ve tedarikçilerinizi tek listede tutun.
• Bir kişi hem müşteriniz hem tedarikçiniz olabilir; uygulama bunu baştan varsayar.
• Türkçe karakterle doğru çalışan arama: "İzmir" ararken "izmir" de bulunur.
• Her carinin güncel bakiyesi liste ekranında görünür.

FATURA VE TAHSİLAT
• Kalem kalem satış ve alış faturası girin.
• Tahsilat ve ödemelerinizi kaydedin.
• Toplam tutarı yazın, birim fiyat kendiliğinden hesaplansın — ya da tersi.
• Her işlemden sonra yürüyen bakiye güncellenir.

PDF EKSTRE
• Tarih aralığı seçin, hesap dökümünü PDF olarak üretin.
• İşlem tarihi, açıklama, vade, borç, alacak ve bakiye kolonlarıyla klasik
  ekstre düzeni.
• İşletme bilgileriniz ve banka hesaplarınız ekstrenin başlığında ve altında
  yer alır.
• WhatsApp, e-posta ya da istediğiniz uygulamayla paylaşın.

FİDAN KATALOGU
• Fidanlarınızı tür, çeşit, anaç, yaş ve kök tipiyle tanımlayın.
  Örnek: Elma / Scarlet / M9.
• Faturaya tek dokunuşla ekleyin.
• Katalog zorunlu değil: "nakliye" gibi kalemleri serbest metin olarak da
  yazabilirsiniz.

SERADA DA ÇALIŞIR
• İnternet yokken de kayıt girilir; bağlantı gelince kendiliğinden eşitlenir.
• Henüz gönderilmemiş kayıtlar ekranda işaretli görünür.

VERİNİZ SİZİN
• Kayıtlarınız yalnızca sizin hesabınıza bağlıdır.
• Reklam yok, izleyici yok, veri satışı yok.
• Hesabınızı ve tüm verinizi uygulama içinden kalıcı olarak silebilirsiniz.

KURUŞ HASSASİYETİ
Tüm tutarlar kuruş cinsinden tam sayı olarak hesaplanır. Yıllara yayılan bir
ekstrede binlerce toplama yapıldığında bile kuruş kayması olmaz.

FidanCari, e-fatura ya da resmî muhasebe programı değildir; mali müşavirinizin
yerini almaz. İşletmenizin gündelik alacak-verecek takibini kolaylaştırmak için
yapılmıştır.
```

---

## App Privacy beyanı

Uygulama Firebase Authentication ve Cloud Firestore kullanır. Analitik, çökme
takibi ve reklam SDK'sı **yoktur** — derlenen ikilide `GoogleAppMeasurement`
sembolü bulunmuyor, yalnızca `FirebaseCore`, `FirebaseAuth` ve
`FirebaseFirestore` bağlanıyor.

> Giriş e-posta ve şifreyle yapılıyor (bkz.
> `lib/data/kimlik/kimlik_repository.dart`), yani **e-posta adresi toplanıyor**
> ve kimliğe bağlı. Şifre saklanmıyor; doğrulamayı Firebase Authentication
> yapıyor. E-posta yalnızca oturumu sürdürmek ve kimin girdiğini göstermek için
> kullanılıyor; pazarlama, analiz ya da izleme amacıyla kullanılmıyor.

**"Does this app collect data?" → Yes**

| Veri türü | Toplanıyor mu | Kimliğe bağlı mı | Amaç | İzleme (tracking) |
|---|---|---|---|---|
| Contact Info → Email Address | Evet | Evet | App Functionality | Hayır |
| Identifiers → User ID | Evet | Evet | App Functionality | Hayır |
| User Content → Other User Content | Evet | Evet | App Functionality | Hayır |

Diğer tüm kategoriler: **Data Not Collected**.

> E-posta ve kullanıcı kimliği giriş sırasında Firebase'den geliyor; ikisi de
> yalnızca oturumu yürütmek için kullanılıyor. Kullanıcı içeriği de
> artık kimliğe bağlı sayılmalı: giriş yapan hesap belli olduğu için kayıtlar
> anonim değil.

**"Do you use data for tracking?" → No.** Uygulama reklam kimliği okumaz,
üçüncü taraflarla veri paylaşmaz; bu yüzden App Tracking Transparency izni de
istenmiyor.

`User Content` açıklaması olarak: cari kayıtları, faturalar, tahsilatlar ve
fidan katalogu — kullanıcının kendi girdiği işletme kayıtları.

---

## İnceleme notu (App Review Information → Notes)

```
TR:
FidanCari, fidan üreticileri ve satıcıları için bir cari hesap / ön muhasebe
uygulamasıdır. Kullanıcı kendi müşterilerini kaydeder, satış-alış faturası ve
tahsilat girer, yürüyen bakiyeyi izler ve tarih aralığına göre PDF ekstre
üretip paylaşır. Uygulama tek işletme içindir ve kendi verisinden başkasını
görmez.

Giriş ekranı yoktur: uygulama açıldığında doğrudan kullanılabilir. Kullanıcıdan
e-posta, şifre ya da başka bir kimlik bilgisi istenmez; bu yüzden uygulama içinde
silinecek bir hesap da bulunmuyor. Veri silme talepleri gizlilik politikasındaki
iletişim adresi üzerinden karşılanıyor.

Denemek için önerilen akış:
1. Uygulamayı açın; örnek cariler hazır gelir.
2. Listeden bir cari seçin; işlem geçmişini ve bakiyesini görün.
3. "Ekstre" düğmesiyle tarih aralığı seçip PDF önizlemesini açın.
4. Yeni fatura / tahsilat ekleyerek bakiyenin güncellendiğini görün.

EN:
FidanCari is a bookkeeping / accounts-receivable app for plant nursery
businesses in Turkey. The owner records customers, enters sales & purchase
invoices and payments, tracks the running balance, and generates a PDF account
statement for a chosen date range. It is a single-user app: each account only
sees its own data. The interface is Turkish only, as the target users are
nursery owners in Turkey.

There is no sign-in screen and no account creation: the app is ready to use as
soon as it launches, and it never asks for an email address, password or any
other credential. Because no account is created, there is no in-app account to
delete; data deletion requests are handled through the contact address in the
privacy policy.

The app opens with sample customers and transactions already in place.
```

---

## Ekran görüntüleri

App Store artık yalnızca **6.9" iPhone** (1320 × 2868 veya 1290 × 2796) setini
zorunlu tutuyor; diğer boyutlar bundan ölçeklenir. iPad'i destekliyorsak
**13" iPad** (2064 × 2752) seti de gerekir.

> Uygulama şu an iPhone ve iPad yönelimlerini birlikte destekliyor
> (`Info.plist` → `UISupportedInterfaceOrientations~ipad`). iPad ekran
> görüntüsü hazırlamak istemiyorsak hedef aygıt ailesini yalnızca iPhone'a
> çekmek gerekir.

Önerilen 5 kare (örnek veriyle, hepsi Türkçe):

1. Cari listesi — bakiyeler görünür durumda
2. Cari detayı — işlem geçmişi ve yürüyen bakiye
3. Fatura girişi — kalemler ve genel toplam
4. PDF ekstre önizlemesi
5. Fidan katalogu

Simülatörde çekim:

```bash
flutter run --release -d <simulator-id>
xcrun simctl io booted screenshot magaza/ekran/01-cari-listesi.png
```

---

## Sürüm bilgisi (What's New)

İlk sürümde bu alan istenmez; 1.0.0 için boş bırakılır.
