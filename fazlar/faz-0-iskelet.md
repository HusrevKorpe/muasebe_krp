# Faz 0 — İskelet

**Durum:** Başlanmadı
**Ön koşul:** Yok — ilk faz
**Amaç:** Sonraki fazların üzerine kurulacağı temeli atmak. Bu fazın sonunda görünür
bir özellik yok, ama tüm kuralları zorlayan altyapı hazır.

---

## Kapsam

### Bu fazda var
- Sürüm kontrolü ve klasör yapısı
- Riverpod kurulumu, tema, router
- Kimlik doğrulama (Auth) ve veri izolasyonu
- Firestore güvenlik kuralları + emulator
- Çekirdek yardımcılar: para, tarih, Türkçe arama, logger

### Bu fazda yok
- Cari, işlem, fidan — hiçbir iş özelliği
- Gerçek ekran tasarımı (sadece iskelet ekranlar)

---

## Karar: Auth — **e-posta + şifre** ✅

Firestore'da her kurulumun kendi verisini görmesi gerekiyor. Karar verildi:
**e-posta + şifre** ile giriş.

Gerekçe: Bu bir muhasebe uygulaması, veri kaybı kabul edilemez. Anonim girişte
kullanıcı kimliği cihaza bağlıdır — telefon kaybolursa yılların cari geçmişi
kurtarılamaz. E-posta + şifre ile kullanıcı yeni cihazdan girip verisine ulaşır.

> Apple notu: Google/Facebook gibi üçüncü taraf girişi eklenirse App Store
> "Sign in with Apple" seçeneğini de zorunlu tutar. Sadece e-posta + şifre
> kullandığımız için bu zorunluluk doğmuyor.

**Manuel adım:** Firebase Console → Authentication → Sign-in method →
Email/Password sağlayıcısı etkinleştirilmeli. Bu CLI ile yapılamıyor.

### Revize (13 Ağustos 2026): giriş ekranı kaldırıldı

Uygulama tek bir kişiye TestFlight üzerinden verilecek; çok kullanıcılı bir
ürün değil. Bu yüzden **giriş, kayıt, şifre sıfırlama ve hesap ekranları
kaldırıldı.** Kimlik altyapısı yerinde duruyor, yalnızca kullanıcıya
görünmüyor:

- Açılışta derlemeye gömülü tek hesapla sessizce oturum açılır
  (`lib/data/kimlik/sabit_hesap.dart`, `KimlikRepository.oturumAc`).
- Kimlik bilgisi kaynak koda yazılmaz, `--dart-define-from-file=gizli.json`
  ile derleme anında verilir. `gizli.json` depoya girmez.
- Veri hâlâ `isletmeler/{uid}` altında; uid sabit hesabın uid'sidir. Telefon
  değişse de uygulama silinip kurulsa da aynı veriye dönülür — anonim girişin
  yukarıda reddedilme gerekçesi böylece hâlâ karşılanıyor.
- Firebase oturumu cihazda sakladığı için sunucuya yalnızca ilk açılışta
  gidilir; sonraki açılışlar çevrimdışı da çalışır.

**Yeni manuel adım:** Firebase Console → Authentication → Settings → User
actions → **"Enable create (sign-up)" kapatılmalı.** Şifre IPA'dan
okunabildiği için, o bilgiyle yeni hesap açılmasını sunucu reddetmeli. Hesap
yalnızca konsoldan açılır.

### Revize 2 (13 Ağustos 2026): giriş ekranı geri geldi, defter ortak

Uygulamayı **iki kişi** kullanacak ve ikisi de **aynı** veriyi görecek. Sabit
(derlemeye gömülü) hesap modeli bunu taşımıyordu: kimin ne girdiği belli
olmuyordu ve şifre IPA'nın içinde duruyordu. Yerine:

- **Giriş ekranı geri geldi.** Kullanıcı e-posta ve şifresini yazar
  (`KimlikRepository.girisYap`). `gizli.json` ve `--dart-define-from-file`
  kaldırıldı; derlemede sır kalmadı.
- **Hesabı uygulama açmaz.** Kayıt ekranı, şifre sıfırlama ve hesap silme yok;
  hesaplar Firebase Console → Authentication → Users altında elle açılır.
- **Veri ortak.** `isletmeler/{uid}` yerine sabit `isletmeler/ortak`
  (`Isletme.ortakId`). Kimin girdiğinden bağımsız aynı defter açılır.
- **Kural sadeleşti.** Erişimin tek koşulu açık oturum: `request.auth != null`.
  Hesap açmak konsol işi olduğu için istemci tarafında ayrı bir izin listesine
  gerek kalmadı.
- İşletme profili kapısı da bu revizeyle kalktı: profil boşken de uygulama
  açılır (bkz. `fazlar/faz-1-cari.md`).

> Apple notu hâlâ geçerli: yalnızca e-posta + şifre kullandığımız için
> "Sign in with Apple" zorunluluğu doğmuyor.

**Yeni manuel adımlar:**

1. Authentication → Sign-in method → **Email/Password açık**, diğerleri
   (Google, Anonymous) **kapalı**.
2. Authentication → Settings → User actions → **"Enable create (sign-up)"
   kapalı.** Açık kalırsa uygulamanın API anahtarını eline geçiren biri kendine
   hesap açıp deftere girebilir; kural yalnızca "oturum açık mı" diye soruyor.
