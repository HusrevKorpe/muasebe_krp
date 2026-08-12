import 'package:flutter/material.dart';

/// Oturum durumu belirlenene kadar gösterilen ekran.
class AcilisEkrani extends StatelessWidget {
  const AcilisEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final renkSemasi = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.park, size: 72, color: renkSemasi.primary),
            const SizedBox(height: 16),
            Text(
              'FidanCari',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
