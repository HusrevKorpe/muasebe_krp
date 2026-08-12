import 'package:flutter/material.dart';

import '../../../../app/tema.dart';
import '../../../../core/para/kurus.dart';
import '../../../../core/para/para_bicimi.dart';

/// Bakiyeyi işaretine göre renklendirerek gösterir.
///
/// Pozitif bakiye carinin işletmeye, negatif bakiye işletmenin cariye borçlu
/// olduğu anlamına gelir (bkz. KURALLAR.md §3.4). Sıfır bakiye vurgusuzdur —
/// kapalı hesap dikkat çekmemeli.
class BakiyeMetni extends StatelessWidget {
  const BakiyeMetni({required this.bakiye, this.stil, super.key});

  final Kurus bakiye;
  final TextStyle? stil;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final renk = bakiye.sifirMi
        ? tema.colorScheme.onSurfaceVariant
        : bakiye.pozitifMi
        ? Tema.borcRengi(tema.brightness)
        : Tema.alacakRengi(tema.brightness);

    return Text(
      bakiye.bicimli,
      style: (stil ?? tema.textTheme.titleSmall)?.copyWith(
        color: renk,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
