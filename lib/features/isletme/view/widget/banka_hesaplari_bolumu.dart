import 'package:flutter/material.dart';

import '../../../../core/metin/metinler.dart';
import '../../../../domain/isletme/banka_hesabi.dart';

/// Banka hesabı listesi ve ekleme düğmesi.
///
/// Hesaplar Faz 4'te ekstrenin alt bilgisine basılacak; burada yalnızca
/// toplanıyorlar.
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
      children: [
        Text(Metinler.bankaHesaplari, style: tema.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (hesaplar.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              Metinler.bankaHesabiYok,
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (var sira = 0; sira < hesaplar.length; sira++)
                  ListTile(
                    leading: const Icon(Icons.account_balance_outlined),
                    title: Text(
                      '${hesaplar[sira].banka} · ${hesaplar[sira].paraBirimi}',
                    ),
                    subtitle: Text(hesaplar[sira].ibanBicimli),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: Metinler.sil,
                      onPressed: onSil == null ? null : () => onSil!(sira),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onEkle,
          icon: const Icon(Icons.add),
          label: const Text(Metinler.bankaHesabiEkle),
        ),
      ],
    );
  }
}
