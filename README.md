# FidanCari

Fidancılık işletmeleri için ön muhasebe ve cari hesap takip uygulaması.

İşletme sahibi müşteri ve tedarikçilerini kaydeder, satış/alış faturası ve tahsilat
girer, yürüyen bakiyeyi izler; tarih aralığına göre PDF ekstre üretip WhatsApp veya
e-posta ile paylaşır.

## Neden ayrı bir uygulama

Genel muhasebe uygulamaları fidancılığın ürün yapısını taşımıyor. Bir fidan
**Tür → Çeşit → Anaç** üçlüsüyle tanımlanıyor (örnek: *Elma / Scarlet / M9*),
buna yaş ve kök tipi (tüplü / çıplak kök) ekleniyor. Ayrıca sektörde aynı kişiyle
hem alım hem satım yapıldığı için bir cari aynı anda müşteri ve tedarikçi olabiliyor.

## Özellikler

- **Cari yönetimi** — müşteri/tedarikçi kaydı, Türkçe arama, bakiye takibi
- **İşlemler** — satış/alış faturası, tahsilat, ödeme; kalem bazlı giriş, vade
- **Fidan katalogu** — Tür/Çeşit/Anaç/Yaş/Kök tipi ve fiyat listesi
- **PDF ekstre** — tarih aralığına göre işlem dökümü, banka bilgileri ve toplamlarla
- **Çevrimdışı çalışma** — internet olmadan veri girilir, bağlantı gelince eşitlenir
- **Ortak defter** — Google ile giriş yapan izinli hesaplar aynı kayıtları görür

## Teknik

| | |
|---|---|
| Platform | iOS 15.0+ |
| Framework | Flutter 3.41 · Dart 3.11 |
| Veritabanı | Cloud Firestore |
| State | Riverpod |
| Mimari | MVVM — View → ViewModel → Repository → Firestore |

## Kurulum

```bash
flutter pub get
cd ios && pod install && cd ..
flutter run
```

Firebase bağımlılıkları Swift Package Manager üzerinden çözülür; Xcode paketleri
ilk derlemede kendisi indirir. `pod install` hâlâ gerekli çünkü `printing`
eklentisi yalnızca CocoaPods yayınlıyor.

Firebase yapılandırması repoda mevcuttur (`lib/firebase_options.dart`,
`ios/Runner/GoogleService-Info.plist`, `Info.plist` içindeki `GIDClientID` ve
Google URL şeması). Bunlar istemci anahtarıdır; erişim güvenliği Firestore
kurallarıyla sağlanır.

Uygulamaya girebilmek için hesabın izin listesinde olması gerekir:
Firebase Console → Firestore → `izinliler` koleksiyonu → belge kimliği =
e-posta adresi (küçük harf, alan gerekmez). Liste boşken kimse giremez.

## Geliştirme

Katkı vermeden önce **[KURALLAR.md](KURALLAR.md)** okunmalıdır — mimari sınırlar,
para hesaplama kuralları ve faz kapanış ölçütleri orada tanımlıdır.

Yol haritası ve faz ayrıntıları: [`fazlar/`](fazlar/)

```bash
flutter analyze      # sıfır uyarı vermeli
flutter test         # tüm testler geçmeli
```
