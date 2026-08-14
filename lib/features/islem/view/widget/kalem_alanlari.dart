import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/metin/metinler.dart';
import '../../../../core/para/para_bicimi.dart';
import '../../../../core/para/para_girisi.dart';
import '../../../../domain/islem/islem_kalemi.dart';
import '../../../../domain/islem/kalem_giris_modu.dart';
import '../../../../domain/secenek/secenek_tipi.dart';

/// [KalemDialogu] içindeki alanlar: ürün satırı, fidan kimliği, miktar, giriş
/// modu ve tutar.
///
/// Fidan kimliği tek kutu değil üç kutudur — Tür, Çeşit, Anaç — ve alt alta
/// durur. Kullanıcı satışı böyle söylüyor ("elma, scarlet, M9") ve kalem
/// düzenlemeye açıldığında parçalar kutularına geri dağılıyor; tek birleşik
/// metin bunu yapamıyordu (bkz. [IslemKalemi]).
///
/// Yalnızca Tür zorunlu: "nakliye" gibi satırlarda diğer ikisi boş kalır.
///
/// Her kutunun sağında kendi listesini açan bir düğme var: türler, çeşitler ve
/// anaçlar bir kez giriliyor, sonra her satışta yazmak yerine tıklanıyor
/// (bkz. [SecenekTipi]). Düğmeler üstte alt alta değil kutuların içinde
/// duruyor — kutu zaten uzun ve tutar alanı ekranın altına inmemeli.
class KalemAlanlari extends StatelessWidget {
  const KalemAlanlari({
    required this.tur,
    required this.cesit,
    required this.anac,
    required this.miktar,
    required this.deger,
    required this.mod,
    required this.urunBagliMi,
    required this.tureOdaklan,
    required this.onizleme,
    required this.onUrunSec,
    required this.onSecenekSec,
    required this.onBagiKaldir,
    required this.onModDegisti,
    required this.onDegisti,
    super.key,
  });

  final TextEditingController tur;
  final TextEditingController cesit;
  final TextEditingController anac;
  final TextEditingController miktar;
  final TextEditingController deger;
  final KalemGirisModu mod;
  final bool urunBagliMi;
  final bool tureOdaklan;

  /// Girilen değerlerden kurulan kalem; alanlar eksikse `null`.
  final IslemKalemi? onizleme;

  final VoidCallback onUrunSec;

  /// Kutunun sağındaki liste düğmesine basıldı: ilgili seçim sayfası açılır.
  final ValueChanged<SecenekTipi> onSecenekSec;

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
        _UrunSatiri(
          bagliMi: urunBagliMi,
          onSec: onUrunSec,
          onBagiKaldir: onBagiKaldir,
        ),
        const SizedBox(height: 12),
        _KimlikAlani(
          kontrolcu: tur,
          etiket: Metinler.tur,
          ipucu: Metinler.turIpucu,
          aciklama: Metinler.turAciklama,
          odaklan: tureOdaklan,
          validator: (deger) =>
              (deger ?? '').trim().isEmpty ? Metinler.kalemTuruGerekli : null,
          onDegisti: onDegisti,
          onListe: () => onSecenekSec(SecenekTipi.tur),
        ),
        const SizedBox(height: 12),
        _KimlikAlani(
          kontrolcu: cesit,
          etiket: Metinler.cesit,
          ipucu: Metinler.cesitIpucu,
          onDegisti: onDegisti,
          onListe: () => onSecenekSec(SecenekTipi.cesit),
        ),
        const SizedBox(height: 12),
        _KimlikAlani(
          kontrolcu: anac,
          etiket: Metinler.anac,
          ipucu: Metinler.anacIpucu,
          onDegisti: onDegisti,
          onListe: () => onSecenekSec(SecenekTipi.anac),
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

/// Tür, çeşit ve anaç kutularının ortak biçimi.
///
/// Üçü de aynı görünür; tek fark türün zorunlu olması ve altındaki açıklama.
/// Sağdaki düğme kutunun kendi listesini açar; kutu yine de serbest metin
/// kalır — listede olmayan bir şey yazılabilmeli (bkz. `SecenekListesiEkrani`).
class _KimlikAlani extends StatelessWidget {
  const _KimlikAlani({
    required this.kontrolcu,
    required this.etiket,
    required this.ipucu,
    required this.onDegisti,
    required this.onListe,
    this.aciklama,
    this.odaklan = false,
    this.validator,
  });

  final TextEditingController kontrolcu;
  final String etiket;
  final String ipucu;
  final String? aciklama;
  final bool odaklan;
  final FormFieldValidator<String>? validator;
  final VoidCallback onDegisti;
  final VoidCallback onListe;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: kontrolcu,
      autofocus: odaklan,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: etiket,
        hintText: ipucu,
        helperText: aciklama,
        helperMaxLines: 2,
        suffixIcon: IconButton(
          icon: const Icon(Icons.list_alt_outlined),
          tooltip: Metinler.listedenSec,
          onPressed: onListe,
        ),
      ),
      validator: validator,
      onChanged: (_) => onDegisti(),
    );
  }
}

/// Listeden seçme düğmesi ve bağlı ürün rozeti.
///
/// Rozet kaldırıldığında kalem serbest metne döner: kutulardaki yazı durur,
/// yalnızca ürün bağı kopar.
class _UrunSatiri extends StatelessWidget {
  const _UrunSatiri({
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
            icon: const Icon(Icons.sell_outlined),
            label: const Text(Metinler.urundenSec),
          ),
        ),
        if (bagliMi) ...[
          const SizedBox(width: 8),
          InputChip(
            label: const Text(Metinler.urunBagi),
            onDeleted: onBagiKaldir,
            deleteButtonTooltipMessage: Metinler.urunBaginiKaldir,
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
/// girildiyse birim fiyat. Üstünde kalemin birleşik adı yazar — kullanıcı üç
/// kutudan faturaya ne düşeceğini kaydetmeden görsün.
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
            kalem.ad,
            style: tema.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
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
