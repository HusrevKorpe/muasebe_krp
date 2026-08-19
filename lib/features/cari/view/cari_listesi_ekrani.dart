import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/tasarim/olculer.dart';
import '../../../app/tasarim/yuzen_dugme.dart';
import '../../../app/yollar.dart';
import '../../../core/metin/metinler.dart';
import '../../../domain/cari/cari_grubu.dart';
import '../../../domain/cari/cari_suzgeci.dart';
import 'widget/cari_liste_gorunumu.dart';

/// Kişiler sekmesi: kişi listesi üç görünümde.
///
/// "Müşteriler" ve "Fidancılar" aynı listeyi gruba göre ikiye ayırır (bkz.
/// `CariGrubu`); "Açık Hesaplar" grup gözetmeden bakiyesi sıfır olmayanları
/// borç büyüklüğüne göre listeler. İki istek de kullanıcıdan geldi:
/// *"hesabı kapanmayanları ayrı bir sekmede görebilelim"* ve *"fidancıları
/// aynı şekilde başka bir sekmede yapalım."*
///
/// Sekmeler alt gezinme çubuğuna değil ekranın içine kondu: üçü de aynı
/// listenin görünümü, ayrı bir bölüm değil. Yeni kişi düğmesi üçünde ortak.
class CariListesiEkrani extends StatefulWidget {
  const CariListesiEkrani({super.key});

  @override
  State<CariListesiEkrani> createState() => _CariListesiEkraniDurumu();
}

class _CariListesiEkraniDurumu extends State<CariListesiEkrani>
    with SingleTickerProviderStateMixin {
  late final TabController _sekmeler = TabController(
    length: _sekmeSuzgecleri.length,
    vsync: this,
  );

  static const List<CariSuzgeci> _sekmeSuzgecleri = <CariSuzgeci>[
    CariSuzgeci.musteriler,
    CariSuzgeci.fidancilar,
    CariSuzgeci.acikHesap,
  ];

  /// Açık sekmenin karşılığı olan grup — yeni kişi formu bununla açılıyor.
  ///
  /// Açık hesap sekmesi iki gruptan besleniyor, orada bir tercih yok: müşteri.
  /// Değer düğmeye basıldığı anda okunuyor, o yüzden sekme değişiminde ekranı
  /// yeniden çizmek gerekmiyor.
  CariGrubu get _acikSekmeninGrubu =>
      _sekmeSuzgecleri[_sekmeler.index].sunucuGrubu ?? CariGrubu.musteri;

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
          // Üç sekme dar ekranda sığmıyor; kaydırılabilir çubuk yerine
          // etiketleri sıkıştırmak seçildi — üçü de bir bakışta görünmeli.
          labelPadding: const EdgeInsets.symmetric(horizontal: Olculer.bosluk8),
          tabs: const <Widget>[
            Tab(text: Metinler.cariSekmeMusteriler),
            Tab(text: Metinler.cariSekmeFidancilar),
            Tab(text: Metinler.cariSekmeAcikHesap),
          ],
        ),
      ),
      body: TabBarView(
        controller: _sekmeler,
        children: <Widget>[
          for (final suzgec in _sekmeSuzgecleri)
            CariListeGorunumu(suzgec: suzgec),
        ],
      ),
      floatingActionButton: YuzenDugme(
        // Alt sekmeler `IndexedStack` ile aynı anda ağaçta duruyor; sekmelerin
        // yüzen düğmesi varsayılan hero etiketini paylaşırsa Flutter "multiple
        // heroes share the same tag" diye patlıyor.
        kimlik: 'cariEkle',
        onBasildi: () => context.push(Yollar.cariYeniYolu(_acikSekmeninGrubu)),
        simge: Icons.person_add_alt,
        metin: Metinler.cariEkle,
      ),
    );
  }
}
