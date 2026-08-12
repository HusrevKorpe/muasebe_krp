import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/metin/metinler.dart';
import '../../../../core/tarih/tarih_bicimi.dart';
import '../../../../domain/ekstre/ekstre_araligi.dart';
import '../../viewmodel/ekstre_araligi_viewmodel.dart';

/// Ekstrenin tarih aralığını seçen çip sırası.
///
/// Hazır aralıklar tek dokunuşla seçilir; "özel aralık" çipi takvimi açar ve
/// seçim yapıldıktan sonra çipin üstünde tarihleri gösterir.
class AralikSecici extends ConsumerWidget {
  const AralikSecici({required this.cariId, super.key});

  /// Takvimde geriye gidilebilecek en eski yıl — `TarihAlani` ile aynı sınır.
  static const int _geriyeYil = 10;

  final String cariId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aralik = ref.watch(ekstreAraligiSaglayici(cariId));
    final viewModel = ref.read(ekstreAraligiSaglayici(cariId).notifier);
    final bugun = DateTime.now();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text(Metinler.aralikBuAy),
          selected: aralik.tip == EkstreAralikTipi.buAy,
          onSelected: (_) => viewModel.buAy(bugun),
        ),
        ChoiceChip(
          label: const Text(Metinler.aralikBuYil),
          selected: aralik.tip == EkstreAralikTipi.buYil,
          onSelected: (_) => viewModel.buYil(bugun),
        ),
        ChoiceChip(
          label: const Text(Metinler.aralikTumu),
          selected: aralik.tumuMu,
          onSelected: (_) => viewModel.tumu(),
        ),
        ChoiceChip(
          label: Text(_ozelEtiket(aralik)),
          avatar: const Icon(Icons.date_range_outlined, size: 18),
          selected: aralik.tip == EkstreAralikTipi.ozel,
          onSelected: (_) => _ozelSec(context, viewModel, aralik, bugun),
        ),
      ],
    );
  }

  static String _ozelEtiket(EkstreAraligi aralik) {
    if (aralik.tip != EkstreAralikTipi.ozel) return Metinler.aralikOzel;
    return '${kisaTarih(aralik.baslangic!)} — ${kisaTarih(aralik.bitis!)}';
  }

  Future<void> _ozelSec(
    BuildContext context,
    EkstreAraligiViewModel viewModel,
    EkstreAraligi mevcut,
    DateTime bugun,
  ) async {
    final secilen = await showDateRangePicker(
      context: context,
      firstDate: DateTime(bugun.year - _geriyeYil),
      lastDate: DateTime(bugun.year, bugun.month, bugun.day),
      initialDateRange: mevcut.baslangic == null || mevcut.bitis == null
          ? null
          : DateTimeRange(start: mevcut.baslangic!, end: mevcut.bitis!),
      saveText: Metinler.tamam,
    );

    if (secilen == null) return;
    viewModel.ozel(baslangic: secilen.start, bitis: secilen.end);
  }
}
