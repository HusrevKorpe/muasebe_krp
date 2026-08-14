# Faz 1 — Cari

**Durum:** Sürüyor — kod ve testler tamam, iki kabul kriteri cihazda elle doğrulanmayı bekliyor
**Ön koşul:** Faz 0 kapalı
**Amaç:** Kullanıcının işletme bilgilerini bir kez girmesi, müşteri/tedarikçi listesini
yönetmesi ve bir kişiye dokununca detay sayfasını görmesi. Kullanıcının ilk cümlesi
buydu: *"kişi sayfası olsun, o kişiye bastığında buradaki bilgileri girebilsin."*

---

## Kapsam

### Bu fazda var
- İşletme profili (ekstre başlığındaki firma bilgileri + banka hesapları)
- Cari listesi: arama, sıralama, sayfalama
- Cari ekleme / düzenleme / pasife alma
- Cari detay sayfası — işlem listesi **boş** olarak yerinde durur

### Bu fazda yok
- İşlem girişi (Faz 2)
- Gerçek bakiye hesabı — bakiye alanı `0` gösterir, Faz 2'de dolar
- PDF ekstre (Faz 4)

---

## Firestore veri modeli

### `isletmeler/ortak`

Ekstre başlığını üreten veri. **Zorunlu değil** — hiç doldurulmazsa başlık sade
çıkar (13 Ağustos 2026 revizesi: onboarding kurulum ekranı kaldırıldı). Belge
kimliği sabit; herkes aynı defteri açıyor (bkz. `faz-0` → "Revize 2").

| Alan | Tip | Not |
|---|---|---|
| `ad` | string | "Favori Fidancılık" |
| `unvan` | string | "Tar.Taş.Hay.Ltd.Şti" |
| `adres` | string | Çok satırlı |
| `telefon` | string | |
| `logoUrl` | string? | Faz 4'te ekstreye basılır |
| `bankaHesaplari` | array | `{banka, hesapNo?, iban, paraBirimi}` — referans ekstrede 5 tane |
| `olusturmaTarihi` | timestamp | `serverTimestamp()` |

### `isletmeler/{isletmeId}/cariler/{cariId}`

| Alan | Tip | Not |
|---|---|---|
| `ad` | string | "Ahmet Koyuncu" |
| `unvan` | string? | Firma ünvanı |
| `sehir` | string? | "Isparta" |
| `telefon` | string? | |
| `adres` | string? | |
| `notlar` | string? | |
| `bakiyeKurus` | **int** | Önbellek. Faz 1'de hep `0`. Faz 2'de transaction ile güncellenir |
| `sonIslemTarihi` | timestamp? | Sıralama için |
| `aramaAnahtari` | string | Normalize edilmiş ad — Türkçe arama için |
| `aktif` | bool | Silme yok, pasife alma var |
| `olusturmaTarihi` | timestamp | `serverTimestamp()` |
| `guncellemeTarihi` | timestamp | `serverTimestamp()` |

> `bakiyeKurus` neden şimdiden var: cari listesinde her kişinin bakiyesini göstermek
> için o kişinin tüm işlemlerini çekmek Firestore'da hem yavaş hem pahalıdır
> (bkz. KURALLAR.md §4.3). Alan baştan modelde durur, Faz 2'de dolar.

---

## Görevler

### Domain (`lib/domain/`) — saf Dart
- [x] `Isletme` modeli + `fromMap` / `toMap`
- [x] `Cari` modeli + `fromMap` / `toMap`
- [x] `BankaHesabi` modeli, IBAN biçim doğrulaması (ISO 13616 mod-97)
- [x] Cari doğrulama kuralları (ad zorunlu, telefon hane kontrolü)

### Data (`lib/data/`)
- [x] `IsletmeRepository`: profil oku/yaz
- [x] `CariRepository`: listele (sayfalı), ara, ekle, güncelle, pasife al
- [x] Arama sorgusu `aramaAnahtari` üzerinden — üç bileşik index tanımlandı

### Features
- [x] `features/kurulum/` — ilk açılışta işletme bilgilerini sorar, atlanamaz
- [x] `features/isletme/` — profil düzenleme ekranı, banka hesabı ekle/sil
- [x] `features/cari/view/cari_listesi_ekrani.dart`
- [x] `features/cari/view/cari_form_ekrani.dart` (ekle + düzenle)
- [x] `features/cari/view/cari_detay_ekrani.dart` — üstte özet, altta boş işlem listesi
- [x] `features/cari/viewmodel/` — Riverpod notifier'ları

### Liste ekranı davranışı
- [x] **İki sekme: "Tümü" ve "Açık Hesaplar"** (14 Ağustos 2026 eklemesi,
      kullanıcı isteği: *"hesabı kapanmayanları ayrı bir sekmede görebilelim"*).
      Açık hesap = `bakiyeKurus != 0`; yön ayrımı yok, iki taraf da açık sayılır.
      Sekmenin başında yüklenmiş kayıtların alacak/borç toplamı duruyor.
- [x] Arama kutusu — `aramaAnahtari` üzerinden, 300 ms gecikmeli. **Yalnızca
      "Tümü" sekmesinde:** açık hesap sorgusu bakiyeye aralık süzgeci uyguluyor,
      Firestore aynı sorguda ikinci bir aralık süzgecini sıralayamıyor.
