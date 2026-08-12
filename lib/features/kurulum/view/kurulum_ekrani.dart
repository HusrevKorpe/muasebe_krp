import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../domain/isletme/banka_hesabi.dart';
import '../../../domain/isletme/isletme.dart';
import '../../isletme/view/widget/isletme_form_alanlari.dart';
import '../../isletme/view/widget/isletme_form_kontrolculeri.dart';
import '../../isletme/viewmodel/isletme_viewmodel.dart';
import '../../kimlik/viewmodel/kimlik_viewmodel.dart';

/// İlk açılışta işletme bilgilerini soran kurulum ekranı.
///
/// Atlanabilir değil: bu bilgiler olmadan Faz 4'te üretilecek ekstrenin başlığı
/// boş çıkar. Banka hesapları burada sorulmuyor — kurulumu uzatmamak için
/// sonradan işletme profilinden ekleniyorlar.
///
/// Kayıt başarılı olduğunda ekranı kapatan bir çağrı yok: profil akışı yeni
/// belgeyi yayınlayınca yönlendirici kullanıcıyı ana ekrana taşır.
class KurulumEkrani extends ConsumerStatefulWidget {
  const KurulumEkrani({super.key});

  @override
  ConsumerState<KurulumEkrani> createState() => _KurulumEkraniDurumu();
}

class _KurulumEkraniDurumu extends ConsumerState<KurulumEkrani> {
  final _formAnahtari = GlobalKey<FormState>();
  final _kontrolcular = IsletmeFormKontrolculeri();

  @override
  void dispose() {
    _kontrolcular.dispose();
    super.dispose();
  }

  Future<void> _tamamla() async {
    if (!_formAnahtari.currentState!.validate()) return;

    final basarili = await ref
        .read(isletmeViewModelSaglayici.notifier)
        .kaydet(
          _kontrolcular.isletmeyeUygula(
            const Isletme(id: '', ad: ''),
            bankaHesaplari: const <BankaHesabi>[],
          ),
        );

    if (basarili || !mounted) return;

    final hata = ref.read(isletmeViewModelSaglayici).error;
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
    final islemSuruyor = ref.watch(isletmeViewModelSaglayici).isLoading;
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(Metinler.kurulumBaslik),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: Metinler.cikisYap,
            onPressed: () =>
                ref.read(kimlikViewModelSaglayici.notifier).cikisYap(),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formAnahtari,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                Metinler.kurulumHosGeldiniz,
                style: tema.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                Metinler.kurulumAciklama,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              IsletmeFormAlanlari(
                kontrolcular: _kontrolcular,
                etkin: !islemSuruyor,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: islemSuruyor ? null : _tamamla,
                child: islemSuruyor
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(Metinler.kurulumTamamla),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
