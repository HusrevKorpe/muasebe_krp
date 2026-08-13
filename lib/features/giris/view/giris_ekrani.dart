import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../data/isletme/isletme_repository.dart';
import '../viewmodel/giris_viewmodel.dart';

/// Google ile giriş ekranı.
///
/// İki durumu birden gösterir, çünkü ikisi de aynı yere çıkar — hesap seçmeye:
///
/// * Oturum yok: "Google ile giriş yap".
/// * Oturum var ama hesap izin listesinde değil: ne olduğu yazılır ve tek
///   çıkış yolu olan "Çıkış yap" düğmesi gösterilir. Bunu ayrı bir ekrana
///   koymak, kullanıcıyı çıkamayacağı bir odada bırakırdı.
class GirisEkrani extends ConsumerWidget {
  const GirisEkrani({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final durum = ref.watch(girisViewModelSaglayici);
    final reddedildi = ref.watch(erisimReddedildiSaglayici);
    final islemSuruyor = durum.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.park, size: 72, color: tema.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  Metinler.uygulamaAdi,
                  style: tema.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reddedildi
                      ? const YetkiHatasi().mesaj
                      : Metinler.girisAciklama,
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: reddedildi
                        ? tema.colorScheme.error
                        : tema.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                if (islemSuruyor)
                  const CircularProgressIndicator()
                else if (reddedildi)
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(girisViewModelSaglayici.notifier).cikisYap(),
                    icon: const Icon(Icons.logout),
                    label: const Text(Metinler.cikisYap),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => ref
                        .read(girisViewModelSaglayici.notifier)
                        .googleIleGir(),
                    icon: const Icon(Icons.login),
                    label: const Text(Metinler.googleIleGir),
                  ),
                // Vazgeçmek hata sayılmadığı için burada bir şey görünmez;
                // yalnızca gerçek hatalar yazılır.
                if (durum.hasError && !reddedildi) ...[
                  const SizedBox(height: 24),
                  Text(
                    durum.error is UygulamaHatasi
                        ? (durum.error! as UygulamaHatasi).mesaj
                        : Metinler.beklenmeyenHata,
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
