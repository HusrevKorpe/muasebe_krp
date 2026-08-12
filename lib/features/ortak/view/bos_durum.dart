import 'package:flutter/material.dart';

/// Liste ve bölüm boş kaldığında gösterilen ortak yerleşim.
class BosDurum extends StatelessWidget {
  const BosDurum({
    required this.simge,
    required this.baslik,
    required this.aciklama,
    this.eylem,
    super.key,
  });

  final IconData simge;
  final String baslik;
  final String aciklama;

  /// İsteğe bağlı çağrı düğmesi — "Cari Ekle" gibi.
  final Widget? eylem;

  @override
  Widget build(BuildContext context) {
    final renkSemasi = Theme.of(context).colorScheme;
    final metinTemasi = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(simge, size: 56, color: renkSemasi.outline),
            const SizedBox(height: 16),
            Text(
              baslik,
              textAlign: TextAlign.center,
              style: metinTemasi.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              aciklama,
              textAlign: TextAlign.center,
              style: metinTemasi.bodyMedium?.copyWith(
                color: renkSemasi.onSurfaceVariant,
              ),
            ),
            if (eylem != null) ...[const SizedBox(height: 24), eylem!],
          ],
        ),
      ),
    );
  }
}
