import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/tasarim/olculer.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../core/tarih/tarih_bicimi.dart';
import '../../../../domain/ekstre/ekstre_araligi.dart';
import '../../viewmodel/ekstre_araligi_viewmodel.dart';

/// Ekstrenin tarih aralığını seçen çip sırası.
///
/// Hazır aralıklar tek dokunuşla seçilir; "Özel" çipi takvimi açar ve seçim
/// yapıldıktan sonra çipin üstünde tarihleri gösterir.
///
/// Çipler uygulamanın standart dokunma yüksekliğinden bilerek küçük ([_Cip]):
/// sıra dört çip taşıyor ve tam boyda ikinci satıra taşıp önizlemenin yerini
/// yiyordu. Burası ekranın konusu değil, süzgeci — seçilen aralık PDF'in
/// başlığında da yazıyor.
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
      spacing: Olculer.bosluk8,
      runSpacing: Olculer.bosluk8,
      children: <Widget>[
        _Cip(
          etiket: Metinler.aralikBuAy,
          secili: aralik.tip == EkstreAralikTipi.buAy,
          onSecildi: () => viewModel.buAy(bugun),
        ),
        _Cip(
          etiket: Metinler.aralikBuYil,
          secili: aralik.tip == EkstreAralikTipi.buYil,
          onSecildi: () => viewModel.buYil(bugun),
        ),
        _Cip(
          etiket: Metinler.aralikTumu,
          secili: aralik.tumuMu,
          onSecildi: viewModel.tumu,
        ),
        _Cip(
          etiket: _ozelEtiket(aralik),
          simge: Icons.date_range_outlined,
          secili: aralik.tip == EkstreAralikTipi.ozel,
          onSecildi: () => _ozelSec(context, viewModel, aralik, bugun),
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

/// Sıraya sığsın diye derlenip toplanmış [ChoiceChip].
class _Cip extends StatelessWidget {
  const _Cip({
    required this.etiket,
    required this.secili,
    required this.onSecildi,
    this.simge,
  });

  final String etiket;
  final bool secili;
  final VoidCallback onSecildi;

  /// Çipin bir sayfa açtığını söyleyen simge — yalnızca "Özel" çipinde var.
  final IconData? simge;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(etiket),
      avatar: simge == null ? null : Icon(simge, size: 16),
      selected: secili,
      onSelected: (_) => onSecildi(),
      // Onay işareti kapalı: seçili çip zaten zeminiyle ayrılıyor, işaret
      // yalnızca çipi genişletip sırayı ikinci satıra itiyordu.
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(
        horizontal: Olculer.bosluk8,
        vertical: Olculer.bosluk8,
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: Olculer.bosluk4),
    );
  }
}
