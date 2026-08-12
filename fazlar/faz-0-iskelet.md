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

---

## Firestore veri modeli (kök)

```
isletmeler/{isletmeId}          # isletmeId = Firebase Auth uid
```

Tüm veri bu belgenin altında yaşar. Güvenlik kuralı tek satırla kurulur:
kullanıcı yalnızca kendi `uid`'si altındaki belgelere erişebilir.

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
- [x] Yuvarlama: `bolVeYuvarla`, `yuzdesi` (KDV), `birimFiyatHesapla` (geri hesap)
- [x] Türkçe metin: `turkceKucuk`, `turkceBuyuk`, `aramaAnahtari`, `turkceKarsilastir`
- [x] Tarih biçimleme: `17 Eylül 2021`, `17.09.2021`, ekstre başlık/alt bilgisi
- [x] `Log` (`print` yerine), sürüm derlemesinde yalnızca hata geçer
- [x] `UygulamaHatasi` hiyerarşisi — Firebase hata kodları Türkçe mesaja çevriliyor
- [x] `FormDogrulama` — e-posta, şifre, zorunlu alan

### Uygulama katmanı
- [x] Material 3 tema, yeşil palet, açık/koyu, TR yerelleştirme
- [x] `go_router`: açılış → giriş/kayıt → ana ekran, oturuma göre yönlendirme
- [x] Riverpod `ProviderScope` kurulumu
- [x] Giriş, kayıt ve şifre sıfırlama ekranları

### Firebase
- [x] Firestore offline persistence açık (`main.dart`)
- [x] `firestore.rules`: kullanıcı yalnızca `isletmeler/{uid}` altına erişir
- [x] `firestore.indexes.json` oluşturuldu (boş başlıyor)
- [x] `firebase.json`'a firestore ve emulator yapılandırması eklendi
- [ ] **Firebase Console'da Email/Password sağlayıcısını etkinleştir** (manuel adım)
- [ ] Güvenlik kurallarını yayınla: `firebase deploy --only firestore:rules`
- [ ] Emulator'de güvenlik kuralı testi (başka uid'nin verisi okunamamalı)

---

## Kabul kriterleri

1. `flutter analyze` → sıfır uyarı
2. `flutter test` → çekirdek yardımcı testleri geçer
3. `flutter build ios --release` → başarılı
4. Uygulama açılıyor, giriş yapılabiliyor, boş ana ekran görünüyor
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
