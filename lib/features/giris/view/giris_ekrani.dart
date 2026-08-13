import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dogrulama/form_dogrulama.dart';
import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../viewmodel/giris_viewmodel.dart';

/// E-posta ve şifreyle giriş ekranı.
///
/// Kayıt bağlantısı yok: hesapları Firebase Console açıyor, kullanıcı kendine
/// hesap açmıyor. Başarılı girişte yönlendirici kendiliğinden ana ekrana taşır.
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

    await ref
        .read(girisViewModelSaglayici.notifier)
        .girisYap(ePosta: _ePostaKontrolcu.text, sifre: _sifreKontrolcu.text);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final durum = ref.watch(girisViewModelSaglayici);
    final islemSuruyor = durum.isLoading;

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
                  children: <Widget>[
                    Icon(Icons.park, size: 72, color: tema.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      Metinler.uygulamaAdi,
                      textAlign: TextAlign.center,
                      style: tema.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Metinler.girisAciklama,
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
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
                      autocorrect: false,
                      autofillHints: const <String>[AutofillHints.email],
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
                      autofillHints: const <String>[AutofillHints.password],
                      validator: FormDogrulama.sifre,
                      enabled: !islemSuruyor,
                      onFieldSubmitted: (_) => _girisYap(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: islemSuruyor ? null : _girisYap,
                      child: islemSuruyor
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(Metinler.girisYap),
                    ),
                    // Hata alanın altında kalıcı duruyor: SnackBar klavye
                    // açıkken görünmüyor ve "bir şey oldu ama ne" hissi
                    // bırakıyordu.
                    if (durum.hasError) ...<Widget>[
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
        ),
      ),
    );
  }
}
