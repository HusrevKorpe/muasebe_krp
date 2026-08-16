import 'package:flutter/material.dart';

import '../../../app/tasarim/olculer.dart';
import '../../../app/tasarim/yuzen_dugme.dart';
import '../../../core/metin/metinler.dart';
import '../../../domain/secenek/secenek.dart';
import '../../../domain/secenek/secenek_tipi.dart';
import 'secenek_metinleri.dart';
import 'widget/secenek_dialogu.dart';
import 'widget/secenek_listesi.dart';

/// Tür, çeşit ya da anaç listesi. Aynı ekran iki işi görür.
///
/// * **Yönetim** ([secimMi] `false`) — Ayarlar → Listeler'den açılır. Satıra
///   dokunmak düzeltme kutusunu açar.
/// * **Seçim** ([secimMi] `true`) — fatura kalemi kutusundaki liste
///   düğmesinden açılır. Satıra dokunmak kutuyu doldurup geri döner; düzeltme
///   satırın sağındaki kaleme taşınır.
///
/// İkisi ayrı ekran olarak yazılmadı: aradaki tek fark dokunmanın ne yaptığı.
/// Seçim **zorunlu değil** — kullanıcı vazgeçip kutuya elle de yazabilir
/// (bkz. `UrunSecimSayfasi`).
class SecenekListesiEkrani extends StatelessWidget {
  const SecenekListesiEkrani({
    required this.tip,
    this.secimMi = false,
    super.key,
  });

  final SecenekTipi tip;
  final bool secimMi;

  /// Seçim sayfası olarak açar. Kullanıcı vazgeçerse `null` döner.
  static Future<String?> sec(BuildContext context, SecenekTipi tip) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (context) => SecenekListesiEkrani(tip: tip, secimMi: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(secimMi ? tip.secimBasligi : tip.listeBasligi),
      ),
      body: SafeArea(
        child: SecenekListesi(
          tip: tip,
          // Yüzen düğme son satırı örtmesin.
          altBosluk: Olculer.yuzenDugmeBoslugu,
          onSecildi: (kayit) {
            if (secimMi) {
              Navigator.of(context).pop(kayit.secenek.ad);
            } else {
              _duzenle(context, kayit.secenek);
            }
          },
          onDuzenle: secimMi
              ? (kayit) => _duzenle(context, kayit.secenek)
              : null,
        ),
      ),
      floatingActionButton: YuzenDugme(
        // Kişiler ve ürünler sekmesindeki düğmelerle aynı hero etiketini
        // paylaşmamalı — bkz. `urun_listesi_ekrani.dart`.
        kimlik: 'secenekEkle',
        onBasildi: () => _ekle(context),
        simge: Icons.add,
        metin: Metinler.secenekEkle,
      ),
    );
  }

  Future<void> _duzenle(BuildContext context, Secenek secenek) =>
      SecenekDialogu.goster(context, secenek);

  /// Yeni satır ekler.
  ///
  /// Seçim sayfasındaysak eklenen ad doğrudan kutuya gider: kullanıcı listede
  /// bulamadığı anacı ekleyip bir de listeden seçmek zorunda kalmasın. Bu, tam
  /// olarak tezgahta tıkanılan yer.
  Future<void> _ekle(BuildContext context) async {
    final ad = await SecenekDialogu.goster(context, Secenek.yeni(tip));
    if (ad == null || !secimMi || !context.mounted) return;

    Navigator.of(context).pop(ad);
  }
}
