import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/metin/metinler.dart';
import '../../ortak/view/bos_durum.dart';
import '../../ortak/view/hata_durumu.dart';
import '../viewmodel/cari_saglayici.dart';
import 'cari_form_ekrani.dart';

/// `/cari/:cariId/duzenle` yolunun sayfası.
///
/// Formun düzenlenecek cariyi hazır bulması gerekiyor. Kaydı gezinme sırasında
/// taşımak yerine kimliğinden yeniden okuyoruz: böylece yol doğrudan açıldığında
/// (derin bağlantı, uygulama yeniden başlatma) da çalışır.
class CariDuzenleEkrani extends ConsumerWidget {
  const CariDuzenleEkrani({required this.cariId, super.key});

  final String cariId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kayit = ref.watch(cariSaglayici(cariId));

    return kayit.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (hata, _) => Scaffold(
        appBar: AppBar(title: const Text(Metinler.cariDuzenle)),
        body: HataDurumu.hatadan(
          hata,
          yenidenDene: () => ref.invalidate(cariSaglayici(cariId)),
        ),
      ),
      data: (deger) => deger == null
          ? Scaffold(
              appBar: AppBar(title: const Text(Metinler.cariDuzenle)),
              body: const BosDurum(
                simge: Icons.person_off_outlined,
                baslik: Metinler.cariBulunamadi,
                aciklama: Metinler.cariYokAciklama,
              ),
            )
          : CariFormEkrani(mevcut: deger.cari),
    );
  }
}
