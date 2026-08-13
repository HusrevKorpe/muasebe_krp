import 'dart:convert';
import 'dart:io';

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

/// Test kullanıcılarının şifresi.
const String testSifresi = 'sifre123';

/// Her test için yeni bir kullanıcı açar ve `uid` değerini döner.
///
/// Testler birbirinin verisini görmesin diye her çağrı ayrı bir hesap üretir ve
/// dönen `uid` işletme kimliği olarak kullanılır. Kurallar artık sahiplik
/// aramıyor (defter ortak), ama ayrı kimlikler testleri birbirinden ayırmaya
/// yarıyor.
///
/// Kullanıcı öntanımlı olarak izin listesine de eklenir; [izinli] `false`
/// verilirse eklenmez ve kuralların onu geri çevirmesi sınanabilir.
///
/// Uygulamanın kendisi hesap açmaz — Google ile giriş yapar. Bu yardımcı
/// yalnızca testin veri izolasyonu için var; emulator'de sağlayıcı kısıtlaması
/// olmadığından burada e-posta/şifre ile hesap açılabiliyor.
Future<String> yeniKullaniciAc(
  FirebaseAuth kimlik, {
  bool izinli = true,
}) async {
  final benzersiz = DateTime.now().microsecondsSinceEpoch;
  final ePosta = 'test$benzersiz@fidancari.test';

  final sonuc = await kimlik.createUserWithEmailAndPassword(
    email: ePosta,
    password: testSifresi,
  );
  if (izinli) await izinListesineEkle(ePosta);

  return sonuc.user!.uid;
}

/// İzin listesine (`izinliler/{ePosta}`) bir e-posta ekler.
///
/// Bu koleksiyon istemciye kapalı — kural motoru dışında kimse okuyamaz, kimse
/// yazamaz (bkz. `firestore.rules`). Test onu [_yonetici] yoluyla doldurur.
/// Gerçek projede aynı işi Firebase Console yapıyor.
Future<void> izinListesineEkle(String ePosta) => _yonetici(
  'PATCH',
  '/v1/projects/$_projeKimligi/databases/(default)/documents/izinliler/$ePosta',
  govde: <String, Object?>{'fields': <String, Object?>{}},
);

/// Emulator'deki tüm Firestore verisini siler.
///
/// Ortak defter modelinde her test aynı yola (`isletmeler/ortak`) yazıyor;
/// önceki koşudan kalan kayıtlar "liste boş" beklentisini bozar. Bunu çağıran
/// test, silmeden **sonra** kullanıcısını açmalı — izin listesi de siliniyor.
Future<void> firestoreVerisiniSil() => _yonetici(
  'DELETE',
  '/emulator/v1/projects/$_projeKimligi/databases/(default)/documents',
);

String get _projeKimligi => DefaultFirebaseOptions.currentPlatform.projectId;

/// Emulator'e kuralları atlayarak istek gönderir.
///
/// `Authorization: Bearer owner` başlığıyla gelen istekleri emulator yönetici
/// sayar ve güvenlik kurallarını hiç değerlendirmez.
Future<void> _yonetici(
  String yontem,
  String yol, {
  Map<String, Object?>? govde,
}) async {
  final adres = Uri.parse(
    'http://$emulatorSunucusu:$firestoreEmulatorKapisi$yol',
  );

  final istemci = HttpClient();
  try {
    final istek = await istemci.openUrl(yontem, adres);
    istek.headers.set(HttpHeaders.authorizationHeader, 'Bearer owner');
    if (govde != null) {
      istek.headers.contentType = ContentType.json;
      istek.write(jsonEncode(govde));
    }

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
