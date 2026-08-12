# Faz 4 — PDF Ekstre

**Durum:** Sürüyor — kod tamam, cihazda doğrulama bekliyor
**Ön koşul:** Faz 2 kapalı (Faz 3 şart değil)
**Amaç:** Bir carinin belirli tarih aralığındaki işlem dökümünü PDF olarak üretmek ve
WhatsApp/e-posta ile paylaşmak. Hedef çıktı, kullanıcının verdiği referans ekstrenin
aynısı.

**Referans dosya:** `~/Desktop/Favori_Fidancılık_Ekstresi.pdf`

---

## Kapsam

### Bu fazda var
- Tarih aralığı seçimiyle ekstre üretimi
- Referans PDF'in birebir yapısı: başlık, tablo, kalem detayları, banka bilgileri, toplamlar
- Paylaşma (WhatsApp, e-posta, dosyaya kaydet)

### Bu fazda yok
- Toplu ekstre (tüm carilere birden)
- E-posta ile otomatik gönderim
- Excel çıktısı

---

## Referans PDF'in yapısı

### Sayfa başlığı
- Sol: işletme logosu
- Orta: işletme ünvanı, adres, telefon, faks, vergi dairesi, vergi no
- Sağ: **İLGİLİ FİRMA** — cari adı ve şehri

### Başlık bloğu
- `İŞLEM DÖKÜMÜ`
- Tarih aralığı: `17 Eylül 2021 — 24 Mayıs 2025`

### Tablo — 6 kolon

| İŞLEM TARİHİ | AÇIKLAMA | VADE TARİHİ | BORÇ | ALACAK | BAKİYE ₺ |
|---|---|---|---|---|---|

- Her satırın solunda işlem tipini gösteren küçük bir simge
- Açıklama biçimi: `Satış Faturası — Zeytin-Hurma (TESLİM EDİLDİ)`
- Fatura satırlarının altında **girintili kalem listesi**:
  `zeytin   7.000 Adet × 7,00 ₺`
- Vade tarihi sadece faturalarda dolu
- Bakiye kolonu **kalın**, her satırda yeniden hesaplanır

### Sayfa sonu
- Sol: **Banka Hesap Bilgileri** — banka adı, hesap no, IBAN (referansta 5 hesap)
- Sağ: `TOPLAM ALACAK`, `TOPLAM BORÇ`, `BAKİYE` — çizgilerle ayrılmış
- Alt: `24.05.2025 tarihinde hazırlanmıştır.` · `SAYFA 1 / 2`

---

## Biçim kuralları

| Ne | Biçim |
|---|---|
| Para | `94.000,00 ₺` — binlik nokta, ondalık virgül, kuruş her zaman iki hane |
| Tarih (tablo) | `17 Eylül 2021` |
| Tarih (alt bilgi) | `24.05.2025` |
| Miktar | `7.000 Adet` |
| Birim fiyat | `× 7,00 ₺` |
| Negatif bakiye | `-12.031,25 ₺` — ayırt edilebilir |

---

## Toplamların doğruluğu

> **Dikkat:** Referans PDF'teki toplamlar, listelenen satırlarla tutmuyor.
> Listelenen faturalar `456.031,25 ₺` ederken `TOPLAM BORÇ` alanında `314.000,00 ₺`
> yazıyor. Son işlem (`142.031,25 ₺`) toplamlarda alacak tarafına yazılmış, ama
> tabloda borç kolonunda gösterilmiş.
>
> Bu, referans yazılımın hatası. **Biz bunu kopyalamayacağız.** Bizim çıktımızda
> tablo ile toplamlar her zaman tutarlı olacak ve bunun otomatik testi bulunacak.

Doğru kural: `TOPLAM BORÇ − TOPLAM ALACAK = BAKİYE`, ve bu değer tablodaki son
satırın bakiyesine eşit olmalıdır.

---

## Görevler

