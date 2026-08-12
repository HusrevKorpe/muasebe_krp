# Faz 4 — PDF Ekstre

**Durum:** Başlanmadı
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
- [ ] `pdf` — PDF üretimi
- [ ] `printing` veya `share_plus` — paylaşma
- [ ] Türkçe karakter destekli font gömülür (varsayılan fontlar `ğ ş ı İ` basmaz)

### Domain — **testi zorunlu**
- [ ] `EkstreOlusturucu`: cari + tarih aralığı + işlemler → ekstre veri modeli
- [ ] Açılış bakiyesi hesabı: aralık başlangıcından önceki işlemlerin toplamı
- [ ] Toplam borç / toplam alacak / kapanış bakiyesi
- [ ] Tutarlılık kontrolü: `toplamBorç − toplamAlacak == kapanışBakiyesi`

### Sunum
- [ ] `features/ekstre/` — tarih aralığı seçimi, önizleme, paylaş
- [ ] PDF şablonu: başlık, tablo, kalem satırları, alt bilgi
- [ ] Çok sayfa desteği: tablo başlığı her sayfada tekrarlanır, `SAYFA n / m`
- [ ] Uzun açıklama satır kaydırma (referansta `(TESL İM EDİLDİ)` diye bölünmüş — bizde bölünmeyecek)

### Kısayollar
- [ ] Cari detay sayfasında "Ekstre Al" butonu
- [ ] Hazır aralıklar: bu ay · bu yıl · tümü · özel aralık

---

## Kabul kriterleri

1. `flutter analyze` sıfır uyarı, `flutter test` geçer, `flutter build ios --release` başarılı
2. **Referans ekstredeki 9 işlem girilip aynı tarih aralığı seçildiğinde, üretilen
   PDF'in tablo satırları ve bakiye kolonu referansla birebir aynı**
3. `TOPLAM BORÇ − TOPLAM ALACAK` değeri son satırın bakiyesine eşit
4. Türkçe karakterler doğru basılıyor: `Şeftali`, `Ayçiçeği`, `İĞDE`
5. Para biçimi `94.000,00 ₺` — nokta/virgül karışmıyor
6. 100+ işlemli cari için çok sayfalı PDF üretiliyor, başlık her sayfada tekrarlanıyor
7. Banka hesapları ve işletme bilgileri başlıkta/altta doğru görünüyor
8. WhatsApp'ta paylaşılıp telefonda açılabiliyor
9. Tarih aralığı seçildiğinde açılış bakiyesi doğru hesaplanıyor

---

## Testler

| Ne test edilir | Neden |
|---|---|
| Referans ekstrenin 9 işlemi → beklenen bakiye kolonu | Fazın ana ölçütü |
| `toplamBorç − toplamAlacak == kapanışBakiyesi` | Referans yazılımın hatasına düşmemek |
| Açılış bakiyesi: aralık ortasından başlayan ekstre | En kolay atlanan hesap |
| Para biçimleme: `9400000` → `94.000,00 ₺` | |
| Negatif bakiye biçimi | |
| Boş aralık: hiç işlem yoksa PDF yine üretilir | Çökmemeli |
| Türkçe karakterli isim PDF'e basılır | Font gömme doğrulaması |

---

## Riskler

- **Türkçe font.** `pdf` paketinin varsayılan fontları `ğ ş ı İ ç ö ü` karakterlerini
  basmaz. Font gömülmezse ekstrede kutucuk çıkar ve müşteriye gönderilemez.
  Bu fazın en sık atlanan maddesi.
- **Açılış bakiyesi.** Tarih aralığı seçildiğinde aralıktan önceki işlemler toplanıp
  başlangıç bakiyesi olarak gösterilmezse ekstre yanlış olur.
- **Çok sayfa.** Referans PDF 2 sayfa. Sayfa kırılımında kalem listesinin faturasından
  kopmaması gerekir.
