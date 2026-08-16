import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/tasarim/olculer.dart';
import '../../../app/tasarim/yuzen_dugme.dart';
import '../../../app/yollar.dart';
import '../../../core/metin/metinler.dart';
import 'widget/urun_listesi.dart';

/// Ürünler sekmesi: sattığımız şeylerin listesi, araması ve fiyatları.
class UrunListesiEkrani extends StatelessWidget {
  const UrunListesiEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Metinler.urunler)),
      body: SafeArea(
        child: UrunListesi(
          // Yüzen düğme son satırı örtmesin.
          altBosluk: Olculer.yuzenDugmeBoslugu,
          onSecildi: (kayit) =>
              context.push(Yollar.urunDuzenleYolu(kayit.urun.id)),
        ),
      ),
      floatingActionButton: YuzenDugme(
        // Kişiler sekmesindeki düğmeyle aynı hero etiketini paylaşmamalı —
        // bkz. `cari_listesi_ekrani.dart`.
        kimlik: 'urunEkle',
        onBasildi: () => context.push(Yollar.urunYeni),
        simge: Icons.add,
        metin: Metinler.urunEkle,
      ),
    );
  }
}
