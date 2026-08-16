import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../app/tasarim/olculer.dart';
import '../../../core/metin/metinler.dart';
import '../../ortak/view/hata_durumu.dart';
import '../viewmodel/ekstre_saglayici.dart';
import 'pdf/ekstre_belgesi.dart';
import 'widget/aralik_secici.dart';

/// Ekstre ekranı: üstte tarih aralığı, altta PDF önizlemesi.
///
/// Paylaşma ve yazdırma düğmeleri önizleme çubuğundan gelir; ayrı bir "kaydet"
/// yolu yok — iOS paylaşım sayfası "Dosyalara Kaydet" seçeneğini zaten sunuyor.
class EkstreEkrani extends ConsumerWidget {
  const EkstreEkrani({required this.cariId, super.key});

  final String cariId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text(Metinler.ekstre)),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Olculer.sayfaKenari,
              Olculer.bosluk4,
              Olculer.sayfaKenari,
              Olculer.bosluk16,
            ),
            child: AralikSecici(cariId: cariId),
          ),
          const Divider(),
          Expanded(child: _Onizleme(cariId: cariId)),
        ],
      ),
    );
  }
}

class _Onizleme extends ConsumerWidget {
  const _Onizleme({required this.cariId});

  final String cariId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdf = ref.watch(ekstrePdfSaglayici(cariId));

    return pdf.when(
      loading: () => const _Yukleniyor(),
      error: (hata, _) => HataDurumu.hatadan(
        hata,
        yenidenDene: () => ref.invalidate(ekstreSaglayici(cariId)),
      ),
      data: (baytlar) => _Belge(cariId: cariId, baytlar: baytlar),
    );
  }
}

class _Belge extends ConsumerWidget {
  const _Belge({required this.cariId, required this.baytlar});

  final String cariId;
  final Uint8List baytlar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ekstre = ref.watch(ekstreSaglayici(cariId)).value;

    return PdfPreview(
      build: (format) => baytlar,
      pdfFileName: ekstre == null ? null : EkstreBelgesi.dosyaAdi(ekstre),
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      allowPrinting: true,
      allowSharing: true,
      loadingWidget: const _Yukleniyor(),
      padding: const EdgeInsets.all(Olculer.bosluk12),
    );
  }
}

class _Yukleniyor extends StatelessWidget {
  const _Yukleniyor();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: Olculer.bosluk16),
          Text(
            Metinler.ekstreUretiliyor,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
