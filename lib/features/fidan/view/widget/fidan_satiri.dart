import 'package:flutter/material.dart';

import '../../../../core/metin/metinler.dart';
import '../../../../core/para/para_bicimi.dart';
import '../../../../data/fidan/fidan_kaydi.dart';

/// Katalog listesinin tek satırı: fidanın görünen adı ve varsayılan fiyatı.
///
/// Fiyat kolonu sayesinde liste aynı zamanda **fiyat listesidir** — ayrı bir
/// ekran açmaya gerek kalmıyor (bkz. `fazlar/faz-3-katalog.md`).
class FidanSatiri extends StatelessWidget {
  const FidanSatiri({required this.kayit, required this.onTap, super.key});

  final FidanKaydi kayit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fidan = kayit.fidan;
    final tema = Theme.of(context);

    return ListTile(
      onTap: onTap,
      title: Text(
        fidan.goruntuAdi,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: kayit.beklemede
          ? _BeklemeRozeti(renkSemasi: tema.colorScheme)
          : null,
      trailing: fidan.varsayilanFiyat.sifirMi
          ? Text(
              Metinler.fiyatYok,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            )
          : Text(
              fidan.varsayilanFiyat.bicimli,
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
