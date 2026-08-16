import 'package:flutter/material.dart';

import '../../../../app/tasarim/olculer.dart';

/// Ayarlar sayfasındaki tek satır: solda simge, ortada başlık ve açıklama,
/// sağda ok.
///
/// [onBasildi] `null` ise satır bilgi satırıdır — ok çizilmez, dokunma dalgası
/// olmaz. Oturum e-postası böyle: gösterilir ama gidilecek bir yer yoktur.
class AyarSatiri extends StatelessWidget {
  const AyarSatiri({
    required this.simge,
    required this.baslik,
    required this.onBasildi,
    this.aciklama,
    super.key,
  });

  static const double _kareBoyu = 40;

  final IconData simge;
  final String baslik;
  final String? aciklama;
  final VoidCallback? onBasildi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return InkWell(
      onTap: onBasildi,
      child: Padding(
        padding: const EdgeInsets.all(Olculer.bosluk16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: _kareBoyu,
              height: _kareBoyu,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tema.colorScheme.surfaceContainer,
                borderRadius: Olculer.koseOrta,
              ),
              child: Icon(
                simge,
                size: 20,
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: Olculer.bosluk16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(baslik, style: tema.textTheme.titleSmall),
                  if (aciklama != null) ...<Widget>[
                    const SizedBox(height: Olculer.bosluk4),
                    Text(
                      aciklama!,
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onBasildi != null) ...<Widget>[
              const SizedBox(width: Olculer.bosluk8),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
