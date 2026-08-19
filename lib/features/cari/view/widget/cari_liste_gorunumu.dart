import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/tasarim/dugme.dart';
import '../../../../app/tasarim/olculer.dart';
import '../../../../app/yollar.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../domain/cari/cari_suzgeci.dart';
import '../../../ortak/view/bos_durum.dart';
import '../../../ortak/view/hata_durumu.dart';
import '../../viewmodel/cari_listesi_durumu.dart';
import '../../viewmodel/cari_listesi_viewmodel.dart';
import 'acik_hesap_ozeti_karti.dart';
import 'cari_arama_alani.dart';
import 'cari_satiri.dart';

/// Tek bir süzgecin kişi listesi — Kişiler ekranındaki bir sekmenin gövdesi.
///
/// Sekme başına bir örnek var: her biri kendi kaydırma konumunu, kendi sayfa
/// sınırını ve kendi arama metnini taşır.
class CariListeGorunumu extends ConsumerStatefulWidget {
  const CariListeGorunumu({required this.suzgec, super.key});

  final CariSuzgeci suzgec;

  @override
  ConsumerState<CariListeGorunumu> createState() => _CariListeGorunumuDurumu();
}

class _CariListeGorunumuDurumu extends ConsumerState<CariListeGorunumu> {
  /// Listenin sonuna bu kadar kala sonraki sayfa istenir; kullanıcı boşluğa
  /// bakmadan devamı gelsin diye.
  static const double _yuklemeEsigi = 400;

  final _kaydirmaKontrolcu = ScrollController();
  final _aramaKontrolcu = TextEditingController();

  @override
  void initState() {
    super.initState();
    _kaydirmaKontrolcu.addListener(_kaydirmayiDinle);
  }

  @override
  void dispose() {
    _kaydirmaKontrolcu
      ..removeListener(_kaydirmayiDinle)
      ..dispose();
    _aramaKontrolcu.dispose();
    super.dispose();
  }

  void _kaydirmayiDinle() {
    if (!_kaydirmaKontrolcu.hasClients) return;
    final konum = _kaydirmaKontrolcu.position;
    if (konum.pixels >= konum.maxScrollExtent - _yuklemeEsigi) {
      _dahaYukle();
    }
  }

  CariListesiViewModel get _viewModel =>
      ref.read(cariListesiViewModelSaglayici(widget.suzgec).notifier);

  void _dahaYukle() => _viewModel.dahaYukle();

  Future<void> _yenile() => _viewModel.yenile();

  /// Liste ekranı doldurmuyorsa sonraki sayfayı kendiliğinden ister.
  ///
  /// Müşteri sekmesinde sunucudan gelen sayfanın fidancıları elde ayıklanıyor
  /// (bkz. `CariSuzgeci.kayitGirerMi`); 25 belgelik bir sayfadan geriye ekranı
  /// doldurmayacak kadar az satır kalabilir. Kaydırma dinleyicisi ancak
  /// kaydırma olayıyla çalıştığı için "daha yükle" o hâlde hiç tetiklenmezdi.
  void _ekraniDoldur(CariListesiDurumu? veri) {
    if (veri == null || !veri.dahaVar || veri.dahaYukleniyor) return;

    // Liste boşken gövde boş durum ekranı; kaydırma denetleyicisi hiçbir listeye
    // bağlı değil ve konumu sorulamaz. Sunucuda okunmamış belge varken boş
    // durum göstermemek için sonraki sayfa doğrudan isteniyor.
    if (veri.bosMu) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _dahaYukle();
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_kaydirmaKontrolcu.hasClients) return;
      if (_kaydirmaKontrolcu.position.maxScrollExtent <= 0) _dahaYukle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final durum = ref.watch(cariListesiViewModelSaglayici(widget.suzgec));
    _ekraniDoldur(durum.value);

