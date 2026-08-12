# Faz 5 — Mağaza Hazırlığı

**Durum:** Sürüyor
**Ön koşul:** Faz 1–4 kapalı
**Amaç:** Uygulamayı App Store'a yayınlanabilir hâle getirmek. Bu faz kod değil,
teslimat fazıdır — reddedilme sebeplerini önceden kapatır.

---

## Kapsam

### Bu fazda var
- Uygulama kimliği: ad, ikon, açılış ekranı
- Apple Developer hesabı, sertifika, provisioning
- Gizlilik politikası ve App Privacy beyanı
- CocoaPods → Swift Package Manager geçişi
- TestFlight ve App Store gönderimi

### Bu fazda yok
- Yeni özellik. Bu fazda özellik yazılmaz.

---

## Zamana duyarlı madde: CocoaPods

> Firebase, CocoaPods desteğini **Ekim 2026**'da durduruyor. `pod install` sırasında
> Firebase'in kendi uyarısı düştü: mevcut sürümler çalışmaya devam edecek ama yeni
> sürüm yayınlanmayacak, Swift Package Manager'a geçiliyor.

Bu maddeyi fazın **başına** al, sonuna değil. Geçiş sırasında derleme kırılırsa
mağaza gönderimi gecikir.

- [x] Flutter'ın SPM desteğini etkinleştir (`flutter config --enable-swift-package-manager`)
- [x] Firebase bağımlılıklarını SPM üzerinden çöz
- [x] `flutter build ios --release` başarılı
- [ ] Cihazda duman testi: giriş → cari → fatura → ekstre

**Firebase riski kapandı.** `firebase-ios-sdk 12.17.0` artık SPM üzerinden
geliyor (bkz. `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`).
Ekim 2026 tarihinin bağladığı bağımlılık artık CocoaPods'ta değil.

### Kalan CocoaPods bağımlılığı: `printing`

`Podfile.lock` 1434 satırdan 22 satıra indi; geriye tek eklenti kaldı:

```
PODS:
  - Flutter (1.0.0)
  - printing (1.0.0)
```

`printing 5.14.3` (ekstre önizleme ve paylaşma) yalnızca `podspec` yayınlıyor,
`Package.swift` yok — yani SPM'e geçirilemiyor.

> **Karar: karma yapı kalıyor.** CocoaPods yalnızca `printing` için ayakta.
> Flutter'ın CocoaPods desteği sürüyor; Ekim 2026 tarihi Firebase'e aitti ve o
> bağımlılık SPM'e taşındı. Bağımlılığı değiştirmek Faz 4'ün ekstre ekranını
> yeniden yazmak demekti; bu fazın "yeni özellik yok" kuralına takılıyor.
>
> `printing` ileride `Package.swift` yayınlarsa geçiş tek satırlık iş olur.
> O güne kadar `pod install` gerekli — bkz. README.

Kabul kriteri 3 bu karara göre aşağıda güncellendi.

---

## Şu anki hedef: önce TestFlight

Uygulama şimdilik yalnızca **TestFlight**'ta duracak; App Store gönderimi sonraya
bırakıldı. Bu, kalan işi ikiye ayırıyor:

| TestFlight için gerekli | App Store'a kalan |
|---|---|
| Bundle ID kaydı, dağıtım sertifikası | Ekran görüntüleri (6.9" iPhone + 13" iPad) |
| App Store Connect'te uygulama kaydı | Açıklama, anahtar kelimeler, kategori |
| Benzersiz build numarası (`1.0.0+4`) | Yaş sınırı ve fiyat beyanı |
| İhracat uygunluğu — `Info.plist` ile kapatıldı | Demo hesap (inceleme için) |
| Gizlilik politikası URL'si — **dış test** yaparsak | |

> **İç test** (kendi ekibinizdeki 100 kişiye kadar) Beta App Review istemez;
> ekran görüntüsü ve mağaza metni de gerekmez. **Dış test** açılırsa Beta App
> Review devreye girer ve gizlilik politikası URL'si zorunlu olur — `docs/`
> klasörü o an için hazır.

