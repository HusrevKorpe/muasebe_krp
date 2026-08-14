import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/yollar.dart';
import '../../../core/metin/metinler.dart';
import '../../../data/kimlik/kimlik_repository.dart';
import '../../../domain/secenek/secenek_tipi.dart';
import '../../giris/viewmodel/giris_viewmodel.dart';
import '../../secenek/view/secenek_metinleri.dart';

/// Ayarlar sekmesi.
///
/// Üç bölüm: işletme bilgileri, tür/çeşit/anaç listeleri ve açık hesap.
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
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text(Metinler.isletmeMenu),
              subtitle: const Text(Metinler.isletmeAyarAciklama),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Yollar.isletme),
            ),
            const Divider(),
            const _ListelerBolumu(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text(Metinler.hesap),
              subtitle: Text(ePosta ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(Metinler.cikisYap),
              onTap: () => _cikisYap(context, ref),
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
        content: const Text(Metinler.cikisOnay),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Metinler.vazgec),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Metinler.cikisYap),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            Metinler.secenekListeleri,
            style: tema.textTheme.titleSmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            Metinler.secenekListeleriAciklama,
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final tip in SecenekTipi.values)
          ListTile(
            leading: const Icon(Icons.list_alt_outlined),
            title: Text(tip.listeBasligi),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Yollar.seceneklerYolu(tip)),
          ),
      ],
    );
  }
}
