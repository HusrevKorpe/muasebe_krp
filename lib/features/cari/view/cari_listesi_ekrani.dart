import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/yollar.dart';
import '../../../core/metin/metinler.dart';
import '../../../domain/cari/cari_siralamasi.dart';
import '../../ortak/view/bos_durum.dart';
import '../../ortak/view/hata_durumu.dart';
import '../viewmodel/cari_listesi_durumu.dart';
import '../viewmodel/cari_listesi_viewmodel.dart';
import 'widget/cari_satiri.dart';

/// Uygulamanın ana ekranı: cari listesi.
class CariListesiEkrani extends ConsumerStatefulWidget {
  const CariListesiEkrani({super.key});

  @override
  ConsumerState<CariListesiEkrani> createState() => _CariListesiEkraniDurumu();
}

class _CariListesiEkraniDurumu extends ConsumerState<CariListesiEkrani> {
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

  void _dahaYukle() {
    ref.read(cariListesiViewModelSaglayici.notifier).dahaYukle();
  }

  @override
  Widget build(BuildContext context) {
    final durum = ref.watch(cariListesiViewModelSaglayici);

    return Scaffold(
      appBar: AppBar(
        title: const Text(Metinler.cariler),
        actions: [
          _SiralamaMenusu(
            secili: durum.value?.siralama ?? CariSiralamasi.ad,
            onSecildi: (siralama) => ref
                .read(cariListesiViewModelSaglayici.notifier)
                .siralamayiDegistir(siralama),
          ),
          const _GenelMenu(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: _AramaAlani(
            kontrolcu: _aramaKontrolcu,
            onDegisti: (metin) => ref
                .read(cariListesiViewModelSaglayici.notifier)
                .aramayiDegistir(metin),
          ),
        ),
      ),
      body: durum.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (hata, _) => HataDurumu.hatadan(hata, yenidenDene: _yenile),
        data: _liste,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Yollar.cariYeni),
        icon: const Icon(Icons.person_add_alt),
        label: const Text(Metinler.cariEkle),
      ),
    );
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

  Future<void> _yenile() =>
      ref.read(cariListesiViewModelSaglayici.notifier).yenile();
}

class _AramaAlani extends StatelessWidget {
  const _AramaAlani({required this.kontrolcu, required this.onDegisti});

  final TextEditingController kontrolcu;
  final ValueChanged<String> onDegisti;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: kontrolcu,
        onChanged: onDegisti,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: Metinler.cariAra,
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: kontrolcu,
            builder: (context, deger, _) => deger.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: Metinler.temizle,
                    onPressed: () {
                      kontrolcu.clear();
                      onDegisti('');
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _SiralamaMenusu extends StatelessWidget {
  const _SiralamaMenusu({required this.secili, required this.onSecildi});

  final CariSiralamasi secili;
  final ValueChanged<CariSiralamasi> onSecildi;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CariSiralamasi>(
      icon: const Icon(Icons.sort),
      tooltip: Metinler.siralama,
      initialValue: secili,
      onSelected: onSecildi,
      itemBuilder: (context) => [
        for (final siralama in CariSiralamasi.values)
          PopupMenuItem<CariSiralamasi>(
            value: siralama,
            child: Text(siralama.baslik),
          ),
      ],
    );
  }
}

class _GenelMenu extends StatelessWidget {
  const _GenelMenu();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      onSelected: (eylem) => eylem(),
      itemBuilder: (context) => [
        PopupMenuItem<VoidCallback>(
          value: () => context.push(Yollar.fidanlar),
          child: const ListTile(
            leading: Icon(Icons.park_outlined),
            title: Text(Metinler.fidanKatalogMenu),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<VoidCallback>(
          value: () => context.push(Yollar.isletme),
          child: const ListTile(
            leading: Icon(Icons.storefront_outlined),
            title: Text(Metinler.isletmeMenu),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        // Çıkış ve hesap silme birlikte hesap ekranında duruyor: Apple, hesap
        // silmenin uygulama içinden bulunabilir olmasını şart koşuyor.
        PopupMenuItem<VoidCallback>(
          value: () => context.push(Yollar.hesap),
          child: const ListTile(
            leading: Icon(Icons.account_circle_outlined),
            title: Text(Metinler.hesapMenu),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