Yükleme:

```bash
flutter build ipa
# Çıktı: build/ios/ipa/FidanCari.ipa
# Xcode → Organizer ya da Transporter uygulamasıyla yüklenir.
```

Her yüklemede build numarası artmalı: `pubspec.yaml` → `version: 1.0.0+N`.

**Arşiv denendi ve çalışıyor** (12 Ağustos 2026): 29,8 MB IPA üretildi, imza
otomatik çözüldü.

| | |
|---|---|
| Takım | `XZU8N95T32` — **Hayrat Nesriyat** |
| Profil | `iOS Team Store Provisioning Profile: com.husrevkorpe.fidancari` |
| App ID | `XZU8N95T32.com.husrevkorpe.fidancari` (joker değil, açık kayıt) |
| Yöntem | `app-store-connect`, `get-task-allow: false` |
| Doğrulama | Sürüm 1.0.0 · Build 4 · Ad FidanCari · Hedef iOS 15.0 |

> **Karar gerekiyor:** uygulama şu an kurumsal **Hayrat Nesriyat** hesabı altında
> imzalanıyor. Mağazada satıcı adı olarak o görünür. Kişisel hesaptan
> yayınlanacaksa `DEVELOPMENT_TEAM` değiştirilip App ID yeniden kaydedilmeli —
> bu, TestFlight'a yüklemeden önce yapılırsa ucuz, sonra yapılırsa değil.

---

## Apple gereksinimleri

Bu bölüm tamamen hesap sahibinin elinde; kodla kapatılamaz.

- [x] Apple Developer Program üyeliği — takım `XZU8N95T32` (Hayrat Nesriyat)
- [x] Bundle ID kaydı: `com.husrevkorpe.fidancari` (arşiv sırasında otomatik
      oluştu, joker değil açık App ID)
- [x] Dağıtım sertifikası ve provisioning profili
- [ ] **App Store Connect'te uygulama kaydı** — App ID kaydı bunu kapsamıyor;
      panelde uygulama oluşturulmadan yükleme reddedilir

### Gizlilik — reddedilme sebebi olur

Uygulama Firestore'a kullanıcı verisi yazıyor ve hesap açtırıyor. Apple bunun için
beyan ve politika istiyor:

- [x] **Gizlilik politikası metni yazıldı** — `magaza/gizlilik-politikasi.md`
      (yayınlanabilir HTML: `docs/gizlilik.html`)
- [ ] Politika yayında bir URL'de (GitHub Pages: `Settings → Pages → main /docs`)
- [x] **App Privacy beyanı hazırlandı** — `magaza/app-store-metinleri.md`
      içindeki tablo panele birebir girilir
- [x] **Hesap silme yolu uygulama içinde** — Menü → Hesap → Hesabı sil

Hesap silme akışı (`lib/features/kimlik/`):

1. Şifreyle yeniden doğrulama — Firebase hassas işlemde yakın giriş ister,
   ayrıca bu adım çevrimdışıyken akışı hiçbir şey silinmeden durdurur.
2. `isletmeler/{uid}` ağacının tamamı silinir: işlemler → cariler → fidanlar →
   işletme profili (`IsletmeVerisiRepository`).
3. Firebase Auth kullanıcısı silinir.

Sıra bilinçli: hesap önce silinseydi Firestore kuralları yazma yetkisini geri
çeker ve arkada erişilemez veri kalırdı.

> Not: Hesap silme, muhasebe kaydının silinmemesi kuralıyla çelişmez. Kullanıcı
> kendi hesabını ve tüm verisini silebilir; kural, tek bir işlemin sessizce
> silinmemesiyle ilgilidir.

---

## Uygulama kimliği

- [x] Uygulama adı: **FidanCari**
- [x] İkon — tüm iOS boyutları, saydamlık yok, köşe yuvarlatma yok
- [x] Açılış ekranı (launch screen)
- [x] `Info.plist` görünen ad: `CFBundleDisplayName` = `FidanCari`
      (önceki değer `Muasebe` idi — ana ekranda yanlış ad görünüyordu)
