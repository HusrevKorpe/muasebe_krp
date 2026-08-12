# Proje Kuralları

Bu dosya bağlayıcıdır. Yeni kod yazarken, kod incelerken ve faz kapatırken buradaki
maddeler ölçüt olarak kullanılır. Bir kuralı ihlal etmek gerekiyorsa önce bu dosya
güncellenir, sonra kod yazılır — sessizce istisna yapılmaz.

---

## 0. Proje Kimliği

| Alan | Değer |
|---|---|
| Ürün | FidanCari — fidancılık ön muhasebe / cari hesap takibi |
| Paket adı | `com.husrevkorpe.fidancari` (**asla değişmez**, mağazaya çıktıktan sonra imkânsız) |
| Firebase projesi | `muasebe-takip` (662432068913) |
| Platform | iOS (minimum **15.0** — Firebase SDK şartı) |
| Stack | Flutter 3.41 / Dart 3.11 · Firestore · Riverpod · MVVM |
| Kullanım modeli | Tek kullanıcı (işletme sahibi kendi cihazında) |

---

## 1. Mimari

### 1.1 Katmanlar ve akış yönü

```
View  →  ViewModel  →  Repository  →  Firestore
                ↓
             Domain (saf Dart)
```

Bağımlılık **yalnızca yukarıdan aşağıya** akar. Alt katman üst katmanı tanımaz.

### 1.2 Klasör yapısı

```
lib/
├── app/           # Uygulama girişi, router, tema
├── core/          # Ortak yardımcılar: para, tarih, hata, uzantılar
├── domain/        # Model + iş kuralları — saf Dart
├── data/          # Repository implementasyonları, Firestore erişimi
└── features/
    └── <ozellik>/
        ├── view/       # Ekranlar ve widget'lar
        └── viewmodel/  # Riverpod notifier'ları
```

### 1.3 Katman ihlali sayılan durumlar

- `package:cloud_firestore` importu **sadece** `lib/data/` altında geçebilir.
  View veya ViewModel içinde `DocumentSnapshot`, `QuerySnapshot`, `FieldValue`
  gibi bir tip görünüyorsa kural ihlalidir.
- `lib/domain/` içinde **hiçbir** Flutter importu olmaz (`material.dart` dahil).
  Domain saf Dart'tır; testi cihazsız çalışır.
- ViewModel içinde `BuildContext` bulunmaz. Navigasyon ve SnackBar View'ın işidir.
- View içinde iş kuralı hesaplanmaz. Ekranda `a * b + kdv` gibi bir satır görünüyorsa
  o hesap domain'e taşınır.

### 1.4 Riverpod

- ViewModel'ler `Notifier` / `AsyncNotifier` olarak yazılır.
- Repository'ler provider ile enjekte edilir — ViewModel içinde `FirebaseFirestore.instance`
  doğrudan çağrılmaz. Aksi hâlde test edilemez.
- Global mutable singleton kullanılmaz.

---

## 2. Kod Kuralları

- **Hiçbir dosya 500 satırı geçmez.** Geçiyorsa sorumluluk fazladır, bölünür.
- Bir dosyada **bir public sınıf** bulunur. Yardımcı private widget'lar aynı dosyada kalabilir.
- `build()` metodu 80 satırı geçerse alt widget'lara ayrılır.
- `print()` kullanılmaz — merkezî logger üzerinden loglanır.
- Ölü kod, yorum satırına alınmış kod ve kullanılmayan import bırakılmaz.
- `// TODO` yazılacaksa faz numarası belirtilir: `// TODO(Faz 3): stok düşümü`.

### 2.1 İsimlendirme

Kod İngilizce, **domain terimleri Türkçe** yazılır. "Anaç"ın karşılığı olan
"rootstock" ne kullanıcının ne de bizim kullandığımız kelime — çevirmek anlam kaybettirir.