3. Authentication → Users → **Add user** ile kullanacak kişilerin hesabı
   açılır; e-posta ve şifre onlara verilir.

---

## Firestore veri modeli (kök)

```
isletmeler/ortak                # sabit kimlik — herkes aynı defteri açar
```

Tüm veri bu belgenin altında yaşar. Güvenlik kuralı tek satırla kurulur:
giriş yapmış her hesap bu defteri okur ve yazar.

---

## Görevler

### Sürüm kontrolü
- [x] `git init`, `.gitignore` gözden geçir
- [x] GitHub remote: `https://github.com/HusrevKorpe/muasebe_krp.git`
- [x] İlk commit ve push

### Klasör yapısı
- [x] `lib/app`, `lib/core`, `lib/data`, `lib/features` oluşturuldu
      (`lib/domain` Faz 1'de model gelince açılacak)
- [x] `lib/main.dart` içindeki geçici Firebase doğrulama ekranı kaldırıldı
- [x] Dart paket adı `muasebe` → `fidancari`, görünen ad `FidanCari`

### Paketler
- [x] `flutter_riverpod` 3.3.2
- [x] `cloud_firestore` 6.8.0
- [x] `firebase_auth` 6.5.7
- [x] `intl` 0.20.2 — `flutter_localizations` bu sürümü sabitliyor, yükseltilemez
- [x] `go_router` 17.5.0
- [x] `flutter_localizations` (TR yerelleştirme)

### Çekirdek yardımcılar (`lib/core/`) — **hepsinin unit testi zorunlu**
- [x] `Kurus` değer tipi: `int` sarmalayıcı, aritmetik işleçler, karşılaştırma
- [x] `kurusBicimle`: `9400000` → `94.000,00 ₺`
- [x] Yuvarlama: `bolVeYuvarla`, `birimFiyatHesapla` (toplamdan geri hesap)
- [x] Türkçe metin: `turkceKucuk`, `turkceBuyuk`, `aramaAnahtari`, `turkceKarsilastir`
- [x] Tarih biçimleme: `17 Eylül 2021`, `17.09.2021`, ekstre başlık/alt bilgisi
- [x] `Log` (`print` yerine), sürüm derlemesinde yalnızca hata geçer
- [x] `UygulamaHatasi` hiyerarşisi — Firebase hata kodları Türkçe mesaja çevriliyor
- [x] `FormDogrulama` — zorunlu alan (e-posta/şifre doğrulaması giriş ekranıyla
      birlikte kaldırıldı)

### Uygulama katmanı
- [x] Material 3 tema, yeşil palet, açık/koyu, TR yerelleştirme
- [x] `go_router`: açılış → kurulum → ana ekran (giriş/kayıt adımı revizeyle
      kaldırıldı)
- [x] Riverpod `ProviderScope` kurulumu
- [x] ~~Giriş, kayıt ve şifre sıfırlama ekranları~~ — revizeyle kaldırıldı,
      yerine açılışta sessiz oturum

### Firebase
- [x] Firestore offline persistence açık (`main.dart`)
- [x] `firestore.rules`: kullanıcı yalnızca `isletmeler/{uid}` altına erişir
- [x] `firestore.indexes.json` oluşturuldu (boş başlıyor)
- [x] `firebase.json`'a firestore ve emulator yapılandırması eklendi
- [ ] **Firebase Console'da Email/Password sağlayıcısını etkinleştir** (manuel adım)
- [ ] **Firebase Console → Authentication → Settings → User actions →
      "Enable create (sign-up)" kapat** (manuel adım, revizeyle geldi)
- [ ] Güvenlik kurallarını ve index'leri yayınla:
      `firebase deploy --only firestore:rules,firestore:indexes`
- [x] Emulator'de güvenlik kuralı testi — `integration_test/guvenlik_kurallari_test.dart`

---

## Kabul kriterleri

1. `flutter analyze` → sıfır uyarı
2. `flutter test` → çekirdek yardımcı testleri geçer
3. `flutter build ios --release` → başarılı
4. Uygulama açılıyor, oturum kendiliğinden açılıyor, boş ana ekran görünüyor
5. Güvenlik kuralları yayında: başka bir `uid` ile veri okumaya çalışmak reddediliyor
6. Uçak modunda uygulama açılıyor ve çökmüyor

---

## Testler

| Ne test edilir | Neden |
|---|---|
| Kuruş toplama/çıkarma | Bakiyenin temeli |
| Yuvarlama ve birim fiyat geri hesabı | Referans ekstredeki `18,79 ₺` vakası (bkz. KURALLAR.md §3.2) |
| Türkçe arama normalizasyonu | `"İstanbul".toLowerCase()` bozuk çalışır |
| Para biçimleme | `9400000` → `94.000,00 ₺` |
| Güvenlik kuralları | Emulator'de: başka uid'nin verisine erişim reddedilmeli |

---

## Riskler

- **Güvenlik kuralları ertelenirse** veritabanı 30 gün boyunca herkese açık kalır.
  Bu fazda mutlaka yazılmalı.
- **Kuruş tipi baştan doğru kurulmazsa** sonraki tüm fazlar `double` sızıntısıyla
  yeniden yazılır. Bu fazın en kritik maddesi.
