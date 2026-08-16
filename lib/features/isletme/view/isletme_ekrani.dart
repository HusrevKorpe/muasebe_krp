import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tasarim/dugme.dart';
import '../../../app/tasarim/olculer.dart';
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
        // Profil hiç doldurulmamış olabilir; o zaman form boş kayıtla açılır.
        data: (isletme) => _ProfilFormu(mevcut: isletme ?? Isletme.bos),
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
        actions: <Widget>[
          Dugme.sade(
            metin: Metinler.vazgec,
            kompakt: true,
            onBasildi: () => Navigator.of(context).pop(false),
          ),
          Dugme.tehlikeli(
            metin: Metinler.sil,
            kompakt: true,
            onBasildi: () => Navigator.of(context).pop(true),
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
          padding: const EdgeInsets.fromLTRB(
            Olculer.sayfaKenari,
            Olculer.bosluk20,
            Olculer.sayfaKenari,
            Olculer.bosluk32,
          ),
          children: <Widget>[
            const _FormAciklamasi(),
            const SizedBox(height: Olculer.bosluk20),
            IsletmeFormAlanlari(
              kontrolcular: _kontrolcular,
              etkin: !islemSuruyor,
            ),
            const SizedBox(height: Olculer.bosluk8),
            BankaHesaplariBolumu(
              hesaplar: _hesaplar,
              onEkle: islemSuruyor ? null : _hesapEkle,
              onSil: islemSuruyor ? null : _hesapSil,
            ),
            const SizedBox(height: Olculer.bosluk24),
            Dugme.birincil(
              metin: Metinler.kaydet,
              onBasildi: _kaydet,
              yukleniyor: islemSuruyor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Formun başındaki "tamamı isteğe bağlı" notu.
///
/// Kutunun içinde duruyor, düz metin olarak değil: kullanıcı forma girer
/// girmez alanları doldurmaya başlıyor, üstteki gri satırı okumuyordu.
class _FormAciklamasi extends StatelessWidget {
  const _FormAciklamasi();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Olculer.bosluk16),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainer,
        borderRadius: Olculer.koseOrta,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 20,
            color: tema.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Olculer.bosluk12),
          Expanded(
            child: Text(
              Metinler.isletmeFormAciklama,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
