import 'package:flutter/material.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';

/// Veri yüklenemediğinde gösterilen ortak yerleşim.
class HataDurumu extends StatelessWidget {
  const HataDurumu({required this.mesaj, this.yenidenDene, super.key});

  /// Yakalanan hatadan kullanıcıya gösterilecek Türkçe mesajı çıkarır.
  ///
  /// Repository katmanı Firebase hatalarını [UygulamaHatasi]'na çeviriyor;
  /// buraya başka bir tip düşerse genel mesaj gösterilir — kullanıcıya İngilizce
  /// hata kodu gösterilmez.
  factory HataDurumu.hatadan(Object? hata, {VoidCallback? yenidenDene}) =>
      HataDurumu(
        mesaj: hata is UygulamaHatasi ? hata.mesaj : Metinler.beklenmeyenHata,
        yenidenDene: yenidenDene,
      );

  final String mesaj;
  final VoidCallback? yenidenDene;

  @override
  Widget build(BuildContext context) {
    final renkSemasi = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: renkSemasi.error),
            const SizedBox(height: 16),
            Text(
              mesaj,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (yenidenDene != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: yenidenDene,
                icon: const Icon(Icons.refresh),
                label: const Text(Metinler.yenidenDene),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
