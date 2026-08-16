import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/tasarim/yuzen_dugme.dart';
import '../../../app/yollar.dart';
import '../../../core/metin/metinler.dart';
import '../../../domain/cari/cari_suzgeci.dart';
import 'widget/cari_liste_gorunumu.dart';

/// Kişiler sekmesi: kişi listesi iki görünümde.
///
/// "Tümü" aktif kişilerin hepsini ada göre, "Açık Hesaplar" yalnızca bakiyesi
/// sıfır olmayanları borç büyüklüğüne göre listeler. Kullanıcının isteği:
/// *"hesabı kapanmayanları ayrı bir sekmede görebilelim."*
///
/// Sekmeler alt gezinme çubuğuna değil ekranın içine kondu: ikisi de aynı
/// listenin görünümü, ayrı bir bölüm değil. Yeni kişi düğmesi ikisinde ortak.
class CariListesiEkrani extends StatefulWidget {
  const CariListesiEkrani({super.key});

  @override
  State<CariListesiEkrani> createState() => _CariListesiEkraniDurumu();
}

class _CariListesiEkraniDurumu extends State<CariListesiEkrani>
    with SingleTickerProviderStateMixin {
  late final TabController _sekmeler = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _sekmeler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Metinler.cariler),
        bottom: TabBar(
          controller: _sekmeler,
          tabs: const <Widget>[
            Tab(text: Metinler.cariSekmeTumu),
            Tab(text: Metinler.cariSekmeAcikHesap),
          ],
        ),
      ),
      body: TabBarView(
        controller: _sekmeler,
        children: const <Widget>[
          CariListeGorunumu(suzgec: CariSuzgeci.tumu),
          CariListeGorunumu(suzgec: CariSuzgeci.acikHesap),
        ],
      ),
      floatingActionButton: YuzenDugme(
        // Alt sekmeler `IndexedStack` ile aynı anda ağaçta duruyor; iki sekmenin
        // yüzen düğmesi varsayılan hero etiketini paylaşırsa Flutter "multiple
        // heroes share the same tag" diye patlıyor.
        kimlik: 'cariEkle',
        onBasildi: () => context.push(Yollar.cariYeni),
        simge: Icons.person_add_alt,
        metin: Metinler.cariEkle,
      ),
    );
  }
}
