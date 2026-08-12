import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/yollar.dart';
import '../../../core/metin/metinler.dart';
import 'widget/fidan_katalog_listesi.dart';

/// Fidan katalogu ekranı: türe göre gruplu liste, arama ve fiyatlar.
class FidanListesiEkrani extends StatelessWidget {
  const FidanListesiEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Metinler.fidanKatalogu)),
      body: SafeArea(
        child: FidanKatalogListesi(
          // Yüzen düğme son satırı örtmesin.
          altBosluk: 88,
          onSecildi: (kayit) =>
              context.push(Yollar.fidanDuzenleYolu(kayit.fidan.id)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Yollar.fidanYeni),
        icon: const Icon(Icons.add),
        label: const Text(Metinler.fidanEkle),
      ),
    );
  }
}
