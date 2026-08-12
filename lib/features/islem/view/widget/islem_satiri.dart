import 'package:flutter/material.dart';

import '../../../../core/metin/metinler.dart';
import '../../../../core/para/kurus.dart';
import '../../../../core/para/para_bicimi.dart';
import '../../../../core/tarih/tarih_bicimi.dart';
import '../../../../domain/islem/islem.dart';
import '../../../cari/view/widget/bakiye_metni.dart';
import 'islem_tipi_gorunumu.dart';

/// İşlem listesinin tek satırı: tarih, açıklama, tutar ve yürüyen bakiye.
///
/// Referans ekstredeki satır düzenini izler; iptal edilmiş kayıt listeden
/// düşmez, üstü çizili görünür (bkz. KURALLAR.md §4.2).
class IslemSatiri extends StatelessWidget {
  const IslemSatiri({
    required this.islem,
    required this.yuruyenBakiye,
    required this.onTap,
    this.beklemede = false,
    super.key,
  });

  final Islem islem;
  final Kurus yuruyenBakiye;
  final VoidCallback onTap;
  final bool beklemede;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final iptalli = islem.iptalMi;

    return ListTile(
      onTap: onTap,
      leading: Icon(
        islem.tip.simge,
        color: iptalli
            ? tema.colorScheme.onSurfaceVariant
            : islem.tip.renk(tema.brightness),
      ),
      title: Text(
        islem.baslik.isEmpty ? islem.tip.ad : islem.baslik,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: tema.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          decoration: iptalli ? TextDecoration.lineThrough : null,
          color: iptalli ? tema.colorScheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: _AltSatir(
        islem: islem,
        beklemede: beklemede,
        iptalli: iptalli,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _tutarMetni(),
            style: tema.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              decoration: iptalli ? TextDecoration.lineThrough : null,
              color: iptalli
                  ? tema.colorScheme.onSurfaceVariant
                  : islem.tip.renk(tema.brightness),
            ),
          ),
          const SizedBox(height: 2),
          BakiyeMetni(bakiye: yuruyenBakiye, stil: tema.textTheme.bodySmall),
        ],
      ),
      isThreeLine: false,
    );
  }

  /// Borç işlemleri artı, alacak işlemleri eksi işaretiyle gösterilir; kolon
  /// yönü ekstredeki borç/alacak ayrımının satır içindeki karşılığıdır.
  String _tutarMetni() {
    final isaret = islem.tip.borcMu ? '+' : '−';
    return '$isaret${islem.toplam.bicimli}';
  }
}

class _AltSatir extends StatelessWidget {
  const _AltSatir({
    required this.islem,
    required this.beklemede,
    required this.iptalli,
  });

  final Islem islem;
  final bool beklemede;
  final bool iptalli;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final parcalar = <String>[
      kisaTarih(islem.islemTarihi),
      if (iptalli) Metinler.iptalEdildi else islem.tip.ad,
    ];

    return Row(
      children: [
        Flexible(
          child: Text(
            parcalar.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.bodySmall,
          ),
        ),
        if (beklemede) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.cloud_upload_outlined,
            size: 14,
            color: tema.colorScheme.tertiary,
          ),
        ],
      ],
    );
  }
}
