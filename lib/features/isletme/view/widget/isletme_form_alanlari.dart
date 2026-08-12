import 'package:flutter/material.dart';

import '../../../../core/metin/metinler.dart';
import '../../../../domain/isletme/isletme_dogrulama.dart';
import 'isletme_form_kontrolculeri.dart';

/// İşletme profilinin metin alanları.
///
/// Alanların çoğu zorunlu: bu bilgiler ekstre başlığına basılıyor ve eksik
/// bırakılırsa müşteriye yarım başlıklı belge gider.
class IsletmeFormAlanlari extends StatelessWidget {
  const IsletmeFormAlanlari({
    required this.kontrolcular,
    required this.etkin,
    super.key,
  });

  final IsletmeFormKontrolculeri kontrolcular;
  final bool etkin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _alan(
          kontrolcu: kontrolcular.ad,
          etiket: Metinler.isletmeAdi,
          ipucu: Metinler.isletmeAdiIpucu,
          simge: Icons.storefront_outlined,
          dogrulayici: IsletmeDogrulama.ad,
        ),
        _alan(
          kontrolcu: kontrolcular.unvan,
          etiket: '${Metinler.isletmeUnvan} (${Metinler.istegeBagli})',
          ipucu: Metinler.isletmeUnvanIpucu,
          simge: Icons.badge_outlined,
        ),
        _alan(
          kontrolcu: kontrolcular.adres,
          etiket: Metinler.adres,
          simge: Icons.location_on_outlined,
          dogrulayici: IsletmeDogrulama.adres,
          satirSayisi: 3,
        ),
        _alan(
          kontrolcu: kontrolcular.telefon,
          etiket: Metinler.telefon,
          simge: Icons.phone_outlined,
          klavye: TextInputType.phone,
          dogrulayici: IsletmeDogrulama.telefon,
        ),
        _alan(
          kontrolcu: kontrolcular.faks,
          etiket: '${Metinler.faks} (${Metinler.istegeBagli})',
          simge: Icons.print_outlined,
          klavye: TextInputType.phone,
        ),
        _alan(
          kontrolcu: kontrolcular.vergiDairesi,
          etiket: Metinler.vergiDairesi,
          simge: Icons.account_balance_outlined,
          dogrulayici: IsletmeDogrulama.vergiDairesi,
        ),
        _alan(
          kontrolcu: kontrolcular.vergiNo,
          etiket: Metinler.vergiNo,
          simge: Icons.numbers,
          klavye: TextInputType.number,
          dogrulayici: IsletmeDogrulama.vergiNo,
        ),
      ],
    );
  }

  Widget _alan({
    required TextEditingController kontrolcu,
    required String etiket,
    required IconData simge,
    String? ipucu,
    TextInputType? klavye,
    String? Function(String?)? dogrulayici,
    int satirSayisi = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: kontrolcu,
        enabled: etkin,
        validator: dogrulayici,
        keyboardType: klavye,
        maxLines: satirSayisi,
        textCapitalization: klavye == null
            ? TextCapitalization.words
            : TextCapitalization.none,
        decoration: InputDecoration(
          labelText: etiket,
          hintText: ipucu,
          prefixIcon: Icon(simge),
        ),
      ),
    );
  }
}
