import 'package:flutter/material.dart';

import '../../../../core/metin/metinler.dart';
import '../../../../core/para/para_bicimi.dart';
import '../../../../data/urun/urun_kaydi.dart';

/// Ürün listesinin tek satırı: adı ve fiyatı.
///
/// Fiyat kolonu sayesinde liste aynı zamanda **fiyat listesidir** — ayrı bir
/// ekran açmaya gerek kalmıyor (bkz. `fazlar/faz-3-katalog.md`).
class UrunSatiri extends StatelessWidget {
  const UrunSatiri({required this.kayit, required this.onTap, super.key});

  final UrunKaydi kayit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final urun = kayit.urun;
    final tema = Theme.of(context);

    return ListTile(
      onTap: onTap,
      title: Text(
        urun.ad,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: kayit.beklemede
          ? _BeklemeRozeti(renkSemasi: tema.colorScheme)
          : null,
      trailing: urun.fiyat.sifirMi
          ? Text(
              Metinler.fiyatYok,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            )
          : Text(
              urun.fiyat.bicimli,
              style: tema.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

/// Sunucuya henüz yazılmamış kayıtların göstergesi (bkz. KURALLAR.md §4.4).
class _BeklemeRozeti extends StatelessWidget {
  const _BeklemeRozeti({required this.renkSemasi});

  final ColorScheme renkSemasi;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.cloud_upload_outlined, size: 14, color: renkSemasi.tertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            Metinler.kaydedilmedi,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: renkSemasi.tertiary),
          ),
        ),
      ],
    );
  }
}
