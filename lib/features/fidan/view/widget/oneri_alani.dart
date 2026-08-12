import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/metin/metinler.dart';
import '../../../../core/metin/turkce.dart' as turkce;
import '../../../../domain/fidan/fidan_oneri_alani.dart';
import '../../viewmodel/fidan_saglayici.dart';

/// Geçmiş girişlerden öneri sunan metin alanı — tür ve anaç için.
///
/// Ayrı bir "türler" koleksiyonu tutulmuyor; öneriler katalogdaki fidanlardan
/// türetiliyor (bkz. [FidanOneriAlani]). Kullanıcı "El" yazınca daha önce
/// girdiği "Elma" altta bir çip olarak beliriyor ve dokununca alanı dolduruyor.
class OneriAlani extends StatelessWidget {
  const OneriAlani({
    required this.alan,
    required this.kontrolcu,
    required this.etiket,
    required this.ipucu,
    required this.simge,
    this.dogrulayici,
    this.etkin = true,
    this.onDegisti,
    super.key,
  });

  final FidanOneriAlani alan;
  final TextEditingController kontrolcu;
  final String etiket;
  final String ipucu;
  final IconData simge;
  final String? Function(String?)? dogrulayici;
  final bool etkin;
  final ValueChanged<String>? onDegisti;

  void _oneriyiUygula(String oneri) {
    kontrolcu.value = TextEditingValue(
      text: oneri,
      selection: TextSelection.collapsed(offset: oneri.length),
    );
    onDegisti?.call(oneri);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: kontrolcu,
          enabled: etkin,
          validator: dogrulayici,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: etiket,
            hintText: ipucu,
            prefixIcon: Icon(simge),
          ),
          onChanged: onDegisti,
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: kontrolcu,
          builder: (context, deger, _) => _Oneriler(
            alan: alan,
            yazilan: deger.text,
            onSecildi: etkin ? _oneriyiUygula : null,
          ),
        ),
      ],
    );
  }
}

/// Alanın altındaki öneri çipleri.
class _Oneriler extends ConsumerWidget {
  const _Oneriler({
    required this.alan,
    required this.yazilan,
    required this.onSecildi,
  });

  final FidanOneriAlani alan;
  final String yazilan;
  final ValueChanged<String>? onSecildi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anahtar = turkce.aramaAnahtari(yazilan);

    // Sorgu yalnızca **ilk harfle** anahtarlanıyor: "E", "El", "Elm", "Elma"
    // tek bir Firestore okumasına düşer, daralan eşleşme burada süzülür.
    final istek = (
      alan: alan,
      onek: anahtar.isEmpty ? '' : anahtar.substring(0, 1),
    );
    final oneriler = ref.watch(fidanOnerileriSaglayici(istek)).value;
    if (oneriler == null || oneriler.isEmpty) return const SizedBox.shrink();

    final eslesenler = oneriler
        .where(
          (oneri) =>
              turkce.aramaAnahtari(oneri).startsWith(anahtar) &&
              turkce.aramaAnahtari(oneri) != anahtar,
        )
        .toList(growable: false);
    if (eslesenler.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Metinler.oneriler,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final oneri in eslesenler)
                ActionChip(
                  label: Text(oneri),
                  onPressed: onSecildi == null ? null : () => onSecildi!(oneri),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
