import 'package:flutter/material.dart';

import '../../../../core/metin/metinler.dart';
import '../../../../core/para/para_bicimi.dart';
import '../../../../domain/islem/islem_kalemi.dart';

/// Fatura kalemlerinin düzenlenebilir listesi.
///
/// Salt okunur kullanımda [onDuzenle] ve [onSil] verilmez; işlem detayı
/// ekranı listeyi böyle gösterir.
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

  bool get _duzenlenebilirMi => onDuzenle != null || onSil != null;

  @override
  Widget build(BuildContext context) {
    if (kalemler.isEmpty) {
      return const _BosKalemUyarisi();
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (var sira = 0; sira < kalemler.length; sira++)
            _KalemSatiri(
              kalem: kalemler[sira],
              onTap: onDuzenle == null ? null : () => onDuzenle!(sira),
              onSil: onSil == null ? null : () => onSil!(sira),
              sonMu: sira == kalemler.length - 1 || !_duzenlenebilirMi,
            ),
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
    required this.sonMu,
  });

  final IslemKalemi kalem;
  final VoidCallback? onTap;
  final VoidCallback? onSil;
  final bool sonMu;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          title: Text(kalem.ad),
          subtitle: Text(
            '${miktarBicimle(kalem.miktar)} ${kalem.birim} × '
            '${kalem.birimFiyat.bicimli}'
            '${kalem.birimFiyatYuvarlanmisMi ? ' ≈' : ''}',
            style: tema.textTheme.bodySmall,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                kalem.tutar.bicimli,
                style: tema.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onSil != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: Metinler.sil,
                  onPressed: onSil,
                ),
            ],
          ),
        ),
        if (!sonMu) const Divider(height: 1),
      ],
    );
  }
}

class _BosKalemUyarisi extends StatelessWidget {
  const _BosKalemUyarisi();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: tema.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.playlist_add_outlined,
            color: tema.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(Metinler.kalemYok, style: tema.textTheme.bodyMedium),
          const SizedBox(height: 4),
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
