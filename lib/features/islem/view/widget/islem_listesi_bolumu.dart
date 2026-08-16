import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/tasarim/olculer.dart';
import '../../../../app/yollar.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../domain/islem/bakiye_satiri.dart';
import '../../../ortak/view/bos_durum.dart';
import '../../../ortak/view/hata_durumu.dart';
import '../../viewmodel/islem_dokumu_saglayici.dart';
import '../../viewmodel/islem_listesi_durumu.dart';
import '../../viewmodel/islem_listesi_viewmodel.dart';
import 'islem_satiri.dart';

/// Cari detayındaki işlem listesi — **sliver** döner, `CustomScrollView`
/// içinde kullanılır.
///
/// Her satırda o işlemden sonraki yürüyen bakiye görünür; bakiye kolonu
/// `islemDokumuSaglayici` içinde üretilir.
class IslemListesiBolumu extends ConsumerWidget {
  const IslemListesiBolumu({required this.cariId, super.key});

  final String cariId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final durum = ref.watch(islemListesiViewModelSaglayici(cariId));

    return durum.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (hata, _) => SliverToBoxAdapter(
        child: SizedBox(
          height: 240,
          child: HataDurumu.hatadan(
            hata,
            yenidenDene: () => ref
                .read(islemListesiViewModelSaglayici(cariId).notifier)
                .yenile(),
          ),
        ),
      ),
      data: (veri) => veri.bosMu
          ? const SliverToBoxAdapter(
              child: SizedBox(
                height: 240,
                child: BosDurum(
                  simge: Icons.receipt_long_outlined,
                  baslik: Metinler.islemYokBaslik,
                  aciklama: Metinler.islemYokAciklama,
                ),
              ),
            )
          : _Liste(cariId: cariId, veri: veri),
    );
  }
}

class _Liste extends ConsumerWidget {
  const _Liste({required this.cariId, required this.veri});

  final String cariId;
  final IslemListesiDurumu veri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dokum = ref.watch(islemDokumuSaglayici(cariId));
    final satirlar = dokum.satirlar;

    // Bekleyen kayıtlar kimliğe göre aranır: döküm satırları kendi sıralamasını
    // uyguladığı için sıra numarasıyla eşleştirmek kırılgan olurdu.
    final bekleyenler = <String>{
      for (final kayit in veri.kayitlar)
        if (kayit.beklemede) kayit.islem.id,
    };

    // Son satır sonraki sayfanın göstergesi ya da hata satırı olur.
    final ekSatir = veri.dahaVar || veri.sayfaHatasi != null;

    return SliverList.separated(
      itemCount: satirlar.length + (ekSatir ? 1 : 0),
      // Çizgi simge karesinin altından değil, yazının hizasından başlıyor —
      // kişi listesindeki ayıraçla aynı düzen.
      separatorBuilder: (context, sira) =>
          const Divider(indent: 72, endIndent: Olculer.sayfaKenari),
      itemBuilder: (context, sira) {
        if (sira >= satirlar.length) {
          return _SayfaSonu(cariId: cariId, veri: veri);
        }

        final BakiyeSatiri satir = satirlar[sira];
        return IslemSatiri(
          islem: satir.islem,
          yuruyenBakiye: satir.yuruyenBakiye,
          beklemede: bekleyenler.contains(satir.islem.id),
          onTap: () => context.push(
            Yollar.islemDetayYolu(cariId, satir.islem.id),
          ),
        );
      },
    );
  }
}

class _SayfaSonu extends ConsumerWidget {
  const _SayfaSonu({required this.cariId, required this.veri});

  final String cariId;
  final IslemListesiDurumu veri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (veri.sayfaHatasi != null) {
      return ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(veri.sayfaHatasi!),
        onTap: () => ref
            .read(islemListesiViewModelSaglayici(cariId).notifier)
            .dahaYukle(),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: Olculer.bosluk24),
      child: Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}
