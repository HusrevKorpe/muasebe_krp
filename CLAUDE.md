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
- **`firestore.rules` değiştiyse deploy et — commit yayın değildir.**
  Firestore sunucudaki son deploy'u uygular. Atlanırsa uygulama
  `permission-denied` verir ve hata kodda aranır, oysa kod doğrudur.
  Bkz. [KURALLAR.md §4.1](KURALLAR.md#41-güvenlik).
- `lib/domain/` **saf Dart** — Flutter importu yok.
- ViewModel'de `BuildContext` yok.
- **Muhasebe kaydı silinmez** — iptal işaretlenir veya ters kayıt atılır.
- Kod ASCII (`anac`, `cesit`), kullanıcıya görünen metin tam Türkçe (`Anaç`, `Çeşit`).
- Domain terimleri Türkçe kalır: `Cari`, `Bakiye`, `Tahsilat` — `Contact`, `Balance` değil.
- **Testler ana session'da koşturulmaz** — iş bitince `test-runner` subagent'ı çağrılır,
  sadece özet raporu beklenir. Bkz. [KURALLAR.md §5.0](KURALLAR.md#50-testleri-kim-çalıştırır).

## Fazlar

Sırayla ilerlenir. Bir faz, kendi dosyasındaki kabul kriterleri sağlanmadan kapatılmaz.

| Faz | Konu | Durum |
|---|---|---|
| [0](fazlar/faz-0-iskelet.md) | İskelet: klasör yapısı, tema, Riverpod, Auth, çekirdek yardımcılar | **Sürüyor** |
| [1](fazlar/faz-1-cari.md) | Cari: işletme profili, liste, arama, detay sayfası | **Sürüyor** |
| [2](fazlar/faz-2-islemler.md) | İşlemler: fatura, tahsilat, kalemler, yürüyen bakiye | **Sürüyor** |
| [3](fazlar/faz-3-katalog.md) | Fidan katalogu: Tür/Çeşit/Anaç/Yaş/Kök tipi, fiyat listesi | **Sürüyor** |
| [4](fazlar/faz-4-ekstre.md) | PDF ekstre: şablon, tarih aralığı, paylaşma | **Sürüyor** |
| [5](fazlar/faz-5-magaza.md) | Mağaza: ikon, gizlilik, SPM geçişi, TestFlight, App Store | **Sürüyor** |

Faz kapandığında bu tablodaki durumu ve ilgili faz dosyasının başlığındaki durumu güncelle.

## Komutlar

Not: `flutter analyze` ve `flutter test` **ana session'da çalıştırılmaz** —
`test-runner` subagent'ı çağrılır (KURALLAR.md §5.0). Aşağıdaki liste o ajanın
ve elle koşturmanın referansıdır.

```bash
flutter analyze                        # sıfır uyarı vermeli (test-runner koşturur)
flutter test                           # tüm testler geçmeli (test-runner koşturur)
flutter build ios --release            # faz kapanışında başarılı olmalı
flutter run                            # cihazda çalıştır

flutter build ipa                      # TestFlight'a giden derleme

firebase emulators:start --only firestore,auth   # repository testleri burada koşar
# Kural/index yayını — dosyayı DEĞİŞTİREN İŞİN PARÇASI, ayrı bir adım değil.
# Commit etmek yayınlamaz; atlanırsa uygulama permission-denied verir.
firebase deploy --only firestore:rules,firestore:indexes --project muasebe-takip

# Emulator'e bağlı testler (emulator ayakta olmalı, cihaz/simülatör gerekir)
flutter test integration_test -d <simulator-id>

# Uygulamayı canlı veriye dokunmadan denemek
flutter run --dart-define=EMULATOR=true

# Uygulama ikonunu ve açılış görselini yeniden üret (PNG'ler elle düzenlenmez)
swift tool/ikon_uret.swift
```

Not: `firebase-tools` Java 21+ istiyor. Homebrew'un kurduğu JDK 21
`/usr/libexec/java_home` listesine girmez (keg-only) ve `JAVA_HOME` vermek de
yetmez — `firebase` komutu `java`'yı `PATH`'ten bulur. Emulator'ü şöyle açın:

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"
firebase emulators:start --only firestore,auth
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
| Kullanım | **Ortak defter.** E-posta/şifreyle giren hesaplar (2 kişi) aynı veriyi görür |

## Klasör yapısı

```
lib/
├── app/           # Giriş, router
│   └── tasarim/   # Tasarım sistemi: renk, ölçü, tema, ortak bileşenler
├── core/          # Para, tarih, arama normalizasyonu, logger, hata
├── domain/        # Model + iş kuralları — saf Dart, testi zorunlu
├── data/          # Repository'ler, Firestore erişimi
└── features/
    └── <ozellik>/
        ├── view/
        └── viewmodel/

docs/              # GitHub Pages: destek sayfası ve gizlilik politikası
magaza/            # App Store Connect metinleri, gizlilik politikası kaynağı
tool/              # Varlık üreticileri (uygulama ikonu)
```

## Bilinmesi gerekenler

- **Referans ekstre:** `~/Desktop/Favori_Fidancılık_Ekstresi.pdf` — üreteceğimiz PDF'in
  hedefi bu. Kolonlar: İşlem Tarihi · Açıklama · Vade Tarihi · Borç · Alacak · Bakiye.
- **Görünüm kararları `lib/app/tasarim/` altında toplanır** (bkz.
  [KURALLAR.md §2.0](KURALLAR.md#20-tasarım-sistemi)). Palet "Toprak Yeşili +
  Krem": ekran zemini krem, kartlar beyaz, ayrım gölgeyle değil ince kenarla
  yapılıyor; iki renk şeması da elle yazılı, `fromSeed` kullanılmıyor. Ekranlar
  ham `FilledButton`/`TextButton` yazmaz — `Dugme`, `SimgeDugmesi`, `YuzenDugme`
  ve `AramaAlani` bileşenleri kullanılır. Borç kırmızı / alacak yeşil ayrımı
  paletin dışında, `Renkler.borc` ve `Renkler.alacak` üzerinden gelir: o bir
  marka tercihi değil, muhasebe anlamı.
- **`!semantics.parentDataDirty` görülünce erişilebilirlik katmanına bakma —
  o hata artçı.** Konsolda binlerce kere tekrar ettiği için asıl hata gibi
  duruyor; oysa zincir şöyle: bir yerde `performLayout` patlıyor → alt ağaç
  boyutsuz kalıyor (`hasSize` hataları) → boyutlanmamış düğümlerin parent
  data'sı temizlenemediği için `flushSemantics` her karede bu assertion'ı
  atıyor. **Konsolu yukarı kaydırıp ilk exception'ı bul**, düzeltilecek olan o.
  Bu projede görülen hâli: `Row(crossAxisAlignment: CrossAxisAlignment.stretch)`
  yüksekliği sınırsız bir bağlamdaydı (`Column`un esnek olmayan çocuğu) ve
  "BoxConstraints forces an infinite height" veriyordu — çare `IntrinsicHeight`
  (bkz. `AcikHesapOzetiKarti`). `Column` içindeki stretch güvenli, `Row`
  içindeki değil: birinin ekseni yatay ve sınırlı, ötekinin dikey ve sınırsız.
- **Vergi hesabı yok.** Fatura toplamı kalem tutarlarının toplamıdır. Referans
  ekstredeki bir faturada %1 vergi görünüyor; öyle bir satır gerekirse "nakliye"
  gibi serbest metin kalemi olarak girilir.
- **Bir cari hem müşteri hem tedarikçi olabilir.** Fidancılıkta alım-satım aynı kişiyle yapılır.
- **Kişiler müşteri/fidancı diye ikiye ayrılıyor — ama yalnızca listede.**
  `Cari.grup` (`CariGrubu`) tek bir alandır; fatura, tahsilat, bakiye ve ekstre
  iki grupta birebir aynı işler. Sebep kullanıcının kendi tarifi: fidancı
  meslektaşlarla sürekli karşılıklı alışveriş var, sıradan müşteriyle bir
  kerelik satış; ikisi tek listede karışınca sürekli çalıştığı 15 kişi
  yüzlerce müşterinin arasında aranıyordu. Bir kişi tek gruba ait — hem müşteri
  hem fidancı olmaz.
  - **Eski kayıtlarda `grup` alanı yok ve göç scripti yazılmadı.** Okurken eksik
    alan `musteri` sayılıyor, ama `grup == 'musteri'` **sorgusu yazılamaz**:
    Firestore'un eşitlik süzgeci alanı olmayan belgeyi eşleştirmez ve o sorgu
    bu özellikten önce kaydedilmiş herkesi listeden düşürürdü. Bu yüzden
    sunucuda yalnızca fidancı listesi süzülüyor (`aktif + grup + aramaAnahtari`
    index'i), müşteri listesi elde ayıklanıyor (`CariSuzgeci.kayitGirerMi`).
    Elde ayıklanan sayfa ekranı doldurmayabildiği için liste kaydırılamaz
    kalırsa sonraki sayfa kendiliğinden isteniyor.
- **"Hesap görme" bakiyeyi kapatan bir işlem tipidir, tahsilat değil.**
  Kullanıcının tarifi: *"adamın bana 105.000 borcu var, 100.000'e düzlüyor;
  100.000 aldıktan sonra hesap kapandı."* Tahsilat normal yoldan girilir, kalan
  fark kişi sayfasının menüsündeki "Hesabı gör" ile kapanır. Tutar formdan
  gelmez, o anki bakiyeden türetilir (`Islem.hesapGorme`). İki tip var
  (`hesapGorulduAlacak` / `hesapGorulduBorc`) çünkü `IslemTipi.borcMu` tipin
  sabiti, yön ise bakiyenin işaretine bağlı; kullanıcıya ikisi de "Hesap
  görüldü" görünür. Kayıt **düzenlenmez** — tutarı elle değişirse bakiye sıfırda
  kalmaz; geri alma yolu iptaldir.
- **Kayıtlı işlem düzenlenebilir, ama silinemez.** Fiyat satışın ardından
  pazarlıkla değişiyor; geçmiş satışın fiyatı, adedi, tarihi ve açıklaması
  işlem detayındaki kalem düğmesinden düzeltilir (`IslemRepository.guncelle`).
  Aynı belge güncellenir — kimlik, oluşturma tarihi ve iptal alanları yerinde
  kalır; bakiyeye `yeni − eski` farkı aynı batch içinde `increment` ile işlenir
  ve `guncellemeTarihi` iz bırakır ("Son düzenleme" satırı). İptalli kayıt
  düzenlenmez, işlem tipi değiştirilmez. Faz 2'de bu yol bilerek yazılmamıştı;
  karar kullanıcı isteğiyle döndü (bkz. `fazlar/faz-2-islemler.md` → Düzenleme).
- **Fidan kimliği üç ayrı alandır:** Tür → Çeşit → Anaç. Hem ürün katalogunda
  (`Urun`) hem fatura satırında (`IslemKalemi`) üçü **ayrı** saklanır ve kullanıcı
  üçünü ayrı kutulara girer. Faturaya yazılan ad üçünden türetilir
  (`urunAdi()` → `Elma Scarlet M9`); ayrı bir "ad" alanı modelde yoktur.
  Yalnızca tür zorunlu — "nakliye" gibi kalemlerde çeşit ve anaç boş kalır.
  Firestore'a `tur`/`cesit`/`anac` yanında türetilmiş `ad` de yazılır: hem
  konsolda okunurluk için hem de göç işareti olarak (bkz. `Urun.alanAd`).
- **Katalog üç şema gördü, üçü de okunuyor**, göç scripti yok:
  ilk hâli beş alan (tür, çeşit, anaç, yaş, kök tipi), sonra tek serbest `ad`,
  bugün yeniden üç alan. Ayrım `tur` ve `ad` alanlarının varlığına bakılarak
  yapılıyor (`Urun.fromMap`, `eskiFidanEki`). Yaş ve kök tipinin bugünkü şemada
  karşılığı yok; ilk şemadan okunurken anacın ardına ekleniyor.
- **Katalog zorunlu değil.** Fatura kalemi katalogdan seçilebilir, ama serbest
  giriş kaldırılmaz — "nakliye" gibi kalemler katalogda yer almaz.
  Katalogdan seçilen kalem `fidanId` taşır; serbest kalemde bu alan boştur.
- **Tür, çeşit ve anacın kendi listeleri var** (`lib/domain/secenek/`).
  Katalogdaki ürün *tam kombinasyondur* (`Elma Scarlet M9`); kombinasyon sayısı
  üç alanın çarpımı kadar olduğu için kullanıcı hepsini ürün olarak giremiyor,
  pratikte üç kutuyu her satışta elle yazıyordu. Kullanıcının isteği: *"anaçları
  bir kere gireyim, tıkla tıkla vereyim."* Bu yüzden üç küçük liste var; her
  kimlik kutusunun sağındaki düğme kendi listesini açıyor, hem fatura kaleminde
  hem ürün formunda. Ürün katalogu **kalkmadı** — fiyat ön dolgusunu ve
  `fidanId` bağını yalnızca o veriyor. Üçü de zorunlu değil, kutular serbest
  metin olarak kalıyor.
  - Listeler `isletmeler/ortak/{turler|cesitler|anaclar}` altında, **tip alanı
    yok** — koleksiyon adı taşıyor. Tek koleksiyon + `tip` alanı olsaydı liste
    sorgusu bileşik index isterdi; bu şemada Firestore'un tek alan için
    kendiliğinden ürettiği index yetiyor ve `firestore.indexes.json` hiç
    değişmedi.
  - **Bu listelerde silme var, pasife alma yok.** Cari/işlem/üründe silme yok
    çünkü onlara kimlikle bağlı geçmiş kayıtlar var; burada yok — kalem, seçilen
    satırın kimliğini değil metnini kopyalıyor. Yanlış yazılmış bir anaç
    listeden temizlenebilmeli.
  - Ekranı Ayarlar → Listeler açıyor. Seçim sayfasındaki "Listeye Ekle"
    düğmesiyle eklenen ad doğrudan kutuya düşüyor: kullanıcı aradığını
    bulamadığında ekleyip bir de listeden seçmek zorunda kalmasın.
- **PDF ekstrede alacak satırları açık yeşil zeminde basılır** — tahsilat ve
  alış faturası, yani kullanıcının deyişiyle "para aldığım ve fidan aldığım"
  satırlar. Ölçüt tip listesi değil, alacak kolonundaki tutar: iptalli kayıt
  zeminsiz kalır (`ekstreAlacakSatiriMi`).
- **Firebase SPM'e taşındı** (Faz 5). `firebase-ios-sdk` artık Swift Package
  Manager üzerinden geliyor; CocoaPods'un Ekim 2026 riski kapandı. Geriye tek
  eklenti kaldı: `printing` henüz `Package.swift` yayınlamıyor, o yüzden
  `Podfile` duruyor. `pod install` hâlâ gerekli.
- **iOS derlemesi terminalden başlatılır — Xcode'da Build'e basılmaz.**
  `flutter pub get` (ve onu tetikleyen `flutter test`, `flutter analyze`,
  pubspec kaydı) `Flutter/ephemeral/.../FlutterGeneratedPluginSwiftPackage/Package.swift`
  dosyasını **her seferinde** Flutter'ın sabiti olan `.iOS("13.0")` ile yeniden
  üretir; projenin 15.0'ına yükseltme yalnızca `flutter run` / `flutter build ios`
  yolunda yapılır (`flutter_tools/.../ios/mac.dart`, `updateMinimumDeployment`).
  Xcode'dan Build'e basılırsa o adım çalışmaz ve Firebase paketleri
  "requires minimum platform version 15.0" hatası verir. Scheme'deki
  "Fix Generated Swift Package iOS Deployment Target" pre-action'ı manifestoyu
  düzeltir ama Xcode paket grafiğini **ondan önce** çözdüğü için o build'i
  kurtaramaz — sadece bir sonrakini. Bu yüzden: cihaza `flutter run`,
  TestFlight'a `flutter build ipa`. Xcode'da build şartsa önce
  `flutter build ios --config-only` çalıştırılır.
- **E-posta/şifre ile giriş, ortak defter.** Uygulamayı iki kişi kullanıyor ve
  ikisi de **aynı** veriyi görüyor. Bu yüzden veri `isletmeler/{uid}` altında
  değil, sabit `isletmeler/ortak` altında (`Isletme.ortakId`).
  Giriş ekranı e-posta ve şifre sorar (`KimlikRepository.girisYap`); Firestore
  kuralı yalnızca "oturum açık mı" diye bakar (`request.auth != null`).
  **Uygulama hesap açmaz:** kayıt ekranı, şifre sıfırlama ve hesap silme yok.
  Kişi eklemek/çıkarmak Firebase Console → Authentication → Users işidir; kod
  değişikliği ya da yeni derleme gerekmez.
  **Manuel adımlar:** Authentication → Sign-in method → Email/Password açık,
  diğerleri kapalı; Settings → User actions → "Enable create (sign-up)" **kapalı**
  (açık kalırsa dışarıdan hesap açılıp deftere girilebilir); Users → Add user
  ile kullanacak kişilerin hesapları.
- **`permission-denied` görülünce koda bakma — iki sebebi var, ikisi de kodun
  dışında.** Sırayla ele:
  1. **Kural yayınlanmamış olabilir.** `firebase deploy --only firestore:rules`
     çalıştır. Çıktı `already up to date, skipping upload` diyorsa kural zaten
     yayındaydı ve sebep bu değil; 2. maddeye geç. Aynı tuzağın index hâli
     `failed-precondition: The query requires an index` diye görünür.
  2. **Cihazdaki oturum geçersiz olabilir — ama uygulama "girişli" görünür.**
     Firebase Auth kullanıcıyı cihazda saklar ve açılışta **ağa hiç sormadan**
     yayar. `oturumSaglayici` dolu bir `User` verir, yönlendirici kullanıcıyı
     içeri alır, ama Firestore'a giden istekte geçerli jeton yoktur: sunucu
     `request.auth`'u boş görür ve kural haklı olarak reddeder. Giriş ekranı
     görünmediği için sorun veri katmanında sanılır. **Çözüm: çıkış yapıp
     yeniden giriş.** Bu projede özellikle muhtemel, çünkü `6df15da` girişi
     Google'dan e-posta/şifreye çevirdi ve Google sağlayıcısının kapatılmasını
     şart koştu; o commit'ten önce açılmış bir Google oturumu cihazda kalmışsa
     jetonu artık tazelenemez.
  Kural ve teşhis tablosu: [KURALLAR.md §4.1](KURALLAR.md#41-güvenlik).
- **İşletme profili zorunlu değil.** Eskiden ilk açılışta doldurulması gereken
  bir kurulum ekranı vardı; kaldırıldı. Profil yalnızca PDF ekstre başlığını
  besliyor, boşsa başlık sade çıkar. Ayarlar → İşletme bilgileri'nden istendiği
  zaman doldurulur.
- **Tema kullanıcının seçimi; `ThemeMode.system` kullanılmıyor.** Ayarlar →
  Görünüm'deki anahtar açık ve koyu arasında geçiyor, üçüncü bir "sisteme uy"
  seçeneği yok — kullanıcı temayı sabitlemek istedi, tek anahtar da o yüzden
  yetiyor (`TemaTercihi`). Seçim **cihaza** yazılıyor (`shared_preferences`,
  `data/tercih/tema_repository.dart`), ortak deftere değil: defteri iki kişi
  paylaşıyor ama telefonu paylaşmıyorlar. Tercih ilk kare çizilmeden önce
  gerektiği için `main()` depoyu açıp `temaRepositorySaglayici`'yı override
  ediyor; sağlayıcının kendisi override edilmezse hata atar. Bu yüzden
  uygulamayı `main()` olmadan kuran her test aynı override'ı vermek zorunda —
  `integration_test/emulator_yardimcilari.dart` içindeki
  `uygulamaDegisiklikleri()` bunun içindir.
- **Çevrimdışı yazma:** Repository'ler `set`/`update` future'ını **beklemez**.
  Firestore çevrimdışıyken bu future yalnızca sunucu onayında tamamlanır;
  beklenirse uçak modunda ekran kilitlenir. Yerel yazma anında görünür, kayıt
  `hasPendingWrites` ile "Kaydedilmedi" olarak işaretlenir.
- **Listeler canlı akış, tek seferlik okuma değil.** Cari, işlem ve ürün
  listeleri `snapshots()` dinler (`listeyiIzle`). `get()` sunucuya gidip cevabını
  bekler ve bağlantı yavaşken dakikalarca dönebilir; akış önce önbellekten
  anında yayar. Bu yüzden kaydettikten sonra liste `invalidate` edilmez —
  kendiliğinden güncellenir, ortak defterin öteki telefonundan girilen kayıt da
  düşer. Sayfalama imleçle değil sorgunun sınırı büyütülerek yapılır
  (`AkisListesiViewModel`). Tek istisna PDF ekstre: eksik geçmişten yanlış
  açılış bakiyesi çıkmasın diye bilerek sunucuyu bekler.
- **Ekran sağlayıcıları çıkışta hemen atılmaz.** `birSureSakla` (5 dakika)
  listeyle detay arasındaki gidiş gelişi spinner'sız yapar; süre sonunda
  Firestore dinleyicisi kapanır.
- **Kişiler ekranı üç sekme: "Müşteriler", "Fidancılar" ve "Açık Hesaplar".**
  İlk ikisi kişileri grubuna göre ayırır (yukarıdaki maddeye bkz.).
  Açık hesap ölçütü `bakiyeKurus != 0` — yön ayrımı yok, hem bize borçlu olan hem borçlu olduğumuz
  cari listeye girer ve iki grup birlikte gelir (`CariSuzgeci`); fidancı
  satırları orada küçük bir rozetle ayrışır. Sıralama bakiyeye göre azalan:
  Firestore aralık süzgeci uygulanan alanı ilk sıralama ölçütü olmaya zorluyor, en borçlu
  zaten başta olmalı. **Aynı sebeple o sekmede arama kutusu yok** — ikinci bir
  aralık süzgeci (`aramaAnahtari`) aynı sorguda sıralanamaz; aranan kişinin
  bakiyesi kendi grup sekmesindeki satırında zaten yazıyor. Yeni index gerekmedi,
  sorgu mevcut `aktif + bakiyeKurus DESC` index'ine oturuyor.
  Sekmenin başındaki alacak/borç toplamı **yüklenmiş kayıtlardan** hesaplanır
  (`AcikHesapOzeti`); sunucuda toplama (`aggregate`) çevrimdışı çalışmadığı için
  tercih edilmedi, onun yerine o sekmenin sayfa boyu 100'e çıkarıldı ve toplam
  eksikse satırın altında söyleniyor.
- **Firestore metin araması öntakıyla sınırlı.** `aramaAnahtari` alanı adın
  normalize hâlini tutar; "koyuncu" yazarak "Ahmet Koyuncu" bulunamaz. Cari
  sayısı birkaç bini geçerse ayrı arama çözümü gerekir.
