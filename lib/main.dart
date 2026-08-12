import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FidanCariApp());
}

class FidanCariApp extends StatelessWidget {
  const FidanCariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FidanCari',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      ),
      home: const FirebaseStatusPage(),
    );
  }
}

/// Geçici ekran: Firebase bağlantısının kurulduğunu doğrular.
/// Faz 1'de gerçek cari listesiyle değiştirilecek.
class FirebaseStatusPage extends StatelessWidget {
  const FirebaseStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Firebase.app();
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Bağlantısı')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 72, color: Colors.green),
            const SizedBox(height: 16),
            Text('Proje: ${app.options.projectId}'),
            Text('Uygulama: ${app.options.appId}'),
          ],
        ),
      ),
    );
  }
}
