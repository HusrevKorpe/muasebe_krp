import 'package:flutter/material.dart';

import '../../../core/metin/metinler.dart';

/// Saklanan oturum yüklenene kadar gösterilen ekran.
///
/// Firebase oturumu cihazda saklıyor ve açılışta asenkron yüklüyor; o kısa
/// sürede boş bir ekran ya da bir anlığına giriş ekranı göstermek yerine
/// burada bekleniyor. Karar verilecek bir şey yok, bu yüzden düğme de yok:
/// oturum varsa uygulama açılır, yoksa giriş ekranına düşülür.
class AcilisEkrani extends StatelessWidget {
  const AcilisEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final renkSemasi = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.park, size: 72, color: renkSemasi.primary),
              const SizedBox(height: 16),
              Text(
                Metinler.uygulamaAdi,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
