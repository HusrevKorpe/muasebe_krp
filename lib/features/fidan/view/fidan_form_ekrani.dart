import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../core/para/kurus.dart';
import '../../../core/para/para_bicimi.dart';
import '../../../core/para/para_girisi.dart';
import '../../../domain/fidan/fidan.dart';
import '../../../domain/fidan/fidan_dogrulama.dart';
import '../../../domain/fidan/fidan_oneri_alani.dart';
import '../../../domain/fidan/kok_tipi.dart';
import '../viewmodel/fidan_form_viewmodel.dart';
import 'widget/kok_tipi_secici.dart';
import 'widget/oneri_alani.dart';

/// Fidan ekleme ve düzenleme formu.
///
/// [mevcut] `null` ise yeni kayıt açılır. Görünen ad alanlardan üretiliyor
/// ([Fidan.goruntuAdi]); form onu canlı önizleme olarak gösterir ki kullanıcı
/// faturada hangi metni göreceğini kaydetmeden bilsin.
class FidanFormEkrani extends ConsumerStatefulWidget {
  const FidanFormEkrani({this.mevcut, super.key});

  final Fidan? mevcut;

  @override
  ConsumerState<FidanFormEkrani> createState() => _FidanFormEkraniDurumu();
}

class _FidanFormEkraniDurumu extends ConsumerState<FidanFormEkrani> {
  final _formAnahtari = GlobalKey<FormState>();

  late final _tur = TextEditingController(text: widget.mevcut?.tur ?? '');
  late final _cesit = TextEditingController(text: widget.mevcut?.cesit ?? '');
  late final _anac = TextEditingController(text: widget.mevcut?.anac ?? '');
  late final _yas = TextEditingController(
    text: widget.mevcut?.yas?.toString() ?? '',
  );
  late final _fiyat = TextEditingController(
    text: widget.mevcut == null || widget.mevcut!.varsayilanFiyat.sifirMi
        ? ''
        : kurusMetni(widget.mevcut!.varsayilanFiyat),
  );

  late KokTipi? _kokTipi = widget.mevcut?.kokTipi;

  bool get _duzenlemeMi => widget.mevcut != null;

  @override
  void dispose() {
    _tur.dispose();
    _cesit.dispose();
    _anac.dispose();
    _yas.dispose();
    _fiyat.dispose();
    super.dispose();
  }

  Fidan _formdanFidan() {
    final mevcut = widget.mevcut;
    final anac = _anac.text.trim();

    return Fidan(
      id: mevcut?.id ?? '',
      tur: _tur.text.trim(),
      cesit: _cesit.text.trim(),
      anac: anac.isEmpty ? null : anac,
      yas: int.tryParse(_yas.text.trim()),
      kokTipi: _kokTipi,
      varsayilanFiyat: kurusAyristir(_fiyat.text) ?? Kurus.sifir,
      aktif: mevcut?.aktif ?? true,
      olusturmaTarihi: mevcut?.olusturmaTarihi,
      guncellemeTarihi: mevcut?.guncellemeTarihi,
    );
  }

  Future<void> _kaydet() async {
    if (!_formAnahtari.currentState!.validate()) return;

    final basarili = await ref
        .read(fidanFormViewModelSaglayici.notifier)
        .kaydet(_formdanFidan());

    if (!mounted) return;
    if (basarili) {
      Navigator.of(context).pop(true);
    } else {
      _hatayiGoster();
    }
  }

