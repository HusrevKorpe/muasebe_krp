import 'package:flutter/material.dart';

import '../../../app/tasarim/olculer.dart';
import '../../../app/tasarim/uygulama_isareti.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const UygulamaIsareti(),
              const SizedBox(height: Olculer.bosluk32),
              SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
