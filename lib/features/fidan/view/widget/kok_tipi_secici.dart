import 'package:flutter/material.dart';

import '../../../../core/metin/metinler.dart';
import '../../../../domain/fidan/kok_tipi.dart';

/// Kök tipi seçimi: belirtilmedi · tüplü · çıplak kök.
///
/// Alan isteğe bağlı olduğu için "Belirtilmedi" ayrı bir seçenek olarak duruyor;
/// kullanıcı seçtiği bir tipi geri alabilmeli.
class KokTipiSecici extends StatelessWidget {
  const KokTipiSecici({
    required this.secili,
    required this.onSecildi,
    this.etkin = true,
    super.key,
  });

  final KokTipi? secili;
  final ValueChanged<KokTipi?> onSecildi;
  final bool etkin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${Metinler.kokTipi} (${Metinler.istegeBagli})',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _Secenek(
              etiket: Metinler.kokTipiYok,
              seciliMi: secili == null,
              onSecildi: etkin ? () => onSecildi(null) : null,
            ),
            for (final tip in KokTipi.values)
              _Secenek(
                etiket: tip.ad,
                seciliMi: secili == tip,
                onSecildi: etkin ? () => onSecildi(tip) : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _Secenek extends StatelessWidget {
  const _Secenek({
    required this.etiket,
    required this.seciliMi,
    required this.onSecildi,
  });

  final String etiket;
  final bool seciliMi;
  final VoidCallback? onSecildi;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(etiket),
      selected: seciliMi,
      onSelected: onSecildi == null ? null : (_) => onSecildi!(),
    );
  }
}
