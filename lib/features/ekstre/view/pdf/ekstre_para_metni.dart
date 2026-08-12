import 'package:pdf/widgets.dart' as pw;

import '../../../../core/para/kurus.dart';
import '../../../../core/para/para_bicimi.dart';
import 'ekstre_stili.dart';

/// Ekstredeki para yazımı: lira kısmı büyük, kuruş kısmı küçük.
///
/// Referans ekstre tutarları `94.000,00 ₺` diye basıyor — `,00 ₺` gövdeden bir
/// punto küçük. Rakamın kendisi değil yalnızca gösterimi bölünür; hesap her
/// zaman kuruş tam sayısı üzerinden yürür (KURALLAR.md §3.1).
pw.Widget ekstreParasi(
  Kurus tutar,
  EkstreStili stil, {
  bool kalin = false,
}) {
  final govde = kalin ? stil.satirKalin : stil.satir;
  final kurusStili = govde.copyWith(
    font: stil.fontlar.normal,
    fontSize: (govde.fontSize ?? 8.5) * EkstreStili.kurusOrani,
  );

  return pw.RichText(
    textAlign: pw.TextAlign.right,
    text: pw.TextSpan(
      style: govde,
      children: <pw.InlineSpan>[
        pw.TextSpan(text: liraKismiMetni(tutar)),
        pw.TextSpan(text: kurusKismiMetni(tutar), style: kurusStili),
      ],
    ),
  );
}

/// `-12.031,25 ₺` değerinin `-12.031` kısmı.
String liraKismiMetni(Kurus tutar) =>
    '${tutar.negatifMi ? '-' : ''}${miktarBicimle(tutar.liraKismi)}';

/// `-12.031,25 ₺` değerinin `,25 ₺` kısmı.
String kurusKismiMetni(Kurus tutar) =>
    ',${tutar.kurusKismi.toString().padLeft(2, '0')} $paraSimgesi';
