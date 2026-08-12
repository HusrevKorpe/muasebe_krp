# Faz 2 — İşlemler

**Durum:** Başlanmadı
**Ön koşul:** Faz 1 kapalı
**Amaç:** Uygulamanın kalbi. Cariye fatura ve tahsilat girmek, kalemleri kaydetmek,
KDV uygulamak ve **yürüyen bakiyeyi** doğru hesaplamak.

> Bu faz, referans ekstredeki tabloyu veri olarak üretir. Faz 4 sadece onu PDF'e basar.

---

## Kapsam

### Bu fazda var
- Dört işlem tipi: satış faturası, alış faturası, tahsilat, ödeme
- Fatura kalemleri (serbest metin ile — katalog Faz 3'te gelir)
- KDV (opsiyonel, varsayılan %1)
- Vade tarihi ve teslim durumu
- Yürüyen bakiye + cari bakiyesinin transaction ile güncellenmesi
- İşlem iptali (silme yok)
- Bakiyeyi işlemlerden yeniden hesaplama

### Bu fazda yok
- Fidan katalogundan kalem seçimi (Faz 3)
- PDF çıktısı (Faz 4)
- Stok düşümü — kapsam dışı, MVP'de yok

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
| `araToplamKurus` | **int** | Kalemler toplamı |
| `kdvOrani` | int | Yüzde olarak. `1` = %1. `0` = KDV yok |
| `kdvKurus` | **int** | |
| `toplamKurus` | **int** | **Saklanan tutar esastır**, yeniden hesaplanmaz |
| `iptal` | bool | |
| `iptalNedeni` | string? | |
| `olusturmaTarihi` | timestamp | `serverTimestamp()` — sıralamada esas |

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

`cariler/{cariId}.bakiyeKurus` alanı **yalnızca Firestore transaction içinde** güncellenir.
İki işlem aynı anda yazılırsa transaction dışı güncelleme bakiyeyi bozar.

Ayrıca **"bakiyeyi işlemlerden yeniden hesapla"** fonksiyonu bulunur. Bu, hem
tutarsızlık onarımı hem de testin doğruluk ölçütüdür.

### İptal

Kayıt silinmez. `iptal = true` işaretlenir, bakiyeye katkısı geri alınır, işlem
listesinde üstü çizili görünür. Sebep: silinen bir tahsilat, sonrasındaki **tüm**
yürüyen bakiyeleri kaydırır ve geri dönüşü olmaz.

---

## Görevler

### Domain (`lib/domain/`) — saf Dart, **testi zorunlu**
- [ ] `Islem`, `IslemKalemi` modelleri
- [ ] `IslemTipi` enum + borç/alacak yönü eşlemesi
- [ ] `KalemHesaplayici`: miktar × birim fiyat → tutar
- [ ] `FaturaHesaplayici`: ara toplam → KDV → genel toplam
- [ ] `BakiyeHesaplayici`: işlem listesi → yürüyen bakiye dizisi + toplamlar
- [ ] Birim fiyat geri hesabı: toplam ÷ miktar, en yakın kuruşa yuvarlama

### Data (`lib/data/`)
- [ ] `IslemRepository`: listele (tarih aralığı + sayfalı), ekle, güncelle, iptal et
- [ ] Ekleme/iptal işlemleri Firestore transaction içinde, cari bakiyesiyle birlikte
- [ ] `bakiyeYenidenHesapla(cariId)` fonksiyonu
- [ ] Gerekli composite index'ler `firestore.indexes.json`'a eklenir

### Features
- [ ] `cari_detay_ekrani` işlem listesiyle doldurulur — her satırda yürüyen bakiye
- [ ] `features/islem/view/fatura_form_ekrani.dart` — kalem ekle/çıkar, KDV anahtarı, vade
- [ ] `features/islem/view/tahsilat_form_ekrani.dart` — tutar, tarih, açıklama
- [ ] `features/islem/view/islem_detay_ekrani.dart` — kalemler, iptal butonu
- [ ] Kalem girişinde **iki mod**: birim fiyat gir · toplam gir (birim fiyat hesaplansın)

### Kalem giriş modu — neden zorunlu

Referans ekstrede Hurma kalemi `1.650 Adet × 18,79 ₺` yazıyor, ama `1.650 × 18,79 = 31.003,50`.
Gerçek toplam `31.000 ₺` ve birim fiyat oradan geri hesaplanmış (`18,787878...`).
Kullanıcı yuvarlak toplam üzerinden çalışıyor. Sadece "birim fiyat gir" dersek
kullanıcıyı kendi çalışma şeklinden koparırız ve faturası tutmaz.

---

## Kabul kriterleri

1. `flutter analyze` sıfır uyarı, `flutter test` geçer, `flutter build ios --release` başarılı
2. **Referans ekstredeki 9 işlem elle girildiğinde, ekrandaki yürüyen bakiye
   PDF'teki bakiye kolonuyla kuruşu kuruşuna aynı çıkıyor**
3. Üçüncü faturaya %1 KDV uygulandığında toplam `142.031,25 ₺` çıkıyor
4. Hurma kalemi "toplam 31.000 ₺" olarak girildiğinde birim fiyat `18,79 ₺` gösteriliyor
   ve fatura toplamı `94.000,00 ₺` çıkıyor — `94.003,50` değil
5. İşlem iptal edilince bakiye geri alınıyor, kayıt listede üstü çizili duruyor
6. `bakiyeYenidenHesapla` çağrıldığında sonuç önbelleklenmiş bakiyeyle aynı
7. Uçak modunda fatura girilebiliyor, internet gelince sunucuya yazılıyor
8. Aynı cariye iki cihazdan/hızlı ardışık iki işlem girildiğinde bakiye bozulmuyor

---

## Testler

| Ne test edilir | Neden |
|---|---|
| Referans ekstrenin 9 işlemi → beklenen bakiye dizisi | Fazın ana doğruluk ölçütü |
| KDV %1: `140.625` → `142.031,25` | Referans ekstredeki gerçek vaka |
| KDV %0: toplam = ara toplam | |
| Birim fiyat geri hesabı: `31.000 ÷ 1.650` → `18,79` gösterilir, toplam `31.000` kalır | Yuvarlama sızıntısı testi |
| Alış faturası bakiyeyi negatife düşürür | Çift yönlü cari |
| İptal edilen işlem bakiyeye katılmaz | |
| `bakiyeYenidenHesapla` == önbelleklenmiş bakiye | Tutarsızlık yakalama |
| Eşzamanlı iki işlem — emulator | Transaction doğrulaması |

---

## Riskler

- **En yüksek riskli faz burası.** Bakiye yanlış hesaplanırsa uygulamanın tek işi
  başarısız olur. Domain testleri yazılmadan UI'a geçilmez.
- **`double` sızıntısı.** Kalem hesabı, KDV ve yuvarlama `double`'a düşerse hata
  kuruşlarda başlar, ekstrede lirada görünür. Kod incelemesinde özellikle bakılacak.
- **Transaction unutulursa** bakiye sessizce bozulur ve fark edilmesi aylar sürer.
