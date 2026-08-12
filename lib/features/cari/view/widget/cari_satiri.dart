import 'package:flutter/material.dart';

import '../../../../core/metin/metinler.dart';
import '../../../../core/metin/turkce.dart';
import '../../../../data/cari/cari_kaydi.dart';
import 'bakiye_metni.dart';

/// Cari listesinin tek satırı.
class CariSatiri extends StatelessWidget {
  const CariSatiri({required this.kayit, required this.onTap, super.key});

  final CariKaydi kayit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cari = kayit.cari;
    final renkSemasi = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: renkSemasi.primaryContainer,
        foregroundColor: renkSemasi.onPrimaryContainer,
        child: Text(_basHarf(cari.ad)),
      ),
      title: Text(
        cari.ad,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: kayit.beklemede
          ? _BeklemeRozeti(renkSemasi: renkSemasi)
          : (cari.altBaslik == null
                ? null
                : Text(
                    cari.altBaslik!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )),
      trailing: BakiyeMetni(bakiye: cari.bakiye),
    );
  }

  /// Avatar harfi. Türkçe büyütme kuralı geçerli: `izmir` → `İ`
  /// (bkz. KURALLAR.md §6.1).
  static String _basHarf(String ad) {
    final kirpilmis = ad.trim();
    return kirpilmis.isEmpty ? '?' : turkceBuyuk(kirpilmis[0]);
  }
}

/// Sunucuya henüz yazılmamış kayıtların göstergesi.
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
