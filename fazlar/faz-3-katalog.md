# Faz 3 — Fidan Katalogu

**Durum:** Başlanmadı
**Ön koşul:** Faz 2 kapalı
**Amaç:** Fidanları yapılandırılmış biçimde tanımlamak ve fatura keserken kalemi
katalogdan seçtirmek. Böylece aynı fidan her faturada aynı isimle geçer ve rapor
alınabilir hâle gelir.

> Kullanıcının tarifi: *"Tür çeşit anaç şeklinde olacak. Mesela elma çeşidi
> scarlet çeşiti m9 anacı şeklinde."*

---

## Kapsam

### Bu fazda var
- Fidan katalogu: Tür → Çeşit → Anaç (+ Yaş, Kök tipi)
- Varsayılan fiyat listesi
- Fatura kaleminde katalogdan seçim
- Katalog dışı kalemler için serbest metin (nakliye, hizmet vb.)

### Bu fazda yok
- Stok adedi takibi — MVP kapsamı dışı
- Parti / lot / parsel takibi
- Fiyat geçmişi

---

## Fidan kimliği

Kullanıcı üç seviye söyledi, ama referans ekstredeki kalemlerde daha fazlası var:
`Hachiya **Tüplü**`, `zeytin gemlik **2 Yaş**`, `asma **anacı** atasarısı`.
Bu yüzden model beş alanlı, son ikisi opsiyonel:

| Alan | Zorunlu | Örnek |
|---|---|---|
| `tur` | Evet | Elma, Zeytin, Ceviz |
| `cesit` | Evet | Scarlet, Gemlik, Hachiya |
| `anac` | Hayır | M9, MM106 |
| `yas` | Hayır | 1, 2 |
| `kokTipi` | Hayır | `tuplu` · `ciplakKok` |

Görünen ad bu alanlardan üretilir: `Elma / Scarlet / M9 · 2 Yaş · Tüplü`.

---

## Firestore veri modeli

### `isletmeler/{isletmeId}/fidanlar/{fidanId}`

| Alan | Tip | Not |
|---|---|---|
| `tur` | string | ASCII değil, kullanıcı verisi — tam Türkçe girilir |
| `cesit` | string | |
| `anac` | string? | |
| `yas` | int? | |
| `kokTipi` | string? | `tuplu` · `ciplakKok` |
| `varsayilanFiyatKurus` | **int** | Faturada ön dolgu olarak gelir, değiştirilebilir |
| `aramaAnahtari` | string | Normalize edilmiş `tur cesit anac` |
| `aktif` | bool | Silme yok, pasife alma var |
| `olusturmaTarihi` | timestamp | `serverTimestamp()` |

> Not: Alan **adları** ASCII (`anac`, `cesit`) — KURALLAR.md §2.2. Alan **değerleri**
> kullanıcı verisidir ve tam Türkçe olur (`Anaç: M9`, `Çeşit: Şeker`).

### Tür ve anaç listeleri

`tur` ve `anac` serbest metin olarak tutulur, ama giriş sırasında daha önce
girilmiş değerler önerilir. Ayrı bir "türler" koleksiyonu açılmaz — kullanıcı
tek kişi, öneri listesi mevcut fidanlardan türetilebilir.

---

## Görevler

### Domain
- [ ] `Fidan` modeli + `fromMap` / `toMap`
- [ ] `KokTipi` enum
- [ ] Görünen ad üretimi: alanlardan `Elma / Scarlet / M9 · 2 Yaş · Tüplü`
- [ ] Doğrulama: `tur` ve `cesit` zorunlu

### Data
- [ ] `FidanRepository`: listele (sayfalı), ara, ekle, güncelle, pasife al
- [ ] Tür/anaç öneri listesi sorgusu
- [ ] Gerekli index'ler `firestore.indexes.json`'a eklenir

### Features
- [ ] `features/fidan/view/fidan_listesi_ekrani.dart` — türe göre gruplu liste
- [ ] `features/fidan/view/fidan_form_ekrani.dart` — tür/anaç alanlarında otomatik öneri
- [ ] Fiyat listesi görünümü

### Faz 2 entegrasyonu
- [ ] Fatura kalem satırına **katalogdan seç** butonu eklenir
- [ ] Seçilince `fidanId`, `ad` ve `birimFiyatKurus` ön dolgu gelir
- [ ] **Serbest metin girişi korunur** — "nakliye" gibi kalemler için zorunlu
- [ ] Geçmiş faturalardaki serbest metin kalemler bozulmaz (`fidanId` boş kalır)

---

## Kabul kriterleri

1. `flutter analyze` sıfır uyarı, `flutter test` geçer, `flutter build ios --release` başarılı
2. `Elma / Scarlet / M9` fidanı eklenebiliyor ve listede doğru görünüyor
3. Tür alanına "El" yazınca daha önce girilmiş "Elma" öneriliyor
4. Fatura keserken katalogdan fidan seçilince birim fiyat otomatik geliyor,
   kullanıcı değiştirebiliyor
5. **"nakliye" kalemi hâlâ serbest metin olarak girilebiliyor** — katalog zorunlu değil
6. Faz 2'de girilmiş eski faturalar açıldığında bozulmadan görünüyor
7. Aynı fidan iki kez eklenmeye çalışıldığında uyarılıyor

---

## Testler

| Ne test edilir | Neden |
|---|---|
| Görünen ad üretimi — opsiyonel alanlar boşken | `Elma / Scarlet` (anaç yoksa ayraç sarkmamalı) |
| Görünen ad — tüm alanlar dolu | `Elma / Scarlet / M9 · 2 Yaş · Tüplü` |
| Doğrulama: `tur` veya `cesit` boşken reddedilir | |
| Türkçe arama: `Şeker` / `seker` | Faz 0 normalizasyonu |
| Kalem: katalogdan seçim `fidanId` yazıyor | |
| Kalem: serbest metin `fidanId` boş bırakıyor | Geriye uyumluluk |
| `FidanRepository` — emulator | Sayfalama, arama, öneri listesi |

---

## Riskler

- **Katalog zorunlu hâle getirilirse** kullanıcı tezgahta yavaşlar: satmak istediği
  fidan katalogda yoksa önce katalogu düzenlemek zorunda kalır. Serbest metin
  seçeneği kaldırılmayacak (KURALLAR.md'deki karar).
- **Aynı fidanın mükerrer kaydı** katalogu zamanla çöplüğe çevirir. Ekleme sırasında
  benzer kayıt kontrolü yapılmalı.
