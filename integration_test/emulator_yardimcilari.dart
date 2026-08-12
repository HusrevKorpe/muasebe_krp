import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fidancari/firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';

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
Future<void> emulatoreBaglan() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.useFirestoreEmulator(
    emulatorSunucusu,
    firestoreEmulatorKapisi,
  );
  await FirebaseAuth.instance.useAuthEmulator(
    emulatorSunucusu,
    kimlikEmulatorKapisi,
  );
}

/// Her test için yeni bir kullanıcı açar ve `uid` değerini döner.
///
/// Testler birbirinin verisini görmesin diye her çağrı ayrı bir hesap üretir;
/// `uid` aynı zamanda işletme kimliği olduğu için veri de izole olur.
Future<String> yeniKullaniciAc(FirebaseAuth kimlik) async {
  final benzersiz = DateTime.now().microsecondsSinceEpoch;
  final sonuc = await kimlik.createUserWithEmailAndPassword(
    email: 'test$benzersiz@fidancari.test',
    password: 'sifre123',
  );
  return sonuc.user!.uid;
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
