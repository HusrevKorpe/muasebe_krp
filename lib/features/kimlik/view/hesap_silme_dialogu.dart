import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../viewmodel/hesap_silme_viewmodel.dart';

/// Hesap silme onayı: uyarı, şifre alanı ve silme işleminin kendisi.
///
/// Silme akışını dialog yürütür ve bitene kadar açık kalır. Kapatılıp arka
/// planda çalışsaydı kullanıcı yarım silinmiş bir veriyle ekranlarda gezerdi.
///
/// `true` ile kapanırsa hesap silinmiştir; yönlendirici oturum düştüğü için
/// kullanıcıyı giriş ekranına taşır.
class HesapSilmeDialogu extends ConsumerStatefulWidget {
  const HesapSilmeDialogu({super.key});

  @override
  ConsumerState<HesapSilmeDialogu> createState() => _HesapSilmeDialoguDurumu();
}

class _HesapSilmeDialoguDurumu extends ConsumerState<HesapSilmeDialogu> {
  final _sifreKontrolcu = TextEditingController();
  bool _sifreGizli = true;
  String? _hataMesaji;

  @override
  void dispose() {
    _sifreKontrolcu.dispose();
    super.dispose();
  }

  Future<void> _sil() async {
    if (_sifreKontrolcu.text.isEmpty) {
      setState(() => _hataMesaji = Metinler.hesapSilOnayIpucu);
      return;
    }

    setState(() => _hataMesaji = null);
    final basarili = await ref
        .read(hesapSilmeViewModelSaglayici.notifier)
        .sil(_sifreKontrolcu.text);

    if (!mounted) return;
    if (basarili) {
      Navigator.of(context).pop(true);
      return;
    }

    final hata = ref.read(hesapSilmeViewModelSaglayici).error;
    setState(() {
      _hataMesaji = hata is UygulamaHatasi
          ? hata.mesaj
          : Metinler.beklenmeyenHata;
    });
  }

  @override
  Widget build(BuildContext context) {
    final siliniyor = ref.watch(hesapSilmeViewModelSaglayici).isLoading;
    final renkSemasi = Theme.of(context).colorScheme;

    return PopScope(
      // Silme sürerken geri tuşu ve dışarı dokunma kapatmaz: yarıda kesilen
      // akış, verisi silinmiş ama hesabı duran bir kullanıcı bırakır.
      canPop: !siliniyor,
      child: AlertDialog(
        title: const Text(Metinler.hesapSilBaslik),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(Metinler.hesapSilAciklama),
              const SizedBox(height: 16),
              TextField(
                controller: _sifreKontrolcu,
                obscureText: _sifreGizli,
                enabled: !siliniyor,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: Metinler.sifre,
                  helperText: Metinler.hesapSilOnayIpucu,
                  errorText: _hataMesaji,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _sifreGizli
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    tooltip: _sifreGizli
                        ? Metinler.sifreyiGoster
                        : Metinler.sifreyiGizle,
                    onPressed: () =>
                        setState(() => _sifreGizli = !_sifreGizli),
                  ),
                ),
                onSubmitted: (_) => _sil(),
              ),
              if (siliniyor) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  Metinler.hesapSilmeSuruyor,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: siliniyor ? null : () => Navigator.of(context).pop(false),
            child: const Text(Metinler.vazgec),
          ),
          FilledButton(
            onPressed: siliniyor ? null : _sil,
            style: FilledButton.styleFrom(
              backgroundColor: renkSemasi.error,
              foregroundColor: renkSemasi.onError,
            ),
            child: const Text(Metinler.sil),
          ),
        ],
      ),
    );
  }
}
