import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/tasarim/bolum_basligi.dart';
import '../../../app/tasarim/dugme.dart';
import '../../../app/tasarim/olculer.dart';
import '../../../app/tasarim/simge_dugmesi.dart';
import '../../../app/yollar.dart';
import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../data/islem/islem_kaydi.dart';
import '../../../domain/islem/islem.dart';
import '../../../domain/islem/islem_tipi.dart';
import '../../ortak/view/bos_durum.dart';
import '../../ortak/view/hata_durumu.dart';
import '../viewmodel/islem_form_viewmodel.dart';
import '../viewmodel/islem_saglayici.dart';
import 'widget/fatura_ozeti.dart';
import 'widget/islem_ozet_karti.dart';
import 'widget/islem_tipi_gorunumu.dart';
import 'widget/kalem_listesi.dart';

/// Bir işlemin ayrıntısı: kalemler, tutar dökümü, düzenleme ve iptal düğmesi.
///
/// Düzenleme ve iptal yalnızca yürürlükteki kayıtta görünür; iptal edilmiş bir
/// kaydın ne tutarı değiştirilir ne de ikinci kez iptal edilir. Hesap görme
/// kaydında düzenleme hiç açılmaz — tutarı bakiyeden türetildi, geri alma yolu
/// iptaldir (bkz. [IslemTipi.duzenlenebilirMi]).
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
    final islem = kayit.value?.islem;
    final duzenlenebilir =
        islem != null && !islem.iptalMi && islem.tip.duzenlenebilirMi;

    return Scaffold(
      appBar: AppBar(
        title: Text(kayit.value?.islem.tip.ad ?? Metinler.islemDetayi),
        actions: <Widget>[
          if (duzenlenebilir)
            SimgeDugmesi(
              simge: Icons.edit_outlined,
              ipucu: Metinler.islemiDuzenle,
              onBasildi: () => _duzenlemeyeGit(context),
            ),
          if (islem != null && !islem.iptalMi)
            SimgeDugmesi(
              simge: Icons.block_outlined,
              ipucu: Metinler.islemiIptalEt,
              tehlikeli: true,
              onBasildi: () => _iptalEt(context, ref, islem),
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
            : _Govde(
                kayit: deger,
                // Satıra dokununca da düzenleme açılır: kullanıcı fiyatı
                // gördüğü yerden düzeltmek istiyor. İptalli kayıtta ve hesap
                // görme kaydında kapalı.
                onDuzenle: duzenlenebilir
                    ? () => _duzenlemeyeGit(context)
                    : null,
              ),
      ),
    );
  }

  void _duzenlemeyeGit(BuildContext context) =>
      context.push(Yollar.islemDuzenleYolu(cariId, islemId));

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
        actions: <Widget>[
          Dugme.sade(
            metin: Metinler.vazgec,
            kompakt: true,
            onBasildi: () => Navigator.of(context).pop(false),
          ),
          Dugme.tehlikeli(
            metin: Metinler.tamam,
            kompakt: true,
            onBasildi: () => Navigator.of(context).pop(true),
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
  const _Govde({required this.kayit, this.onDuzenle});

  final IslemKaydi kayit;

  /// Kalem satırına dokunulduğunda çağrılır. `null` ise satırlar salt okunur.
  final VoidCallback? onDuzenle;

  @override
  Widget build(BuildContext context) {
    final islem = kayit.islem;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Olculer.sayfaKenari,
        Olculer.bosluk20,
        Olculer.sayfaKenari,
        Olculer.bosluk32,
      ),
      children: <Widget>[
        if (islem.iptalMi) ...<Widget>[
          const _IptalUyarisi(),
          const SizedBox(height: Olculer.bosluk16),
        ],
        IslemOzetKarti(kayit: kayit),
        if (islem.kalemler.isNotEmpty) ...<Widget>[
          const SizedBox(height: Olculer.bosluk24),
          BolumBasligi(baslik: Metinler.kalemler),
          KalemListesi(
            kalemler: islem.kalemler,
            onDuzenle: onDuzenle == null ? null : (_) => onDuzenle!(),
          ),
        ],
        const SizedBox(height: Olculer.bosluk20),
        FaturaOzeti(toplam: islem.toplam),
      ],
    );
  }
}

class _IptalUyarisi extends StatelessWidget {
  const _IptalUyarisi();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Olculer.bosluk16),
      decoration: BoxDecoration(
        color: tema.colorScheme.errorContainer,
        borderRadius: Olculer.koseOrta,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.block_outlined,
            size: 20,
            color: tema.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: Olculer.bosluk12),
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
