import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/metin/metinler.dart';
import '../../viewmodel/tema_viewmodel.dart';
import 'ayar_satiri.dart';

/// Ayarlardaki koyu tema anahtarı.
///
/// Satırın kendisi de anahtarla aynı işi yapıyor: küçük bir anahtara nişan
/// almak yerine satırın herhangi bir yerine dokunmak yetiyor.
class TemaSatiri extends ConsumerWidget {
  const TemaSatiri({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final koyu = ref.watch(temaSaglayici).koyuMu;
    final viewModel = ref.read(temaSaglayici.notifier);

    return AyarSatiri(
      simge: koyu ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
      baslik: Metinler.koyuTema,
      aciklama: Metinler.koyuTemaAciklama,
      onBasildi: () => viewModel.koyuTemaSecildi(!koyu),
      sonEk: Switch(value: koyu, onChanged: viewModel.koyuTemaSecildi),
    );
  }
}
