import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/metin/metinler.dart';
import '../../../../core/para/para_bicimi.dart';
import '../../../../core/para/para_girisi.dart';
import '../../../../domain/islem/islem_kalemi.dart';
import '../../../../domain/islem/kalem_giris_modu.dart';
import '../../../fidan/view/fidan_secim_sayfasi.dart';

/// Fatura kalemi ekleme/düzenleme kutusu.
///
/// Kullanıcı tutarı iki uçtan da girebilir: birim fiyattan ya da toplamdan.
/// İkinci mod zorunludur, çünkü kullanıcı yuvarlak toplam üzerinden çalışır —
/// referans ekstredeki `1.650 Adet × 18,79 ₺ = 31.000 ₺` satırı yalnızca böyle
/// tutar (bkz. [KalemGirisModu]).
///
/// Kalem adı katalogdan seçilebilir ama **serbest metin girişi korunur**:
/// "nakliye" gibi kalemler katalogda yer almaz ve katalog zorunlu olsaydı
/// kullanıcı tezgahta tıkanırdı (bkz. `fazlar/faz-3-katalog.md`).
class KalemDialogu extends StatefulWidget {
  const KalemDialogu({this.mevcut, super.key});

  final IslemKalemi? mevcut;

  /// Kutuyu açar. Kullanıcı vazgeçerse `null` döner.
  static Future<IslemKalemi?> goster(
    BuildContext context, {
    IslemKalemi? mevcut,
  }) => showDialog<IslemKalemi>(
    context: context,
    builder: (context) => KalemDialogu(mevcut: mevcut),
  );

  @override
  State<KalemDialogu> createState() => _KalemDialoguDurumu();
}

class _KalemDialoguDurumu extends State<KalemDialogu> {
  final _formAnahtari = GlobalKey<FormState>();
  late final TextEditingController _ad;
  late final TextEditingController _miktar;
  late final TextEditingController _deger;

  KalemGirisModu _mod = KalemGirisModu.birimFiyat;

  /// Katalogdan seçilen fidanın kimliği. Serbest metin kalemlerde `null` kalır
  /// ve Faz 2'de girilmiş eski kalemler bu hâliyle bozulmadan açılır.
  String? _fidanId;

  bool get _duzenlemeMi => widget.mevcut != null;

  @override
  void initState() {
    super.initState();
    final mevcut = widget.mevcut;
    _fidanId = mevcut?.fidanId;
    // Düzenlemede toplam gösterilir: kayıtta esas olan tutardır, birim fiyat
    // ondan türetilmiş olabilir.
    _mod = mevcut != null && mevcut.birimFiyatYuvarlanmisMi
        ? KalemGirisModu.toplam
        : KalemGirisModu.birimFiyat;
    _ad = TextEditingController(text: mevcut?.ad ?? '');
    _miktar = TextEditingController(
      text: mevcut == null ? '' : miktarBicimle(mevcut.miktar),
    );
    _deger = TextEditingController(
      text: mevcut == null
          ? ''
          : kurusMetni(
              _mod == KalemGirisModu.toplam ? mevcut.tutar : mevcut.birimFiyat,
            ),
    );
  }

  @override
  void dispose() {
    _ad.dispose();
    _miktar.dispose();
    _deger.dispose();
    super.dispose();
  }

  /// Girilen değerlerden kalemi kurar. Alanlar geçersizse `null` döner.
  IslemKalemi? _kalemiKur() {
    final miktar = miktarAyristir(_miktar.text);
    final deger = kurusAyristir(_deger.text);
    if (miktar == null || miktar <= 0 || deger == null) return null;

    final ad = _ad.text.trim();
    return switch (_mod) {
      KalemGirisModu.birimFiyat => IslemKalemi.birimFiyattan(
        ad: ad,
        miktar: miktar,
        birimFiyat: deger,
        fidanId: _fidanId,
      ),
      KalemGirisModu.toplam => IslemKalemi.toplamdan(
        ad: ad,
        miktar: miktar,
        toplam: deger,
        fidanId: _fidanId,
      ),
    };
  }

