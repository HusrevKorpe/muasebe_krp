import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/metin/metinler.dart';
import '../../../../data/secenek/secenek_kaydi.dart';
import '../../../../domain/secenek/secenek_tipi.dart';
import '../../../ortak/view/bos_durum.dart';
import '../../../ortak/view/hata_durumu.dart';
import '../../viewmodel/secenek_listesi_durumu.dart';
import '../../viewmodel/secenek_listesi_viewmodel.dart';

/// Arama kutusu + ada göre sıralı, sayfalanan tür/çeşit/anaç listesi.
///
/// Aynı liste iki yerde: Ayarlar'daki yönetim ekranında (satıra dokununca
/// düzeltme kutusu açılır) ve kalem kutusunun seçim sayfasında (satıra
/// dokununca kutuyu doldurur). Fark yalnızca [onSecildi] ile [onDuzenle]
/// geri çağrılarında — bkz. `UrunListesi`.
class SecenekListesi extends ConsumerStatefulWidget {
  const SecenekListesi({
    required this.tip,
    required this.onSecildi,
    this.onDuzenle,
    this.altBosluk = 24,
    super.key,
  });

  final SecenekTipi tip;

  /// Satıra dokunulduğunda çağrılır.
  final ValueChanged<SecenekKaydi> onSecildi;

  /// Satırın sağındaki düzeltme düğmesi. `null` ise düğme çizilmez — yönetim
  /// ekranında dokunmak zaten düzeltmeye götürüyor.
  final ValueChanged<SecenekKaydi>? onDuzenle;

  /// Listenin altındaki boşluk. Yüzen düğme son satırı örtmesin diye büyütülür.
  final double altBosluk;

  @override
  ConsumerState<SecenekListesi> createState() => _SecenekListesiDurumu();
}

class _SecenekListesiDurumu extends ConsumerState<SecenekListesi> {
  /// Listenin sonuna bu kadar kala sonraki sayfa istenir.
  static const double _yuklemeEsigi = 400;

  final _kaydirmaKontrolcu = ScrollController();
  late final TextEditingController _aramaKontrolcu;

  /// Bu ekranın beslendiği sağlayıcı. Üç listenin her biri ayrı bir sağlayıcı
  /// (bkz. [secenekListesiSaglayici]).
  late final _saglayici = secenekListesiSaglayici(widget.tip);

  @override
  void initState() {
    super.initState();
    // Liste durumu ekranlar arasında korunuyor; arama kutusu boş açılırsa
    // kullanıcı süzülmüş bir listeye sebepsiz bakardı.
    _aramaKontrolcu = TextEditingController(
      text: ref.read(_saglayici).value?.arama ?? '',
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

  void _dahaYukle() => ref.read(_saglayici.notifier).dahaYukle();

  Future<void> _yenile() => ref.read(_saglayici.notifier).yenile();

  @override
  Widget build(BuildContext context) {
    final durum = ref.watch(_saglayici);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: _AramaAlani(
            kontrolcu: _aramaKontrolcu,
            onDegisti: (metin) =>
                ref.read(_saglayici.notifier).aramayiDegistir(metin),
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

  Widget _liste(SecenekListesiDurumu veri) {
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
        separatorBuilder: (context, sira) => const Divider(height: 1),
        itemBuilder: (context, sira) {
          if (sira >= veri.kayitlar.length) return _sayfaSonu(veri);

          final kayit = veri.kayitlar[sira];
          final onDuzenle = widget.onDuzenle;
          return _SecenekSatiri(
            kayit: kayit,
            onTap: () => widget.onSecildi(kayit),
            onDuzenle: onDuzenle == null ? null : () => onDuzenle(kayit),
          );
        },
      ),
    );
  }

  Widget _sayfaSonu(SecenekListesiDurumu veri) {
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

  Widget _bosDurum(SecenekListesiDurumu veri) {
    if (veri.aramaVarMi) {
      return const BosDurum(
        simge: Icons.search_off,
        baslik: Metinler.aramaSonucuYokBaslik,
        aciklama: Metinler.aramaSonucuYokAciklama,
      );
    }
    return const BosDurum(
      simge: Icons.list_alt_outlined,
      baslik: Metinler.secenekYokBaslik,
      aciklama: Metinler.secenekYokAciklama,
    );
  }
}

/// Listenin tek satırı: yalnızca ad. Kayıt başka bir şey taşımıyor.
class _SecenekSatiri extends StatelessWidget {
  const _SecenekSatiri({
    required this.kayit,
    required this.onTap,
    required this.onDuzenle,
  });

  final SecenekKaydi kayit;
  final VoidCallback onTap;
  final VoidCallback? onDuzenle;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return ListTile(
      onTap: onTap,
      title: Text(
        kayit.secenek.ad,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: kayit.beklemede
          ? _BeklemeRozeti(renkSemasi: tema.colorScheme)
          : null,
      trailing: onDuzenle == null
          ? null
          : IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: Metinler.secenekDuzenle,
              onPressed: onDuzenle,
            ),
    );
  }
}

/// Sunucuya henüz yazılmamış kayıtların göstergesi (bkz. KURALLAR.md §4.4).
class _BeklemeRozeti extends StatelessWidget {
  const _BeklemeRozeti({required this.renkSemasi});

  final ColorScheme renkSemasi;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.cloud_upload_outlined, size: 14, color: renkSemasi.tertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            Metinler.kaydedilmedi,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: renkSemasi.tertiary),
          ),
        ),
      ],
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
        hintText: Metinler.secenekAra,
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
