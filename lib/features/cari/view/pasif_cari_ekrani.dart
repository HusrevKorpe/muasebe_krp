import 'package:flutter/material.dart';

import '../../../app/tasarim/olculer.dart';
import '../../../core/metin/metinler.dart';
import '../../../domain/cari/cari_suzgeci.dart';
import 'widget/cari_liste_gorunumu.dart';

/// Ayarlar → Kaldırılan Kişiler: listeden çıkarılmış kişiler ve geri alma.
///
/// Pasife alınan kişi hiçbir sekmede görünmüyor — üç sekmenin de sorgusu
/// `aktif == true` ile başlıyor — ve geri alma yolu yoktu. Kayıt Firestore'da
/// duruyordu ama kullanıcı için kaybolmuştu; bu sayfa o kayda tek kapı.
///
/// Sekme değil ayrı bir sayfa: kişi kaldırmak seyrek bir iş, geri almak daha da
/// seyrek. Alt gezinme çubuğunda ya da Kişiler ekranının dördüncü sekmesinde
/// yer kaplaması, günde yirmi kez bakılan listelerin yanında yanlış olurdu.
class PasifCariEkrani extends StatelessWidget {
  const PasifCariEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(Metinler.pasifCariler)),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Açıklama listenin üstünde duruyor: sayfayı ilk açan kullanıcı
            // satırlara neden dokunacağını bilmeli.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Olculer.sayfaKenari,
                Olculer.bosluk12,
                Olculer.sayfaKenari,
                0,
              ),
              child: Text(
                Metinler.pasifCarilerAciklama,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Expanded(
              child: CariListeGorunumu(suzgec: CariSuzgeci.pasifler),
            ),
          ],
        ),
      ),
    );
  }
}
