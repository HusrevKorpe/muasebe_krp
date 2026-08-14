# Faz 3 — Fidan Katalogu

**Durum:** Sürüyor — kod, birim ve emulator testleri tamam; kabul kriterlerinin
cihazda elle doğrulanması bekliyor
**Ön koşul:** Faz 2 kapalı (kod tarafı tamam; ekstrenin cihazda elle girilmesi
ve uçak modu denemesi Faz 2'de açık)
**Amaç:** Fidanları yapılandırılmış biçimde tanımlamak ve fatura keserken kalemi
katalogdan seçtirmek. Böylece aynı fidan her faturada aynı isimle geçer ve rapor
alınabilir hâle gelir.

> Kullanıcının tarifi: *"Tür çeşit anaç şeklinde olacak. Mesela elma çeşidi
> scarlet çeşiti m9 anacı şeklinde."*

> **Bu dosya kısmen eskidir.** Model `Fidan` iken `Urun` oldu, katalog önce tek
> serbest ada sadeleşti, sonra kullanıcının isteğiyle yeniden Tür/Çeşit/Anaç'a
> bölündü — bu kez yaş ve kök tipi olmadan, ve aynı üç kutu fatura satırında da
> var. Tür/anaç öneri listesi (`oneriler`) ve `turAnahtari` alanı kaldırıldı;
> yerine kullanıcının kendi girdiği üç seçim listesi geldi (bkz. aşağıdaki
> "Tür ve anaç listeleri"). Güncel durum için CLAUDE.md → "Bilinmesi
> gerekenler". Aşağıdaki alan tabloları ve dosya adları ilk sürümü anlatıyor;
> kabul kriterleri hâlâ geçerli.

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
Bu yüzden model beş alanlı, son üçü opsiyonel:

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
| `turAnahtari` | string | Normalize `tur` — tür önerisi sorgusu buradan süzer |
| `anacAnahtari` | string? | Normalize `anac`. Anaç yoksa `null` yazılır |
| `aktif` | bool | Silme yok, pasife alma var |
| `olusturmaTarihi` | timestamp | `serverTimestamp()` |
| `guncellemeTarihi` | timestamp | `serverTimestamp()` |

> Not: Alan **adları** ASCII (`anac`, `cesit`) — KURALLAR.md §2.2. Alan **değerleri**
> kullanıcı verisidir ve tam Türkçe olur (`Anaç: M9`, `Çeşit: Şeker`).

### Tür ve anaç listeleri

> **Bu bölümdeki karar tersine döndü.** Aşağıdaki tasarım (öneri listesini
> mevcut fidanlardan türetmek) yazıldı, çalıştı, sonra kaldırıldı. Bugünkü hâli
> bölümün sonundaki "Bugün: üç ayrı liste" başlığında.

`tur` ve `anac` serbest metin olarak tutulur, ama giriş sırasında daha önce
girilmiş değerler önerilir. Ayrı bir "türler" koleksiyonu açılmaz — kullanıcı
tek kişi, öneri listesi mevcut fidanlardan türetilebilir.

**Plandan sapma — iki ek anahtar alanı.** Bu faz dosyası başlangıçta yalnızca
`aramaAnahtari`'nı yazıyordu. Öneri listesi ondan üretilemiyor: anahtar
`"elma scarlet m9"` biçiminde ve Firestore `distinct` bilmiyor, öntakı süzgeci
de yalnızca **baştan** eşleşiyor — anaç aramak için ayrı bir alan şart.
Alternatif, katalogun tamamını çekip bellekte ayıklamaktı; bu KURALLAR.md
§4.3'ü (liste sorgusu sayfalanır) çiğnerdi. Bu yüzden `turAnahtari` ve
`anacAnahtari` alanları eklendi: öneri sorgusu öntakıyla süzülüp `limit` ile
sınırlanıyor, ayrı değerler taranan belgelerden türetiliyor.

**Öneri sorgusu yazılan metnin tamamıyla değil ilk harfiyle anahtarlanır.**
"E", "El", "Elm", "Elma" tek bir Firestore okumasına düşer, daralan eşleşme
ekranda yerel olarak süzülür. Aksi hâlde her tuşa basış bir okuma olurdu.

#### Bugün: üç ayrı liste

Öneri listesi kaldırıldı, yerine kullanıcının kendi doldurduğu üç koleksiyon
geldi: `turler`, `cesitler`, `anaclar` (`lib/domain/secenek/`).

> Kullanıcının tarifi: *"Ürünlerden seç aynı o şekilde kalsın, altına anaçlardan
> seç yazalım. Anaçları gireyim ben, tıklayınca hangi anaç olduğunu şey yapalım.
> Bir de çeşitlerden seç diye bir şey yapalım... Onları hemen ilk başta
> kaydedeyim, tıkla tıkla vereyim direkt."*

**Neden ürün katalogu yetmedi.** Katalogdaki kayıt tam kombinasyondur
(`Elma Scarlet M9`). Kombinasyon sayısı üç alanın çarpımı kadar; kullanıcı
`Elma Scarlet M9`, `Elma Scarlet MM106`, `Elma Granny M9` … hepsini ayrı ürün
olarak giremiyor ve pratikte üç kutuyu her satışta elle yazıyordu. Üç küçük
liste bir çarpım tablosunun yerini tutuyor: 3 tür + 5 çeşit + 4 anaç = 12 kayıt,
karşılığında 60 kombinasyon.

**Neden öneri listesi değil de elle girilen liste.** Öneri, katalogda o değer
zaten varsa çalışıyor; kullanıcı listeyi *önden* kurmak istiyor ("hemen ilk
başta kaydedeyim"). Ayrıca öneri sorgusu bu dosyada anlatılan iki ek anahtar
alanını ve tarama sınırını gerektiriyordu; ayrı koleksiyon ikisini de gereksiz
kılıyor.

| Karar | Gerekçe |
|---|---|
| Tip alanı yok, koleksiyon adı taşıyor | Tek koleksiyon + `tip` alanı, `tip == x` süzgecini ada göre sıralamayla birleştirir ve bileşik index isterdi. Bu şemada tek alanlık otomatik index yetiyor; `firestore.indexes.json` hiç değişmedi. |
| Silme var, pasife alma yok | Satıra kimlikle bağlı geçmiş kayıt yok: kalem, seçilen satırın kimliğini değil **metnini** kopyalıyor. Yanlış yazılmış bir anaç listeden temizlenebilmeli (KURALLAR.md §4.2 muhasebe kaydını korur, yazım kolaylığını değil). |
| Düğmeler kutuların içinde, üstte alt alta değil | Kullanıcı "üründen seçin altına" demişti; kalem kutusu zaten uzun ve dört tam genişlik düğme tutar alanını ekranın altına indiriyordu. Her düğme kendi kutusunun sağında duruyor. |
| Tür için de liste var | Kullanıcı yalnızca çeşit ve anaç saydı, ama tür elle yazılmaya devam etseydi "tıkla tıkla" isteği yarım kalırdı. |
| Seçim sayfasından ekleme kutuyu dolduruyor | Listede bulunmayan anacı ekleyip bir de listeden seçmek zorunda kalmak, tam olarak tezgahta tıkanılan yer. |

---

## Görevler

### Domain (`lib/domain/fidan/`) — saf Dart, **testi zorunlu**
- [x] `Fidan` modeli + `fromMap` / `toMap`
- [x] `KokTipi` enum
- [x] Görünen ad üretimi: alanlardan `Elma / Scarlet / M9 · 2 Yaş · Tüplü`
- [x] Doğrulama: `tur` ve `cesit` zorunlu (`FidanDogrulama`)
- [x] Mükerrer ölçütü: `tekillikAnahtari` / `ayniFidanMi`

Görünen ad domain'de üretiliyor, çünkü faturaya giren metin bu — ekranda
kurulsaydı katalogdan seçilen kalemin adı ekrandan ekrana değişebilirdi.
"Yaş", "Tüplü" gibi ekler `Metinler`'den geliyor; domain saf Dart kalıyor
(`core/metin/metinler.dart` Flutter'a bağlı değil) ve metin tek yerde duruyor
— KURALLAR.md §6.

### Data (`lib/data/fidan/`)
- [x] `FidanRepository`: listele (sayfalı), ara, izle, ekle, güncelle, pasife al
- [x] Tür/anaç öneri listesi sorgusu (`oneriler`)
- [x] Mükerrer kontrolü sorgusu (`benzerleriBul`)
- [x] Gerekli index'ler `firestore.indexes.json`'a eklendi (3 bileşik index)

Yazma future'ları burada da **beklenmiyor**: kullanıcı serada internetsizken
katalog düzenleyebilmeli (KURALLAR.md §4.4).

### Features
- [x] `features/fidan/view/fidan_listesi_ekrani.dart` — türe göre gruplu liste
- [x] `features/fidan/view/fidan_form_ekrani.dart` — tür/anaç alanlarında otomatik öneri
- [x] Fiyat listesi görünümü — ayrı ekran değil, liste satırının sağ kolonu
- [x] `fidan_secim_sayfasi.dart` — fatura kalemi için katalog seçici
- [x] Cari listesi menüsüne "Fidan katalogu" girişi

Fiyat listesi ayrı bir ekran olarak yazılmadı: katalog listesi zaten türe göre
gruplu ve her satırda varsayılan fiyat var. İkinci bir ekran aynı sorguyu ikinci
kez okurdu.

### Faz 2 entegrasyonu
- [x] Fatura kalem satırına **katalogdan seç** butonu eklendi
- [x] Seçilince `fidanId`, `ad` ve `birimFiyatKurus` ön dolgu geliyor
- [x] **Serbest metin girişi korunuyor** — "nakliye" gibi kalemler için zorunlu
- [x] Geçmiş faturalardaki serbest metin kalemler bozulmuyor (`fidanId` boş kalır)

---

## Kabul kriterleri

| # | Kriter | Durum |
|---|---|---|
| 1 | `flutter analyze` sıfır uyarı, `flutter test` geçer, `flutter build ios --release` başarılı | ✅ |
| 2 | `Elma / Scarlet / M9` fidanı eklenebiliyor ve listede doğru görünüyor | ✅ emulator testi; cihazda göz kontrolü bekliyor |
| 3 | Tür alanına "El" yazınca daha önce girilmiş "Elma" öneriliyor | ✅ emulator testi (`oneriler`); çip görünümü cihazda bakılacak |
| 4 | Fatura keserken katalogdan fidan seçilince birim fiyat otomatik geliyor, kullanıcı değiştirebiliyor | ⏳ kod hazır, cihazda elle denenmeli |
| 5 | **"nakliye" kalemi hâlâ serbest metin olarak girilebiliyor** — katalog zorunlu değil | ✅ birim testi |
| 6 | Faz 2'de girilmiş eski faturalar açıldığında bozulmadan görünüyor | ✅ birim testi (`fidanId` olmadan yazılmış kalem okunuyor) |
| 7 | Aynı fidan iki kez eklenmeye çalışıldığında uyarılıyor | ✅ emulator testi (`benzerleriBul`) + birim testi (`ayniFidanMi`) |

### 4 neden otomatik doğrulanmadı

Kalem kutusundan katalog sayfasına gidip geri dönme akışı widget testinde
Navigator yığını kurmayı gerektiriyor; kazancı, kurulum maliyetini karşılamıyor.
Akışın iki ucu ayrı ayrı test edilmiş durumda: katalog sorgusu emulator
testinde, `fidanId` ve fiyatın kaleme taşınması birim testinde.

---

## Testler

| Ne test edilir | Nerede | Durum |
|---|---|---|
| Görünen ad — opsiyonel alanlar boşken (`Elma / Scarlet`) | `test/domain/fidan/fidan_test.dart` | ✅ |
| Görünen ad — tüm alanlar dolu | `test/domain/fidan/fidan_test.dart` | ✅ |
| Doğrulama: `tur` veya `cesit` boşken reddedilir | `test/domain/fidan/fidan_dogrulama_test.dart` | ✅ |
| Yaş ve fiyat isteğe bağlı, geçersiz değer reddedilir | `test/domain/fidan/fidan_dogrulama_test.dart` | ✅ |
| Türkçe arama: `Şeker` / `seker` aynı anahtar | `test/domain/fidan/fidan_test.dart` | ✅ |
| Mükerrer: yalnızca yaşı farklı kayıt ayrı fidandır | `test/domain/fidan/fidan_test.dart` | ✅ |
| Kalem: katalogdan seçim `fidanId` yazıyor | `test/domain/islem/islem_kalemi_test.dart` | ✅ |
| Kalem: serbest metin `fidanId` boş bırakıyor | `test/domain/islem/islem_kalemi_test.dart` | ✅ |
| Faz 2 kalemi `fidanId` alanı olmadan bozulmadan okunuyor | `test/domain/islem/islem_kalemi_test.dart` | ✅ |
| Sayfalama, arama, öneri listesi, mükerrer kontrolü | `integration_test/fidan_repository_test.dart` | ✅ |
| Aynı anahtarlı (yalnızca yaşı farklı) kayıtlar sayfa sınırında kaybolmuyor | `integration_test/fidan_repository_test.dart` | ✅ |
| Pasife alınan fidan listede ve öneride görünmüyor, belge duruyor | `integration_test/fidan_repository_test.dart` | ✅ |

---

## Riskler

- **Katalog zorunlu hâle getirilirse** kullanıcı tezgahta yavaşlar: satmak istediği
  fidan katalogda yoksa önce katalogu düzenlemek zorunda kalır. Serbest metin
  seçeneği kaldırılmayacak (KURALLAR.md'deki karar).
- **Aynı fidanın mükerrer kaydı** katalogu zamanla çöplüğe çevirir. Ekleme sırasında
  benzer kayıt kontrolü yapılmalı. Kontrol **kaydederken** yapılıyor, yazarken
  değil: her tuşa basışta sorgu atmak Firestore okumasını kullanıcının yazma
  hızıyla çarpardı (KURALLAR.md §4.3). Ölçüt `tur + cesit + anac + yas + kokTipi`;
  aynı fidanın 1 ve 2 yaşlısı mükerrer sayılmaz. Çevrimdışıyken kontrol yerel
  önbellekten okur; önbellek boşsa mükerrer kayıt geçebilir — yazmayı engellemek
  yerine buna izin veriyoruz, aksi hâlde uçak modunda katalog düzenlenemezdi
  (KURALLAR.md §4.4).
- **Katalogdaki fiyat geçmişi bozmaz.** Kalem, kaydedildiği andaki adı ve
  tutarı kendi içinde taşıyor (`IslemKalemi`). Katalogda fiyat düzeltmek eski
  faturaları geriye dönük kaydırmıyor — KURALLAR.md §3.2.
- **Öneri listesi taranan belgelerden türetiliyor** (`oneriTaramaSiniri = 40`).
  Katalog aynı türden yüzlerce kayıt içerdiğinde ilk harfin ötesindeki türler
  öneri listesine girmeyebilir. Öneri bir kolaylık, zorunluluk değil: alan
  serbest metin olarak yazılabiliyor.
