# FidanCari

Fidancılık ön muhasebe ve cari hesap takip uygulaması. İşletme sahibi müşterilerini
(cari) kaydeder, satış/alış faturası ve tahsilat girer, yürüyen bakiyeyi izler ve
tarih aralığına göre PDF ekstre üretip paylaşır.

## ÖNCE BUNU OKU

**[KURALLAR.md](KURALLAR.md) bağlayıcıdır.** Kod yazmadan önce oku. Öne çıkanlar:

- **Para asla `double` değil** — kuruş cinsinden `int`. Firestore'a da `int` yazılır.
- **Dosya başına 500 satır** sınırı, bir dosyada bir public sınıf.
- **Katman akışı:** View → ViewModel → Repository → Firestore.
  `cloud_firestore` importu **sadece** `lib/data/` altında geçebilir.
- `lib/domain/` **saf Dart** — Flutter importu yok.
- ViewModel'de `BuildContext` yok.
- **Muhasebe kaydı silinmez** — iptal işaretlenir veya ters kayıt atılır.
- Kod ASCII (`anac`, `cesit`), kullanıcıya görünen metin tam Türkçe (`Anaç`, `Çeşit`).
- Domain terimleri Türkçe kalır: `Cari`, `Bakiye`, `Tahsilat` — `Contact`, `Balance` değil.
- **Testler ana session'da koşturulmaz** — iş bitince `test-runner` subagent'ı çağrılır,
  sadece özet raporu beklenir. Bkz. [KURALLAR.md §5.0](KURALLAR.md#50-testleri-kim-çalıştırır).

## Fazlar

Sırayla ilerlenir. Bir faz, kendi dosyasındaki kabul kriterleri sağlanmadan kapatılmaz.

| Faz | Konu | Durum |
|---|---|---|
| [0](fazlar/faz-0-iskelet.md) | İskelet: klasör yapısı, tema, Riverpod, Auth, çekirdek yardımcılar | **Sürüyor** |
| [1](fazlar/faz-1-cari.md) | Cari: işletme profili, liste, arama, detay sayfası | **Sürüyor** |
| [2](fazlar/faz-2-islemler.md) | İşlemler: fatura, tahsilat, kalemler, yürüyen bakiye | **Sürüyor** |
| [3](fazlar/faz-3-katalog.md) | Fidan katalogu: Tür/Çeşit/Anaç/Yaş/Kök tipi, fiyat listesi | **Sürüyor** |
| [4](fazlar/faz-4-ekstre.md) | PDF ekstre: şablon, tarih aralığı, paylaşma | **Sürüyor** |
| [5](fazlar/faz-5-magaza.md) | Mağaza: ikon, gizlilik, SPM geçişi, TestFlight, App Store | **Sürüyor** |

Faz kapandığında bu tablodaki durumu ve ilgili faz dosyasının başlığındaki durumu güncelle.

## Komutlar

Not: `flutter analyze` ve `flutter test` **ana session'da çalıştırılmaz** —
`test-runner` subagent'ı çağrılır (KURALLAR.md §5.0). Aşağıdaki liste o ajanın
ve elle koşturmanın referansıdır.

```bash
flutter analyze                        # sıfır uyarı vermeli (test-runner koşturur)
flutter test                           # tüm testler geçmeli (test-runner koşturur)
flutter build ios --release            # faz kapanışında başarılı olmalı
flutter run                            # cihazda çalıştır

flutter build ipa                      # TestFlight'a giden derleme

firebase emulators:start --only firestore,auth   # repository testleri burada koşar
firebase deploy --only firestore:rules,firestore:indexes   # kural ve index yayını

# Emulator'e bağlı testler (emulator ayakta olmalı, cihaz/simülatör gerekir)
flutter test integration_test -d <simulator-id>

# Uygulamayı canlı veriye dokunmadan denemek
flutter run --dart-define=EMULATOR=true

# Uygulama ikonunu ve açılış görselini yeniden üret (PNG'ler elle düzenlenmez)
swift tool/ikon_uret.swift
```

Not: `firebase-tools` Java 21+ istiyor. Homebrew'un kurduğu JDK 21
`/usr/libexec/java_home` listesine girmez (keg-only) ve `JAVA_HOME` vermek de
yetmez — `firebase` komutu `java`'yı `PATH`'ten bulur. Emulator'ü şöyle açın:

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"
firebase emulators:start --only firestore,auth
```

Not: `pod install` çalıştırmak gerekirse `ios/` dizinine geçilir. CocoaPods spec
deposu eskiyse `pod install --repo-update` gerekir.

## Teknik künye

| Alan | Değer |
|---|---|
| Paket adı | `com.husrevkorpe.fidancari` — **asla değiştirilmez** |
| Firebase projesi | `muasebe-takip` (662432068913) |
| Platform | iOS, minimum **15.0** (Firebase SDK şartı) |
| Stack | Flutter 3.41 · Dart 3.11 · Firestore · Riverpod · MVVM |
| Kullanım | **Ortak defter.** E-posta/şifreyle giren hesaplar (2 kişi) aynı veriyi görür |

## Klasör yapısı

```
lib/
├── app/           # Giriş, router, tema
├── core/          # Para, tarih, arama normalizasyonu, logger, hata
├── domain/        # Model + iş kuralları — saf Dart, testi zorunlu
├── data/          # Repository'ler, Firestore erişimi
└── features/
    └── <ozellik>/
        ├── view/
        └── viewmodel/

docs/              # GitHub Pages: destek sayfası ve gizlilik politikası
magaza/            # App Store Connect metinleri, gizlilik politikası kaynağı
tool/              # Varlık üreticileri (uygulama ikonu)
```

## Bilinmesi gerekenler

- **Referans ekstre:** `~/Desktop/Favori_Fidancılık_Ekstresi.pdf` — üreteceğimiz PDF'in
  hedefi bu. Kolonlar: İşlem Tarihi · Açıklama · Vade Tarihi · Borç · Alacak · Bakiye.
- **Vergi hesabı yok.** Fatura toplamı kalem tutarlarının toplamıdır. Referans
  ekstredeki bir faturada %1 vergi görünüyor; öyle bir satır gerekirse "nakliye"
  gibi serbest metin kalemi olarak girilir.
- **Bir cari hem müşteri hem tedarikçi olabilir.** Fidancılıkta alım-satım aynı kişiyle yapılır.
- **Fidan kimliği:** Tür → Çeşit → Anaç (+ Yaş, Kök tipi). Örnek: Elma / Scarlet / M9.
  Görünen ad bu alanlardan üretilir (`Fidan.goruntuAdi`) ve faturaya o metin yazılır.
- **Katalog zorunlu değil.** Fatura kalemi katalogdan seçilebilir, ama serbest
  metin girişi kaldırılmaz — "nakliye" gibi kalemler katalogda yer almaz.
  Katalogdan seçilen kalem `fidanId` taşır; serbest metin kalemde bu alan boştur.
- **Firebase SPM'e taşındı** (Faz 5). `firebase-ios-sdk` artık Swift Package
  Manager üzerinden geliyor; CocoaPods'un Ekim 2026 riski kapandı. Geriye tek
  eklenti kaldı: `printing` henüz `Package.swift` yayınlamıyor, o yüzden
  `Podfile` duruyor. `pod install` hâlâ gerekli.
- **E-posta/şifre ile giriş, ortak defter.** Uygulamayı iki kişi kullanıyor ve
  ikisi de **aynı** veriyi görüyor. Bu yüzden veri `isletmeler/{uid}` altında
  değil, sabit `isletmeler/ortak` altında (`Isletme.ortakId`).
  Giriş ekranı e-posta ve şifre sorar (`KimlikRepository.girisYap`); Firestore
  kuralı yalnızca "oturum açık mı" diye bakar (`request.auth != null`).
  **Uygulama hesap açmaz:** kayıt ekranı, şifre sıfırlama ve hesap silme yok.
  Kişi eklemek/çıkarmak Firebase Console → Authentication → Users işidir; kod
  değişikliği ya da yeni derleme gerekmez.
  **Manuel adımlar:** Authentication → Sign-in method → Email/Password açık,
  diğerleri kapalı; Settings → User actions → "Enable create (sign-up)" **kapalı**
  (açık kalırsa dışarıdan hesap açılıp deftere girilebilir); Users → Add user
  ile kullanacak kişilerin hesapları.
- **İşletme profili zorunlu değil.** Eskiden ilk açılışta doldurulması gereken
  bir kurulum ekranı vardı; kaldırıldı. Profil yalnızca PDF ekstre başlığını
  besliyor, boşsa başlık sade çıkar. Ayarlar → İşletme bilgileri'nden istendiği
  zaman doldurulur.
- **Çevrimdışı yazma:** Repository'ler `set`/`update` future'ını **beklemez**.
  Firestore çevrimdışıyken bu future yalnızca sunucu onayında tamamlanır;
  beklenirse uçak modunda ekran kilitlenir. Yerel yazma anında görünür, kayıt
  `hasPendingWrites` ile "Kaydedilmedi" olarak işaretlenir.
- **Firestore metin araması öntakıyla sınırlı.** `aramaAnahtari` alanı adın
  normalize hâlini tutar; "koyuncu" yazarak "Ahmet Koyuncu" bulunamaz. Cari
  sayısı birkaç bini geçerse ayrı arama çözümü gerekir.
