import 'package:flutter/material.dart';

import '../../../../app/tasarim/olculer.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../core/para/kurus.dart';
import '../../../../core/para/para_bicimi.dart';

/// Faturanın genel toplamı.
///
/// Hesabı kendisi yapmaz; toplam domain katmanında `FaturaHesaplayici` ile
/// üretilir (bkz. KURALLAR.md §1.3).
///
/// Beyaz karttan ayrılıyor: satırların altındaki toplam, kalem listesiyle aynı
/// zeminde durduğunda bir kalem satırı gibi okunuyordu.
class FaturaOzeti extends StatelessWidget {
  const FaturaOzeti({required this.toplam, super.key});

  final Kurus toplam;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Olculer.bosluk20,
        vertical: Olculer.bosluk16,
      ),
      decoration: BoxDecoration(
        color: tema.colorScheme.primaryContainer,
        borderRadius: Olculer.koseBuyuk,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            Metinler.genelToplam,
            style: tema.textTheme.titleSmall?.copyWith(
              color: tema.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: Olculer.bosluk12),
          Flexible(
            child: Text(
              toplam.bicimli,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: tema.textTheme.titleLarge?.copyWith(
                color: tema.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
