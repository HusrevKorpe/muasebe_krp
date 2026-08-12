# Faz 1 — Cari

**Durum:** Başlanmadı
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

### `isletmeler/{isletmeId}`

Ekstre başlığını üreten veri. Onboarding'de bir kez sorulur.

| Alan | Tip | Not |
|---|---|---|
| `ad` | string | "Favori Fidancılık" |
| `unvan` | string | "Tar.Taş.Hay.Ltd.Şti" |
| `adres` | string | Çok satırlı |
| `telefon` | string | |
| `faks` | string? | Referans ekstrede var |
| `vergiDairesi` | string | "Yüreğir" |
| `vergiNo` | string | |
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
| `vergiDairesi` | string? | |
| `vergiNo` | string? | |
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
- [ ] `Isletme` modeli + `fromMap` / `toMap`
- [ ] `Cari` modeli + `fromMap` / `toMap`
- [ ] `BankaHesabi` modeli, IBAN biçim doğrulaması
- [ ] Cari doğrulama kuralları (ad zorunlu, vergi no biçimi)

### Data (`lib/data/`)
- [ ] `IsletmeRepository`: profil oku/yaz
- [ ] `CariRepository`: listele (sayfalı), ara, ekle, güncelle, pasife al
- [ ] Arama sorgusu `aramaAnahtari` üzerinden — index tanımı eklenir

### Features
- [ ] `features/onboarding/` — ilk açılışta işletme bilgilerini sor
- [ ] `features/isletme/` — profil düzenleme ekranı, banka hesabı ekle/sil
- [ ] `features/cari/view/cari_listesi_ekrani.dart`
- [ ] `features/cari/view/cari_form_ekrani.dart` (ekle + düzenle)
- [ ] `features/cari/view/cari_detay_ekrani.dart` — üstte özet, altta boş işlem listesi
- [ ] `features/cari/viewmodel/` — Riverpod notifier'ları

### Liste ekranı davranışı
- [ ] Arama kutusu — `aramaAnahtari` üzerinden, Türkçe normalizasyonlu
- [ ] Sayfalama (sonsuz kaydırma), tek `get()` ile tüm koleksiyon çekilmez
- [ ] Sıralama: ada göre / bakiyeye göre / son işleme göre
- [ ] Boş durum ekranı ("Henüz cari yok, ekleyin")
- [ ] Çevrimdışı göstergesi (`hasPendingWrites`)

---

## Kabul kriterleri

1. `flutter analyze` sıfır uyarı, `flutter test` geçer, `flutter build ios --release` başarılı
2. İlk açılışta işletme bilgileri soruluyor, kaydediliyor, tekrar sorulmuyor
3. Cari eklenebiliyor, listede görünüyor, düzenlenebiliyor
4. **"İstanbul" araması `istanbul`, `İSTANBUL`, `ıstanbul` yazımlarıyla da sonuç veriyor**
5. 100+ cari ile liste akıcı kayıyor, tek seferde hepsi çekilmiyor
6. Cariye dokununca detay sayfası açılıyor, üstte ad/şehir/bakiye görünüyor
7. Uçak modunda cari eklenebiliyor, "kaydedilmedi" göstergesi çıkıyor, internet gelince yazılıyor
8. Pasife alınan cari listede görünmüyor ama veritabanında duruyor

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

---

## Riskler

- **Firestore'da metin araması zayıftır.** `aramaAnahtari` ile "başlangıcı eşleşen"
  araması yapılabilir, ortadan eşleşme yapılamaz. Cari sayısı birkaç bini geçerse
  ayrı bir arama çözümü gerekir — bu fazda kapsam dışı, not olarak duruyor.
- **Onboarding atlanabilir olmamalı.** İşletme bilgisi eksikse Faz 4'te ekstre başlığı
  boş çıkar. Zorunlu alanlar baştan zorlanmalı.