### Paketler
- [x] `pdf` — PDF üretimi
- [x] `printing` — önizleme, paylaşma ve yazdırma (`PdfPreview`)
- [x] Türkçe karakter destekli font gömülür (varsayılan fontlar `ğ ş ı İ` basmaz)
      → Roboto, `assets/fonts/` (Apache 2.0, Flutter SDK kopyası). Testi fontun
      karakter tablosunu tarıyor: `₺ ğ ş ı İ ç ö ü —` hepsi doğrulanıyor.

### Domain — **testi zorunlu**
- [x] `EkstreOlusturucu`: cari + tarih aralığı + işlemler → ekstre veri modeli
- [x] Açılış bakiyesi hesabı: aralık başlangıcından önceki işlemlerin toplamı
- [x] Toplam borç / toplam alacak / kapanış bakiyesi
- [x] Tutarlılık kontrolü: `açılış + toplamBorç − toplamAlacak == kapanışBakiyesi`
      **ve** kapanış bakiyesi = son satırın bakiyesi. Tutmazsa PDF üretilmez,
      `DogrulamaHatasi` fırlar (`EkstreBelgesi.uret`).

### Sunum
- [x] `features/ekstre/` — tarih aralığı seçimi, önizleme, paylaş
- [x] PDF şablonu: başlık, tablo, kalem satırları, alt bilgi
- [x] Çok sayfa desteği: tablo başlığı her sayfada tekrarlanır, `SAYFA n / m`
- [x] Uzun açıklama satır kaydırma (referansta `(TESL İM EDİLDİ)` diye bölünmüş — bizde bölünmeyecek)

### Kısayollar
- [x] Cari detay sayfasında "Ekstre Al" butonu
- [x] Hazır aralıklar: bu ay · bu yıl · tümü · özel aralık

---

## Referanstan bilerek ayrıldığımız yerler

| Konu | Referans | Bizde | Neden |
|---|---|---|---|
| Alış faturasının kolonu | Tabloda **BORÇ**, toplamda alacak | **ALACAK** | Referansın hatası; tablo ile toplamlar tutmuyordu |
| `TOPLAM BORÇ` | `314.000,00 ₺` (satırlarla tutmuyor) | Satırlardan hesaplanır | Tutarlılık kontrolü zorunlu |
| Alış faturası etiketi | `Fiş / Fatura` | `Alış Faturası` | Uygulamanın işlem tipi adı |
| İkinci sayfanın üstü | Boş | İşletme + cari şeridi | Dağılan sayfa kime ait, okunabilmeli |
| IBAN | Bitişik | Dörtlü gruplu | Kullanıcı bankaya elle giriyor |
| Sol üst logo | Görsel logo | İşletme adı yazı olarak | Logo yükleme özelliği yok — Faz 5'e kaldı |
| Satır simgesi | Material simgeleri | Vektör çizim (sayfa / madenî para) | Simge fontu PDF'e gömülemiyor |

## Faz sırasında eklenen çekirdek yardımcılar

- `core/tarih/gun_siniri.dart` — `gunBasi` / `gunSonu`. Aralığın bitişi günün
  **sonuna** genişler; yoksa o gün girilen işlem ekstreden düşerdi.
- `core/tarih/tarih_bicimi.dart` → `tabloTarihi` — `05 Aralık 2024`. Tabloda gün
  iki haneli; cümle içinde (`uzunTarih`) tek haneli kalır.
