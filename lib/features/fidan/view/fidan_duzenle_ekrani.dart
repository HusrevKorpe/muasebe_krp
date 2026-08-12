import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/metin/metinler.dart';
import '../../ortak/view/bos_durum.dart';
import '../../ortak/view/hata_durumu.dart';
import '../viewmodel/fidan_saglayici.dart';
import 'fidan_form_ekrani.dart';

/// `/fidanlar/:fidanId` yolunun sayfası.
///
/// Formun düzenlenecek fidanı hazır bulması gerekiyor. Kaydı gezinme sırasında
/// taşımak yerine kimliğinden yeniden okuyoruz: böylece yol doğrudan açıldığında
/// da çalışır (bkz. `CariDuzenleEkrani`).
class FidanDuzenleEkrani extends ConsumerWidget {
  const FidanDuzenleEkrani({required this.fidanId, super.key});

  final String fidanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kayit = ref.watch(fidanSaglayici(fidanId));

    return kayit.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (hata, _) => Scaffold(
        appBar: AppBar(title: const Text(Metinler.fidanDuzenle)),
        body: HataDurumu.hatadan(
          hata,
          yenidenDene: () => ref.invalidate(fidanSaglayici(fidanId)),
        ),
      ),
      data: (deger) => deger == null
          ? Scaffold(
              appBar: AppBar(title: const Text(Metinler.fidanDuzenle)),
              body: const BosDurum(
                simge: Icons.park_outlined,
                baslik: Metinler.fidanBulunamadi,
                aciklama: Metinler.fidanYokAciklama,
              ),
            )
          : FidanFormEkrani(mevcut: deger.fidan),
    );
  }
}
