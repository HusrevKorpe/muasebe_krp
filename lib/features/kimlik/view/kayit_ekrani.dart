import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dogrulama/form_dogrulama.dart';
import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../viewmodel/kimlik_viewmodel.dart';

class KayitEkrani extends ConsumerStatefulWidget {
  const KayitEkrani({super.key});

  @override
  ConsumerState<KayitEkrani> createState() => _KayitEkraniDurumu();
}

class _KayitEkraniDurumu extends ConsumerState<KayitEkrani> {
  final _formAnahtari = GlobalKey<FormState>();
  final _ePostaKontrolcu = TextEditingController();
  final _sifreKontrolcu = TextEditingController();
  final _sifreTekrarKontrolcu = TextEditingController();
  bool _sifreGizli = true;

  @override
  void dispose() {
    _ePostaKontrolcu.dispose();
    _sifreKontrolcu.dispose();
    _sifreTekrarKontrolcu.dispose();
    super.dispose();
  }

  Future<void> _kayitOl() async {
    if (!_formAnahtari.currentState!.validate()) return;

    final basarili = await ref.read(kimlikViewModelSaglayici.notifier).kayitOl(
          ePosta: _ePostaKontrolcu.text,
          sifre: _sifreKontrolcu.text,
        );

    if (basarili || !mounted) return;

    final hata = ref.read(kimlikViewModelSaglayici).error;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            hata is UygulamaHatasi ? hata.mesaj : Metinler.beklenmeyenHata,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final islemSuruyor = ref.watch(kimlikViewModelSaglayici).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text(Metinler.kayitOl)),
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
                    Text(
                      Metinler.kayitAciklama,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
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
                        helperText:
                            'En az ${FormDogrulama.enAzSifreUzunlugu} karakter',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _sifreGizli
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip:
                              _sifreGizli
                              ? Metinler.sifreyiGoster
                              : Metinler.sifreyiGizle,
                          onPressed: () =>
                              setState(() => _sifreGizli = !_sifreGizli),
                        ),
                      ),
                      obscureText: _sifreGizli,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: FormDogrulama.sifre,
                      enabled: !islemSuruyor,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sifreTekrarKontrolcu,
                      decoration: const InputDecoration(
                        labelText: Metinler.sifreTekrari,
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: _sifreGizli,
                      textInputAction: TextInputAction.done,
                      validator: (deger) => FormDogrulama.sifreTekrari(
                        deger,
                        _sifreKontrolcu.text,
                      ),
                      enabled: !islemSuruyor,
                      onFieldSubmitted: (_) => _kayitOl(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: islemSuruyor ? null : _kayitOl,
                      child: islemSuruyor
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(Metinler.hesapOlustur),
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
