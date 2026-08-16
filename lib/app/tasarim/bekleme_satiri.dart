import 'package:flutter/material.dart';

import '../../core/metin/metinler.dart';
import 'olculer.dart';

/// Sunucuya henüz yazılmamış kaydın göstergesi — liste satırlarının alt yazısı.
///
/// Kişi, ürün ve seçenek satırlarında birbirinin kopyası üç tane vardı
/// (bkz. KURALLAR.md §4.4). Tek yerden geldiğinde "kaydedilmedi" her listede
/// aynı renkte ve aynı boyda görünüyor.
class BeklemeSatiri extends StatelessWidget {
  const BeklemeSatiri({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Row(
      children: <Widget>[
        Icon(
          Icons.cloud_upload_outlined,
          size: 14,
          color: tema.colorScheme.tertiary,
        ),
        const SizedBox(width: Olculer.bosluk4),
        Flexible(
          child: Text(
            Metinler.kaydedilmedi,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.tertiary,
            ),
          ),
        ),
      ],
    );
  }
}
