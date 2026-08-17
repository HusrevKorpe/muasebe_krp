import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/uygulama.dart';
import 'core/log/log.dart';
import 'data/tercih/tema_repository.dart';
import 'firebase_options.dart';

/// Uygulamayı yerel Firebase emulator'üne bağlar.
///
/// `flutter run --dart-define=EMULATOR=true` ile açılır. Canlı veriye
/// dokunmadan kayıt ve arama akışını denemek içindir; sürüm derlemesinde
/// tanımlanmadığı için etkisizdir.
///
/// Not: emulator kendi kullanıcı listesini tutar; canlı projedeki hesapla
/// giriş yapılamaz. Bu kiple denemek için emulator arayüzünden (localhost:4000)
/// bir e-posta/şifre hesabı açmak gerekir.
const bool _emulatorKullan = bool.fromEnvironment('EMULATOR');

const String _emulatorSunucusu = 'localhost';
const int _firestoreEmulatorKapisi = 8080;
const int _kimlikEmulatorKapisi = 9099;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (_emulatorKullan) {
    Log.uyari('Emulator kipi açık — canlı veriye bağlanılmıyor.');
    FirebaseFirestore.instance.useFirestoreEmulator(
      _emulatorSunucusu,
      _firestoreEmulatorKapisi,
    );
    await FirebaseAuth.instance.useAuthEmulator(
      _emulatorSunucusu,
      _kimlikEmulatorKapisi,
    );
  }

  // Çevrimdışı çalışma zorunlu: kullanıcı serada/tarlada internetsiz kalır.
  // Bkz. KURALLAR.md §4.4
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Tema tercihi cihazda duruyor ve ilk kare çizilmeden önce elde olmalı;
  // sonradan okunsaydı uygulama açık temayla açılıp bir kare sonra kararırdı.
  final tercihler = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      // Liste tipi yazılmıyor: riverpod `Override` sınıfını dışa aktarmıyor,
      // adı yazılamaz. Bağlamdan çıkarılıyor.
      overrides: [
        temaRepositorySaglayici.overrideWithValue(TemaRepository(tercihler)),
      ],
      child: const FidanCariUygulamasi(),
    ),
  );
}
