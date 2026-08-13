import 'package:flutter/material.dart';

import '../../../core/metin/metinler.dart';
import '../../../domain/urun/urun.dart';
import 'widget/urun_listesi.dart';

/// Fatura kalemi için listeden ürün seçme sayfası.
///
/// Seçim **zorunlu değildir**: kullanıcı vazgeçip kalem adını elle yazabilir.
/// Nakliye, hizmet gibi kalemler listede yer almaz ve bu yol kapanırsa
/// kullanıcı tezgahta tıkanır (bkz. `fazlar/faz-3-katalog.md` riskler).
class UrunSecimSayfasi extends StatelessWidget {
  const UrunSecimSayfasi({super.key});

  /// Sayfayı açar. Kullanıcı vazgeçerse `null` döner.
  static Future<Urun?> goster(BuildContext context) {
    return Navigator.of(context).push<Urun>(
      MaterialPageRoute<Urun>(builder: (context) => const UrunSecimSayfasi()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Metinler.urunSec)),
      body: SafeArea(
        child: UrunListesi(
          onSecildi: (kayit) => Navigator.of(context).pop(kayit.urun),
        ),
      ),
    );
  }
}
