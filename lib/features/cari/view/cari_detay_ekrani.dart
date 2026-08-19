import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/tasarim/bolum_basligi.dart';
import '../../../app/tasarim/dugme.dart';
import '../../../app/tasarim/olculer.dart';
import '../../../app/tasarim/simge_dugmesi.dart';
import '../../../app/yollar.dart';
import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../core/para/para_bicimi.dart';
import '../../../core/tarih/gun_siniri.dart';
import '../../../data/cari/cari_kaydi.dart';
import '../../../domain/cari/cari.dart';
import '../../../domain/islem/islem.dart';
import '../../../domain/islem/islem_tipi.dart';
import '../../islem/view/widget/islem_dugmeleri.dart';
import '../../islem/view/widget/islem_listesi_bolumu.dart';
import '../../islem/viewmodel/islem_form_viewmodel.dart';
import '../../islem/viewmodel/islem_listesi_viewmodel.dart';
import '../../ortak/view/bos_durum.dart';
import '../../ortak/view/hata_durumu.dart';
import '../viewmodel/cari_saglayici.dart';
import 'widget/cari_bilgi_bolumu.dart';
import 'widget/cari_ozet_karti.dart';

/// Kişi sayfası: üstte özet, ortada hareket listesi, altta dört giriş düğmesi.
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
        actions: <Widget>[
          if (kayit.value != null) ...<Widget>[
            SimgeDugmesi(
              simge: Icons.picture_as_pdf_outlined,
              ipucu: Metinler.ekstreAl,
              onBasildi: () => context.push(Yollar.ekstreYolu(widget.cariId)),
            ),
            SimgeDugmesi(
              simge: Icons.edit_outlined,
              ipucu: Metinler.duzenle,
              onBasildi: _duzenlemeyeGit,
            ),
            PopupMenuButton<VoidCallback>(
              onSelected: (eylem) => eylem(),
              tooltip: Metinler.digerIslemler,
              itemBuilder: (context) => <PopupMenuEntry<VoidCallback>>[
                // Hesabı kapalı kişide "hesabı gör" anlamsız; kapatılacak
                // bakiye yoksa madde hiç görünmüyor.
                if (!kayit.value!.cari.bakiye.sifirMi)
                  PopupMenuItem<VoidCallback>(
                    value: () => _hesabiGor(kayit.value!.cari),
                    child: const ListTile(
                      leading: Icon(Icons.handshake_outlined),
                      title: Text(Metinler.hesabiGor),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
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
      bottomNavigationBar: kayit.value == null
          ? null
          : IslemDugmeleri(onSecildi: _islemEkle),
    );
  }

  Widget _govde(CariKaydi kayit) {
    return CustomScrollView(
      controller: _kaydirmaKontrolcu,
      slivers: <Widget>[
        SliverToBoxAdapter(child: _Ust(kayit: kayit)),
        IslemListesiBolumu(cariId: widget.cariId),
        const SliverToBoxAdapter(child: SizedBox(height: Olculer.bosluk24)),
      ],
    );
  }

  Future<void> _islemEkle(IslemTipi tip) async {
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

  /// Kalan bakiyeyi kapatan "hesap görüldü" kaydını yazar.
  ///
  /// Kullanıcının isteği: *"adamın bana 105.000 borcu var, 100.000'e düzlüyor;
  /// 100.000 aldıktan sonra hesap kapandı yapabilir miyiz, 5.000 almadan."*
  /// Tahsilatı kullanıcı normal yoldan girer; burada kapanan yalnızca kalandır.
  /// Tutar formdan değil bakiyeden geldiği için soru tek onaydan ibaret.
  ///
  /// Kayıt silinmez, iptal edilebilir (KURALLAR.md §4.2): yanlışlıkla kapatılan
  /// hesap kaydın iptaliyle eski hâline döner.
  Future<void> _hesabiGor(Cari cari) async {
    final bakiye = cari.bakiye;
    if (bakiye.sifirMi) return;

    final tutar = kurusBicimle(bakiye.mutlak);
    final onaylandi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Metinler.hesabiGor),
        content: Text(
          bakiye.pozitifMi
              ? Metinler.hesabiGorOnayAlacak(tutar)
              : Metinler.hesabiGorOnayBorc(tutar),
        ),
        actions: <Widget>[
          Dugme.sade(
            metin: Metinler.vazgec,
            kompakt: true,
            onBasildi: () => Navigator.of(context).pop(false),
          ),
          Dugme.birincil(
            metin: Metinler.tamam,
            kompakt: true,
            onBasildi: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (onaylandi != true || !mounted) return;

    final basarili = await ref
        .read(islemFormViewModelSaglayici.notifier)
        .kaydet(
          cariId: widget.cariId,
          islem: Islem.hesapGorme(
            bakiye: bakiye,
            baslik: Metinler.hesapGoruldu,
            islemTarihi: gunBasi(DateTime.now()),
          ),
        );

    if (!mounted) return;
    final hata = ref.read(islemFormViewModelSaglayici).error;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            basarili
                ? Metinler.hesapGorulduBildirimi
                : (hata is UygulamaHatasi
                      ? hata.mesaj
                      : Metinler.beklenmeyenHata),
          ),
        ),
      );
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Olculer.sayfaKenari,
        Olculer.bosluk20,
        Olculer.sayfaKenari,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CariOzetKarti(kayit: kayit),
          CariBilgiBolumu(cari: kayit.cari),
          const SizedBox(height: Olculer.bosluk32),
          BolumBasligi(baslik: Metinler.islemler),
        ],
      ),
    );
  }
}
