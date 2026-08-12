import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../data/isletme/isletme_repository.dart';
import '../../../domain/isletme/banka_hesabi.dart';
import '../../../domain/isletme/isletme.dart';
import '../../ortak/view/hata_durumu.dart';
import '../viewmodel/isletme_viewmodel.dart';
import 'banka_hesabi_dialogu.dart';
import 'widget/banka_hesaplari_bolumu.dart';
import 'widget/isletme_form_alanlari.dart';
import 'widget/isletme_form_kontrolculeri.dart';

/// İşletme profili düzenleme ekranı.
class IsletmeEkrani extends ConsumerWidget {
  const IsletmeEkrani({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(isletmeProfiliSaglayici);

    return Scaffold(
      appBar: AppBar(title: const Text(Metinler.isletmeBaslik)),
      body: profil.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (hata, _) => HataDurumu.hatadan(
          hata,
          yenidenDene: () => ref.invalidate(isletmeProfiliSaglayici),
        ),
        // Profil `null` olamaz: kurulum tamamlanmadan bu ekrana gelinemiyor.
        // Yine de savunmacı davranıp boş kayıtla açılıyoruz.
        data: (isletme) =>
            _ProfilFormu(mevcut: isletme ?? const Isletme(id: '', ad: '')),
      ),
    );
  }
}

class _ProfilFormu extends ConsumerStatefulWidget {
  const _ProfilFormu({required this.mevcut});

  final Isletme mevcut;

  @override
  ConsumerState<_ProfilFormu> createState() => _ProfilFormuDurumu();
}

class _ProfilFormuDurumu extends ConsumerState<_ProfilFormu> {
  final _formAnahtari = GlobalKey<FormState>();

  /// Denetleyiciler bir kez kurulur. Kaydettikten sonra akış yeni bir belge
  /// yayınladığında kullanıcının yazdıkları sıfırlanmasın diye `late final`.
  late final IsletmeFormKontrolculeri _kontrolcular = IsletmeFormKontrolculeri(
    widget.mevcut,
  );

  late List<BankaHesabi> _hesaplar = List<BankaHesabi>.of(
    widget.mevcut.bankaHesaplari,
  );

  @override
  void dispose() {
    _kontrolcular.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (!_formAnahtari.currentState!.validate()) return;

    final basarili = await ref
        .read(isletmeViewModelSaglayici.notifier)
        .kaydet(
          _kontrolcular.isletmeyeUygula(
            widget.mevcut,
            bankaHesaplari: _hesaplar,
          ),
        );

    if (!mounted) return;
    _mesajGoster(
      basarili ? Metinler.kaydedildi : _hataMesaji(),
    );
    if (basarili) Navigator.of(context).maybePop();
  }

  Future<void> _hesapEkle() async {
    final hesap = await showDialog<BankaHesabi>(
      context: context,
      builder: (context) => const BankaHesabiDialogu(),
    );
    if (hesap == null) return;
    setState(() => _hesaplar = <BankaHesabi>[..._hesaplar, hesap]);
  }

  Future<void> _hesapSil(int sira) async {
    final onaylandi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(Metinler.bankaHesabiSilOnay),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Metinler.vazgec),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Metinler.sil),
          ),
        ],
      ),
    );
    if (onaylandi != true) return;
    setState(() => _hesaplar = <BankaHesabi>[..._hesaplar]..removeAt(sira));
  }

  String _hataMesaji() {
    final hata = ref.read(isletmeViewModelSaglayici).error;
    return hata is UygulamaHatasi ? hata.mesaj : Metinler.beklenmeyenHata;
  }

  void _mesajGoster(String mesaj) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mesaj)));
  }

  @override
  Widget build(BuildContext context) {
    final islemSuruyor = ref.watch(isletmeViewModelSaglayici).isLoading;

    return SafeArea(
      child: Form(
        key: _formAnahtari,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            IsletmeFormAlanlari(
              kontrolcular: _kontrolcular,
              etkin: !islemSuruyor,
            ),
            const SizedBox(height: 8),
            BankaHesaplariBolumu(
              hesaplar: _hesaplar,
              onEkle: islemSuruyor ? null : _hesapEkle,
              onSil: islemSuruyor ? null : _hesapSil,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: islemSuruyor ? null : _kaydet,
              child: islemSuruyor
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(Metinler.kaydet),
            ),
          ],
        ),
      ),
    );
  }
}