- `core/metin/turkce.dart` → `ilkHarfBuyuk` — kalem birimi `adet` → `Adet`.
- `data/islem/islem_repository.dart` → `ekstreIcinGetir` — **sayfalama yok**
  (KURALLAR.md §4.3'ten bilinçli sapma): açılış bakiyesi aralıktan önceki tüm
  işlemlerin toplamıdır, bir sayfayla hesaplanamaz. 2000 kayıtlık okuma sınırı
  aşılırsa eksik veriyle ekstre üretmek yerine hata verilir.

---

## Kabul kriterleri

1. [x] `flutter analyze` sıfır uyarı, `flutter test` geçer, `flutter build ios --release` başarılı
2. [x] **Referans ekstredeki 9 işlem girilip aynı tarih aralığı seçildiğinde, üretilen
   PDF'in tablo satırları ve bakiye kolonu referansla birebir aynı**
   — `ekstre_olusturucu_test.dart`; tek fark 9. satırın kolonu (yukarıdaki tablo)
3. [x] `TOPLAM BORÇ − TOPLAM ALACAK` değeri son satırın bakiyesine eşit
4. [x] Türkçe karakterler doğru basılıyor: `Şeftali`, `Ayçiçeği`, `İĞDE`
5. [x] Para biçimi `94.000,00 ₺` — nokta/virgül karışmıyor
6. [x] 100+ işlemli cari için çok sayfalı PDF üretiliyor, başlık her sayfada tekrarlanıyor
7. [x] Banka hesapları ve işletme bilgileri başlıkta/altta doğru görünüyor
8. [ ] WhatsApp'ta paylaşılıp telefonda açılabiliyor — **cihazda elle doğrulanacak**
9. [x] Tarih aralığı seçildiğinde açılış bakiyesi doğru hesaplanıyor

---

## Testler

| Ne test edilir | Nerede |
|---|---|
| Referans ekstrenin 9 işlemi → beklenen bakiye kolonu | `test/domain/ekstre/ekstre_olusturucu_test.dart` |
| `açılış + toplamBorç − toplamAlacak == kapanışBakiyesi` | aynı dosya, üç ayrı aralıkla |
| Açılış bakiyesi: aralık ortasından başlayan ekstre | aynı dosya |
| Aralıktan sonraki işlemler bakiyeye girmez | aynı dosya |
| İptalli kayıt tabloda kalır, bakiyeye girmez | aynı dosya |
| Boş aralık / hiç işlemi olmayan cari | aynı dosya + `ekstre_belgesi_test.dart` |
| Gün sınırları, ters aralık, ay sonu taşması | `test/domain/ekstre/ekstre_araligi_test.dart` |
| Gömülü fontta `₺ ğ ş ı İ ç ö ü —` var mı | `test/features/ekstre/ekstre_belgesi_test.dart` |
| PDF'e font gerçekten gömülüyor mu (`/FontFile2`) | aynı dosya |
| 100+ işlemde çok sayfa üretimi | aynı dosya |
| Tutarsız ekstre PDF'e basılmıyor | aynı dosya |
| Açıklama biçimi ve dosya adı | aynı dosya |
| Para biçimleme `9400000` → `94.000,00 ₺`, negatif bakiye | `test/core/para/para_bicimi_test.dart` (Faz 0) |
| `ekstreIcinGetir` sıralama, bitiş sınırı, iptalli kayıt | `integration_test/islem_repository_test.dart` |
| Cari detay → ekstre → önizleme, aralık değiştirme | `integration_test/ekstre_akisi_test.dart` |

> Önizlemenin cihazda rasterlenmesi (`printing` eklentisi) yalnızca
> `ekstre_akisi_test.dart` ile görülebiliyor — PDF üretimi saf Dart, ama
> ekranda göstermek platform kanalından geçiyor.

---

## Riskler

- **Türkçe font.** `pdf` paketinin varsayılan fontları `ğ ş ı İ ç ö ü` karakterlerini
  basmaz. Font gömülmezse ekstrede kutucuk çıkar ve müşteriye gönderilemez.
  Bu fazın en sık atlanan maddesi.
- **Açılış bakiyesi.** Tarih aralığı seçildiğinde aralıktan önceki işlemler toplanıp
  başlangıç bakiyesi olarak gösterilmezse ekstre yanlış olur.
- **Çok sayfa.** Referans PDF 2 sayfa. Sayfa kırılımında kalem listesinin faturasından
  kopmaması gerekir.
