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
- [ ] Cihazda duman testi: açılış → cari → fatura → ekstre

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
| İhracat uygunluğu — `Info.plist` ile kapatıldı | Örnek veriyle dolu inceleme derlemesi |
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

> Derleme artık `--dart-define-from-file=gizli.json` istemiyor: sabit hesabın
> yerini kullanıcının girdiği e-posta/şifre aldı ve derlemeye gömülecek bir sır
> kalmadı (bkz. `fazlar/faz-0-iskelet.md` → "Revize 2"). Yani Xcode'dan
> doğrudan alınan arşiv de çalışır.

Her yüklemede build numarası artmalı: `pubspec.yaml` → `version: 1.0.0+N`.

**Arşiv denendi ve çalışıyor** (12 Ağustos 2026): 29,8 MB IPA üretildi, imza
otomatik çözüldü.

| | |
|---|---|
| Takım | `VJ96R83FLT` — **Muhammed Körpe** (kişisel) |
| Profil | `iOS Team Store Provisioning Profile: com.husrevkorpe.fidancari` |
| App ID | `VJ96R83FLT.com.husrevkorpe.fidancari` (joker değil, açık kayıt) |
| Yöntem | `app-store-connect`, `get-task-allow: false` |
| Doğrulama | Sürüm 1.0.0 · Build 4 · Ad FidanCari · Hedef iOS 15.0 |

> **Karar verildi (13 Ağustos 2026):** yayın kişisel hesaptan yapılacak.
> `DEVELOPMENT_TEAM` kurumsal **Hayrat Nesriyat** (`XZU8N95T32`) takımından
> kişisel takıma (`VJ96R83FLT`) alındı. İlk arşiv kurumsal takımla üretilmişti;
> App ID kişisel takım altında yeniden kaydedildi ve sertifika/profil sıfırdan
> üretilecek.

---

## Apple gereksinimleri

Bu bölüm tamamen hesap sahibinin elinde; kodla kapatılamaz.

- [x] Apple Developer Program üyeliği — takım `VJ96R83FLT` (Muhammed Körpe)
- [x] Bundle ID kaydı: `com.husrevkorpe.fidancari` (kişisel takım altında elle
      kaydedildi, joker değil açık App ID)
- [x] Dağıtım sertifikası ve provisioning profili
- [ ] **App Store Connect'te uygulama kaydı** — App ID kaydı bunu kapsamıyor;
      panelde uygulama oluşturulmadan yükleme reddedilir

### Gizlilik — reddedilme sebebi olur

Uygulama Firestore'a kullanıcı verisi yazıyor. Apple bunun için beyan ve
politika istiyor:

- [x] **Gizlilik politikası metni yazıldı** — `magaza/gizlilik-politikasi.md`
      (yayınlanabilir HTML: `docs/gizlilik.html`)
- [ ] Politika yayında bir URL'de (GitHub Pages: `Settings → Pages → main /docs`)
- [x] **App Privacy beyanı hazırlandı** — `magaza/app-store-metinleri.md`
      içindeki tablo panele birebir girilir
- [x] ~~**Hesap silme yolu uygulama içinde**~~ — **artık gerekmiyor**, aşağıya bak

#### Hesap silme neden kaldırıldı (13 Ağustos 2026)

Apple'ın hesap silme şartı (App Store Review Guideline 5.1.1(v)) **hesap
açtıran** uygulamalar içindir. Uygulama tek kişiye TestFlight'tan verilecek
şekilde sadeleştirildi: giriş ve kayıt ekranları kaldırıldı, oturum açılışta
derlemeye gömülü sabit hesapla sessizce açılıyor (bkz.
`fazlar/faz-0-iskelet.md` → "Revize"). Kullanıcı uygulama içinde hesap
oluşturmadığı için silme yükümlülüğü de doğmuyor.

Bununla birlikte kaldırılan kod: `lib/features/kimlik/` (giriş, kayıt, hesap,
hesap silme ekranları) ve `IsletmeVerisiRepository`. Kullanıcının verisini
silmesi gerekirse yol, gizlilik politikasındaki iletişim adresi üzerinden
talep etmek — konsoldan silinir.

> Not: Bu, mağazaya açık dağıtıma geçilirse **yeniden gerekli olur.** O gün
> giriş/kayıt akışı da geri gelmek zorunda olduğu için karar birlikte gözden
> geçirilir.

