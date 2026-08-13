import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/metin/metinler.dart';
import '../../ortak/view/bos_durum.dart';
import '../../ortak/view/hata_durumu.dart';
import '../viewmodel/urun_saglayici.dart';
import 'urun_form_ekrani.dart';

/// `/urunler/:urunId` yolunun sayfası.
///
/// Formun düzenlenecek ürünü hazır bulması gerekiyor. Kaydı gezinme sırasında
/// taşımak yerine kimliğinden yeniden okuyoruz: böylece yol doğrudan açıldığında
/// da çalışır (bkz. `CariDuzenleEkrani`).
class UrunDuzenleEkrani extends ConsumerWidget {
  const UrunDuzenleEkrani({required this.urunId, super.key});

  final String urunId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kayit = ref.watch(urunSaglayici(urunId));

    return kayit.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (hata, _) => Scaffold(
        appBar: AppBar(title: const Text(Metinler.urunDuzenle)),
        body: HataDurumu.hatadan(
          hata,
          yenidenDene: () => ref.invalidate(urunSaglayici(urunId)),
        ),
      ),
      data: (deger) => deger == null
          ? Scaffold(
              appBar: AppBar(title: const Text(Metinler.urunDuzenle)),
              body: const BosDurum(
                simge: Icons.sell_outlined,
                baslik: Metinler.urunBulunamadi,
                aciklama: Metinler.urunYokAciklama,
              ),
            )
          : UrunFormEkrani(mevcut: deger.urun),
    );
  }
}
