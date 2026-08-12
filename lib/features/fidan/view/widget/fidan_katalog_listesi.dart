import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/metin/metinler.dart';
import '../../../../core/metin/turkce.dart' as turkce;
import '../../../../data/fidan/fidan_kaydi.dart';
import '../../../ortak/view/bos_durum.dart';
import '../../../ortak/view/hata_durumu.dart';
import '../../viewmodel/fidan_listesi_durumu.dart';
import '../../viewmodel/fidan_listesi_viewmodel.dart';
import 'fidan_satiri.dart';

/// Arama kutusu + türe göre gruplanmış, sayfalanan katalog listesi.
///
/// İki ekran aynı listeyi gösteriyor: katalog ekranı (satıra dokununca
/// düzenlemeye gider) ve fatura kaleminin fidan seçici sayfası (satıra
/// dokununca kalemi doldurur). Fark yalnızca [onSecildi] geri çağrısında.
class FidanKatalogListesi extends ConsumerStatefulWidget {
  const FidanKatalogListesi({
    required this.onSecildi,
    this.altBosluk = 24,
    super.key,
  });

  final ValueChanged<FidanKaydi> onSecildi;

  /// Listenin altındaki boşluk. Katalog ekranında yüzen düğme satırları
  /// örtmesin diye büyütülür.
  final double altBosluk;

  @override
  ConsumerState<FidanKatalogListesi> createState() =>
      _FidanKatalogListesiDurumu();
}

class _FidanKatalogListesiDurumu extends ConsumerState<FidanKatalogListesi> {
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
      text: ref.read(fidanListesiViewModelSaglayici).value?.arama ?? '',
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
    ref.read(fidanListesiViewModelSaglayici.notifier).dahaYukle();
  }

  Future<void> _yenile() =>
      ref.read(fidanListesiViewModelSaglayici.notifier).yenile();

  @override
  Widget build(BuildContext context) {
    final durum = ref.watch(fidanListesiViewModelSaglayici);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: _AramaAlani(
            kontrolcu: _aramaKontrolcu,
            onDegisti: (metin) => ref
                .read(fidanListesiViewModelSaglayici.notifier)
                .aramayiDegistir(metin),
          ),
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

  Widget _liste(FidanListesiDurumu veri) {
    if (veri.bosMu) return _bosDurum(veri);

    final satirlar = _katalogSatirlari(veri.kayitlar);
    // Son satır sonraki sayfanın göstergesi ya da hata satırı olur.
    final ekSatir = veri.dahaVar || veri.sayfaHatasi != null;

    return RefreshIndicator(
      onRefresh: _yenile,
      child: ListView.builder(
        controller: _kaydirmaKontrolcu,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: widget.altBosluk),
        itemCount: satirlar.length + (ekSatir ? 1 : 0),
        itemBuilder: (context, sira) {
          if (sira >= satirlar.length) return _sayfaSonu(veri);

          final satir = satirlar[sira];
          return switch (satir) {
            _TurBasligi(:final tur) => _TurBasligiSatiri(tur: tur),
            _FidanSatirVerisi(:final kayit) => FidanSatiri(
              kayit: kayit,
              onTap: () => widget.onSecildi(kayit),
            ),
          };
        },
      ),
    );
  }

  Widget _sayfaSonu(FidanListesiDurumu veri) {
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

  Widget _bosDurum(FidanListesiDurumu veri) {
    if (veri.aramaVarMi) {
      return const BosDurum(
        simge: Icons.search_off,
        baslik: Metinler.aramaSonucuYokBaslik,
        aciklama: Metinler.aramaSonucuYokAciklama,
      );
    }
    return const BosDurum(
      simge: Icons.park_outlined,
      baslik: Metinler.fidanYokBaslik,
      aciklama: Metinler.fidanYokAciklama,
    );
  }
}

/// Kayıtları tür başlıklarıyla birlikte düz bir satır listesine çevirir.
///
/// Sorgu `aramaAnahtari` sırasında geldiği ve anahtar türle başladığı için aynı
/// tür zaten yan yana; başlık, tür değiştiği yere konuyor. Ayrı bir gruplama
/// sorgusu atılmıyor (KURALLAR.md §4.3).
List<_KatalogSatiri> _katalogSatirlari(List<FidanKaydi> kayitlar) {
  final satirlar = <_KatalogSatiri>[];
  String? oncekiAnahtar;

  for (final kayit in kayitlar) {
    final tur = kayit.fidan.tur.trim();
    final anahtar = turkce.aramaAnahtari(tur);
    if (anahtar != oncekiAnahtar) {
      satirlar.add(_TurBasligi(tur));
      oncekiAnahtar = anahtar;
    }
    satirlar.add(_FidanSatirVerisi(kayit));
  }
  return satirlar;
}

sealed class _KatalogSatiri {
  const _KatalogSatiri();
}

class _TurBasligi extends _KatalogSatiri {
  const _TurBasligi(this.tur);

  final String tur;
}

class _FidanSatirVerisi extends _KatalogSatiri {
  const _FidanSatirVerisi(this.kayit);

  final FidanKaydi kayit;
}

class _TurBasligiSatiri extends StatelessWidget {
  const _TurBasligiSatiri({required this.tur});

  final String tur;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      width: double.infinity,
      color: tema.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        tur.isEmpty ? Metinler.tur : tur,
        style: tema.textTheme.labelLarge?.copyWith(
          color: tema.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _AramaAlani extends StatelessWidget {
  const _AramaAlani({required this.kontrolcu, required this.onDegisti});

  final TextEditingController kontrolcu;
  final ValueChanged<String> onDegisti;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: kontrolcu,
      onChanged: onDegisti,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: Metinler.fidanAra,
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
    );
  }
}