  Future<void> _katalogdanKaldir() async {
    final onaylandi = await _onayAl(
      baslik: Metinler.fidanPasifeAl,
      mesaj: Metinler.fidanPasifeAlOnay,
    );
    if (!onaylandi || !mounted) return;

    final basarili = await ref
        .read(fidanFormViewModelSaglayici.notifier)
        .pasifeAl(widget.mevcut!.id);

    if (!mounted) return;
    if (basarili) {
      // Ekran kapanıyor; onay mesajı bir üstteki listede görünsün.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(Metinler.fidanPasifeAlindi)),
        );
      Navigator.of(context).pop(false);
    } else {
      _hatayiGoster();
    }
  }

  Future<bool> _onayAl({required String baslik, required String mesaj}) async {
    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(baslik),
        content: Text(mesaj),
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
    final hata = ref.read(fidanFormViewModelSaglayici).error;
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
    final islemSuruyor = ref.watch(fidanFormViewModelSaglayici).isLoading;
    final etkin = !islemSuruyor;

    return Scaffold(
      appBar: AppBar(
        title: Text(_duzenlemeMi ? Metinler.fidanDuzenle : Metinler.fidanEkle),
        actions: [
          if (_duzenlemeMi)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: Metinler.fidanPasifeAl,
              onPressed: etkin ? _katalogdanKaldir : null,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formAnahtari,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _Onizleme(fidan: _formdanFidan()),
              const SizedBox(height: 24),
              _Alanlar(
                tur: _tur,
                cesit: _cesit,
                anac: _anac,
                yas: _yas,
                fiyat: _fiyat,
                kokTipi: _kokTipi,
                etkin: etkin,
                onKokTipi: (tip) => setState(() => _kokTipi = tip),
                onDegisti: () => setState(() {}),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: etkin ? _kaydet : null,
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

/// Fidanın alanları: tür, çeşit, anaç, yaş, kök tipi ve varsayılan fiyat.
class _Alanlar extends StatelessWidget {
  const _Alanlar({
    required this.tur,
    required this.cesit,
    required this.anac,
    required this.yas,
    required this.fiyat,
    required this.kokTipi,
    required this.etkin,
    required this.onKokTipi,
    required this.onDegisti,
  });

  final TextEditingController tur;
  final TextEditingController cesit;
  final TextEditingController anac;
  final TextEditingController yas;
  final TextEditingController fiyat;
  final KokTipi? kokTipi;
  final bool etkin;
  final ValueChanged<KokTipi?> onKokTipi;
  final VoidCallback onDegisti;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OneriAlani(
          alan: FidanOneriAlani.tur,
          kontrolcu: tur,
          etiket: Metinler.tur,
          ipucu: Metinler.turIpucu,
          simge: Icons.park_outlined,
          dogrulayici: FidanDogrulama.tur,
          etkin: etkin,
          onDegisti: (_) => onDegisti(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: cesit,
          enabled: etkin,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: Metinler.cesit,
            hintText: Metinler.cesitIpucu,
            prefixIcon: Icon(Icons.eco_outlined),
          ),
          validator: FidanDogrulama.cesit,
          onChanged: (_) => onDegisti(),
        ),
        const SizedBox(height: 16),
        OneriAlani(
          alan: FidanOneriAlani.anac,
          kontrolcu: anac,
          etiket: '${Metinler.anac} (${Metinler.istegeBagli})',
          ipucu: Metinler.anacIpucu,
          simge: Icons.account_tree_outlined,
          etkin: etkin,
          onDegisti: (_) => onDegisti(),
        ),
        const SizedBox(height: 16),
        _YasAlani(kontrolcu: yas, etkin: etkin, onDegisti: onDegisti),
        const SizedBox(height: 16),
        KokTipiSecici(secili: kokTipi, etkin: etkin, onSecildi: onKokTipi),
        const SizedBox(height: 16),
        _FiyatAlani(kontrolcu: fiyat, etkin: etkin, onDegisti: onDegisti),
      ],
    );
  }
}

/// Alanlardan üretilen görünen adın canlı önizlemesi.
class _Onizleme extends StatelessWidget {
  const _Onizleme({required this.fidan});

  final Fidan fidan;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ad = fidan.goruntuAdi;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tema.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Metinler.fidanOnizlemeBaslik,
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ad.isEmpty ? Metinler.fidanOnizlemeBos : ad,
            style: tema.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: ad.isEmpty ? tema.colorScheme.outline : null,
            ),
          ),
          if (!fidan.varsayilanFiyat.sifirMi) ...[
            const SizedBox(height: 4),
            Text(
              fidan.varsayilanFiyat.bicimli,
              style: tema.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _YasAlani extends StatelessWidget {
  const _YasAlani({
    required this.kontrolcu,
    required this.etkin,
    required this.onDegisti,
  });

  final TextEditingController kontrolcu;
  final bool etkin;
  final VoidCallback onDegisti;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: kontrolcu,
      enabled: etkin,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: const InputDecoration(
        labelText: '${Metinler.yas} (${Metinler.istegeBagli})',
        hintText: Metinler.yasIpucu,
        prefixIcon: Icon(Icons.timelapse_outlined),
      ),
      validator: FidanDogrulama.yas,
      onChanged: (_) => onDegisti(),
    );
  }
}

class _FiyatAlani extends StatelessWidget {
  const _FiyatAlani({
    required this.kontrolcu,
    required this.etkin,
    required this.onDegisti,
  });

  final TextEditingController kontrolcu;
  final bool etkin;
  final VoidCallback onDegisti;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: kontrolcu,
      enabled: etkin,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: const InputDecoration(
        labelText: '${Metinler.varsayilanFiyat} (${Metinler.istegeBagli})',
        prefixIcon: Icon(Icons.sell_outlined),
        suffixText: paraSimgesi,
        helperText: Metinler.varsayilanFiyatAciklama,
        helperMaxLines: 2,
      ),
      validator: FidanDogrulama.varsayilanFiyat,
      onChanged: (_) => onDegisti(),
    );
  }
}
