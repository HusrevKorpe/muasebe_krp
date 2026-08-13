import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../core/para/para_bicimi.dart';
import '../../../core/tarih/tarih_bicimi.dart';
import '../../../data/islem/islem_kaydi.dart';
import '../../../domain/islem/islem.dart';
import '../../ortak/view/bos_durum.dart';
import '../../ortak/view/hata_durumu.dart';
import '../viewmodel/islem_form_viewmodel.dart';
import '../viewmodel/islem_saglayici.dart';
import 'widget/fatura_ozeti.dart';
import 'widget/islem_tipi_gorunumu.dart';
import 'widget/kalem_listesi.dart';

/// Bir işlemin ayrıntısı: kalemler, tutar dökümü ve iptal düğmesi.
class IslemDetayEkrani extends ConsumerWidget {
  const IslemDetayEkrani({
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

    return Scaffold(
      appBar: AppBar(
        title: Text(kayit.value?.islem.tip.ad ?? Metinler.islemDetayi),
        actions: [
          if (kayit.value != null && !kayit.value!.islem.iptalMi)
            IconButton(
              icon: const Icon(Icons.block_outlined),
              tooltip: Metinler.islemiIptalEt,
              onPressed: () => _iptalEt(context, ref, kayit.value!.islem),
            ),
        ],
      ),
      body: kayit.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (hata, _) => HataDurumu.hatadan(
          hata,
          yenidenDene: () => ref.invalidate(islemSaglayici(anahtar)),
        ),
        data: (deger) => deger == null
            ? const BosDurum(
                simge: Icons.receipt_long_outlined,
                baslik: Metinler.islemYokBaslik,
                aciklama: Metinler.islemYokAciklama,
              )
            : _Govde(kayit: deger),
      ),
    );
  }

  /// İptal onaylanırsa kayıt silinmez; iptal işaretlenir ve bakiyeye katkısı
  /// geri alınır (bkz. KURALLAR.md §4.2).
  Future<void> _iptalEt(
    BuildContext context,
    WidgetRef ref,
    Islem islem,
  ) async {
    final onaylandi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Metinler.islemiIptalEt),
        content: const Text(Metinler.islemIptalOnay),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Metinler.vazgec),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Metinler.tamam),
          ),
        ],
      ),
    );

    if (onaylandi != true || !context.mounted) return;

    final basarili = await ref
        .read(islemFormViewModelSaglayici.notifier)
        .iptalEt(cariId: cariId, islem: islem);

    if (!context.mounted) return;
    final hata = ref.read(islemFormViewModelSaglayici).error;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            basarili
                ? Metinler.islemIptalEdildi
                : (hata is UygulamaHatasi
                      ? hata.mesaj
                      : Metinler.beklenmeyenHata),
          ),
        ),
      );
  }
}

class _Govde extends StatelessWidget {
  const _Govde({required this.kayit});

  final IslemKaydi kayit;

  @override
  Widget build(BuildContext context) {
    final islem = kayit.islem;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (islem.iptalMi) ...[
          const _IptalUyarisi(),
          const SizedBox(height: 16),
        ],
        _OzetKarti(kayit: kayit),
        if (islem.kalemler.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            Metinler.kalemler,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          KalemListesi(kalemler: islem.kalemler),
        ],
        const SizedBox(height: 24),
        FaturaOzeti(toplam: islem.toplam),
      ],
    );
  }
}

class _OzetKarti extends StatelessWidget {
  const _OzetKarti({required this.kayit});

  final IslemKaydi kayit;

  @override
  Widget build(BuildContext context) {
    final islem = kayit.islem;
    final tema = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(islem.tip.simge, color: islem.tip.renk(tema.brightness)),
                const SizedBox(width: 8),
                Text(islem.tip.ad, style: tema.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(islem.baslik, style: tema.textTheme.headlineSmall),
            const Divider(height: 32),
            _BilgiSatiri(
              etiket: islem.tip.kolonEtiketi,
              deger: islem.toplam.bicimli,
              vurgulu: true,
              renk: islem.iptalMi ? null : islem.tip.renk(tema.brightness),
            ),
            _BilgiSatiri(
              etiket: Metinler.islemTarihi,
              deger: uzunTarih(islem.islemTarihi),
            ),
            if (islem.iptalNedeni != null)
              _BilgiSatiri(
                etiket: Metinler.iptalNedeni,
                deger: islem.iptalNedeni!,
              ),
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
}

class _IptalUyarisi extends StatelessWidget {
  const _IptalUyarisi();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tema.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.block_outlined, color: tema.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              Metinler.iptalliIslemUyarisi,
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BilgiSatiri extends StatelessWidget {
  const _BilgiSatiri({
    required this.etiket,
    required this.deger,
    this.vurgulu = false,
    this.renk,
  });

  final String etiket;
  final String deger;
  final bool vurgulu;
  final Color? renk;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final stil = vurgulu
        ? tema.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: renk,
          )
        : tema.textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiket,
            style: tema.textTheme.bodyMedium?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
          Flexible(child: Text(deger, style: stil, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
