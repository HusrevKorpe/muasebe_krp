import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../core/para/kurus.dart';
import '../../../core/para/para_bicimi.dart';
import '../../../core/para/para_girisi.dart';
import '../../../domain/urun/urun.dart';
import '../../../domain/urun/urun_dogrulama.dart';
import '../viewmodel/urun_form_viewmodel.dart';

/// Ürün ekleme ve düzenleme formu: ad ve fiyat.
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

  late final _ad = TextEditingController(text: widget.mevcut?.ad ?? '');
  late final _fiyat = TextEditingController(
    text: widget.mevcut == null || widget.mevcut!.fiyat.sifirMi
        ? ''
        : kurusMetni(widget.mevcut!.fiyat),
  );

  bool get _duzenlemeMi => widget.mevcut != null;

  @override
  void dispose() {
    _ad.dispose();
    _fiyat.dispose();
    super.dispose();
  }

  Urun _formdanUrun() {
    final mevcut = widget.mevcut;
    return Urun(
      id: mevcut?.id ?? '',
      ad: _ad.text.trim(),
      fiyat: kurusAyristir(_fiyat.text) ?? Kurus.sifir,
      aktif: mevcut?.aktif ?? true,
      olusturmaTarihi: mevcut?.olusturmaTarihi,
      guncellemeTarihi: mevcut?.guncellemeTarihi,
    );
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
              TextFormField(
                controller: _ad,
                enabled: !islemSuruyor,
                autofocus: !_duzenlemeMi,
                textCapitalization: TextCapitalization.sentences,
                validator: UrunDogrulama.ad,
                decoration: const InputDecoration(
                  labelText: Metinler.urunAdi,
                  hintText: Metinler.urunAdiIpucu,
                  prefixIcon: Icon(Icons.sell_outlined),
                ),
              ),
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
