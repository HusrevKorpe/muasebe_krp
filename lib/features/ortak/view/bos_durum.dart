import 'package:flutter/material.dart';

import '../../../app/tasarim/olculer.dart';

/// Liste ve bölüm boş kaldığında gösterilen ortak yerleşim.
///
/// Simge çıplak durmuyor, soluk bir kutunun içinde: boş ekranda tek başına
/// duran büyük gri bir ikon "bir şey yüklenemedi" gibi okunuyordu. Kutu onu
/// bilinçli bir çizim hâline getiriyor.
class BosDurum extends StatelessWidget {
  const BosDurum({
    required this.simge,
    required this.baslik,
    required this.aciklama,
    this.eylem,
    super.key,
  });

  static const double _kutuBoyu = 76;

  final IconData simge;
  final String baslik;
  final String aciklama;

  /// İsteğe bağlı çağrı düğmesi — "Kişi Ekle" gibi.
  final Widget? eylem;

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
                color: tema.colorScheme.surfaceContainer,
                borderRadius: Olculer.koseBuyuk,
              ),
              child: Icon(
                simge,
                size: 34,
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Olculer.bosluk20),
            Text(
              baslik,
              textAlign: TextAlign.center,
              style: tema.textTheme.titleMedium,
            ),
            const SizedBox(height: Olculer.bosluk8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                aciklama,
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (eylem != null) ...<Widget>[
              const SizedBox(height: Olculer.bosluk24),
              eylem!,
            ],
          ],
        ),
      ),
    );
  }
}
