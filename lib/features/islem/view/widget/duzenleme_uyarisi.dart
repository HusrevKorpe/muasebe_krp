import 'package:flutter/material.dart';

import '../../../../core/metin/metinler.dart';

/// Kayıtlı bir işlem düzenlenirken formun başında duran not.
///
/// Değişiklik bakiyeye anında yansıyor ve müşteriye daha önce gönderilmiş PDF
/// ekstre bu kaydı eski hâliyle gösteriyor olabilir. Kullanıcı düzeltmeyi
/// yaparken bunu bilmeli — uyarı engellemez, hatırlatır.
class DuzenlemeUyarisi extends StatelessWidget {
  const DuzenlemeUyarisi({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: tema.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              Metinler.islemDuzenlemeUyarisi,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
