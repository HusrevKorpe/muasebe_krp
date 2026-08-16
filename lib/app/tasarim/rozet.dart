import 'package:flutter/material.dart';

import 'olculer.dart';

/// Küçük, hap biçimli etiket: "Kaydedilmedi", "İptal edildi", bakiye tutarı.
///
/// Renk dışarıdan veriliyor çünkü rozetin anlamı taşıdığı renkte: bekleyen
/// kayıt kiremit, iptalli kayıt gri, borç kırmızı. Zemin aynı renkten
/// üretiliyor ki iki değer elle uyumsuz girilemesin.
class Rozet extends StatelessWidget {
  const Rozet({
    required this.metin,
    required this.renk,
    this.simge,
    this.zemin,
    this.stil,
    this.kalin = true,
    super.key,
  });

  final String metin;

  /// Metin ve simge rengi.
  final Color renk;

  /// Zemin rengi. Verilmezse [renk]'in soluk hâli kullanılır.
  final Color? zemin;

  final IconData? simge;

  /// Yazı biçimi. Verilmezse `labelMedium` kullanılır; para rozetleri bunu
  /// büyütüyor — tutar liste satırının asıl bilgisi, etiket değil.
  final TextStyle? stil;

  final bool kalin;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final yazi = (stil ?? tema.textTheme.labelMedium)?.copyWith(
      color: renk,
      fontWeight: kalin ? FontWeight.w700 : FontWeight.w500,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Olculer.bosluk8,
        vertical: Olculer.bosluk4,
      ),
      decoration: BoxDecoration(
        color: zemin ?? renk.withValues(alpha: 0.12),
        borderRadius: Olculer.koseTam,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (simge != null) ...<Widget>[
            Icon(simge, size: 13, color: renk),
            const SizedBox(width: Olculer.bosluk4),
          ],
          Flexible(
            child: Text(
              metin,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: yazi,
            ),
          ),
        ],
      ),
    );
  }
}
