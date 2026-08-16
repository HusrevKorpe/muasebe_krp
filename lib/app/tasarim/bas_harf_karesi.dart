import 'package:flutter/material.dart';

import '../../core/metin/turkce.dart';
import 'olculer.dart';

/// Bir adın baş harfini taşıyan yumuşak köşeli kare — kişi listesinin ve kişi
/// sayfasının simgesi.
///
/// Daire değil kare: liste satırları da kartlar da yuvarlatılmış kare, daire bu
/// ailenin dışında kalıyordu.
///
/// Harf Türkçe kurallarıyla büyütülüyor: `izmir` → `İ`, `ısparta` → `I`
/// (bkz. KURALLAR.md §6.1).
class BasHarfKaresi extends StatelessWidget {
  const BasHarfKaresi({required this.ad, this.cap = 46, super.key});

  final String ad;

  /// Karenin kenar uzunluğu. Liste satırında 46, kişi sayfasının başlığında 56.
  final double cap;

  @override
  Widget build(BuildContext context) {
    final sema = Theme.of(context).colorScheme;

    return Container(
      width: cap,
      height: cap,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: sema.primaryContainer,
        borderRadius: Olculer.koseOrta,
      ),
      child: Text(
        _basHarf(ad),
        style: TextStyle(
          color: sema.onPrimaryContainer,
          fontSize: cap * 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _basHarf(String ad) {
    final kirpilmis = ad.trim();
    return kirpilmis.isEmpty ? '?' : turkceBuyuk(kirpilmis[0]);
  }
}
