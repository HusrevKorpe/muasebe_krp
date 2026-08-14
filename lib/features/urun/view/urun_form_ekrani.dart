import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../core/para/kurus.dart';
import '../../../core/para/para_bicimi.dart';
import '../../../core/para/para_girisi.dart';
import '../../../domain/secenek/secenek_tipi.dart';
import '../../../domain/urun/urun.dart';
import '../../../domain/urun/urun_adi.dart';
import '../../../domain/urun/urun_dogrulama.dart';
import '../../secenek/view/secenek_listesi_ekrani.dart';
import '../viewmodel/urun_form_viewmodel.dart';

/// Ürün ekleme ve düzenleme formu: tür, çeşit, anaç ve fiyat.
///
/// Fidan kimliği üç ayrı kutuya giriliyor — fatura satırındaki kutuların
/// aynısı, liste düğmeleri dahil. İki ekran aynı üç alanı yazmalı ki
/// katalogdan seçilen kalem kutulara olduğu gibi dağılsın (bkz.
/// `KalemAlanlari`).
///
/// [mevcut] `null` ise yeni kayıt açılır. Ekleme ve düzenleme aynı ekranda:
/// alanlar birebir aynı, tek fark başlık ve listeden kaldırma düğmesi.
class UrunFormEkrani extends ConsumerStatefulWidget {
  const UrunFormEkrani({this.mevcut, super.key});

  final Urun? mevcut;

  @override
  ConsumerState<UrunFormEkrani> createState() => _UrunFormEkraniDurumu();
}

class _UrunFormEkraniDurumu extends ConsumerState<UrunFormEkrani> {
  final _formAnahtari = GlobalKey<FormState>();

  late final _tur = TextEditingController(text: widget.mevcut?.tur ?? '');
  late final _cesit = TextEditingController(text: widget.mevcut?.cesit ?? '');
  late final _anac = TextEditingController(text: widget.mevcut?.anac ?? '');
  late final _fiyat = TextEditingController(
    text: widget.mevcut == null || widget.mevcut!.fiyat.sifirMi
        ? ''
        : kurusMetni(widget.mevcut!.fiyat),
  );

  bool get _duzenlemeMi => widget.mevcut != null;

  @override
  void dispose() {
    _tur.dispose();
    _cesit.dispose();
    _anac.dispose();
    _fiyat.dispose();
    super.dispose();
  }

  Urun _formdanUrun() {
    final mevcut = widget.mevcut;
    return Urun(
      id: mevcut?.id ?? '',
      tur: _tur.text.trim(),
      cesit: _cesit.text.trim(),
      anac: _anac.text.trim(),
      fiyat: kurusAyristir(_fiyat.text) ?? Kurus.sifir,
      aktif: mevcut?.aktif ?? true,
      olusturmaTarihi: mevcut?.olusturmaTarihi,
      guncellemeTarihi: mevcut?.guncellemeTarihi,
    );
  }

  /// Tek bir kutuyu kendi listesinden doldurur — kalem kutusundaki düğmenin
  /// aynısı (bkz. `KalemDialogu`). Katalogu kurarken de aynı adlar tıklanmalı
  /// ki `Elma` bir yerde `elma` yazılmasın.
  Future<void> _secenekSec(SecenekTipi tip) async {
    final ad = await SecenekListesiEkrani.sec(context, tip);
    if (ad == null || !mounted) return;

    setState(() {
      switch (tip) {
        case SecenekTipi.tur:
          _tur.text = ad;
        case SecenekTipi.cesit:
          _cesit.text = ad;
        case SecenekTipi.anac:
          _anac.text = ad;
      }
    });
  }

  Future<void> _kaydet() async {
    if (!_formAnahtari.currentState!.validate()) return;

    final basarili = await ref
        .read(urunFormViewModelSaglayici.notifier)
        .kaydet(_formdanUrun());

    if (!mounted) return;
    if (basarili) {
      Navigator.of(context).pop(true);
    } else {
      _hatayiGoster();
    }
  }

  Future<void> _listedenKaldir() async {
    final onaylandi = await _onayAl();
    if (!onaylandi || !mounted) return;

    final basarili = await ref
        .read(urunFormViewModelSaglayici.notifier)
        .pasifeAl(widget.mevcut!.id);

    if (!mounted) return;
    if (basarili) {
      // Ekran kapanıyor; onay mesajı bir üstteki listede görünsün.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(Metinler.urunPasifeAlindi)));
      Navigator.of(context).pop(false);
    } else {
      _hatayiGoster();
    }
  }

