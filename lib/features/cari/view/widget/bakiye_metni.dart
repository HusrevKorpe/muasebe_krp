import 'package:flutter/material.dart';

import '../../../../app/tasarim/renkler.dart';
import '../../../../app/tasarim/rozet.dart';
import '../../../../core/para/kurus.dart';
import '../../../../core/para/para_bicimi.dart';

/// Bakiyeyi işaretine göre renklendirerek gösterir.
///
/// Pozitif bakiye carinin işletmeye, negatif bakiye işletmenin cariye borçlu
/// olduğu anlamına gelir (bkz. KURALLAR.md §3.4). Sıfır bakiye vurgusuzdur —
/// kapalı hesap dikkat çekmemeli.
///
/// [rozet] verildiğinde tutar hap biçiminde soluk bir zemine oturur. Liste
/// satırında bu gerekiyor: kırmızı ve yeşil rakamlar zeminsiz alt alta
/// dizildiğinde satırlar birbirine karışıyor, rozet her satıra kendi kutusunu
/// veriyor.
class BakiyeMetni extends StatelessWidget {
  const BakiyeMetni({
    required this.bakiye,
    this.stil,
    this.rozet = false,
    super.key,
  });

  final Kurus bakiye;
  final TextStyle? stil;
  final bool rozet;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final parlaklik = tema.brightness;

    final renk = bakiye.sifirMi
        ? tema.colorScheme.onSurfaceVariant
        : bakiye.pozitifMi
        ? Renkler.borc(parlaklik)
        : Renkler.alacak(parlaklik);

    if (!rozet) {
      return Text(
        bakiye.bicimli,
        style: (stil ?? tema.textTheme.titleSmall)?.copyWith(
          color: renk,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Rozet(
      metin: bakiye.bicimli,
      renk: renk,
      stil: stil ?? tema.textTheme.titleSmall,
      zemin: bakiye.sifirMi
          ? tema.colorScheme.surfaceContainer
          : bakiye.pozitifMi
          ? Renkler.borcZemini(parlaklik)
          : Renkler.alacakZemini(parlaklik),
    );
  }
}
