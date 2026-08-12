# Faz 5 — Mağaza Hazırlığı

**Durum:** Başlanmadı
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

- [ ] Flutter'ın SPM desteğini etkinleştir
- [ ] Firebase bağımlılıklarını SPM üzerinden çöz
- [ ] `flutter build ios --release` başarılı
- [ ] Cihazda duman testi: giriş → cari → fatura → ekstre

---

## Apple gereksinimleri

- [ ] Apple Developer Program üyeliği (99 USD / yıl)
- [ ] Bundle ID kaydı: `com.husrevkorpe.fidancari`
- [ ] Dağıtım sertifikası ve provisioning profili
- [ ] App Store Connect'te uygulama kaydı

### Gizlilik — reddedilme sebebi olur

Uygulama Firestore'a kullanıcı verisi yazıyor ve hesap açtırıyor. Apple bunun için
beyan ve politika istiyor:

- [ ] **Gizlilik politikası** yayında bir URL'de (App Store Connect zorunlu alan)
- [ ] **App Privacy** beyanı: toplanan veri türleri (e-posta, kullanıcı içeriği)
- [ ] **Hesap silme yolu uygulama içinde** — Apple, hesap açtıran uygulamalarda
      uygulama içinden hesap silmeyi zorunlu tutuyor. Bu bir **koddur**, unutulursa reddedilir.

> Not: Hesap silme, muhasebe kaydının silinmemesi kuralıyla çelişmez. Kullanıcı
> kendi hesabını ve tüm verisini silebilir; kural, tek bir işlemin sessizce
> silinmemesiyle ilgilidir.

---

## Uygulama kimliği

- [ ] Uygulama adı belirlenir (öneri: **FidanCari**)
- [ ] İkon — tüm iOS boyutları, saydamlık yok, köşe yuvarlatma yok
- [ ] Açılış ekranı (launch screen)
- [ ] `Info.plist` görünen ad: `CFBundleDisplayName`
- [ ] Sürüm ve build numarası düzeni: `1.0.0+1`

### App Store metinleri
- [ ] Uygulama açıklaması (Türkçe)
- [ ] Anahtar kelimeler: fidan, fidancılık, cari hesap, ön muhasebe, ekstre
- [ ] Ekran görüntüleri — gerekli tüm cihaz boyutları
- [ ] Destek URL'si
- [ ] Kategori: İş / Finans
- [ ] Yaş sınırı beyanı

### İnceleme notu
Apple gözden geçirmeci hesap açıp uygulamayı denemek zorunda. Boş bir uygulama
görürlerse reddedebilirler.

- [ ] Demo hesap bilgisi verilir (içi örnek cari ve işlemle dolu)
- [ ] İnceleme notunda uygulamanın ne yaptığı Türkçe/İngilizce kısaca açıklanır

---

## Yayın öncesi son kontrol

- [ ] `flutter analyze` sıfır uyarı
- [ ] `flutter test` tüm testler geçer
- [ ] `flutter build ios --release` başarılı
- [ ] Gerçek cihazda tam akış: kayıt → işletme bilgisi → cari → fatura → tahsilat → ekstre paylaş
- [ ] Uçak modunda veri girişi ve sonradan senkron
- [ ] Firestore güvenlik kuralları **canlıda** yayında ve test modu kapalı
- [ ] Repoda gerçek müşteri verisi, IBAN veya kişisel bilgi yok
- [ ] Uygulama içinden hesap silme çalışıyor
- [ ] TestFlight'ta en az bir dış test turu yapıldı

---

## Kabul kriterleri

1. Uygulama TestFlight'ta yüklenip çalışıyor
2. App Store Connect'te tüm zorunlu alanlar dolu
3. SPM geçişi tamamlanmış, CocoaPods bağımlılığı kalmamış
4. Gizlilik politikası yayında ve erişilebilir
5. Uygulama incelemeye gönderilmiş

---

## Riskler

- **Apple Developer hesabı onayı** birkaç gün sürebilir. Faz başında başvurulmalı.
- **Hesap silme özelliği** en sık atlanan reddedilme sebebi. Kod gerektirir, son güne bırakılmaz.
- **SPM geçişi** derlemeyi kırabilir. Fazın başında yapılır ki düzeltmek için zaman kalsın.
- **Boş uygulama görüntüsü.** Demo hesap örnek veriyle dolu olmalı.