#### Güncelleme (13 Ağustos 2026): giriş geri geldi — açık uçlar

Uygulamaya e-posta/şifre giriş ekranı geri geldi (bkz.
`fazlar/faz-0-iskelet.md` → "Revize 2"). Bu, mağaza tarafında iki maddeyi
yeniden açar:

- **Hesap silme (5.1.1(v)).** Şart hâlâ tartışmalı: uygulama hesap
  *açtırmıyor* — kayıt ekranı yok, hesapları geliştirici konsoldan açıyor.
  Yine de artık görünür bir giriş formu var ve inceleyen kişi bunu hesap açma
  sanabilir. Reddedilirse en ucuz yanıt: ayarlara "verimi sil" akışı eklemek
  yerine gizlilik politikasındaki talep yolunu göstermek; ısrar ederse akış
  yazılır.
- **Demo hesabı.** Artık giriş ekranı görünüyor, yani App Review "Sign-in
  required" sorusuna **evet** işaretlenip inceleme hesabı verilmeli. Bunun için
  konsoldan bir e-posta/şifre hesabı açmak yeter.

İkisi de App Store gönderimini ilgilendiriyor; iç TestFlight testinde inceleme
yapılmadığı için o aşamada engel değil.

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
Apple gözden geçirmeci uygulamayı açıp denemek zorunda. Boş bir uygulama
görürlerse reddedebilirler.

- [x] İnceleme notu yazıldı (TR + EN)
- [ ] ~~**Demo giriş bilgisi gerekmiyor**~~ → **Gerekiyor.** Giriş ekranı
      göründüğü için panelde "Sign-in required" **evet** işaretlenir ve
      inceleme için konsoldan açılmış bir e-posta/şifre verilir.
- [ ] **Örnek veri — App Store gönderimine ertelendi.** İç TestFlight testinde
      inceleme yapılmadığı için gerekmiyor; dış test ya da mağaza gönderimi
      açılmadan önce uygulama örnek cari ve işlemle dolu olmalı.

---

## Yayın öncesi son kontrol

- [x] `flutter analyze` sıfır uyarı
- [x] `flutter test` tüm testler geçer (284 test)
- [x] `flutter build ios --release` başarılı
- [x] `flutter build ipa` başarılı — imzalı, App Store dağıtımına uygun
- [ ] Gerçek cihazda tam akış: giriş → cari → fatura → tahsilat → ekstre paylaş
- [ ] Uçak modunda veri girişi ve sonradan senkron
- [ ] Firestore güvenlik kuralları **canlıda** yayında ve test modu kapalı
- [x] Repoda gerçek müşteri verisi, IBAN veya kişisel bilgi yok
- [ ] Giriş **cihazda** doğrulandı: ilk giriş (internetli), ikinci açılış
      (uçak modunda — saklı oturumla açılmalı), çıkış yapıp yeniden giriş
- [ ] Yanlış şifre girilince "E-posta veya şifre hatalı." mesajı çıkıyor
- [ ] **İki hesapla** doğrulandı: ikinci telefonda diğer hesapla girilince aynı
      kayıtlar görünüyor
- [ ] Firebase Console → Authentication → Sign-in method: Email/Password
      **açık**, Google ve Anonymous **kapalı**
- [ ] Authentication → Settings → User actions → "Enable create (sign-up)"
      **kapalı**
- [ ] Authentication → Users altında kullanacak herkesin hesabı açık
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
- ~~**Hesap silme özelliği** en sık atlanan reddedilme sebebi.~~ → Uygulama hesap
  açtırmıyor, ama giriş formu görünür olduğu için inceleme yine takılabilir;
  bkz. yukarıdaki "Güncelleme (13 Ağustos 2026)".
- **Kayıt uç noktası açık kalırsa defter açıkta demektir.** Kural yalnızca
  "oturum açık mı" diye soruyor; Authentication → Settings → User actions →
  "Enable create (sign-up)" kapatılmazsa dışarıdan hesap açılıp veri okunabilir.
- ~~**SPM geçişi** derlemeyi kırabilir.~~ → Geçiş yapıldı, derleme çalışıyor.
- **Boş uygulama görüntüsü.** İnceleme öncesi uygulama örnek veriyle dolu olmalı.
- **iPad ekran görüntüsü.** Uygulama iPad yönelimlerini de destekliyor; bu,
  ayrı bir ekran görüntüsü seti demek.
