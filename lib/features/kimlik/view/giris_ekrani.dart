import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/yollar.dart';
import '../../../core/dogrulama/form_dogrulama.dart';
import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../viewmodel/kimlik_viewmodel.dart';

class GirisEkrani extends ConsumerStatefulWidget {
  const GirisEkrani({super.key});

  @override
  ConsumerState<GirisEkrani> createState() => _GirisEkraniDurumu();
}

class _GirisEkraniDurumu extends ConsumerState<GirisEkrani> {
  final _formAnahtari = GlobalKey<FormState>();
  final _ePostaKontrolcu = TextEditingController();
  final _sifreKontrolcu = TextEditingController();
  bool _sifreGizli = true;

  @override
  void dispose() {
    _ePostaKontrolcu.dispose();
    _sifreKontrolcu.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    if (!_formAnahtari.currentState!.validate()) return;

    final basarili = await ref.read(kimlikViewModelSaglayici.notifier).girisYap(
          ePosta: _ePostaKontrolcu.text,
          sifre: _sifreKontrolcu.text,
        );

    // Başarılı girişte yönlendirici otomatik olarak ana ekrana taşır.
    if (!basarili && mounted) _hatayiGoster();
  }

  Future<void> _sifremiUnuttum() async {
    final hata = FormDogrulama.ePosta(_ePostaKontrolcu.text);
    if (hata != null) {
      _mesajGoster(Metinler.sifreOncePosta);
      return;
    }

    final basarili = await ref
        .read(kimlikViewModelSaglayici.notifier)
        .sifreSifirlamaGonder(_ePostaKontrolcu.text);

    if (!mounted) return;
    if (basarili) {
      _mesajGoster(Metinler.sifreBaglantisiGonderildi);
    } else {
      _hatayiGoster();
    }
  }

  void _hatayiGoster() {
    final hata = ref.read(kimlikViewModelSaglayici).error;
    _mesajGoster(
      hata is UygulamaHatasi ? hata.mesaj : Metinler.beklenmeyenHata,
    );
  }

  void _mesajGoster(String mesaj) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mesaj)));
  }

  @override
  Widget build(BuildContext context) {
    final islemSuruyor = ref.watch(kimlikViewModelSaglayici).isLoading;
    final renkSemasi = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formAnahtari,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.park, size: 64, color: renkSemasi.primary),
                    const SizedBox(height: 12),
                    Text(
                      Metinler.uygulamaAdi,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Metinler.uygulamaTanimi,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: renkSemasi.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _ePostaKontrolcu,
                      decoration: const InputDecoration(
                        labelText: Metinler.ePosta,
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: FormDogrulama.ePosta,
                      enabled: !islemSuruyor,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sifreKontrolcu,
                      decoration: InputDecoration(
                        labelText: Metinler.sifre,
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
                      obscureText: _sifreGizli,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      validator: FormDogrulama.sifre,
                      enabled: !islemSuruyor,
                      onFieldSubmitted: (_) => _girisYap(),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: islemSuruyor ? null : _sifremiUnuttum,
                        child: const Text(Metinler.sifremiUnuttum),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: islemSuruyor ? null : _girisYap,
                      child: islemSuruyor
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(Metinler.girisYap),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(Metinler.hesabinizYokMu),
                        TextButton(
                          onPressed: islemSuruyor
                              ? null
                              : () => context.push(Yollar.kayit),
                          child: const Text(Metinler.kayitOlun),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
