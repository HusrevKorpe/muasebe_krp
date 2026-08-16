import 'package:flutter/material.dart';

import '../../../../app/tasarim/olculer.dart';
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

  static const double _kareBoyu = 40;

  final Islem islem;
  final Kurus yuruyenBakiye;
  final VoidCallback onTap;
  final bool beklemede;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final iptalli = islem.iptalMi;
    final renk = iptalli
        ? tema.colorScheme.onSurfaceVariant
        : islem.tip.renk(tema.brightness);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Olculer.sayfaKenari,
        vertical: Olculer.bosluk8,
      ),
      leading: Container(
        width: _kareBoyu,
        height: _kareBoyu,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: iptalli
              ? tema.colorScheme.surfaceContainer
              : islem.tip.zemin(tema.brightness),
          borderRadius: Olculer.koseOrta,
        ),
        child: Icon(islem.tip.simge, size: 19, color: renk),
      ),
      title: Text(
        islem.baslik.isEmpty ? islem.tip.ad : islem.baslik,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: tema.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
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
        children: <Widget>[
          Text(
            _tutarMetni(),
            style: tema.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              decoration: iptalli ? TextDecoration.lineThrough : null,
              color: renk,
            ),
          ),
          const SizedBox(height: Olculer.bosluk4),
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
      children: <Widget>[
        Flexible(
          child: Text(
            parcalar.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.bodySmall?.copyWith(
              color: iptalli
                  ? tema.colorScheme.error
                  : tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (beklemede) ...<Widget>[
          const SizedBox(width: Olculer.bosluk8),
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
