import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/firebase/firebase_saglayicilar.dart';
import '../../kimlik/viewmodel/kimlik_viewmodel.dart';

/// Ana ekran iskeleti.
///
/// Faz 1'de cari listesiyle değiştirilecek — bkz. `fazlar/faz-1-cari.md`.
class AnaEkran extends ConsumerWidget {
  const AnaEkran({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kullanici = ref.watch(oturumDurumuSaglayici).value;
    final renkSemasi = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FidanCari'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış yap',
            onPressed: () =>
                ref.read(kimlikViewModelSaglayici.notifier).cikisYap(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: renkSemasi.primary),
              const SizedBox(height: 16),
              Text(
                'Cari listesi Faz 1\'de gelecek',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                kullanici?.email ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: renkSemasi.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
