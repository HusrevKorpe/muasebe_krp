import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/metin/metinler.dart';
import '../../../data/firebase/firebase_saglayicilar.dart';
import '../viewmodel/kimlik_viewmodel.dart';
import 'hesap_silme_dialogu.dart';

/// Hesap ekranı: giriş yapılan e-posta, çıkış ve hesap silme.
///
/// Hesap silme uygulama içinden erişilebilir olmak zorunda — Apple, hesap
/// açtıran uygulamalarda bunu şart koşuyor (bkz. fazlar/faz-5-magaza.md).
class HesapEkrani extends ConsumerWidget {
  const HesapEkrani({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ePosta = ref.watch(kullaniciEPostasiSaglayici);
    final renkSemasi = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text(Metinler.hesapBaslik)),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text(Metinler.hesapGirisYapan),
              subtitle: Text(ePosta ?? '—'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(Metinler.cikisYap),
              onTap: () =>
                  ref.read(kimlikViewModelSaglayici.notifier).cikisYap(),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.delete_forever, color: renkSemasi.error),
              title: Text(
                Metinler.hesapSil,
                style: TextStyle(color: renkSemasi.error),
              ),
              subtitle: const Text(Metinler.hesapSilAciklama),
              isThreeLine: true,
              onTap: () => _hesabiSil(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _hesabiSil(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final silindi = await showDialog<bool>(
      context: context,
      // Silme sürerken kazara kapanmasın; dialog kendi `PopScope`'uyla da
      // korunuyor ama barrier'ı burada kapatmak tek satır.
      barrierDismissible: false,
      builder: (context) => const HesapSilmeDialogu(),
    );

    if (silindi != true) return;
    // Yönlendirici oturum düştüğü için giriş ekranına taşıyor; burada yalnızca
    // sonucu bildiriyoruz.
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(Metinler.hesapSilindi)));
  }
}