- [x] Sürüm ve build numarası düzeni: `1.0.0+N`
- [x] `ITSAppUsesNonExemptEncryption = false` — her yüklemede ihracat uygunluğu
      sorusu sorulmasın diye

İkonun kaynağı `tool/ikon_uret.swift`. PNG'ler elle düzenlenmez; renk ya da
biçim değişince betik yeniden koşturulur:

```bash
swift tool/ikon_uret.swift
```

Betik 15 ikon boyutunu ve üç açılış görselini basar. Mağaza ikonunda alfa kanalı
bulunmaz (`noneSkipLast`) — alfalı ikon reddedilme sebebidir.

### App Store metinleri

Hepsi `magaza/app-store-metinleri.md` içinde hazır.

- [x] Uygulama açıklaması (Türkçe)
- [x] Anahtar kelimeler
- [x] Destek URL'si sayfası yazıldı (`docs/index.html`) — [ ] yayınlanmadı
- [x] Kategori: İş / Finans
- [x] Yaş sınırı beyanı: 4+
- [ ] **Ekran görüntüleri — TestFlight sonrasına ertelendi.** 6.9" iPhone seti
      zorunlu; iPad desteklendiği için 13" iPad seti de gerekir (ya da hedef
      aygıt ailesi iPhone'a çekilir). İç testte istenmiyor.

### İnceleme notu
Apple gözden geçirmeci hesap açıp uygulamayı denemek zorunda. Boş bir uygulama
görürlerse reddedebilirler.

- [x] İnceleme notu yazıldı (TR + EN)
- [ ] **Demo hesap — App Store gönderimine ertelendi.** İç TestFlight testinde
      inceleme yapılmadığı için gerekmiyor; dış test ya da mağaza gönderimi
      açılmadan önce örnek cari ve işlemle doldurulmalı.

---

## Yayın öncesi son kontrol

- [x] `flutter analyze` sıfır uyarı
- [x] `flutter test` tüm testler geçer (284 test)
- [x] `flutter build ios --release` başarılı
- [x] `flutter build ipa` başarılı — imzalı, App Store dağıtımına uygun
- [ ] Gerçek cihazda tam akış: kayıt → işletme bilgisi → cari → fatura → tahsilat → ekstre paylaş
- [ ] Uçak modunda veri girişi ve sonradan senkron
- [ ] Firestore güvenlik kuralları **canlıda** yayında ve test modu kapalı
- [x] Repoda gerçek müşteri verisi, IBAN veya kişisel bilgi yok
- [ ] Uygulama içinden hesap silme **cihazda** doğrulandı (kod yazıldı)
- [ ] TestFlight'ta en az bir dış test turu yapıldı

---

## Kabul kriterleri

1. Uygulama TestFlight'ta yüklenip çalışıyor
2. App Store Connect'te tüm zorunlu alanlar dolu
3. ~~SPM geçişi tamamlanmış, CocoaPods bağımlılığı kalmamış~~ →
   **Firebase SPM'e taşındı; CocoaPods yalnızca `printing` için ayakta.**
   Karar verildi, kriter bu hâliyle karşılanmış sayılır.
4. Gizlilik politikası yayında ve erişilebilir
5. Uygulama incelemeye gönderilmiş

---

## Riskler

- **Apple Developer hesabı onayı** birkaç gün sürebilir. Faz başında başvurulmalı.
- **Hesap silme özelliği** en sık atlanan reddedilme sebebi. ~~Kod gerektirir~~ →
  kod yazıldı, cihazda doğrulanması kaldı.
- ~~**SPM geçişi** derlemeyi kırabilir.~~ → Geçiş yapıldı, derleme çalışıyor.
- **Boş uygulama görüntüsü.** Demo hesap örnek veriyle dolu olmalı.
- **iPad ekran görüntüsü.** Uygulama iPad yönelimlerini de destekliyor; bu,
  ayrı bir ekran görüntüsü seti demek.
