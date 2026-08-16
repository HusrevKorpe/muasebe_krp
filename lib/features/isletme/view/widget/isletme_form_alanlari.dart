import 'package:flutter/material.dart';

import '../../../../app/tasarim/olculer.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../domain/isletme/isletme_dogrulama.dart';
import 'isletme_form_kontrolculeri.dart';

/// İşletme profilinin metin alanları.
///
/// Alanların **hiçbiri zorunlu değil**: bu bilgiler yalnızca ekstre başlığına
/// basılıyor, boş bırakılırsa başlık sade çıkar. Etiketlerde "(isteğe bağlı)"
/// eki yok — tamamı isteğe bağlı olduğu için her satıra aynı eki koymak
/// gürültüden başka bir şey olmazdı; formun başındaki açıklama bunu söylüyor.
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
        ),
        _alan(
          kontrolcu: kontrolcular.unvan,
          etiket: Metinler.isletmeUnvan,
          ipucu: Metinler.isletmeUnvanIpucu,
          simge: Icons.badge_outlined,
        ),
        _alan(
          kontrolcu: kontrolcular.adres,
          etiket: Metinler.adres,
          simge: Icons.location_on_outlined,
          satirSayisi: 3,
        ),
        _alan(
          kontrolcu: kontrolcular.telefon,
          etiket: Metinler.telefon,
          simge: Icons.phone_outlined,
          klavye: TextInputType.phone,
          dogrulayici: IsletmeDogrulama.telefon,
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
      padding: const EdgeInsets.only(bottom: Olculer.bosluk16),
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
