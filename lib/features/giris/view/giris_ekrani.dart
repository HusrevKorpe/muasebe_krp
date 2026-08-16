import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tasarim/dugme.dart';
import '../../../app/tasarim/olculer.dart';
import '../../../app/tasarim/simge_dugmesi.dart';
import '../../../app/tasarim/uygulama_isareti.dart';
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
            padding: const EdgeInsets.all(Olculer.bosluk24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formAnahtari,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const UygulamaIsareti(aciklamaVar: false),
                    const SizedBox(height: Olculer.bosluk8),
                    Text(
                      Metinler.girisAciklama,
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Olculer.bosluk32),
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
                    const SizedBox(height: Olculer.bosluk16),
                    TextFormField(
                      controller: _sifreKontrolcu,
                      decoration: InputDecoration(
                        labelText: Metinler.sifre,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: SimgeDugmesi(
                          simge: _sifreGizli
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          ipucu: _sifreGizli
                              ? Metinler.sifreyiGoster
                              : Metinler.sifreyiGizle,
                          onBasildi: () =>
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
                    const SizedBox(height: Olculer.bosluk24),
                    Dugme.birincil(
                      metin: Metinler.girisYap,
                      onBasildi: _girisYap,
                      yukleniyor: islemSuruyor,
                    ),
                    // Hata alanın altında kalıcı duruyor: SnackBar klavye
                    // açıkken görünmüyor ve "bir şey oldu ama ne" hissi
                    // bırakıyordu.
                    if (durum.hasError) ...<Widget>[
                      const SizedBox(height: Olculer.bosluk20),
                      Container(
                        padding: const EdgeInsets.all(Olculer.bosluk12),
                        decoration: BoxDecoration(
                          color: tema.colorScheme.errorContainer,
                          borderRadius: Olculer.koseOrta,
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.error_outline,
                              size: 18,
                              color: tema.colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: Olculer.bosluk8),
                            Expanded(
                              child: Text(
                                durum.error is UygulamaHatasi
                                    ? (durum.error! as UygulamaHatasi).mesaj
                                    : Metinler.beklenmeyenHata,
                                style: tema.textTheme.bodySmall?.copyWith(
                                  color: tema.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
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
