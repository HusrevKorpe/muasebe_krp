import 'package:flutter/material.dart';

import '../../../../core/metin/metinler.dart';
import '../../../../domain/islem/islem_tipi.dart';
import 'islem_tipi_gorunumu.dart';

/// Yeni işlem eklerken tipin seçildiği alt sayfa.
///
/// Dört tip birlikte sunulur: bir cari hem müşteri hem tedarikçi olabilir, bu
/// yüzden aynı kişiye hem satış faturası hem alış faturası girilebilmeli
/// (bkz. KURALLAR.md §3.4).
class IslemTipiSecici extends StatelessWidget {
  const IslemTipiSecici({super.key});

  /// Alt sayfayı açar. Kullanıcı vazgeçerse `null` döner.
  static Future<IslemTipi?> goster(BuildContext context) =>
      showModalBottomSheet<IslemTipi>(
        context: context,
        showDragHandle: true,
        builder: (context) => const IslemTipiSecici(),
      );

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(Metinler.islemTipi, style: tema.textTheme.titleMedium),
          ),
          for (final tip in IslemTipi.values)
            ListTile(
              leading: Icon(tip.simge, color: tip.renk(tema.brightness)),
              title: Text(tip.ad),
              subtitle: Text(tip.kolonEtiketi),
              onTap: () => Navigator.of(context).pop(tip),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