| Türkçe kalır | İngilizce olur |
|---|---|
| `Cari`, `Bakiye`, `Tahsilat`, `Fatura`, `Anac`, `Cesit`, `Tur`, `Vade` | `Repository`, `Service`, `isLoading`, `onPressed`, `build` |

```dart
class CariRepository { ... }          // doğru
Future<void> saveTahsilat(...) { ... } // doğru
class ContactRepository { ... }        // yanlış — cari, contact değil
```

### 2.2 Karakter seti

Kod içinde **ASCII** kullanılır: `anac`, `cesit`, `bakiye` — şapkasız, noktasız.
Bu kural dosya adlarını, sınıf/değişken adlarını ve **Firestore alan adlarını** kapsar.

Kullanıcıya görünen metinlerde tam Türkçe yazılır: `'Anaç'`, `'Çeşit'`, `'Bakiye'`.

---

## 3. Para ve Hesaplama

> Bu bölüm listenin en kritik kısmıdır. Uygulamanın tek işi doğru bakiye göstermek.

### 3.1 Para asla `double` olmaz

Tüm parasal değerler **kuruş cinsinden `int`** olarak tutulur.

```dart
// 94.000,00 ₺
const int tutarKurus = 9400000;   // doğru
const double tutar = 94000.00;    // YASAK
```

**Neden:** `0.1 + 0.2 == 0.30000000000000004`. Dört yıllık bir ekstrede binlerce
toplama yapılınca bu sapma kuruştan liraya çıkar ve müşteriye yanlış borç gösterilir.
Elimizdeki örnek ekstrede bu risk zaten görünür durumda: bir kalemin birim fiyatı
`18,79 ₺` yazıyor ama gerçek değer `18,787878...`.

Bu kural Firestore'da saklanan alanları da kapsar — veritabanına da `int` yazılır.

### 3.2 Yuvarlama ve birim fiyat

- Bölme yapılan her yerde (birim fiyat = toplam ÷ adet) sonuç **en yakın kuruşa** yuvarlanır.
- Kullanıcı "toplam tutar" girdiğinde birim fiyat geriye hesaplanır ve **girilen toplam
  esas alınır** — yuvarlanmış birim fiyattan yeniden çarpılarak toplam üretilmez.
- Fatura tutarı kalem toplamlarından türetilir, ama kaydedildikten sonra **saklanan
  tutar esastır**; geçmişe dönük yeniden hesaplama yapılmaz.

### 3.3 KDV

- KDV **fatura bazında opsiyoneldir**, varsayılan oran **%1** (fidan KDV oranı).
- Oran fatura kaydında saklanır. Yarın oran değişirse geçmiş faturalar etkilenmez.

### 3.4 Bakiye

- Bakiye = `toplam borç − toplam alacak`. Negatif bakiye, işletmenin o cariye
  borçlu olduğu anlamına gelir ve ekranda ayırt edilir.
- Bir cari **hem müşteri hem tedarikçi** olabilir. Model bunu baştan varsayar.
- Tüm para hesapları `lib/domain/` içindedir ve **unit testi vardır**.

---

## 4. Firestore

### 4.1 Güvenlik

- **Güvenlik kuralları yazılmadan hiçbir koleksiyon canlıya çıkmaz.**
  Firebase'in test modu 30 gün sonra kapanır; o güne kadar veritabanı herkese açıktır.
- `firestore.rules` ve `firestore.indexes.json` repoda versiyonlanır.

### 4.2 Veri bütünlüğü

- **Muhasebe kaydı fiziksel olarak silinmez.** Yanlış giriş için iptal işaretlemesi
  veya ters kayıt kullanılır. Silinen bir tahsilat, sonraki tüm bakiyeleri kaydırır.
- Tarih alanlarında `FieldValue.serverTimestamp()` kullanılır. Cihaz saati değiştirilebilir
  ve işlem sıralamasını bozar.
- Cari kaydındaki önbelleklenmiş bakiye **yalnızca Firestore transaction içinde**
  güncellenir. Ayrıca "bakiyeyi işlemlerden yeniden hesapla" fonksiyonu bulunur ve
  test edilir.

