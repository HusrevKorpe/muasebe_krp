import 'package:flutter/material.dart';

import '../../core/metin/turkce.dart';
import 'olculer.dart';

/// Bir kart öbeğinin üstündeki başlık: "Hareketler", "Neler", "Banka Hesapları".
///
/// Sağa isteğe bağlı bir eylem alıyor — başlıkla düğmeyi her ekranda ayrı ayrı
/// `Row`'a dizmek yerine. Başlık küçük ve seyrek harfli: kartların içindeki
/// içerikle yarışmasın, yalnızca öbeği adlandırsın.
///
/// Büyütme [turkceBuyuk] ile yapılıyor; `'İletişim'.toUpperCase()` "ILETISIM"
/// veriyor (bkz. KURALLAR.md §6.1).
class BolumBasligi extends StatelessWidget {
  const BolumBasligi({required this.baslik, this.eylem, super.key});

  final String baslik;

  /// Başlığın sağındaki düğme — "Satır ekle" gibi.
  final Widget? eylem;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Olculer.bosluk12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              turkceBuyuk(baslik),
              style: tema.textTheme.labelMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ?eylem,
        ],
      ),
    );
  }
}
