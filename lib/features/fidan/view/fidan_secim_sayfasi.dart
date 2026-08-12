import 'package:flutter/material.dart';

import '../../../core/metin/metinler.dart';
import '../../../domain/fidan/fidan.dart';
import 'widget/fidan_katalog_listesi.dart';

/// Fatura kalemi için katalogdan fidan seçme sayfası.
///
/// Seçim **zorunlu değildir**: kullanıcı vazgeçip kalem adını elle yazabilir.
/// Nakliye, hizmet gibi kalemler katalogda yer almaz ve bu yol kapanırsa
/// kullanıcı tezgahta tıkanır (bkz. `fazlar/faz-3-katalog.md` riskler).
class FidanSecimSayfasi extends StatelessWidget {
  const FidanSecimSayfasi({super.key});

  /// Sayfayı açar. Kullanıcı vazgeçerse `null` döner.
  static Future<Fidan?> goster(BuildContext context) {
    return Navigator.of(context).push<Fidan>(
      MaterialPageRoute<Fidan>(builder: (context) => const FidanSecimSayfasi()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Metinler.fidanSec)),
      body: SafeArea(
        child: FidanKatalogListesi(
          onSecildi: (kayit) => Navigator.of(context).pop(kayit.fidan),
        ),
      ),
    );
  }
}
