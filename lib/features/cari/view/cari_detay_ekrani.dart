import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/yollar.dart';
import '../../../core/metin/metinler.dart';
import '../../../core/tarih/tarih_bicimi.dart';
import '../../../data/cari/cari_kaydi.dart';
import '../../../domain/cari/cari.dart';
import '../../ortak/view/bos_durum.dart';
import '../../ortak/view/hata_durumu.dart';
import '../viewmodel/cari_saglayici.dart';
import 'widget/bakiye_metni.dart';

/// Cari detay sayfası: üstte özet, altta işlem listesi.
///
/// İşlem listesi Faz 1'de bilerek boş duruyor — yeri hazır, içeriği Faz 2'de
/// dolacak (bkz. `fazlar/faz-2-islemler.md`).
class CariDetayEkrani extends ConsumerWidget {
  const CariDetayEkrani({required this.cariId, super.key});

  final String cariId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kayit = ref.watch(cariSaglayici(cariId));

    return Scaffold(
      appBar: AppBar(
        title: Text(kayit.value?.cari.ad ?? Metinler.cariler),
        actions: [
          if (kayit.value != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: Metinler.duzenle,
              onPressed: () => _duzenlemeyeGit(context),
            ),
        ],
      ),
      body: kayit.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (hata, _) => HataDurumu.hatadan(
          hata,
          yenidenDene: () => ref.invalidate(cariSaglayici(cariId)),
        ),
        data: (deger) => deger == null
            ? const BosDurum(
                simge: Icons.person_off_outlined,
                baslik: Metinler.cariBulunamadi,
                aciklama: Metinler.cariYokAciklama,
              )
            : _Govde(kayit: deger),
      ),
    );
  }

  /// Düzenleme ekranı `false` dönerse cari pasife alınmıştır; detay sayfasının
  /// da kapanması gerekir, aksi hâlde listede olmayan bir kayda bakılır.
  Future<void> _duzenlemeyeGit(BuildContext context) async {
    final sonuc = await context.push<bool>(Yollar.cariDuzenleYolu(cariId));
    if (sonuc == false && context.mounted) context.pop();
  }
}

class _Govde extends StatelessWidget {
  const _Govde({required this.kayit});

  final CariKaydi kayit;

  @override
  Widget build(BuildContext context) {
    final cari = kayit.cari;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _OzetKarti(kayit: kayit),
        const SizedBox(height: 24),
        if (_iletisimVarMi(cari)) ...[
          _Bolum(
            baslik: Metinler.iletisim,
            satirlar: [
              if (cari.telefon != null)
                _BilgiSatiri(
                  simge: Icons.phone_outlined,
                  etiket: Metinler.telefon,
                  deger: cari.telefon!,
                ),
              if (cari.sehir != null)
                _BilgiSatiri(
                  simge: Icons.location_city_outlined,
                  etiket: Metinler.sehir,
                  deger: cari.sehir!,
                ),
              if (cari.adres != null)
                _BilgiSatiri(
                  simge: Icons.home_outlined,
                  etiket: Metinler.adres,
                  deger: cari.adres!,
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        if (cari.vergiDairesi != null || cari.vergiNo != null) ...[
          _Bolum(
            baslik: Metinler.vergiBilgileri,
            satirlar: [
              if (cari.vergiDairesi != null)
                _BilgiSatiri(
                  simge: Icons.account_balance_outlined,
                  etiket: Metinler.vergiDairesi,
                  deger: cari.vergiDairesi!,
                ),
              if (cari.vergiNo != null)
                _BilgiSatiri(
                  simge: Icons.numbers,
                  etiket: Metinler.vergiNo,
                  deger: cari.vergiNo!,
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        if (cari.notlar != null) ...[
          _Bolum(
            baslik: Metinler.notlar,
            satirlar: [
              _BilgiSatiri(
                simge: Icons.notes_outlined,
                etiket: Metinler.notlar,
                deger: cari.notlar!,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        Text(Metinler.islemler, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const SizedBox(
          height: 220,
          child: BosDurum(
            simge: Icons.receipt_long_outlined,
            baslik: Metinler.islemYokBaslik,
            aciklama: Metinler.islemYokAciklama,
          ),
        ),
      ],
    );
  }

  static bool _iletisimVarMi(Cari cari) =>
      cari.telefon != null || cari.sehir != null || cari.adres != null;
}

class _OzetKarti extends StatelessWidget {
  const _OzetKarti({required this.kayit});

  final CariKaydi kayit;

  @override
  Widget build(BuildContext context) {
    final cari = kayit.cari;
    final tema = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cari.ad, style: tema.textTheme.headlineSmall),
            if (cari.altBaslik != null) ...[
              const SizedBox(height: 4),
              Text(
                cari.altBaslik!,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const Divider(height: 32),
            Text(
              Metinler.bakiye,
              style: tema.textTheme.labelLarge?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            BakiyeMetni(bakiye: cari.bakiye, stil: tema.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              _bakiyeAciklamasi(cari),
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            if (cari.sonIslemTarihi != null) ...[
              const SizedBox(height: 12),
              Text(
                '${Metinler.sonIslem}: ${kisaTarih(cari.sonIslemTarihi!)}',
                style: tema.textTheme.bodySmall,
              ),
            ],
            if (kayit.beklemede) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 16,
                    color: tema.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      Metinler.kaydedilmediAciklama,
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _bakiyeAciklamasi(Cari cari) {
    if (cari.bakiye.sifirMi) return Metinler.bakiyeKapali;
    return cari.bakiye.pozitifMi
        ? Metinler.bakiyeCariBorclu
        : Metinler.bakiyeIsletmeBorclu;
  }
}

class _Bolum extends StatelessWidget {
  const _Bolum({required this.baslik, required this.satirlar});

  final String baslik;
  final List<Widget> satirlar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(baslik, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: satirlar),
        ),
      ],
    );
  }
}

class _BilgiSatiri extends StatelessWidget {
  const _BilgiSatiri({
    required this.simge,
    required this.etiket,
    required this.deger,
  });

  final IconData simge;
  final String etiket;
  final String deger;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(simge),
      title: Text(etiket, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(deger, style: Theme.of(context).textTheme.bodyLarge),
      dense: true,
    );
  }
}
