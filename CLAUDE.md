# FidanCari

Fidancılık ön muhasebe ve cari hesap takip uygulaması. İşletme sahibi müşterilerini
(cari) kaydeder, satış/alış faturası ve tahsilat girer, yürüyen bakiyeyi izler ve
tarih aralığına göre PDF ekstre üretip paylaşır.

## ÖNCE BUNU OKU

**[KURALLAR.md](KURALLAR.md) bağlayıcıdır.** Kod yazmadan önce oku. Öne çıkanlar:

- **Para asla `double` değil** — kuruş cinsinden `int`. Firestore'a da `int` yazılır.
- **Dosya başına 500 satır** sınırı, bir dosyada bir public sınıf.
- **Katman akışı:** View → ViewModel → Repository → Firestore.
  `cloud_firestore` importu **sadece** `lib/data/` altında geçebilir.
- `lib/domain/` **saf Dart** — Flutter importu yok.
- ViewModel'de `BuildContext` yok.
- **Muhasebe kaydı silinmez** — iptal işaretlenir veya ters kayıt atılır.
- Kod ASCII (`anac`, `cesit`), kullanıcıya görünen metin tam Türkçe (`Anaç`, `Çeşit`).
- Domain terimleri Türkçe kalır: `Cari`, `Bakiye`, `Tahsilat` — `Contact`, `Balance` değil.

## Fazlar

Sırayla ilerlenir. Bir faz, kendi dosyasındaki kabul kriterleri sağlanmadan kapatılmaz.

| Faz | Konu | Durum |
|---|---|---|
| [0](fazlar/faz-0-iskelet.md) | İskelet: klasör yapısı, tema, Riverpod, Auth, çekirdek yardımcılar | **Sürüyor** |
| [1](fazlar/faz-1-cari.md) | Cari: işletme profili, liste, arama, detay sayfası | Başlanmadı |
| [2](fazlar/faz-2-islemler.md) | İşlemler: fatura, tahsilat, kalemler, KDV, yürüyen bakiye | Başlanmadı |
| [3](fazlar/faz-3-katalog.md) | Fidan katalogu: Tür/Çeşit/Anaç/Yaş/Kök tipi, fiyat listesi | Başlanmadı |
| [4](fazlar/faz-4-ekstre.md) | PDF ekstre: şablon, tarih aralığı, paylaşma | Başlanmadı |
| [5](fazlar/faz-5-magaza.md) | Mağaza: ikon, gizlilik, SPM geçişi, TestFlight, App Store | Başlanmadı |

Faz kapandığında bu tablodaki durumu ve ilgili faz dosyasının başlığındaki durumu güncelle.

## Komutlar

```bash
flutter analyze                        # sıfır uyarı vermeli
flutter test                           # tüm testler geçmeli
flutter build ios --release            # faz kapanışında başarılı olmalı
flutter run                            # cihazda çalıştır

firebase emulators:start --only firestore   # repository testleri burada koşar
firebase deploy --only firestore:rules      # güvenlik kurallarını yayınla
```

Not: `pod install` çalıştırmak gerekirse `ios/` dizinine geçilir. CocoaPods spec
deposu eskiyse `pod install --repo-update` gerekir.

## Teknik künye

| Alan | Değer |
|---|---|
| Paket adı | `com.husrevkorpe.fidancari` — **asla değiştirilmez** |
| Firebase projesi | `muasebe-takip` (662432068913) |
| Platform | iOS, minimum **15.0** (Firebase SDK şartı) |
| Stack | Flutter 3.41 · Dart 3.11 · Firestore · Riverpod · MVVM |
| Kullanım | Tek kullanıcı — her kurulum kendi verisiyle çalışır |

## Klasör yapısı

```
lib/
├── app/           # Giriş, router, tema
├── core/          # Para, tarih, arama normalizasyonu, logger, hata
├── domain/        # Model + iş kuralları — saf Dart, testi zorunlu
├── data/          # Repository'ler, Firestore erişimi
└── features/
    └── <ozellik>/
        ├── view/
        └── viewmodel/
```

## Bilinmesi gerekenler

- **Referans ekstre:** `~/Desktop/Favori_Fidancılık_Ekstresi.pdf` — üreteceğimiz PDF'in
  hedefi bu. Kolonlar: İşlem Tarihi · Açıklama · Vade Tarihi · Borç · Alacak · Bakiye.
- **KDV %1**, fatura bazında opsiyonel. Referans ekstredeki üç faturadan yalnızca
  birinde uygulanmış.
- **Bir cari hem müşteri hem tedarikçi olabilir.** Fidancılıkta alım-satım aynı kişiyle yapılır.
- **Fidan kimliği:** Tür → Çeşit → Anaç (+ Yaş, Kök tipi). Örnek: Elma / Scarlet / M9.
- **CocoaPods desteği Ekim 2026'da bitiyor** — Faz 5'te SPM'e geçilecek.