    return Column(
      children: [
        _baslik(durum.value),
        Expanded(
          child: durum.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (hata, _) => HataDurumu.hatadan(hata, yenidenDene: _yenile),
            data: _liste,
          ),
        ),
      ],
    );
  }

  /// Sekmenin üst şeridi: kişi sekmelerinde arama kutusu, açık hesaplarda
  /// toplam satırı. Açık hesapta arama yok — gerekçesi
  /// `CariRepository.listeyiIzle`'de.
  Widget _baslik(CariListesiDurumu? veri) {
    if (!widget.suzgec.acikHesapMi) {
      return CariAramaAlani(
        kontrolcu: _aramaKontrolcu,
        onDegisti: (metin) => _viewModel.aramayiDegistir(metin),
      );
    }
    // Liste boşken toplam satırı yerine boş durum ekranı konuşur.
    if (veri == null || veri.bosMu) return const SizedBox.shrink();

    return AcikHesapOzetiKarti(ozet: veri.ozet, eksikVar: veri.dahaVar);
  }

  Widget _liste(CariListesiDurumu veri) {
    if (veri.bosMu) {
      // Sunucuda okunmamış belge varken liste henüz "boş" değil: sonraki sayfa
      // yolda (bkz. [_ekraniDoldur]) ve boş durum yazısı bir anlığına yanıltır.
      return veri.dahaVar
          ? const Center(child: CircularProgressIndicator())
          : _bosDurum(veri);
    }

    // Son satır sonraki sayfanın göstergesi ya da hata satırı olur.
    final ekSatir = veri.dahaVar || veri.sayfaHatasi != null;

    return RefreshIndicator(
      onRefresh: _yenile,
      child: ListView.separated(
        controller: _kaydirmaKontrolcu,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: Olculer.yuzenDugmeBoslugu),
        itemCount: veri.kayitlar.length + (ekSatir ? 1 : 0),
        // Çizgi baş harf karesinin altından değil, yazının hizasından başlıyor;
        // tam genişlikte bir çizgi satırları kesip listeyi tabloya çeviriyordu.
        separatorBuilder: (context, sira) =>
            const Divider(indent: 78, endIndent: Olculer.sayfaKenari),
        itemBuilder: (context, sira) {
          if (sira >= veri.kayitlar.length) return _sayfaSonu(veri);

          final kayit = veri.kayitlar[sira];
          return CariSatiri(
            kayit: kayit,
            // Grup rozeti yalnızca iki grubun karıştığı sekmede anlamlı;
            // fidancı listesinde her satırda "Fidancı" yazmak gürültü olurdu.
            grubuGoster: widget.suzgec.acikHesapMi,
            onTap: () => context.push(Yollar.cariDetayYolu(kayit.cari.id)),
          );
        },
      ),
    );
  }

  Widget _sayfaSonu(CariListesiDurumu veri) {
    if (veri.sayfaHatasi != null) {
      return ListTile(
        leading: const Icon(Icons.error_outline),
        title: const Text(Metinler.dahaFazlaYuklenemedi),
        onTap: _dahaYukle,
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: Olculer.bosluk24),
      child: Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }

  Widget _bosDurum(CariListesiDurumu veri) {
    if (widget.suzgec.acikHesapMi) {
      return const BosDurum(
        simge: Icons.check_circle_outline,
        baslik: Metinler.acikHesapYokBaslik,
        aciklama: Metinler.acikHesapYokAciklama,
      );
    }
    if (veri.aramaVarMi) {
      return const BosDurum(
        simge: Icons.search_off,
        baslik: Metinler.aramaSonucuYokBaslik,
        aciklama: Metinler.aramaSonucuYokAciklama,
      );
    }
    // Fidancı sekmesi baştan boş: kimse fidancı işaretlenmemiş. Buradan "Kişi
    // Ekle"ye yollamak yanlış olurdu — kişi zaten kayıtlı, yapılacak iş onu
    // fidancı işaretlemek.
    if (widget.suzgec == CariSuzgeci.fidancilar) {
      return const BosDurum(
        simge: Icons.storefront_outlined,
        baslik: Metinler.fidanciYokBaslik,
        aciklama: Metinler.fidanciYokAciklama,
      );
    }
    return BosDurum(
      simge: Icons.people_outline,
      baslik: Metinler.cariYokBaslik,
      aciklama: Metinler.cariYokAciklama,
      eylem: Dugme.birincil(
        metin: Metinler.cariEkle,
        simge: Icons.person_add_alt,
        onBasildi: () => context.push(Yollar.cariYeni),
      ),
    );
  }
}
