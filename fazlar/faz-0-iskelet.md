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

## Karar bekleyen konu: Auth

Firestore'da her kurulumun kendi verisini görmesi gerekiyor. İki seçenek:

| Seçenek | Artı | Eksi |
|---|---|---|
| **E-posta + şifre** (öneri) | Telefon kaybolursa veri kurtarılır, yeni cihazdan girilir | Bir giriş ekranı gerekir |
| Anonim giriş | Giriş ekranı yok, açınca kullanılır | **Telefon kaybolursa 4 yıllık cari geçmişi gider** |

**Öneri: e-posta + şifre.** Bu bir muhasebe uygulaması; veri kaybı kabul edilemez.
Anonim girişte kullanıcı kimliği cihaza bağlıdır ve kurtarılamaz.

> Apple notu: Google/Facebook gibi üçüncü taraf girişi eklersek App Store
> "Sign in with Apple" seçeneğini de zorunlu tutar. Sadece e-posta + şifre
> kullanırsak bu zorunluluk doğmaz.

Karar verilmeden §Görevler'deki Auth maddeleri başlatılmaz.

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
- [ ] `lib/app`, `lib/core`, `lib/domain`, `lib/data`, `lib/features` oluştur
- [ ] `lib/main.dart` içindeki geçici Firebase doğrulama ekranını kaldır

### Paketler
- [ ] `flutter_riverpod`
- [ ] `cloud_firestore`
- [ ] `firebase_auth`
- [ ] `intl` (TR para/tarih biçimi)
- [ ] `go_router` (yönlendirme)

### Çekirdek yardımcılar (`lib/core/`) — **hepsinin unit testi zorunlu**
- [ ] `Kurus` değer tipi: `int` sarmalayıcı, toplama/çıkarma, `1.234,56 ₺` biçimleme
- [ ] Yuvarlama: en yakın kuruşa yuvarlama, birim fiyat geri hesabı
- [ ] Türkçe arama normalizasyonu (`I/ı/İ/i` sorunu) — ekranlarda `toLowerCase()` yasak
- [ ] Tarih biçimleme: `17 Eylül 2021` ve `17.09.2021`
- [ ] Logger (`print` yerine)

### Uygulama katmanı
- [ ] Material 3 tema, yeşil tonlu palet, TR yerelleştirme (`Locale('tr','TR')`)
- [ ] `go_router` iskeleti: giriş → ana ekran
- [ ] Riverpod `ProviderScope` kurulumu

### Firebase
- [ ] Firestore offline persistence açık
- [ ] `firestore.rules`: kullanıcı yalnızca `isletmeler/{uid}` altına erişir
- [ ] `firestore.indexes.json` dosyasını oluştur (boş başlar)
- [ ] Firestore emulator kurulumu, testlerin emulator'e bağlanması

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