  void _kaydet() {
    if (!_formAnahtari.currentState!.validate()) return;
    final kalem = _kalemiKur();
    if (kalem == null) return;
    Navigator.of(context).pop(kalem);
  }

  /// Katalogdan fidan seçer: ad ve birim fiyat ön dolgu gelir.
  ///
  /// Gelen fiyat yalnızca bir başlangıç değeridir; kullanıcı alanı olduğu gibi
  /// değiştirebilir. Faturaya giren tutar katalogdaki fiyattan bağımsızdır
  /// (bkz. KURALLAR.md §3.2).
  Future<void> _katalogdanSec() async {
    final fidan = await FidanSecimSayfasi.goster(context);
    if (fidan == null || !mounted) return;

    setState(() {
      _fidanId = fidan.id;
      _ad.text = fidan.goruntuAdi;
      if (!fidan.varsayilanFiyat.sifirMi) {
        _mod = KalemGirisModu.birimFiyat;
        _deger.text = kurusMetni(fidan.varsayilanFiyat);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_duzenlemeMi ? Metinler.kalemDuzenle : Metinler.kalemEkle),
      content: SingleChildScrollView(
        child: Form(
          key: _formAnahtari,
          child: _KalemAlanlari(
            ad: _ad,
            miktar: _miktar,
            deger: _deger,
            mod: _mod,
            katalogaBagliMi: _fidanId != null,
            adaOdaklan: !_duzenlemeMi,
            onizleme: _kalemiKur(),
            onKatalogdanSec: _katalogdanSec,
            onBagiKaldir: () => setState(() => _fidanId = null),
            onModDegisti: (mod) => setState(() => _mod = mod),
            onDegisti: () => setState(() {}),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(Metinler.vazgec),
        ),
        FilledButton(
          onPressed: _kaydet,
          child: Text(_duzenlemeMi ? Metinler.kaydet : Metinler.ekle),
        ),
      ],
    );
  }
}

/// Kutunun içindeki alanlar: katalog satırı, ad, miktar, giriş modu ve tutar.
class _KalemAlanlari extends StatelessWidget {
  const _KalemAlanlari({
    required this.ad,
    required this.miktar,
    required this.deger,
    required this.mod,
    required this.katalogaBagliMi,
    required this.adaOdaklan,
    required this.onizleme,
    required this.onKatalogdanSec,
    required this.onBagiKaldir,
    required this.onModDegisti,
    required this.onDegisti,
  });

  final TextEditingController ad;
  final TextEditingController miktar;
  final TextEditingController deger;
  final KalemGirisModu mod;
  final bool katalogaBagliMi;
  final bool adaOdaklan;

  /// Girilen değerlerden kurulan kalem; alanlar eksikse `null`.
  final IslemKalemi? onizleme;

  final VoidCallback onKatalogdanSec;
  final VoidCallback onBagiKaldir;
  final ValueChanged<KalemGirisModu> onModDegisti;
  final VoidCallback onDegisti;

  bool get _birimFiyatModu => mod == KalemGirisModu.birimFiyat;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KatalogSatiri(
          bagliMi: katalogaBagliMi,
          onSec: onKatalogdanSec,
          onBagiKaldir: onBagiKaldir,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: ad,
          autofocus: adaOdaklan,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: Metinler.kalemAdi,
            hintText: Metinler.kalemAdiIpucu,
            helperText: Metinler.katalogSerbestMetinAciklama,
            helperMaxLines: 2,
          ),
          validator: (deger) =>
              (deger ?? '').trim().isEmpty ? Metinler.kalemAdiGerekli : null,
          onChanged: (_) => onDegisti(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: miktar,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(
            labelText: Metinler.miktar,
            suffixText: IslemKalemi.varsayilanBirim,
          ),
          validator: _miktarDogrula,
          onChanged: (_) => onDegisti(),
        ),
        const SizedBox(height: 16),
        _ModSecici(mod: mod, onDegisti: onModDegisti),
        const SizedBox(height: 12),
        TextFormField(
          controller: deger,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            labelText: _birimFiyatModu
                ? Metinler.birimFiyat
                : Metinler.toplamGir,
            suffixText: paraSimgesi,
            helperText: _birimFiyatModu
                ? Metinler.birimFiyatGirAciklama
                : Metinler.toplamGirAciklama,
            helperMaxLines: 2,
          ),
          validator: _tutarDogrula,
          onChanged: (_) => onDegisti(),
        ),
        if (onizleme != null) ...[
          const SizedBox(height: 16),
          _Onizleme(kalem: onizleme!, mod: mod),
        ],
      ],
    );
  }

  static String? _miktarDogrula(String? deger) {
    if ((deger ?? '').trim().isEmpty) return Metinler.miktarGerekli;
    final miktar = miktarAyristir(deger);
    if (miktar == null) return Metinler.miktarGecersiz;
    return miktar <= 0 ? Metinler.miktarGecersiz : null;
  }

  static String? _tutarDogrula(String? deger) {
    if ((deger ?? '').trim().isEmpty) return Metinler.tutarGerekli;
    final tutar = kurusAyristir(deger);
    if (tutar == null) return Metinler.tutarGecersiz;
    return tutar.pozitifMi ? null : Metinler.tutarSifirOlamaz;
  }
}

