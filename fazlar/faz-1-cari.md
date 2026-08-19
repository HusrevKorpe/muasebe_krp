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
| `grup` | string | `"musteri"` \| `"fidanci"` — kişinin hangi sekmede listeleneceği |
| `bakiyeKurus` | **int** | Önbellek. Faz 1'de hep `0`. Faz 2'de transaction ile güncellenir |
| `sonIslemTarihi` | timestamp? | Sıralama için |
| `aramaAnahtari` | string | Normalize edilmiş ad — Türkçe arama için |
| `aktif` | bool | Silme yok, pasife alma var |
| `olusturmaTarihi` | timestamp | `serverTimestamp()` |
| `guncellemeTarihi` | timestamp | `serverTimestamp()` |

> `grup` alanı **eski belgelerde yok** ve göç scripti de yazılmadı. Okurken
> eksik alan `musteri` sayılıyor (`CariGrubu.anahtardan`), ama Firestore'un
> eşitlik süzgeci alanı olmayan belgeyi eşleştirmediği için `grup == 'musteri'`
> sorgusu **yazılamaz**: o sorgu bu özellikten önce kaydedilmiş herkesi listeden
> düşürürdü. Bu yüzden sunucuda yalnızca fidancı listesi süzülüyor, müşteri
> listesi elde ayıklanıyor (`CariSuzgeci.kayitGirerMi`).

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
- [x] **Üç sekme: "Müşteriler", "Fidancılar" ve "Açık Hesaplar".**
      Açık hesap sekmesi 14 Ağustos 2026'da eklendi (kullanıcı isteği:
      *"hesabı kapanmayanları ayrı bir sekmede görebilelim"*); açık hesap =
      `bakiyeKurus != 0`, yön ayrımı yok, iki taraf da açık sayılır ve sekmenin
      başında yüklenmiş kayıtların alacak/borç toplamı duruyor.
      Müşteri/fidancı ayrımı 19 Ağustos 2026'da eklendi (kullanıcı isteği:
      *"fidancılarla sürekli alışveriş oluyor, birbirimizden alıp veriyoruz;
      fidancıları başka bir sekmede yapalım"*). Ayrım yalnızca listede: iki
      grubun muhasebesi birebir aynı. Grup kişi formunun en üstündeki
      anahtardan seçiliyor, mevcut kayıtların hepsi müşteri sayılıyor.
      Açık hesap sekmesi iki gruptan da besleniyor; orada fidancı satırları
      küçük bir rozetle ayrışıyor.
- [x] Arama kutusu — `aramaAnahtari` üzerinden, 300 ms gecikmeli. **Müşteri ve
      fidancı sekmelerinde var, açık hesapta yok:** açık hesap sorgusu bakiyeye
      aralık süzgeci uyguluyor, Firestore aynı sorguda ikinci bir aralık
      süzgecini sıralayamıyor.
- [x] Müşteri sekmesinde sunucudan gelen sayfa elde ayıklandığı için ekranı
      doldurmayabiliyor; liste kaydırılamaz kalırsa sonraki sayfa
      kendiliğinden isteniyor (`CariListeGorunumu._ekraniDoldur`).
- [x] Sayfalama (sonsuz kaydırma), tek `get()` ile tüm koleksiyon çekilmez
- [x] Sıralama: liste her zaman ada göre. Ekranda seçim menüsü yok; ölçüt
      repository'de duruyor (`CariSiralamasi`), çağrı yeri açıkça isterse verir.
- [x] **Kaldırılan kişiler ayrı bir sayfada: Ayarlar → Kaldırılan Kişiler.**
      19 Ağustos 2026'da eklendi (kullanıcı sorusu: *"pasife aldığımız
      müşteriler gözükmüyor"*). Üç sekmenin de sorgusu `aktif == true` ile
      başladığı için pasife alınan kişi hiçbir listede görünmüyordu ve geri
      alma yolu yoktu — kayıt Firestore'da duruyor ama kullanıcı için
      kaybolmuş oluyordu. Sayfa aynı liste görünümünü kullanıyor
      (`CariSuzgeci.pasifler`), tek farkı sorgunun `aktif == false` olması ve
      satır sonundaki geri alma düğmesi. Yeni index gerekmedi: alan iki hâlde
      de eşitlikle süzülüyor.
- [x] **Satırlar numaralı, listenin başında kişi sayısı var.**
      19 Ağustos 2026'da eklendi (kullanıcı isteği: *"14 açık hesap diyor ya,
      eklediğimiz kişi sayısını göstersin... kaç farklı kişi olduğunu bilelim,
      1-2-3 diye sıralasın herkesi"*). Numara satırın listedeki yeri, kişinin
      kimliği değil: arama yapınca ya da sekme değişince yeniden 1'den başlıyor.
      Sayı arama kutusunun altında duruyor; liste sonuna kadar yüklüyse eldeki
      satırlardan, kesikse sunucudaki toplama sorgusundan geliyor
      (`CariRepository.sayiyiOku`). Müşteri sayısı iki sorgunun farkı —
      `grup == 'musteri'` sorgusu yazılamıyor, gerekçesi yukarıdaki grup
      maddesinde. Toplama sorgusunun önbellek kaynağı yok: çevrimdışıyken sayı
      yüklenen kayıtlardan veriliyor ve "25+ kişi" diye görünüyor.
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
| 9 | Kaldırılan kişi Ayarlar → Kaldırılan Kişiler'de görünüyor ve geri alınabiliyor | ✅ emulator testi |

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
| `test/domain/cari/cari_test.dart` | `fromMap`/`toMap` gidiş-dönüş, arama anahtarı, alan sızıntısı, grup |
| `test/domain/cari/cari_grubu_test.dart` | Grup anahtarları; alanı olmayan belge müşteri sayılır |
| `test/domain/cari/cari_suzgeci_test.dart` | Hangi süzgeç sunucuda, hangisi elde uygulanıyor |
| `test/domain/cari/cari_dogrulama_test.dart` | Ad ve telefon doğrulaması |
| `test/domain/isletme/isletme_test.dart` | İşletme + banka hesabı gidiş-dönüş |
| `test/domain/isletme/iban_test.dart` | IBAN mod-97 |
| `test/data/firebase/firestore_donusum_test.dart` | `Timestamp` → `DateTime` sınırı |
| `test/features/cari/cari_satiri_test.dart` | Satırdaki sıra numarası, üç hanede ad hizası bozulmuyor |
| `test/features/cari/kisi_sayisi_satiri_test.dart` | "128 kişi" / eksik sayıda "25+ kişi" |
| `integration_test/cari_repository_test.dart` | Emulator: sayfalama, arama, sıralama, pasife alma, geri alma, grup süzgeci, kişi sayısı |
| `integration_test/guvenlik_kurallari_test.dart` | Emulator: `firestore.rules` izolasyonu |
| `integration_test/uygulama_akisi_test.dart` | Kurulum → cari ekle → ara → detay tam akışı |

---

## Riskler

- **Firestore'da metin araması zayıftır.** `aramaAnahtari` ile "başlangıcı eşleşen"
  araması yapılabilir, ortadan eşleşme yapılamaz. Cari sayısı birkaç bini geçerse
  ayrı bir arama çözümü gerekir — bu fazda kapsam dışı, not olarak duruyor.
- **Onboarding atlanabilir olmamalı.** İşletme bilgisi eksikse Faz 4'te ekstre başlığı
  boş çıkar. Zorunlu alanlar baştan zorlanmalı.
