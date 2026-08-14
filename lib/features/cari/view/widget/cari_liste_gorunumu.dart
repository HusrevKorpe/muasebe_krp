import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    final durum = ref.watch(cariListesiViewModelSaglayici(widget.suzgec));

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

  /// Sekmenin üst şeridi: "Tümü"de arama kutusu, açık hesaplarda toplam satırı.
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
    if (veri.bosMu) return _bosDurum(veri);

    // Son satır sonraki sayfanın göstergesi ya da hata satırı olur.
    final ekSatir = veri.dahaVar || veri.sayfaHatasi != null;

    return RefreshIndicator(
      onRefresh: _yenile,
      child: ListView.separated(
        controller: _kaydirmaKontrolcu,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: veri.kayitlar.length + (ekSatir ? 1 : 0),
        separatorBuilder: (context, sira) => const Divider(height: 1),
        itemBuilder: (context, sira) {
          if (sira >= veri.kayitlar.length) return _sayfaSonu(veri);

          final kayit = veri.kayitlar[sira];
          return CariSatiri(
            kayit: kayit,
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
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
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
    return BosDurum(
      simge: Icons.people_outline,
      baslik: Metinler.cariYokBaslik,
      aciklama: Metinler.cariYokAciklama,
      eylem: FilledButton.icon(
        onPressed: () => context.push(Yollar.cariYeni),
        icon: const Icon(Icons.person_add_alt),
        label: const Text(Metinler.cariEkle),
      ),
    );
  }
}
