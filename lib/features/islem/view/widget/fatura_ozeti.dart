import 'package:flutter/material.dart';

import '../../../../core/metin/metinler.dart';
import '../../../../core/para/kurus.dart';
import '../../../../core/para/para_bicimi.dart';

/// Faturanın genel toplamı.
///
/// Hesabı kendisi yapmaz; toplam domain katmanında `FaturaHesaplayici` ile
/// üretilir (bkz. KURALLAR.md §1.3).
class FaturaOzeti extends StatelessWidget {
  const FaturaOzeti({required this.toplam, super.key});

  final Kurus toplam;

  @override
  Widget build(BuildContext context) {
    final stil = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Metinler.genelToplam, style: stil),
            Text(toplam.bicimli, style: stil),
          ],
        ),
      ),
    );
  }
}
