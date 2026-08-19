import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/tasarim/dugme.dart';
import '../../../../app/tasarim/olculer.dart';
import '../../../../app/tasarim/simge_dugmesi.dart';
import '../../../../app/yollar.dart';
import '../../../../core/hata/hatalar.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../domain/cari/cari_suzgeci.dart';
import '../../../ortak/view/bos_durum.dart';
import '../../../ortak/view/hata_durumu.dart';
import '../../viewmodel/cari_form_viewmodel.dart';
import '../../viewmodel/cari_listesi_durumu.dart';
import '../../viewmodel/cari_listesi_viewmodel.dart';
import '../../viewmodel/cari_sayisi_saglayici.dart';
import 'acik_hesap_ozeti_karti.dart';
import 'cari_arama_alani.dart';
import 'cari_satiri.dart';
import 'kisi_sayisi_satiri.dart';

/// Tek bir süzgecin kişi listesi — Kişiler ekranındaki bir sekmenin gövdesi.
///
/// Sekme başına bir örnek var: her biri kendi kaydırma konumunu, kendi sayfa
/// sınırını ve kendi arama metnini taşır.
///
/// Kaldırılan kişiler sayfası da (`CariSuzgeci.pasifler`) bu görünümü
/// kullanıyor: sorgusu, sayfalaması ve araması sekmelerinkiyle aynı, farkı
/// satır sonundaki geri alma düğmesi.
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

  /// Aşağı çekerek yenileme: liste akışını yeniden kurar, başlıktaki kişi
  /// sayısını da yeniden sordurur. Sayı tek seferlik bir toplama sorgusundan
  /// geliyor (`cariSayisiSaglayici`); listeyle birlikte tazelenmezse kullanıcı
  /// çekip bıraktığı hâlde eski sayıyı görürdü.
  Future<void> _yenile() {
    ref.invalidate(cariSayisiSaglayici(widget.suzgec));
    return _viewModel.yenile();
  }

  /// Kaldırılmış kişiyi listeye geri alır.
  ///
  /// Onay sorulmuyor: geri almak yıkıcı bir iş değil, yanlışlıkla basılırsa
  /// kişi kartındaki "Listeden kaldır" ile aynı yere dönülür. Liste
  /// tazelenmiyor — kayıt aktifleşince bu sayfanın sorgusundan kendiliğinden
  /// düşüyor.
  Future<void> _geriAl(String cariId) async {
    final basarili = await ref
        .read(cariFormViewModelSaglayici.notifier)
        .geriAl(cariId);

    if (!mounted) return;
    final hata = ref.read(cariFormViewModelSaglayici).error;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            basarili
                ? Metinler.cariGeriAlindi
                : (hata is UygulamaHatasi
                      ? hata.mesaj
                      : Metinler.beklenmeyenHata),
          ),
        ),
      );
  }

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

  /// Sekmenin üst şeridi: kişi sekmelerinde arama kutusu ve kişi sayısı, açık
  /// hesaplarda toplam kartı. Açık hesapta arama yok — gerekçesi
  /// `CariRepository.listeyiIzle`'de; sayı zaten toplam kartının başında.
  Widget _baslik(CariListesiDurumu? veri) {
    if (widget.suzgec.acikHesapMi) {
      // Liste boşken toplam satırı yerine boş durum ekranı konuşur.
      if (veri == null || veri.bosMu) return const SizedBox.shrink();
      return AcikHesapOzetiKarti(ozet: veri.ozet, eksikVar: veri.dahaVar);
    }

    return Column(
      children: <Widget>[
        CariAramaAlani(
          kontrolcu: _aramaKontrolcu,
          onDegisti: (metin) => _viewModel.aramayiDegistir(metin),
        ),
        // Liste boşken sayı satırı da susuyor: "0 kişi" yazısı, altındaki boş
        // durum ekranının söylediğini bir kez daha söylemek olurdu.
        if (veri != null && !veri.bosMu) _sayiSatiri(veri),
      ],
    );
  }

  /// Arama kutusunun altındaki "128 kişi" satırı.
  ///
  /// Sayı önce eldeki satırlardan okunuyor. Liste kesikse — yani sunucuda
  /// okunmamış kayıt varsa — sunucudan tam sayı isteniyor; o gelene kadar ve
  /// çevrimdışıyken hiç gelmezse yüklenen kayıt sayısı "+" ile gösteriliyor.
  ///
  /// Arama sırasında sunucuya sorulmuyor: toplama sorgusu aramayı saymıyor ve
  /// öntakı araması zaten bir avuç kayıt döndürüyor, o da tek sayfaya sığıyor.
  Widget _sayiSatiri(CariListesiDurumu veri) {
    final sunucudanSor = veri.dahaVar && !veri.aramaVarMi;
    final tamSayi = sunucudanSor
        ? ref.watch(cariSayisiSaglayici(widget.suzgec)).value
        : null;

    return KisiSayisiSatiri(
      adet: tamSayi ?? veri.kayitlar.length,
      enAz: tamSayi == null && veri.dahaVar,
    );
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

    // Geri alma sağlayıcısı burada **izleniyor**, yalnızca okunmuyor: sağlayıcı
    // `autoDispose` ve dinleyicisi olmadan çağrılırsa yazma tamamlanmadan
    // atılabilir. Aynı değer düğmeyi işlem sürerken pasif tutuyor.
    final geriAlmaSuruyor =
        widget.suzgec.pasifMi &&
        ref.watch(cariFormViewModelSaglayici).isLoading;

    return RefreshIndicator(
      onRefresh: _yenile,
      child: ListView.separated(
        controller: _kaydirmaKontrolcu,
        physics: const AlwaysScrollableScrollPhysics(),
        // Alttaki boşluk yüzen "Kişi Ekle" düğmesinin altında kalan son satır
        // için; kaldırılan kişiler sayfasında o düğme yok.
        padding: EdgeInsets.only(
          bottom: widget.suzgec.pasifMi
              ? Olculer.bosluk24
              : Olculer.yuzenDugmeBoslugu,
        ),
        itemCount: veri.kayitlar.length + (ekSatir ? 1 : 0),
        // Çizgi yazının hizasından başlıyor; girintinin hesabı
        // `CariSatiri.ayracGirintisi`'nde.
        separatorBuilder: (context, sira) => const Divider(
          indent: CariSatiri.ayracGirintisi,
          endIndent: Olculer.sayfaKenari,
        ),
        itemBuilder: (context, sira) {
          if (sira >= veri.kayitlar.length) return _sayfaSonu(veri);

          final kayit = veri.kayitlar[sira];
          return CariSatiri(
            kayit: kayit,
            // Numara listedeki yer: arama yapınca ya da öteki sekmeye geçince
            // yeniden 1'den başlar.
            sira: sira + 1,
            // Grup rozeti yalnızca iki grubun karıştığı listede anlamlı;
            // fidancı listesinde her satırda "Fidancı" yazmak gürültü olurdu.
            grubuGoster: widget.suzgec.gruplarKarisikMi,
            // Kaldırılan kişiler sayfasında satır sonunda geri alma düğmesi
            // var; kişiye dokunmak yine kartını açıyor, geçmişi orada.
            eylem: widget.suzgec.pasifMi
                ? SimgeDugmesi(
                    simge: Icons.restore,
                    ipucu: Metinler.cariGeriAl,
                    vurgulu: true,
                    onBasildi: geriAlmaSuruyor
                        ? null
                        : () => _geriAl(kayit.cari.id),
                  )
                : null,
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
    // Kaldırılan kişiler sayfası boşsa yapılacak bir iş yok: buraya kişi
    // eklenmiyor, kişi kartından kaldırılarak geliniyor.
    if (widget.suzgec.pasifMi) {
      return const BosDurum(
        simge: Icons.person_off_outlined,
        baslik: Metinler.pasifCariYokBaslik,
        aciklama: Metinler.pasifCariYokAciklama,
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