- [x] Sayfalama (sonsuz kaydırma), tek `get()` ile tüm koleksiyon çekilmez
- [x] Sıralama: liste her zaman ada göre. Ekranda seçim menüsü yok; ölçüt
      repository'de duruyor (`CariSiralamasi`), çağrı yeri açıkça isterse verir.
- [x] Boş durum ekranı — arama sonucu boşsa ayrı metin
- [x] Çevrimdışı göstergesi (`hasPendingWrites`) — liste satırı ve detay kartı

---

## Kabul kriterleri

| # | Kriter | Durum |
|---|---|---|
| 1 | `flutter analyze` sıfır uyarı, `flutter test` geçer, `flutter build ios --release` başarılı | ✅ |
| 2 | İlk açılışta işletme bilgileri soruluyor, kaydediliyor, tekrar sorulmuyor | ✅ akış testi |
| 3 | Cari eklenebiliyor, listede görünüyor, düzenlenebiliyor | ✅ akış + emulator testi |
| 4 | "İstanbul" araması `istanbul`, `İSTANBUL`, `ıstanbul` yazımlarıyla da sonuç veriyor | ✅ akış + emulator testi |
| 5 | 100+ cari ile liste akıcı kayıyor, tek seferde hepsi çekilmiyor | ⏳ sayfalama doğrulandı, 100+ kayıtla cihazda bakılmalı |
| 6 | Cariye dokununca detay sayfası açılıyor, üstte ad/şehir/bakiye görünüyor | ✅ akış testi |
| 7 | Uçak modunda cari eklenebiliyor, "kaydedilmedi" göstergesi çıkıyor, internet gelince yazılıyor | ⏳ kod hazır, cihazda elle denenmeli |
| 8 | Pasife alınan cari listede görünmüyor ama veritabanında duruyor | ✅ emulator testi |

### 5 ve 7 neden otomatik doğrulanmadı

- **5** performans kriteri; simülatörde ölçmek gerçek cihazdaki kaydırma akıcılığı
  hakkında bilgi vermez. Sayfalamanın kayıt tekrarlamadığı ve atlamadığı emulator
  testiyle doğrulandı; kalan iş 100+ kayıtla cihazda göz kontrolü.
- **7** uçuş modunu açıp kapatmayı gerektiriyor; simülatörde ağ kesintisi
  taklit edilemiyor. Yazma tarafı buna göre kuruldu: repository `set`/`update`
  future'ını **beklemiyor** (çevrimdışıyken sunucu onayı hiç gelmez ve ekran
  kilitlenirdi), kayıt `hasPendingWrites` ile "Kaydedilmedi" olarak işaretleniyor.

---

## Elle doğrulama

Firebase Console'da Email/Password sağlayıcısı henüz açılmadığı için uygulama
canlı projeye giriş yapamıyor. Emulator'e bağlanarak denenebilir:

```bash
firebase emulators:start --only firestore,auth
flutter run --dart-define=EMULATOR=true
```

---

## Testler

| Ne test edilir | Neden |
|---|---|
| Türkçe arama: `İstanbul` / `istanbul` / `ISTANBUL` | Faz 0'daki normalizasyonun gerçek veriyle doğrulanması |
| `Cari.fromMap` / `toMap` gidiş-dönüş | Alan kaybı veya tip bozulması olmamalı |
| Cari doğrulama (boş ad reddedilmeli) | |
| IBAN biçim doğrulaması | Ekstrede basılacak, yanlış IBAN para kaybettirir |
| `CariRepository` — emulator | Sayfalama, arama, pasife alma |
| Güvenlik kuralı: başka uid'nin carisi okunamaz | Emulator |

### Yazılan testler

| Dosya | Kapsam |
|---|---|
| `test/domain/cari/cari_test.dart` | `fromMap`/`toMap` gidiş-dönüş, arama anahtarı, alan sızıntısı |
| `test/domain/cari/cari_dogrulama_test.dart` | Ad ve telefon doğrulaması |
| `test/domain/isletme/isletme_test.dart` | İşletme + banka hesabı gidiş-dönüş |
| `test/domain/isletme/iban_test.dart` | IBAN mod-97 |
| `test/data/firebase/firestore_donusum_test.dart` | `Timestamp` → `DateTime` sınırı |
| `integration_test/cari_repository_test.dart` | Emulator: sayfalama, arama, sıralama, pasife alma |
| `integration_test/guvenlik_kurallari_test.dart` | Emulator: `firestore.rules` izolasyonu |
| `integration_test/uygulama_akisi_test.dart` | Kurulum → cari ekle → ara → detay tam akışı |

---

## Riskler

- **Firestore'da metin araması zayıftır.** `aramaAnahtari` ile "başlangıcı eşleşen"
  araması yapılabilir, ortadan eşleşme yapılamaz. Cari sayısı birkaç bini geçerse
  ayrı bir arama çözümü gerekir — bu fazda kapsam dışı, not olarak duruyor.
- **Onboarding atlanabilir olmamalı.** İşletme bilgisi eksikse Faz 4'te ekstre başlığı
  boş çıkar. Zorunlu alanlar baştan zorlanmalı.
