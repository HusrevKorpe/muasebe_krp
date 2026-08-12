import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/yollar.dart';
import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../core/tarih/tarih_bicimi.dart';
import '../../../data/cari/cari_kaydi.dart';
import '../../../domain/cari/cari.dart';
import '../../islem/view/widget/islem_listesi_bolumu.dart';
import '../../islem/view/widget/islem_tipi_secici.dart';
import '../../islem/viewmodel/islem_form_viewmodel.dart';
import '../../islem/viewmodel/islem_listesi_viewmodel.dart';
import '../../ortak/view/bos_durum.dart';
import '../../ortak/view/hata_durumu.dart';
import '../viewmodel/cari_saglayici.dart';
import 'widget/bakiye_metni.dart';

/// Cari detay sayfası: üstte özet, altta işlem listesi.
class CariDetayEkrani extends ConsumerStatefulWidget {
  const CariDetayEkrani({required this.cariId, super.key});

  final String cariId;

  @override
  ConsumerState<CariDetayEkrani> createState() => _CariDetayEkraniDurumu();
}

class _CariDetayEkraniDurumu extends ConsumerState<CariDetayEkrani> {
  /// Listenin sonuna bu kadar kala sonraki sayfa istenir.
  static const double _yuklemeEsigi = 400;

  final _kaydirmaKontrolcu = ScrollController();

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
    super.dispose();
  }

  void _kaydirmayiDinle() {
    if (!_kaydirmaKontrolcu.hasClients) return;
    final konum = _kaydirmaKontrolcu.position;
    if (konum.pixels >= konum.maxScrollExtent - _yuklemeEsigi) {
      ref
          .read(islemListesiViewModelSaglayici(widget.cariId).notifier)
          .dahaYukle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final kayit = ref.watch(cariSaglayici(widget.cariId));

    return Scaffold(
      appBar: AppBar(
        title: Text(kayit.value?.cari.ad ?? Metinler.cariler),
        actions: [
          if (kayit.value != null) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: Metinler.ekstreAl,
              onPressed: () => context.push(Yollar.ekstreYolu(widget.cariId)),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: Metinler.duzenle,
              onPressed: _duzenlemeyeGit,
            ),
            PopupMenuButton<VoidCallback>(
              onSelected: (eylem) => eylem(),
              itemBuilder: (context) => [
                PopupMenuItem<VoidCallback>(
                  value: _bakiyeyiYenidenHesapla,
                  child: const ListTile(
                    leading: Icon(Icons.calculate_outlined),
                    title: Text(Metinler.bakiyeYenidenHesapla),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: kayit.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (hata, _) => HataDurumu.hatadan(
          hata,
          yenidenDene: () => ref.invalidate(cariSaglayici(widget.cariId)),
        ),
        data: (deger) => deger == null
            ? const BosDurum(
                simge: Icons.person_off_outlined,
                baslik: Metinler.cariBulunamadi,
                aciklama: Metinler.cariYokAciklama,
              )
            : _govde(deger),
      ),
      floatingActionButton: kayit.value == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _islemEkle,
              icon: const Icon(Icons.add),
              label: const Text(Metinler.islemEkle),
            ),
    );
  }

  Widget _govde(CariKaydi kayit) {
    return CustomScrollView(
      controller: _kaydirmaKontrolcu,
      slivers: [
        SliverToBoxAdapter(child: _Ust(kayit: kayit)),
        IslemListesiBolumu(cariId: widget.cariId),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  Future<void> _islemEkle() async {
    final tip = await IslemTipiSecici.goster(context);
    if (tip == null || !mounted) return;

    await context.push<bool>(Yollar.islemYeniYolu(widget.cariId, tip));
  }

  /// Düzenleme ekranı `false` dönerse cari pasife alınmıştır; detay sayfasının
  /// da kapanması gerekir, aksi hâlde listede olmayan bir kayda bakılır.
  Future<void> _duzenlemeyeGit() async {
    final sonuc = await context.push<bool>(
      Yollar.cariDuzenleYolu(widget.cariId),
    );
    if (sonuc == false && mounted) context.pop();
  }

  /// Bakiyeyi tüm işlemlerden baştan hesaplar. Önbelleklenmiş bakiye ile
  /// işlemler ayrışmışsa tek onarım yolu budur (bkz. KURALLAR.md §4.2).
  Future<void> _bakiyeyiYenidenHesapla() async {
    final sonuc = await ref
        .read(islemFormViewModelSaglayici.notifier)
        .bakiyeyiYenidenHesapla(widget.cariId);

    if (!mounted) return;
    final hata = ref.read(islemFormViewModelSaglayici).error;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            sonuc != null
                ? Metinler.bakiyeYenidenHesaplandi
                : (hata is UygulamaHatasi
                      ? hata.mesaj
                      : Metinler.beklenmeyenHata),
          ),
        ),
      );
  }
}

/// Özet kartı, bilgi bölümleri ve işlem listesi başlığı.
class _Ust extends StatelessWidget {
  const _Ust({required this.kayit});

  final CariKaydi kayit;

  @override
  Widget build(BuildContext context) {
    final cari = kayit.cari;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OzetKarti(kayit: kayit),
          const SizedBox(height: 24),
          if (_iletisimVarMi(cari)) ...[
            _Bolum(
              baslik: Metinler.iletisim,
              satirlar: [
                if (cari.telefon != null)
                  _BilgiSatiri(
                    simge: Icons.phone_outlined,
                    etiket: Metinler.telefon,
                    deger: cari.telefon!,
                  ),
                if (cari.sehir != null)
                  _BilgiSatiri(
                    simge: Icons.location_city_outlined,
                    etiket: Metinler.sehir,
                    deger: cari.sehir!,
                  ),
                if (cari.adres != null)
                  _BilgiSatiri(
                    simge: Icons.home_outlined,
                    etiket: Metinler.adres,
                    deger: cari.adres!,
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          if (cari.vergiDairesi != null || cari.vergiNo != null) ...[
            _Bolum(
              baslik: Metinler.vergiBilgileri,
              satirlar: [
                if (cari.vergiDairesi != null)
                  _BilgiSatiri(
                    simge: Icons.account_balance_outlined,
                    etiket: Metinler.vergiDairesi,
                    deger: cari.vergiDairesi!,
                  ),
                if (cari.vergiNo != null)
                  _BilgiSatiri(
                    simge: Icons.numbers,
                    etiket: Metinler.vergiNo,
                    deger: cari.vergiNo!,
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          if (cari.notlar != null) ...[
            _Bolum(
              baslik: Metinler.notlar,
              satirlar: [
                _BilgiSatiri(
                  simge: Icons.notes_outlined,
                  etiket: Metinler.notlar,
                  deger: cari.notlar!,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          Text(
            Metinler.islemler,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static bool _iletisimVarMi(Cari cari) =>
      cari.telefon != null || cari.sehir != null || cari.adres != null;
}

class _OzetKarti extends StatelessWidget {
  const _OzetKarti({required this.kayit});

  final CariKaydi kayit;

  @override
  Widget build(BuildContext context) {
    final cari = kayit.cari;
    final tema = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cari.ad, style: tema.textTheme.headlineSmall),
            if (cari.altBaslik != null) ...[
              const SizedBox(height: 4),
              Text(
                cari.altBaslik!,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const Divider(height: 32),
            Text(
              Metinler.bakiye,
              style: tema.textTheme.labelLarge?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            BakiyeMetni(bakiye: cari.bakiye, stil: tema.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              _bakiyeAciklamasi(cari),
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            if (cari.sonIslemTarihi != null) ...[
              const SizedBox(height: 12),
              Text(
                '${Metinler.sonIslem}: ${kisaTarih(cari.sonIslemTarihi!)}',
                style: tema.textTheme.bodySmall,
              ),
            ],
            if (kayit.beklemede) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 16,
                    color: tema.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      Metinler.kaydedilmediAciklama,
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _bakiyeAciklamasi(Cari cari) {
    if (cari.bakiye.sifirMi) return Metinler.bakiyeKapali;
    return cari.bakiye.pozitifMi
        ? Metinler.bakiyeCariBorclu
        : Metinler.bakiyeIsletmeBorclu;
  }
}

class _Bolum extends StatelessWidget {
  const _Bolum({required this.baslik, required this.satirlar});

  final String baslik;
  final List<Widget> satirlar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(baslik, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: satirlar),
        ),
      ],
    );
  }
}

class _BilgiSatiri extends StatelessWidget {
  const _BilgiSatiri({
    required this.simge,
    required this.etiket,
    required this.deger,
  });

  final IconData simge;
  final String etiket;
  final String deger;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(simge),
      title: Text(etiket, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(deger, style: Theme.of(context).textTheme.bodyLarge),
      dense: true,
    );
  }
}
