import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fidancari/app/uygulama.dart';
import 'package:fidancari/data/tercih/tema_repository.dart';
import 'package:fidancari/firebase_options.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Emulator'e bağlı testler için ortak kurulum.
///
/// Canlı veritabanıyla test yapılmaz (KURALLAR.md §5.1). Bu testleri koşmadan
/// önce emulator ayakta olmalı:
///
/// ```bash
/// firebase emulators:start --only firestore,auth
/// flutter test integration_test --device-id <simulator-id>
/// ```
///
/// Not: emulator bileşik index aramaz, otomatik üretir. `firestore.indexes.json`
/// içindeki tanımların doğruluğu burada değil, canlı projede doğrulanır.
const String emulatorSunucusu = 'localhost';
const int firestoreEmulatorKapisi = 8080;
const int kimlikEmulatorKapisi = 9099;

/// Sunucuya yazma onayını beklerken denenecek en fazla süre.
const Duration _sunucuBeklemeSuresi = Duration(seconds: 10);
const Duration _yoklamaAraligi = Duration(milliseconds: 100);

/// Firebase'i başlatır ve emulator'e yönlendirir. Testte bir kez çağrılır.
///
/// Yerel önbellek de siliniyor: liste ekranları artık `snapshots()` dinliyor ve
/// akışın ilk yayını önbellekten geliyor. [firestoreVerisiniSil] emulator'ü
/// yönetici olarak boşaltır ama istemcinin diskteki kopyasından haberi olmaz;
/// temizlenmezse önceki koşunun kayıtları bir kare boyunca ekranda görünür.
/// Çağrı, istemci ilk okumasını yapmadan **önce** olmak zorunda.
Future<void> emulatoreBaglan() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.useFirestoreEmulator(
    emulatorSunucusu,
    firestoreEmulatorKapisi,
  );
  await FirebaseFirestore.instance.clearPersistence();
  await FirebaseAuth.instance.useAuthEmulator(
    emulatorSunucusu,
    kimlikEmulatorKapisi,
  );
}

/// Uygulamayı `pumpWidget`'e verilecek hâliyle kurar.
///
/// `main()` tema deposunu açıp `temaRepositorySaglayici` üzerine enjekte
/// ediyor; testte `main()` çalışmadığı için aynı kurulum burada yapılır.
/// Depo boş açılıyor: her koşu varsayılan (açık) temayla başlasın, önceki
/// koşuda seçilmiş bir tema testi değiştirmesin.
///
/// Değişiklik listesini değil kurulmuş widget'ı döndürüyor: riverpod `Override`
/// sınıfını dışa aktarmıyor, o yüzden `List<Override>` bir imzada yazılamıyor.
Future<Widget> uygulamayiKur() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final tercihler = await SharedPreferences.getInstance();

  return ProviderScope(
    overrides: [
      temaRepositorySaglayici.overrideWithValue(TemaRepository(tercihler)),
    ],
    child: const FidanCariUygulamasi(),
  );
}

/// Test kullanıcılarının şifresi.
const String testSifresi = 'sifre123';

/// Her test için yeni bir kullanıcı açar ve `uid` değerini döner.
///
/// Testler birbirinin verisini görmesin diye her çağrı ayrı bir hesap üretir ve
/// dönen `uid` işletme kimliği olarak kullanılır. Kurallar artık sahiplik
/// aramıyor (defter ortak), ama ayrı kimlikler testleri birbirinden ayırmaya
/// yarıyor.
///
/// Gerçek projede hesabı Firebase Console açıyor; uygulamanın kendisi hesap
/// açmıyor. Emulator'de konsol olmadığı için test hesabı burada açılıyor.
Future<String> yeniKullaniciAc(FirebaseAuth kimlik) async {
  final benzersiz = DateTime.now().microsecondsSinceEpoch;

  final sonuc = await kimlik.createUserWithEmailAndPassword(
    email: 'test$benzersiz@fidancari.test',
    password: testSifresi,
  );

  return sonuc.user!.uid;
}

