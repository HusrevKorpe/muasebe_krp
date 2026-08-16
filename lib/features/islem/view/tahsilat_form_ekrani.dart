import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tasarim/dugme.dart';
import '../../../app/tasarim/olculer.dart';
import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../core/para/para_bicimi.dart';
import '../../../core/para/para_girisi.dart';
import '../../../domain/islem/islem.dart';
import '../../../domain/islem/islem_tipi.dart';
import '../../ortak/view/tarih_alani.dart';
import '../viewmodel/islem_form_viewmodel.dart';
import 'widget/duzenleme_uyarisi.dart';
import 'widget/islem_tipi_gorunumu.dart';

/// "Para aldım" ve "Para verdim" giriş formu.
///
/// Satıştan farkı satırı olmamasıdır: tek tutar, bir tarih ve bir açıklama.
/// Açıklama zorunlu değil; boş bırakılırsa tipin varsayılan metni yazılır
/// ("Müşteriden Tahsilat"), çünkü hesap dökümünde satırın bir açıklaması
/// olmalı.
///
/// [mevcut] verilirse kayıtlı bir tahsilat düzenlenir; yanlış girilmiş bir
/// tutar bu yoldan düzeltilir (bkz. `FaturaFormEkrani`).
class TahsilatFormEkrani extends ConsumerStatefulWidget {
  const TahsilatFormEkrani({
    required this.cariId,
    required this.tip,
    this.mevcut,
    super.key,
  });

  final String cariId;
  final IslemTipi tip;

  /// Düzenlenen kayıt. `null` ise yeni tahsilat girilir.
  final Islem? mevcut;

  @override
  ConsumerState<TahsilatFormEkrani> createState() =>
      _TahsilatFormEkraniDurumu();
}

class _TahsilatFormEkraniDurumu extends ConsumerState<TahsilatFormEkrani> {
  final _formAnahtari = GlobalKey<FormState>();
  late final TextEditingController _tutar = TextEditingController(
    text: widget.mevcut == null ? '' : kurusMetni(widget.mevcut!.toplam),
  );
  late final TextEditingController _baslik = TextEditingController(
    text: widget.mevcut?.baslik ?? widget.tip.varsayilanBaslik,
  );

  late DateTime _islemTarihi = widget.mevcut?.islemTarihi ?? _bugun();

  bool get _duzenlemeMi => widget.mevcut != null;

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

    final yazilan = _baslik.text.trim();
    final mevcut = widget.mevcut;
    final islem = Islem.odeme(
      id: mevcut?.id ?? '',
      tip: widget.tip,
      baslik: yazilan.isEmpty ? widget.tip.varsayilanBaslik : yazilan,
      islemTarihi: _islemTarihi,
      tutar: tutar,
    );

    final viewModel = ref.read(islemFormViewModelSaglayici.notifier);
    final basarili = mevcut == null
        ? await viewModel.kaydet(cariId: widget.cariId, islem: islem)
        : await viewModel.guncelle(
            cariId: widget.cariId,
            eski: mevcut,
            yeni: islem,
          );

    if (!mounted) return;
    if (basarili) {
      // Ekran kapanıyor; onay mesajı bir üstteki detay sayfasında görünsün.
      if (_duzenlemeMi) _uyariGoster(Metinler.islemGuncellendi);
      Navigator.of(context).pop(true);
    } else {
      final hata = ref.read(islemFormViewModelSaglayici).error;
      _uyariGoster(
        hata is UygulamaHatasi ? hata.mesaj : Metinler.beklenmeyenHata,
      );
    }
  }

  void _uyariGoster(String mesaj) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mesaj)));
  }

  @override
  Widget build(BuildContext context) {
    final islemSuruyor = ref.watch(islemFormViewModelSaglayici).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _duzenlemeMi
              ? '${widget.tip.ad} · ${Metinler.duzenle}'
              : widget.tip.ad,
        ),
      ),
      body: SafeArea(
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
              if (_duzenlemeMi) ...<Widget>[
                const DuzenlemeUyarisi(),
                const SizedBox(height: Olculer.bosluk20),
              ],
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
                // Tutar ekranın asıl girdisi; başlık boyunda yazılıyor ki
                // kullanıcı yazdığı rakamı klavyenin üstünden okuyabilsin.
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: const InputDecoration(
                  labelText: Metinler.tutar,
                  suffixText: paraSimgesi,
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: _tutarDogrula,
              ),
              const SizedBox(height: Olculer.bosluk16),
              TarihAlani(
                etiket: Metinler.islemTarihi,
                tarih: _islemTarihi,
                etkin: !islemSuruyor,
                onSecildi: (tarih) => setState(() => _islemTarihi = tarih),
              ),
              const SizedBox(height: Olculer.bosluk16),
              TextFormField(
                controller: _baslik,
                enabled: !islemSuruyor,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: '${Metinler.aciklama} (${Metinler.istegeBagli})',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: Olculer.bosluk32),
              Dugme.birincil(
                metin: Metinler.kaydet,
                onBasildi: _kaydet,
                yukleniyor: islemSuruyor,
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