  Future<bool> _onayAl() async {
    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Metinler.urunPasifeAl),
        content: const Text(Metinler.urunPasifeAlOnay),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Metinler.vazgec),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Metinler.tamam),
          ),
        ],
      ),
    );
    return sonuc ?? false;
  }

  void _hatayiGoster() {
    final hata = ref.read(urunFormViewModelSaglayici).error;
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
    final islemSuruyor = ref.watch(urunFormViewModelSaglayici).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_duzenlemeMi ? Metinler.urunDuzenle : Metinler.urunEkle),
        actions: [
          if (_duzenlemeMi)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: Metinler.urunPasifeAl,
              onPressed: islemSuruyor ? null : _listedenKaldir,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formAnahtari,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _KimlikAlani(
                kontrolcu: _tur,
                etiket: Metinler.tur,
                ipucu: Metinler.turIpucu,
                simge: Icons.sell_outlined,
                aciklama: Metinler.turAciklama,
                enabled: !islemSuruyor,
                odaklan: !_duzenlemeMi,
                validator: UrunDogrulama.tur,
                onListe: () => _secenekSec(SecenekTipi.tur),
              ),
              const SizedBox(height: 16),
              _KimlikAlani(
                kontrolcu: _cesit,
                etiket: Metinler.cesit,
                ipucu: Metinler.cesitIpucu,
                simge: Icons.label_outline,
                enabled: !islemSuruyor,
                onListe: () => _secenekSec(SecenekTipi.cesit),
              ),
              const SizedBox(height: 16),
              _KimlikAlani(
                kontrolcu: _anac,
                etiket: Metinler.anac,
                ipucu: Metinler.anacIpucu,
                simge: Icons.account_tree_outlined,
                enabled: !islemSuruyor,
                onListe: () => _secenekSec(SecenekTipi.anac),
              ),
              const SizedBox(height: 16),
              _AdOnizlemesi(tur: _tur, cesit: _cesit, anac: _anac),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fiyat,
                enabled: !islemSuruyor,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                validator: UrunDogrulama.fiyat,
                decoration: const InputDecoration(
                  labelText: Metinler.urunFiyati,
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: paraSimgesi,
                  helperText: Metinler.urunFiyatiAciklama,
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 32),
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
      ),
    );
  }
}

/// Tür, çeşit ve anaç kutularının ortak biçimi.
///
/// Üçü de aynı görünür; tek fark türün zorunlu olması ve altındaki açıklama.
/// Sağdaki düğme kutunun kendi listesini açar (bkz. `SecenekListesiEkrani`);
/// kutu yine de serbest metin kalır.
class _KimlikAlani extends StatelessWidget {
  const _KimlikAlani({
    required this.kontrolcu,
    required this.etiket,
    required this.ipucu,
    required this.simge,
    required this.enabled,
    required this.onListe,
    this.aciklama,
    this.odaklan = false,
    this.validator,
  });

  final TextEditingController kontrolcu;
  final String etiket;
  final String ipucu;
  final IconData simge;
  final bool enabled;
  final VoidCallback onListe;
  final String? aciklama;
  final bool odaklan;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: kontrolcu,
      enabled: enabled,
      autofocus: odaklan,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.next,
      validator: validator,
      decoration: InputDecoration(
        labelText: etiket,
        hintText: ipucu,
        prefixIcon: Icon(simge),
        suffixIcon: IconButton(
          icon: const Icon(Icons.list_alt_outlined),
          tooltip: Metinler.listedenSec,
          onPressed: enabled ? onListe : null,
        ),
        helperText: aciklama,
        helperMaxLines: 2,
      ),
    );
  }
}

/// Üç kutudan üretilen adı canlı gösterir: `Elma Scarlet M9`.
///
/// Ad ayrı bir alan değil, parçalardan türetiliyor (bkz. [urunAdi]); kullanıcı
/// faturaya ne düşeceğini kaydetmeden görmeli. Kutular boşken satır hiç
/// çizilmez, boş bir kutu görünmesin.
class _AdOnizlemesi extends StatelessWidget {
  const _AdOnizlemesi({
    required this.tur,
    required this.cesit,
    required this.anac,
  });

  final TextEditingController tur;
  final TextEditingController cesit;
  final TextEditingController anac;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[tur, cesit, anac]),
      builder: (context, _) {
        final ad = urunAdi(
          tur: tur.text,
          cesit: cesit.text,
          anac: anac.text,
        );
        if (ad.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tema.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Metinler.urunAdiOnizleme,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ad,
                style: tema.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
