import 'package:flutter/material.dart';

import '../../../../app/tasarim/bolum_basligi.dart';
import '../../../../app/tasarim/dugme.dart';
import '../../../../app/tasarim/olculer.dart';
import '../../../../app/tasarim/simge_dugmesi.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../domain/isletme/banka_hesabi.dart';

/// Banka hesabı listesi ve ekleme düğmesi.
///
/// Hesaplar ekstrenin alt bilgisine basılıyor; burada yalnızca toplanıyorlar.
class BankaHesaplariBolumu extends StatelessWidget {
  const BankaHesaplariBolumu({
    required this.hesaplar,
    required this.onEkle,
    required this.onSil,
    super.key,
  });

  final List<BankaHesabi> hesaplar;
  final VoidCallback? onEkle;
  final void Function(int sira)? onSil;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        BolumBasligi(baslik: Metinler.bankaHesaplari),
        if (hesaplar.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: Olculer.bosluk20,
              horizontal: Olculer.bosluk16,
            ),
            decoration: BoxDecoration(
              color: tema.colorScheme.surfaceContainer,
              borderRadius: Olculer.koseBuyuk,
              border: Border.all(color: tema.colorScheme.outlineVariant),
            ),
            child: Text(
              Metinler.bankaHesabiYok,
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: <Widget>[
                for (var sira = 0; sira < hesaplar.length; sira++) ...<Widget>[
                  _HesapSatiri(
                    hesap: hesaplar[sira],
                    onSil: onSil == null ? null : () => onSil!(sira),
                  ),
                  if (sira != hesaplar.length - 1)
                    const Divider(indent: Olculer.bosluk16 + 40),
                ],
              ],
            ),
          ),
        const SizedBox(height: Olculer.bosluk12),
        Dugme.ikincil(
          metin: Metinler.bankaHesabiEkle,
          simge: Icons.add,
          genis: true,
          onBasildi: onEkle,
        ),
      ],
    );
  }
}

class _HesapSatiri extends StatelessWidget {
  const _HesapSatiri({required this.hesap, required this.onSil});

  static const double _kareBoyu = 40;

  final BankaHesabi hesap;
  final VoidCallback? onSil;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Olculer.bosluk16,
        Olculer.bosluk12,
        Olculer.bosluk4,
        Olculer.bosluk12,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: _kareBoyu,
            height: _kareBoyu,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tema.colorScheme.surfaceContainer,
              borderRadius: Olculer.koseOrta,
            ),
            child: Icon(
              Icons.account_balance_outlined,
              size: 20,
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Olculer.bosluk16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${hesap.banka} · ${hesap.paraBirimi}',
                  style: tema.textTheme.titleSmall,
                ),
                const SizedBox(height: Olculer.bosluk4),
                Text(
                  hesap.ibanBicimli,
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SimgeDugmesi(
            simge: Icons.delete_outline,
            ipucu: Metinler.sil,
            tehlikeli: true,
            onBasildi: onSil,
          ),
        ],
      ),
    );
  }
}