/// Katalogdan seçme düğmesi ve bağlı fidan rozeti.
///
/// Rozet kaldırıldığında kalem serbest metne döner: ad alanındaki yazı durur,
/// yalnızca katalog bağı (`fidanId`) kopar.
class _KatalogSatiri extends StatelessWidget {
  const _KatalogSatiri({
    required this.bagliMi,
    required this.onSec,
    required this.onBagiKaldir,
  });

  final bool bagliMi;
  final VoidCallback onSec;
  final VoidCallback onBagiKaldir;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSec,
            icon: const Icon(Icons.park_outlined),
            label: const Text(Metinler.katalogdanSec),
          ),
        ),
        if (bagliMi) ...[
          const SizedBox(width: 8),
          InputChip(
            label: const Text(Metinler.katalogBagi),
            onDeleted: onBagiKaldir,
            deleteButtonTooltipMessage: Metinler.katalogBaginiKaldir,
          ),
        ],
      ],
    );
  }
}

/// Birim fiyat / toplam tutar seçimi.
class _ModSecici extends StatelessWidget {
  const _ModSecici({required this.mod, required this.onDegisti});

  final KalemGirisModu mod;
  final ValueChanged<KalemGirisModu> onDegisti;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Metinler.girisModu, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        SegmentedButton<KalemGirisModu>(
          segments: const <ButtonSegment<KalemGirisModu>>[
            ButtonSegment<KalemGirisModu>(
              value: KalemGirisModu.birimFiyat,
              label: Text(Metinler.birimFiyatGir),
            ),
            ButtonSegment<KalemGirisModu>(
              value: KalemGirisModu.toplam,
              label: Text(Metinler.toplamGir),
            ),
          ],
          selected: <KalemGirisModu>{mod},
          showSelectedIcon: false,
          onSelectionChanged: (secim) => onDegisti(secim.first),
        ),
      ],
    );
  }
}

/// Hesaplanan karşı değeri gösterir: birim fiyat girildiyse tutar, toplam
/// girildiyse birim fiyat.
class _Onizleme extends StatelessWidget {
  const _Onizleme({required this.kalem, required this.mod});

  final IslemKalemi kalem;
  final KalemGirisModu mod;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final hesaplanan = mod == KalemGirisModu.birimFiyat
        ? '${Metinler.tutar}: ${kalem.tutar.bicimli}'
        : '${Metinler.birimFiyat}: ${kalem.birimFiyat.bicimli}';

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
            '${miktarBicimle(kalem.miktar)} ${kalem.birim} × '
            '${kalem.birimFiyat.bicimli}',
            style: tema.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            hesaplanan,
            style: tema.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (kalem.birimFiyatYuvarlanmisMi) ...[
            const SizedBox(height: 6),
            Text(
              Metinler.birimFiyatYaklasik,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.tertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