/// Emulator'deki tüm Firestore verisini siler.
///
/// Ortak defter modelinde her test aynı yola (`isletmeler/ortak`) yazıyor;
/// önceki koşudan kalan kayıtlar "liste boş" beklentisini bozar.
Future<void> firestoreVerisiniSil() => _yonetici(
  'DELETE',
  '/emulator/v1/projects/$_projeKimligi/databases/(default)/documents',
);

String get _projeKimligi => DefaultFirebaseOptions.currentPlatform.projectId;

/// Emulator'e kuralları atlayarak istek gönderir.
///
/// `Authorization: Bearer owner` başlığıyla gelen istekleri emulator yönetici
/// sayar ve güvenlik kurallarını hiç değerlendirmez.
Future<void> _yonetici(String yontem, String yol) async {
  final adres = Uri.parse(
    'http://$emulatorSunucusu:$firestoreEmulatorKapisi$yol',
  );

  final istemci = HttpClient();
  try {
    final istek = await istemci.openUrl(yontem, adres);
    istek.headers.set(HttpHeaders.authorizationHeader, 'Bearer owner');

    final yanit = await istek.close();
    final cevap = await yanit.transform(utf8.decoder).join();
    if (yanit.statusCode != HttpStatus.ok) {
      fail('Emulator isteği başarısız ($yontem $yol → ${yanit.statusCode}): '
          '$cevap');
    }
  } finally {
    istemci.close();
  }
}

/// Canlı liste akışından, [kosul] sağlanan ilk sayfayı döner.
///
/// Akış önce yerel önbellekten yayar; testteki yazmalar `sunucudaBekle` ile
/// onaylandığı için o ilk yayın da doludur. Yine de sayfa sayfa beklemek testi
/// yayın sırasına bağımlı olmaktan kurtarır: kayıt sonradan düşse de sınama
/// bunu görür, koşulsuz `first` ise erken yayını yakalayıp kırılırdı.
Future<S> sayfayiBekle<S>(
  Stream<S> akis, {
  required bool Function(S sayfa) kosul,
}) {
  return akis.firstWhere(kosul).timeout(
    _sunucuBeklemeSuresi,
    onTimeout: () => fail('Akış beklenen sayfayı yaymadı.'),
  );
}

/// Belge sunucuya yazılana kadar bekler.
///
/// Repository yazma future'ını bilerek beklemiyor (çevrimdışı çalışabilmek
/// için); testin sunucu durumunu görmesi gerektiğinden burada yoklama yapılır.
Future<DocumentSnapshot<Map<String, dynamic>>> sunucudaBekle(
  DocumentReference<Map<String, dynamic>> belge, {
  bool Function(Map<String, dynamic> veri)? kosul,
}) async {
  final biti = DateTime.now().add(_sunucuBeklemeSuresi);

  while (DateTime.now().isBefore(biti)) {
    final anlik = await belge.get(const GetOptions(source: Source.server));
    if (anlik.exists && (kosul == null || kosul(anlik.data()!))) {
      return anlik;
    }
    await Future<void>.delayed(_yoklamaAraligi);
  }

  fail('Belge beklenen durumda sunucuya yazılmadı: ${belge.path}');
}

/// Belge sunucudan silinene kadar bekler — [sunucudaBekle]'nin tersi.
///
/// Silme future'ı da beklenmiyor (KURALLAR.md §4.4); silmenin sunucuya
/// ulaştığını sınayan testler bunu kullanır.
Future<void> sunucudanSilinmeyiBekle(
  DocumentReference<Map<String, dynamic>> belge,
) async {
  final biti = DateTime.now().add(_sunucuBeklemeSuresi);

  while (DateTime.now().isBefore(biti)) {
    final anlik = await belge.get(const GetOptions(source: Source.server));
    if (!anlik.exists) return;
    await Future<void>.delayed(_yoklamaAraligi);
  }

  fail('Belge sunucudan silinmedi: ${belge.path}');
}
