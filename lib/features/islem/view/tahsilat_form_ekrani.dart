import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../core/para/para_bicimi.dart';
import '../../../core/para/para_girisi.dart';
import '../../../domain/islem/islem.dart';
import '../../../domain/islem/islem_tipi.dart';
import '../../ortak/view/tarih_alani.dart';
import '../viewmodel/islem_form_viewmodel.dart';
import 'widget/islem_tipi_gorunumu.dart';

/// Tahsilat ve ödeme giriş formu.
///
/// Faturadan farkı kalemi, KDV'si ve vadesi olmamasıdır: tek tutar, bir tarih
/// ve bir açıklama.
class TahsilatFormEkrani extends ConsumerStatefulWidget {
  const TahsilatFormEkrani({
    required this.cariId,
    required this.tip,
    super.key,
  });

  final String cariId;
  final IslemTipi tip;

  @override
  ConsumerState<TahsilatFormEkrani> createState() =>
      _TahsilatFormEkraniDurumu();
}

class _TahsilatFormEkraniDurumu extends ConsumerState<TahsilatFormEkrani> {
  final _formAnahtari = GlobalKey<FormState>();
  final _tutar = TextEditingController();
  late final TextEditingController _baslik = TextEditingController(
    text: widget.tip.varsayilanBaslik,
  );

  late DateTime _islemTarihi = _bugun();

  static DateTime _bugun() {
    final an = DateTime.now();
    return DateTime(an.year, an.month, an.day);
  }

  @override
  void dispose() {
    _tutar.dispose();
    _baslik.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (!_formAnahtari.currentState!.validate()) return;

    final tutar = kurusAyristir(_tutar.text);
    if (tutar == null) return;

    final islem = Islem.odeme(
      tip: widget.tip,
      baslik: _baslik.text.trim(),
      islemTarihi: _islemTarihi,
      tutar: tutar,
    );

    final basarili = await ref
        .read(islemFormViewModelSaglayici.notifier)
        .kaydet(cariId: widget.cariId, islem: islem);

    if (!mounted) return;
    if (basarili) {
      Navigator.of(context).pop(true);
    } else {
      final hata = ref.read(islemFormViewModelSaglayici).error;
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
  }

  @override
  Widget build(BuildContext context) {
    final islemSuruyor = ref.watch(islemFormViewModelSaglayici).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(widget.tip.formBasligi)),
      body: SafeArea(
        child: Form(
          key: _formAnahtari,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              TextFormField(
                controller: _tutar,
                enabled: !islemSuruyor,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: const InputDecoration(
                  labelText: Metinler.tutar,
                  suffixText: paraSimgesi,
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: _tutarDogrula,
              ),
              const SizedBox(height: 16),
              TarihAlani(
                etiket: Metinler.islemTarihi,
                tarih: _islemTarihi,
                etkin: !islemSuruyor,
                onSecildi: (tarih) => setState(() => _islemTarihi = tarih),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _baslik,
                enabled: !islemSuruyor,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: Metinler.aciklama,
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (deger) => (deger ?? '').trim().isEmpty
                    ? Metinler.aciklamaGerekli
                    : null,
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

  static String? _tutarDogrula(String? deger) {
    if ((deger ?? '').trim().isEmpty) return Metinler.tutarGerekli;
    final tutar = kurusAyristir(deger);
    if (tutar == null) return Metinler.tutarGecersiz;
    return tutar.pozitifMi ? null : Metinler.tutarSifirOlamaz;
  }
}
