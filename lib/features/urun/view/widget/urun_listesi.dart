import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/tasarim/arama_alani.dart';
import '../../../../app/tasarim/olculer.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../data/urun/urun_kaydi.dart';
import '../../../ortak/view/bos_durum.dart';
import '../../../ortak/view/hata_durumu.dart';
import '../../viewmodel/urun_listesi_durumu.dart';
import '../../viewmodel/urun_listesi_viewmodel.dart';
import 'urun_satiri.dart';

/// Arama kutusu + ada göre sıralı, sayfalanan ürün listesi.
///
/// İki ekran aynı listeyi gösteriyor: ürünler sekmesi (satıra dokununca
/// düzenlemeye gider) ve fatura kaleminin ürün seçici sayfası (satıra
/// dokununca kalemi doldurur). Fark yalnızca [onSecildi] geri çağrısında.
class UrunListesi extends ConsumerStatefulWidget {
  const UrunListesi({required this.onSecildi, this.altBosluk = 24, super.key});

  final ValueChanged<UrunKaydi> onSecildi;

  /// Listenin altındaki boşluk. Ürünler sekmesinde yüzen düğme satırları
  /// örtmesin diye büyütülür.
  final double altBosluk;

  @override
  ConsumerState<UrunListesi> createState() => _UrunListesiDurumu();
}

class _UrunListesiDurumu extends ConsumerState<UrunListesi> {
  /// Listenin sonuna bu kadar kala sonraki sayfa istenir.
  static const double _yuklemeEsigi = 400;

  final _kaydirmaKontrolcu = ScrollController();
  late final TextEditingController _aramaKontrolcu;

  @override
  void initState() {
    super.initState();
    // Liste durumu ekranlar arasında korunuyor; arama kutusu boş açılırsa
    // kullanıcı süzülmüş bir listeye sebepsiz bakardı.
    _aramaKontrolcu = TextEditingController(
      text: ref.read(urunListesiViewModelSaglayici).value?.arama ?? '',
    );
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

  void _dahaYukle() {
    ref.read(urunListesiViewModelSaglayici.notifier).dahaYukle();
  }

  Future<void> _yenile() =>
      ref.read(urunListesiViewModelSaglayici.notifier).yenile();

  @override
  Widget build(BuildContext context) {
    final durum = ref.watch(urunListesiViewModelSaglayici);

    return Column(
      children: [
        AramaAlani(
          kontrolcu: _aramaKontrolcu,
          ipucu: Metinler.urunAra,
          onDegisti: (metin) => ref
              .read(urunListesiViewModelSaglayici.notifier)
              .aramayiDegistir(metin),
        ),
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

  Widget _liste(UrunListesiDurumu veri) {
    if (veri.bosMu) return _bosDurum(veri);

    // Son satır sonraki sayfanın göstergesi ya da hata satırı olur.
    final ekSatir = veri.dahaVar || veri.sayfaHatasi != null;

    return RefreshIndicator(
      onRefresh: _yenile,
      child: ListView.separated(
        controller: _kaydirmaKontrolcu,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: widget.altBosluk),
        itemCount: veri.kayitlar.length + (ekSatir ? 1 : 0),
        separatorBuilder: (context, sira) =>
            const Divider(indent: 72, endIndent: Olculer.sayfaKenari),
        itemBuilder: (context, sira) {
          if (sira >= veri.kayitlar.length) return _sayfaSonu(veri);

          final kayit = veri.kayitlar[sira];
          return UrunSatiri(
            kayit: kayit,
            onTap: () => widget.onSecildi(kayit),
          );
        },
      ),
    );
  }

  Widget _sayfaSonu(UrunListesiDurumu veri) {
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

  Widget _bosDurum(UrunListesiDurumu veri) {
    if (veri.aramaVarMi) {
      return const BosDurum(
        simge: Icons.search_off,
        baslik: Metinler.aramaSonucuYokBaslik,
        aciklama: Metinler.aramaSonucuYokAciklama,
      );
    }
    return const BosDurum(
      simge: Icons.sell_outlined,
      baslik: Metinler.urunYokBaslik,
      aciklama: Metinler.urunYokAciklama,
    );
  }
}
