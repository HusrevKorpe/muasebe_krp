import 'package:flutter/material.dart';

import '../../../../app/tasarim/olculer.dart';
import '../../../../app/tasarim/simge_dugmesi.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../core/para/para_bicimi.dart';
import '../../../../domain/islem/islem_kalemi.dart';

/// Fatura kalemlerinin düzenlenebilir listesi.
///
/// [onSil] yalnızca giriş formunda verilir; satır çarpısı orada görünür. İşlem
/// detayı silmeyi geçer ama [onDuzenle]'yi bağlar: satıra dokunmak kaydın
/// düzenleme ekranını açar. İptalli kayıtta ikisi de verilmez, liste salt
/// okunur kalır.
class KalemListesi extends StatelessWidget {
  const KalemListesi({
    required this.kalemler,
    this.onDuzenle,
    this.onSil,
    super.key,
  });

  final List<IslemKalemi> kalemler;
  final ValueChanged<int>? onDuzenle;
  final ValueChanged<int>? onSil;

  @override
  Widget build(BuildContext context) {
    if (kalemler.isEmpty) return const _BosKalemUyarisi();

    return Card(
      child: Column(
        children: <Widget>[
          for (var sira = 0; sira < kalemler.length; sira++) ...<Widget>[
            _KalemSatiri(
              kalem: kalemler[sira],
              onTap: onDuzenle == null ? null : () => onDuzenle!(sira),
              onSil: onSil == null ? null : () => onSil!(sira),
            ),
            if (sira != kalemler.length - 1)
              const Divider(indent: Olculer.bosluk16, endIndent: Olculer.bosluk16),
          ],
        ],
      ),
    );
  }
}

class _KalemSatiri extends StatelessWidget {
  const _KalemSatiri({
    required this.kalem,
    required this.onTap,
    required this.onSil,
  });

  final IslemKalemi kalem;
  final VoidCallback? onTap;
  final VoidCallback? onSil;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Olculer.bosluk16,
          Olculer.bosluk12,
          onSil == null ? Olculer.bosluk16 : Olculer.bosluk4,
          Olculer.bosluk12,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(kalem.ad, style: tema.textTheme.titleSmall),
                  const SizedBox(height: Olculer.bosluk4),
                  Text(
                    '${miktarBicimle(kalem.miktar)} ${kalem.birim} × '
                    '${kalem.birimFiyat.bicimli}'
                    '${kalem.birimFiyatYuvarlanmisMi ? ' ≈' : ''}',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Olculer.bosluk12),
            Text(
              kalem.tutar.bicimli,
              style: tema.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (onSil != null)
              SimgeDugmesi(
                simge: Icons.close,
                ipucu: Metinler.sil,
                onBasildi: onSil,
              ),
          ],
        ),
      ),
    );
  }
}

/// Satır girilmemişken kalem listesinin yerinde duran kesik çerçeveli kutu.
class _BosKalemUyarisi extends StatelessWidget {
  const _BosKalemUyarisi();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: Olculer.bosluk24,
        horizontal: Olculer.bosluk16,
      ),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainer,
        borderRadius: Olculer.koseBuyuk,
        border: Border.all(color: tema.colorScheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.playlist_add_outlined,
            color: tema.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Olculer.bosluk8),
          Text(Metinler.kalemYok, style: tema.textTheme.titleSmall),
          const SizedBox(height: Olculer.bosluk4),
          Text(
            Metinler.kalemYokAciklama,
            textAlign: TextAlign.center,
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