### 4.3 Maliyet ve performans

- Liste ekranlarında **sayfalama zorunludur**. Koleksiyonun tamamı tek `get()` ile çekilmez —
  Firestore okuma başına ücretlendirir.
- Cari listesinde bakiye göstermek için o carinin işlemleri çekilmez; önbelleklenmiş
  bakiye alanı okunur.
- Her sorgunun index'i `firestore.indexes.json` içinde tanımlıdır.

### 4.4 Çevrimdışı

- Firestore offline persistence **açıktır**. Kullanıcı serada/tarlada internetsiz kalır.
- UI, henüz sunucuya yazılmamış kayıtları ayırt edilebilir şekilde gösterir
  (`metadata.hasPendingWrites`).

---

## 5. Test ve Faz Kapanışı

Bir faz, aşağıdakilerin **hepsi** sağlanmadan kapatılmaz:

1. `flutter analyze` → **sıfır uyarı**
2. `flutter test` → tüm testler geçer
3. `flutter build ios --release` → başarılı
4. Fazın kabul kriterleri (kendi `.md` dosyasında yazılı) cihazda elle doğrulanır

### 5.1 Otomatik test zorunlu olan yerler

- `lib/domain/` içindeki **tüm** hesaplamalar: bakiye, KDV, yuvarlama, birim fiyat
  geri hesabı, ekstre toplamları.
- Repository'ler Firestore **emulator**'ünde test edilir. Canlı veritabanıyla test yapılmaz.

### 5.2 Test edilmesi beklenmeyen yerler

Saf görsel widget'lar için test zorlanmaz. Test yazmak uğruna anlamsız test yazılmaz.

---

## 6. Metin ve Yerelleştirme

- Kullanıcıya görünen tüm metinler Türkçedir.
- Metinler widget içine gömülmez, tek bir yerden gelir. Faz 1'de sabit metin dosyası
  yeterlidir; çok dil gerekirse `l10n`'a taşınır.
- Para biçimi: `1.234.567,89 ₺` (binlik nokta, ondalık virgül).
- Tarih biçimi: `17 Eylül 2021` (ekstrede), `17.09.2021` (dar alanlarda).

### 6.1 Türkçe arama tuzağı

`"İstanbul".toLowerCase()` Dart'ta beklenen sonucu vermez; `I/ı/İ/i` dönüşümü bozuktur.
Cari isminde arama yapacağımız için bu kesinlikle karşımıza çıkar.

**Kural:** Arama ve sıralama normalizasyonu `core/` altındaki tek bir yardımcı
fonksiyondan geçer. Ekranlarda doğrudan `toLowerCase()` çağrılmaz.

---

## 7. Güvenlik ve Mağaza

- `GoogleService-Info.plist` ve `firebase_options.dart` repoda tutulabilir — bunlar
  istemci anahtarıdır, gizli değildir. Güvenlik Firestore kurallarıyla sağlanır.
- Gerçek müşteri verisi, IBAN ve kişisel bilgi **repoya commit edilmez**.
  Örnek/test verisi uydurma olur.
- Her faz sonunda `pubspec.yaml` içindeki build numarası artırılır.
- **CocoaPods → SPM geçişi:** Firebase, CocoaPods desteğini Ekim 2026'da durduruyor.
  Bu geçiş fazlardan birine görev olarak yazılır, son ana bırakılmaz.

---

## 8. Hızlı Kontrol Listesi

Kod göndermeden önce:

- [ ] Dosya 500 satırın altında mı?
- [ ] Para değeri `int` (kuruş) mu?
- [ ] `cloud_firestore` importu sadece `data/` altında mı?
- [ ] ViewModel'de `BuildContext` var mı?
- [ ] Domain'de Flutter importu var mı?
- [ ] Yeni hesaplama eklendiyse testi yazıldı mı?
- [ ] `flutter analyze` temiz mi?
- [ ] Kullanıcıya görünen metin Türkçe, kod ASCII mi?
