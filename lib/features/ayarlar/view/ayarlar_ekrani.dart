import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/tasarim/bolum_basligi.dart';
import '../../../app/tasarim/dugme.dart';
import '../../../app/tasarim/olculer.dart';
import '../../../app/yollar.dart';
import '../../../core/metin/metinler.dart';
import '../../../data/kimlik/kimlik_repository.dart';
import '../../../domain/secenek/secenek_tipi.dart';
import '../../giris/viewmodel/giris_viewmodel.dart';
import '../../secenek/view/secenek_metinleri.dart';
import 'widget/ayar_satiri.dart';

/// Ayarlar sekmesi.
///
/// Üç bölüm: işletme bilgileri, tür/çeşit/anaç listeleri ve hesap.
/// İşletme satırının ayrı bir sekmede olmasının sebebi, önceden sağ üstteki üç
/// nokta menüsünde saklı olmasıydı — hesap dökümünün başlığındaki bilgiyi
/// düzeltmek isteyen kullanıcı onu bulamıyordu.
///
/// Listeler de burada: satış girerken kullanılıyorlar ama düzenlemeleri seyrek
/// bir iş. Ayrı bir sekme açmak, günde bir kez bakılmayan bir şeye alt çubukta
/// yer vermek olurdu.
///
/// Çıkış da burada: uygulamayı iki kişi kullanıyor ve cihazı devreden kişinin
/// hesabından çıkabilmesi gerekiyor.
class AyarlarEkrani extends ConsumerWidget {
  const AyarlarEkrani({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ePosta = ref.watch(oturumEPostasiSaglayici);

    return Scaffold(
      appBar: AppBar(title: const Text(Metinler.ayarlar)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Olculer.sayfaKenari,
            Olculer.bosluk8,
            Olculer.sayfaKenari,
            Olculer.bosluk32,
          ),
          children: <Widget>[
            BolumBasligi(baslik: Metinler.ayarIsletmeBolumu),
            Card(
              child: AyarSatiri(
                simge: Icons.storefront_outlined,
                baslik: Metinler.isletmeMenu,
                aciklama: Metinler.isletmeAyarAciklama,
                onBasildi: () => context.push(Yollar.isletme),
              ),
            ),
            const SizedBox(height: Olculer.bosluk24),
            const _ListelerBolumu(),
            const SizedBox(height: Olculer.bosluk24),
            BolumBasligi(baslik: Metinler.hesap),
            Card(
              child: AyarSatiri(
                simge: Icons.account_circle_outlined,
                baslik: ePosta ?? Metinler.hesap,
                aciklama: Metinler.hesapAciklama,
                onBasildi: null,
              ),
            ),
            const SizedBox(height: Olculer.bosluk16),
            Dugme.tehlikeliSade(
              metin: Metinler.cikisYap,
              simge: Icons.logout,
              onBasildi: () => _cikisYap(context, ref),
              genis: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Çıkış onaylatılır: yanlışlıkla basılırsa yeniden giriş yapmak için
  /// internet gerekir ve kullanıcı tarlada olabilir.
  Future<void> _cikisYap(BuildContext context, WidgetRef ref) async {
    final onaylandi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Metinler.cikisYap),
        content: const Text(Metinler.cikisOnay),
        actions: <Widget>[
          Dugme.sade(
            metin: Metinler.vazgec,
            kompakt: true,
            onBasildi: () => Navigator.of(context).pop(false),
          ),
          Dugme.birincil(
            metin: Metinler.cikisYap,
            kompakt: true,
            onBasildi: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (onaylandi != true) return;

    // Ekran kapatılmıyor: oturum düşünce yönlendirici giriş ekranına taşıyor.
    await ref.read(girisViewModelSaglayici.notifier).cikisYap();
  }
}

/// Tür, çeşit ve anaç listelerine giden üç satır.
///
/// Üçü ayrı ayrı listeleniyor, tek bir "Listeler" sayfasının arkasına
/// saklanmıyor: kullanıcı buraya belirli bir listeyi düzenlemeye geliyor
/// ("anaçları gireyim"), gezinmeye değil.
class _ListelerBolumu extends StatelessWidget {
  const _ListelerBolumu();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tipler = SecenekTipi.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BolumBasligi(baslik: Metinler.secenekListeleri),
        Padding(
          padding: const EdgeInsets.only(bottom: Olculer.bosluk12),
          child: Text(
            Metinler.secenekListeleriAciklama,
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Card(
          child: Column(
            children: <Widget>[
              for (var sira = 0; sira < tipler.length; sira++) ...<Widget>[
                AyarSatiri(
                  simge: Icons.list_alt_outlined,
                  baslik: tipler[sira].listeBasligi,
                  onBasildi: () =>
                      context.push(Yollar.seceneklerYolu(tipler[sira])),
                ),
                if (sira != tipler.length - 1)
                  const Divider(indent: Olculer.bosluk16 + 40),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
