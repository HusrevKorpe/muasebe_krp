import 'package:flutter/material.dart';

import '../../../../core/metin/metinler.dart';
import '../../../../core/para/para_bicimi.dart';
import '../../../../domain/islem/fatura_toplami.dart';

/// Faturanın tutar dökümü: ara toplam → KDV → genel toplam.
///
/// Hesabı kendisi yapmaz; [FaturaToplami] domain katmanında üretilir
/// (bkz. KURALLAR.md §1.3).
class FaturaOzeti extends StatelessWidget {
  const FaturaOzeti({required this.toplam, super.key});

  final FaturaToplami toplam;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Satir(
              etiket: Metinler.araToplam,
              deger: toplam.araToplam.bicimli,
            ),
            if (toplam.kdvVarMi) ...[
              const SizedBox(height: 8),
              _Satir(
                etiket: '${Metinler.kdv} (%${toplam.kdvOrani})',
                deger: toplam.kdv.bicimli,
              ),
            ],
            const Divider(height: 24),
            _Satir(
              etiket: Metinler.genelToplam,
              deger: toplam.toplam.bicimli,
              stil: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Satir extends StatelessWidget {
  const _Satir({required this.etiket, required this.deger, this.stil});

  final String etiket;
  final String deger;
  final TextStyle? stil;

  @override
  Widget build(BuildContext context) {
    final varsayilan = Theme.of(context).textTheme.bodyMedium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(etiket, style: stil ?? varsayilan),
        Text(deger, style: stil ?? varsayilan),
      ],
    );
  }
}
