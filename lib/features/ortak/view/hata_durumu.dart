import 'package:flutter/material.dart';

import '../../../app/tasarim/dugme.dart';
import '../../../app/tasarim/olculer.dart';
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

  static const double _kutuBoyu = 76;

  final String mesaj;
  final VoidCallback? yenidenDene;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Olculer.bosluk32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: _kutuBoyu,
              height: _kutuBoyu,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tema.colorScheme.errorContainer,
                borderRadius: Olculer.koseBuyuk,
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 34,
                color: tema.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: Olculer.bosluk20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                mesaj,
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyLarge,
              ),
            ),
            if (yenidenDene != null) ...<Widget>[
              const SizedBox(height: Olculer.bosluk24),
              Dugme.ikincil(
                metin: Metinler.yenidenDene,
                simge: Icons.refresh,
                onBasildi: yenidenDene,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
