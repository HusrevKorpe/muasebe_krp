# Faz 2 — İşlemler

**Durum:** Sürüyor — kod, birim ve emulator testleri tamam; iki kabul kriteri
(referans ekstrenin cihazda elle girilmesi, uçak modu) cihazda doğrulanmayı bekliyor
**Ön koşul:** Faz 1 kapalı
**Amaç:** Uygulamanın kalbi. Cariye fatura ve tahsilat girmek, kalemleri kaydetmek
ve **yürüyen bakiyeyi** doğru hesaplamak.

> Bu faz, referans ekstredeki tabloyu veri olarak üretir. Faz 4 sadece onu PDF'e basar.

---

## Kapsam

### Bu fazda var
- Dört işlem tipi: satış faturası, alış faturası, tahsilat, ödeme
- Fatura kalemleri (serbest metin ile — katalog Faz 3'te gelir)
- Vade tarihi ve teslim durumu
- Yürüyen bakiye + cari bakiyesinin transaction ile güncellenmesi
- İşlem iptali (silme yok)
- Bakiyeyi işlemlerden yeniden hesaplama

### Bu fazda yok
- Fidan katalogundan kalem seçimi (Faz 3)
- PDF çıktısı (Faz 4)
- Stok düşümü — kapsam dışı, MVP'de yok
- Vergi hesabı — kapsam dışı. Fatura toplamı kalem tutarlarının toplamıdır;
  vergi satırı gerekirse serbest metin kalemi olarak girilir (KURALLAR.md §3.3)

---

## Firestore veri modeli

### `isletmeler/{isletmeId}/cariler/{cariId}/islemler/{islemId}`

| Alan | Tip | Not |
|---|---|---|
| `tip` | string | `satisFaturasi` · `alisFaturasi` · `tahsilat` · `odeme` |
| `baslik` | string | "Zeytin-Hurma" — ekstrede açıklama olarak görünür |
| `islemTarihi` | timestamp | Kullanıcının seçtiği tarih |
| `vadeTarihi` | timestamp? | Sadece faturalarda |
| `durum` | string | `beklemede` · `teslimEdildi` · `iptal` |
| `kalemler` | array | Aşağıda |
| `toplamKurus` | **int** | Kalemler toplamı. **Saklanan tutar esastır**, yeniden hesaplanmaz |
| `iptal` | bool | |
| `iptalNedeni` | string? | |
| `olusturmaTarihi` | timestamp | `serverTimestamp()` — kayıt izi, **sıralamada kullanılmaz** |
| `guncellemeTarihi` | timestamp? | Yalnızca sonradan düzenlenmiş kayıtta var; `serverTimestamp()` |

> **Sıralama neden `olusturmaTarihi` değil:** `serverTimestamp()` sunucu onaylayana
> kadar `null` okunur. Çevrimdışı girilen bir fatura, sıralama ona bakarsa listede
> yerini bulamaz (KURALLAR.md §4.4). Sıralama `(islemTarihi, belge kimliği)`
> ölçütüne dayanır; belge kimlikleri `data/islem/islem_kimligi.dart` içinde zaman
> sıralı üretilir, böylece **aynı güne düşen** işlemler giriş sırasını korur.
> Referans ekstrede bu şart görünüyor: 17 Eylül 2021'de önce fatura, sonra
> tahsilat işlenmiş; ters dizilirse ara bakiye tutmaz.

### Kalem yapısı (`kalemler` dizisi içinde)

| Alan | Tip | Not |
|---|---|---|
| `ad` | string | "zeytin", "nakliye" |
| `fidanId` | string? | Faz 3'te katalogdan seçilirse dolar |
| `miktar` | int | "7.000 Adet" |
| `birim` | string | `adet` (varsayılan) |
| `birimFiyatKurus` | **int** | |
| `tutarKurus` | **int** | |

> Kalemler ayrı alt koleksiyon değil, belge içinde dizi. Bir faturada onlarca kalem
> olur, binlerce olmaz — tek belge okumasıyla gelmesi hem hızlı hem ucuz.

---

## Bakiye kuralları

### İşaret yönü

| İşlem | Etki |
|---|---|
| Satış faturası | **Borç** — cari bize borçlanır |
| Tahsilat | **Alacak** — cari borcunu öder |
| Alış faturası | **Alacak** — biz cariye borçlanırız |
| Ödeme | **Borç** — biz cariye öderiz |

`bakiye = toplamBorç − toplamAlacak`. Pozitif bakiye cari bize borçlu demektir.
Negatif bakiye ekranda ayırt edilir.

> Referans ekstrede bu durum görünüyor: son satır bir alış faturası ve bakiye
> `-12.031,25 ₺`'ye düşüyor. **Bir cari hem müşteri hem tedarikçi olabilir.**

### Önbelleklenmiş bakiye

`cariler/{cariId}.bakiyeKurus` alanı, işlem kaydıyla **aynı atomik yazmada**
güncellenir: `WriteBatch` içinde `FieldValue.increment` ile.

> **Plandan sapma — `runTransaction` kullanılmadı.** Bu faz dosyası başlangıçta
> bakiyenin Firestore transaction içinde güncellenmesini yazıyordu. Transaction
> sunucu bağlantısı ister, çevrimdışı kuyruğa alınmaz ve hata verir; bu hâliyle
> **kabul kriteri 7'yi (uçak modunda fatura girme) doğrudan çiğnerdi.** Batch
> normal yazma gibi kuyruğa alınır, `increment` de sunucuda atomik uygulanır —
> iki cihazın artışı üst üste biner (kabul kriteri 8). Yani her iki kriter de
> ancak bu yolla sağlanıyor. KURALLAR.md §4.2 buna göre güncellendi.

`sonIslemTarihi` alanı bunun istisnası: yalnızca cari listesini sıralamak için
kullanıldığından atomik değil, önbellekten okunup karşılaştırılarak yazılır —
geriye tarihli bir işlem girildiğinde alan geri kaymasın diye.

Ayrıca **"bakiyeyi işlemlerden yeniden hesapla"** fonksiyonu bulunur. Bu, hem
tutarsızlık onarımı hem de testin doğruluk ölçütüdür. Ekranda cari detayının
üst menüsünden çağrılır.

### İptal

Kayıt silinmez. `iptal = true` işaretlenir, bakiyeye katkısı geri alınır, işlem
listesinde üstü çizili görünür. Sebep: silinen bir tahsilat, sonrasındaki **tüm**
yürüyen bakiyeleri kaydırır ve geri dönüşü olmaz.

### Düzenleme

Kayıtlı bir işlemin fiyatı, adedi, tarihi ve açıklaması **yerinde değiştirilebilir**
(`IslemRepository.guncelle`). Aynı belge güncellenir: kimlik, oluşturma tarihi ve
iptal alanları yerinde kalır, bakiyeye `yeni − eski` farkı `increment` ile yazılır.
Değişiklik `guncellemeTarihi` ile sunucu saatinde işaretlenir ve işlem detayında
"Son düzenleme" satırı olarak görünür.

İptalli kayıt düzenlenmez; tip de değiştirilmez — satışı alışa çevirmek yeni bir
kayıt girmekle aynı şeydir.

**Bu, ilk kararın tersi.** Başta güncelleme yolu bilerek yazılmamıştı: yanlış giriş
iptal edilip yeniden girilecekti. Kullanım bunu taşımadı — fidancılıkta fiyat satış
sonrası pazarlıkla değişiyor ve kullanıcı geçmiş satışın rakamını düzeltmek
istiyor. Her düzeltme için iptal + yeniden giriş, ekstreyi ölü satırlarla
dolduruyordu. Kararın gerekçesi olan risk (bakiyenin sessizce kayması) iki şeyle
karşılanıyor: bakiye farkı işlem yazmasıyla **aynı batch** içinde işleniyor ve
düzenleme kayıtta iz bırakıyor. Silme hâlâ yok (KURALLAR.md §4.2).

---

## Görevler

### Domain (`lib/domain/`) — saf Dart, **testi zorunlu**
- [x] `Islem`, `IslemKalemi` modelleri
- [x] `IslemTipi` enum + borç/alacak yönü eşlemesi
- [x] Kalem hesabı: miktar × birim fiyat → tutar (`IslemKalemi.birimFiyattan`)
- [x] `FaturaHesaplayici`: kalem tutarları → genel toplam
- [x] `BakiyeHesaplayici`: işlem listesi → yürüyen bakiye dizisi + toplamlar
- [x] Birim fiyat geri hesabı: toplam ÷ miktar, en yakın kuruşa yuvarlama
      (`IslemKalemi.toplamdan`)

`KalemHesaplayici` ayrı bir sınıf olarak yazılmadı: yapacağı iki hesap
(`kalemTutari`, `birimFiyatHesapla`) Faz 0'da `core/para/yuvarlama.dart` içinde
zaten vardı. `IslemKalemi`'nin iki fabrikası bunları çağırıyor — araya yalnızca
onları yeniden yayınlayan bir sınıf koymak katman eklerdi, kural değil.

### Data (`lib/data/`)
- [x] `IslemRepository`: listele (tarih aralığı + sayfalı), ekle, güncelle, iptal et
- [x] Ekleme/güncelleme/iptal işlemleri tek atomik yazmada, cari bakiyesiyle
      birlikte (batch + `increment` — yukarıdaki sapma notuna bakın)
- [x] `bakiyeYenidenHesapla(cariId)` fonksiyonu
- [x] Gerekli composite index'ler `firestore.indexes.json`'a eklendi

İşlem **güncelleme** yolu sonradan eklendi; gerekçesi yukarıdaki "Düzenleme"
başlığında. Silme yolu hâlâ yok.

### Features
- [x] `cari_detay_ekrani` işlem listesiyle doldurulur — her satırda yürüyen bakiye
- [x] `features/islem/view/fatura_form_ekrani.dart` — kalem ekle/çıkar, vade
- [x] `features/islem/view/tahsilat_form_ekrani.dart` — tutar, tarih, açıklama
- [x] `features/islem/view/islem_detay_ekrani.dart` — kalemler, düzenle ve iptal
      düğmeleri, düzenlenmiş kayıtta "Son düzenleme" satırı
- [x] `features/islem/view/islem_duzenle_ekrani.dart` — kaydı kimliğinden okur,
      tipine göre fatura ya da tahsilat formunu `mevcut` ile açar
- [x] Kalem girişinde **iki mod**: birim fiyat gir · toplam gir (birim fiyat hesaplansın)

### Kalem giriş modu — neden zorunlu

Referans ekstrede Hurma kalemi `1.650 Adet × 18,79 ₺` yazıyor, ama `1.650 × 18,79 = 31.003,50`.
Gerçek toplam `31.000 ₺` ve birim fiyat oradan geri hesaplanmış (`18,787878...`).
Kullanıcı yuvarlak toplam üzerinden çalışıyor. Sadece "birim fiyat gir" dersek
kullanıcıyı kendi çalışma şeklinden koparırız ve faturası tutmaz.

---

## Kabul kriterleri

| # | Kriter | Durum |
|---|---|---|
| 1 | `flutter analyze` sıfır uyarı, `flutter test` geçer, `flutter build ios --release` başarılı | ✅ |
| 2 | **Referans ekstredeki 9 işlem elle girildiğinde, ekrandaki yürüyen bakiye PDF'teki bakiye kolonuyla kuruşu kuruşuna aynı çıkıyor** | ⏳ birim testi geçiyor, cihazda elle girilmeli |
| 3 | Üçüncü faturanın toplamı `142.031,25 ₺` çıkıyor — ekstredeki %1 vergi satırı serbest metin kalemi olarak girilir | ✅ birim testi |
| 4 | Hurma kalemi "toplam 31.000 ₺" olarak girildiğinde birim fiyat `18,79 ₺` gösteriliyor ve fatura toplamı `94.000,00 ₺` çıkıyor — `94.003,50` değil | ✅ birim testi |
| 5 | İşlem iptal edilince bakiye geri alınıyor, kayıt listede üstü çizili duruyor | ✅ bakiye ve kayıt emulator testinde; üstü çizili gösterim cihazda göz kontrolü bekliyor |
| 6 | `bakiyeYenidenHesapla` çağrıldığında sonuç önbelleklenmiş bakiyeyle aynı | ✅ emulator testi |
| 7 | Uçak modunda fatura girilebiliyor, internet gelince sunucuya yazılıyor | ⏳ kod hazır (batch + `increment`), cihazda elle denenmeli |
| 8 | Aynı cariye iki cihazdan/hızlı ardışık iki işlem girildiğinde bakiye bozulmuyor | ✅ emulator testi — beş eşzamanlı yazma |

### 2 ve 7 neden otomatik doğrulanmadı

- **2** fazın ana ölçütü ve domain testinde geçiyor
  (`referans_ekstre_test.dart`, dokuz satırın tamamı kuruşu kuruşuna). Kalan iş,
  aynı dokuz işlemi cihazda **elle girip** ekrandaki kolonu PDF ile karşılaştırmak;
  bu, formların girilen değerleri domain'e doğru taşıdığını da doğrular.
- **7** uçuş modunu açıp kapatmayı gerektiriyor, simülatörde ağ kesintisi taklit
  edilemiyor. Yazma tarafı buna göre kuruldu: batch commit future'ı beklenmiyor
  ve `increment` çevrimdışı kuyruğa alınıyor.

**Emulator testlerini koşmak için** `firebase-tools` JDK 21 istiyor; Homebrew'un
kurduğu sürüm `java_home` listesine girmediği için `PATH`'e elle eklenmeli:

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"
firebase emulators:start --only firestore,auth
flutter test integration_test -d <simulator-id>
```

---

## Testler

| Ne test edilir | Nerede | Durum |
|---|---|---|
| Referans ekstrenin 9 işlemi → beklenen bakiye dizisi | `test/domain/islem/referans_ekstre_test.dart` | ✅ |
| Fatura toplamı = kalem tutarlarının toplamı, üzerine ek binmez | `test/domain/islem/fatura_hesaplayici_test.dart` | ✅ |
| Birim fiyat geri hesabı: `31.000 ÷ 1.650` → `18,79` gösterilir, toplam `31.000` kalır | `test/domain/islem/islem_kalemi_test.dart` | ✅ |
| Alış faturası bakiyeyi negatife düşürür | `test/domain/islem/bakiye_hesaplayici_test.dart` | ✅ |
| İptal edilen işlem bakiyeye katılmaz | `test/domain/islem/bakiye_hesaplayici_test.dart` | ✅ |
| Tutar metni ayrıştırma (`31.000,50` → kuruş), `double`'a düşmeden | `test/core/para/para_girisi_test.dart` | ✅ |
| Kimlik sıralaması aynı günün işlemlerini giriş sırasında tutar | `test/data/islem/islem_kimligi_test.dart` | ✅ |
| `bakiyeYenidenHesapla` == önbelleklenmiş bakiye | `integration_test/islem_repository_test.dart` | ✅ |
| Eşzamanlı beş işlem — bakiye bozulmuyor | `integration_test/islem_repository_test.dart` | ✅ |
| İptal: kayıt duruyor, bakiye geri alınıyor, ikinci iptal iki kez düşmüyor | `integration_test/islem_repository_test.dart` | ✅ |
| Düzenleme: aynı belge güncelleniyor, bakiyeye yalnızca fark işleniyor, iptalli kayıt düzenlenmiyor | `integration_test/islem_repository_test.dart` | ✅ |
| Düzenlemeden sonra yeniden hesaplanan bakiye önbelleklenmişle aynı | `integration_test/islem_repository_test.dart` | ✅ |
| Sayfalama ve tarih aralığı süzgeci | `integration_test/islem_repository_test.dart` | ✅ |

---

## Riskler

- **En yüksek riskli faz burası.** Bakiye yanlış hesaplanırsa uygulamanın tek işi
  başarısız olur. Domain testleri yazılmadan UI'a geçilmez.
- **`double` sızıntısı.** Kalem hesabı, toplama ve yuvarlama `double`'a düşerse hata
  kuruşlarda başlar, ekstrede lirada görünür. Kod incelemesinde özellikle bakılacak.
  Kullanıcının yazdığı tutar metni de bu yüzden `double.parse` ile değil,
  `core/para/para_girisi.dart` içinde tam sayı aritmetiğiyle ayrıştırılıyor.
- **Atomik yazma unutulursa** bakiye sessizce bozulur ve fark edilmesi aylar sürer.
  Bakiyeye dokunan her yol `WriteBatch` + `increment` kullanmalı; tek istisna
  `bakiyeYenidenHesapla` onarımıdır.
- **Ekrandaki yürüyen bakiye önbelleğe dayanıyor.** Liste, carinin
  `bakiyeKurus` alanından geriye sayarak kolonu üretir; alan bozuksa satırların
  hepsi birden kayar. Kullanıcının elindeki tek onarım, cari detayındaki
  "Bakiyeyi yeniden hesapla" menüsüdür.
