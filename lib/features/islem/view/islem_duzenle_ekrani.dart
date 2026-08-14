import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/metin/metinler.dart';
import '../../../domain/islem/islem.dart';
import '../../ortak/view/bos_durum.dart';
import '../../ortak/view/hata_durumu.dart';
import '../viewmodel/islem_saglayici.dart';
import 'fatura_form_ekrani.dart';
import 'tahsilat_form_ekrani.dart';

/// `/cari/:cariId/islem/:islemId/duzenle` yolunun sayfası.
///
/// Formun düzenlenecek kaydı hazır bulması gerekiyor; kaydı gezinme sırasında
/// taşımak yerine kimliğinden okuyoruz, böylece yol doğrudan açıldığında da
/// çalışır (bkz. `UrunDuzenleEkrani`). Okunan kayıt aynı zamanda bakiye
/// farkının dayanağı: `IslemRepository.guncelle` "eski" hâli buradan alır.
///
/// Tipe göre iki forma dallanır — fatura satır taşır, tahsilat taşımaz.
/// İptalli kayıt düzenlenmez: detay ekranı düğmeyi zaten göstermiyor, bu yol
/// elle açılırsa da uyarıyla karşılanır.
class IslemDuzenleEkrani extends ConsumerWidget {
  const IslemDuzenleEkrani({
    required this.cariId,
    required this.islemId,
    super.key,
  });

  final String cariId;
  final String islemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anahtar = (cariId: cariId, islemId: islemId);
    final kayit = ref.watch(islemSaglayici(anahtar));

    return kayit.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (hata, _) => Scaffold(
        appBar: AppBar(title: const Text(Metinler.islemDuzenle)),
        body: HataDurumu.hatadan(
          hata,
          yenidenDene: () => ref.invalidate(islemSaglayici(anahtar)),
        ),
      ),
      data: (deger) {
        final islem = deger?.islem;
        if (islem == null) {
          return _bosEkran(
            simge: Icons.receipt_long_outlined,
            baslik: Metinler.islemYokBaslik,
            aciklama: Metinler.islemYokAciklama,
          );
        }
        if (islem.iptalMi) {
          return _bosEkran(
            simge: Icons.block_outlined,
            baslik: Metinler.iptalEdildi,
            aciklama: Metinler.iptalliIslemUyarisi,
          );
        }

        return _form(islem);
      },
    );
  }

  Widget _form(Islem islem) => islem.tip.faturaMi
      ? FaturaFormEkrani(cariId: cariId, tip: islem.tip, mevcut: islem)
      : TahsilatFormEkrani(cariId: cariId, tip: islem.tip, mevcut: islem);

  Scaffold _bosEkran({
    required IconData simge,
    required String baslik,
    required String aciklama,
  }) => Scaffold(
    appBar: AppBar(title: const Text(Metinler.islemDuzenle)),
    body: BosDurum(simge: simge, baslik: baslik, aciklama: aciklama),
  );
}
