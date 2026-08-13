import 'package:flutter/material.dart';

import '../../../../domain/islem/islem_tipi.dart';
import 'islem_tipi_gorunumu.dart';

/// Kişi sayfasının altındaki dört giriş düğmesi.
///
/// Önceden tek bir "İşlem ekle" düğmesi vardı ve tip bir alt sayfada
/// seçiliyordu. Dört tip doğrudan burada duruyor: kullanıcı ne yaptığını zaten
/// biliyor, araya bir seçim ekranı koymak fazladan dokunuş.
///
/// Dört tip birlikte sunulur: bir cari hem müşteri hem tedarikçi olabilir, bu
/// yüzden aynı kişiye hem satış hem alış girilebilmeli (bkz. KURALLAR.md §3.4).
class IslemDugmeleri extends StatelessWidget {
  const IslemDugmeleri({required this.onSecildi, super.key});

  final ValueChanged<IslemTipi> onSecildi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Material(
      color: tema.colorScheme.surface,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: <Widget>[
              for (final tip in IslemTipi.values) ...<Widget>[
                Expanded(child: _Dugme(tip: tip, onBasildi: onSecildi)),
                if (tip != IslemTipi.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Dugme extends StatelessWidget {
  const _Dugme({required this.tip, required this.onBasildi});

  final IslemTipi tip;
  final ValueChanged<IslemTipi> onBasildi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final renk = tip.renk(tema.brightness);

    return InkWell(
      onTap: () => onBasildi(tip),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(tip.simge, color: renk),
            const SizedBox(height: 6),
            Text(
              tip.ad,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: tema.textTheme.labelMedium?.copyWith(color: renk),
            ),
          ],
        ),
      ),
    );
  }
}
