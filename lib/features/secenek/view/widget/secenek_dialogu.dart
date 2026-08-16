import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/tasarim/dugme.dart';
import '../../../../app/tasarim/olculer.dart';
import '../../../../core/hata/hatalar.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../domain/secenek/secenek.dart';
import '../../../../domain/secenek/secenek_dogrulama.dart';
import '../../viewmodel/secenek_form_viewmodel.dart';
import '../secenek_metinleri.dart';

/// Listeye satır ekleme ve satırı düzeltme kutusu.
///
/// Tek alan var: ad. Kayıt başka bir şey taşımıyor (bkz. [Secenek]) ve girişin
/// tamamı bir kutuya sığdığı için ayrı bir ekran açılmıyor — kullanıcı seçim
/// sayfasındayken aradığını bulamazsa buradan ekleyip yoluna devam ediyor.
///
/// Hata mesajı kutunun içinde gösteriliyor, SnackBar ile değil: kutu açıkken
/// ekranın altındaki şerit modal perdenin arkasında kalır.
class SecenekDialogu extends ConsumerStatefulWidget {
  const SecenekDialogu({required this.mevcut, super.key});

  /// Düzeltilecek satır. Yeni kayıt için `Secenek.yeni(tip)` verilir.
  final Secenek mevcut;

  /// Kutuyu açar.
  ///
  /// Kaydedilirse **kaydedilen ad** döner; vazgeçilir ya da silinirse `null`.
  /// Adı geri vermesinin sebebi seçim akışı: kullanıcı listede bulamadığı
  /// anacı buradan ekleyince seçim sayfası kapanıp kutuya o adı yazsın.
  static Future<String?> goster(BuildContext context, Secenek mevcut) =>
      showDialog<String>(
        context: context,
        builder: (context) => SecenekDialogu(mevcut: mevcut),
      );

  @override
  ConsumerState<SecenekDialogu> createState() => _SecenekDialoguDurumu();
}

class _SecenekDialoguDurumu extends ConsumerState<SecenekDialogu> {
  final _formAnahtari = GlobalKey<FormState>();
  late final _ad = TextEditingController(text: widget.mevcut.ad);

  /// Kaydetme sırasında oluşan hata — mükerrer kayıt uyarısı buraya düşer.
  String? _hata;

  bool get _duzenlemeMi => !widget.mevcut.yeniMi;

  @override
  void dispose() {
    _ad.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (!_formAnahtari.currentState!.validate()) return;

    final ad = _ad.text.trim();
    final basarili = await ref
        .read(secenekFormViewModelSaglayici.notifier)
        .kaydet(widget.mevcut.kopyala(ad: ad));

    if (!mounted) return;
    if (basarili) {
      Navigator.of(context).pop(ad);
    } else {
      setState(() => _hata = _hataMesaji());
    }
  }

  Future<void> _sil() async {
    final onaylandi = await _onayAl();
    if (!onaylandi || !mounted) return;

    final mesajci = ScaffoldMessenger.of(context);
    final basarili = await ref
        .read(secenekFormViewModelSaglayici.notifier)
        .sil(widget.mevcut);

    if (!mounted) return;
    if (basarili) {
      // Kutu kapanıyor; onay mesajı altındaki listede görünsün.
      mesajci
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(Metinler.secenekSilindi)));
      Navigator.of(context).pop();
    } else {
      setState(() => _hata = _hataMesaji());
    }
  }

  Future<bool> _onayAl() async {
    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Metinler.secenekSil),
        content: const Text(Metinler.secenekSilOnay),
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
    return sonuc ?? false;
  }

  String _hataMesaji() {
    final hata = ref.read(secenekFormViewModelSaglayici).error;
    return hata is UygulamaHatasi ? hata.mesaj : Metinler.beklenmeyenHata;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final islemSuruyor = ref.watch(secenekFormViewModelSaglayici).isLoading;
    final tip = widget.mevcut.tip;

    return AlertDialog(
      title: Text(
        _duzenlemeMi ? Metinler.secenekDuzenle : Metinler.secenekEkle,
      ),
      content: Form(
        key: _formAnahtari,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kutu kaydetme sırasında da açık kalıyor. `IslemViewModel`'in
            // `build`'i async olduğu için ilk karede durum `loading`; kutu o
            // karede `enabled: false` çizilseydi `autofocus` boşa düşer ve
            // klavye açılmazdı. Kaydetme zaten ağa bağlanmıyor, kilitlenecek
            // bir bekleme yok (KURALLAR.md §4.4).
            TextFormField(
              controller: _ad,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              validator: SecenekDogrulama.ad,
              decoration: InputDecoration(
                labelText: tip.etiket,
                hintText: tip.ipucu,
              ),
              // Hata eskimiş olabilir: kullanıcı yazdığı anda kalkmalı.
              onChanged: (_) {
                if (_hata != null) setState(() => _hata = null);
              },
              onFieldSubmitted: islemSuruyor ? null : (_) => _kaydet(),
            ),
            if (_hata != null) ...[
              const SizedBox(height: Olculer.bosluk12),
              Text(
                _hata!,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        if (_duzenlemeMi)
          Dugme.tehlikeliSade(
            metin: Metinler.sil,
            kompakt: true,
            onBasildi: islemSuruyor ? null : _sil,
          ),
        Dugme.sade(
          metin: Metinler.vazgec,
          kompakt: true,
          onBasildi: islemSuruyor ? null : () => Navigator.of(context).pop(),
        ),
        Dugme.birincil(
          metin: Metinler.kaydet,
          kompakt: true,
          onBasildi: islemSuruyor ? null : _kaydet,
        ),
      ],
    );
  }
}
