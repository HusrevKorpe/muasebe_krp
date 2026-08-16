import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tasarim/bolum_basligi.dart';
import '../../../app/tasarim/dugme.dart';
import '../../../app/tasarim/olculer.dart';
import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../core/para/kurus.dart';
import '../../../domain/islem/fatura_hesaplayici.dart';
import '../../../domain/islem/islem.dart';
import '../../../domain/islem/islem_basligi.dart';
import '../../../domain/islem/islem_kalemi.dart';
import '../../../domain/islem/islem_tipi.dart';
import '../../ortak/view/tarih_alani.dart';
import '../viewmodel/islem_form_viewmodel.dart';
import 'widget/duzenleme_uyarisi.dart';
import 'widget/fatura_ozeti.dart';
import 'widget/islem_tipi_gorunumu.dart';
import 'widget/kalem_dialogu.dart';
import 'widget/kalem_listesi.dart';

/// "Sattım" ve "Aldım" giriş formu.
///
/// Tutar hesabı burada yapılmaz: kalem tutarları [IslemKalemi] fabrikalarında,
/// fatura toplamı [FaturaHesaplayici] içinde üretilir (bkz. KURALLAR.md §1.3).
/// Ekran yalnızca kullanıcının girdiklerini toplayıp domain'e verir.
///
/// Açıklama alanı **zorunlu değil**: boş bırakılırsa başlık kalem adlarından
/// üretilir (bkz. [IslemBasligi]). Bir satış girmek için doldurulması gereken
/// tek şey satırlar.
///
/// [mevcut] verilirse kayıtlı bir fatura düzenlenir: alanlar aynı, tek fark
/// kaydın yeni belge açmak yerine yerinde güncellenmesi
/// (bkz. `IslemRepository.guncelle`). Fiyatı ya da adedi yanlış girilmiş bir
/// satış bu yoldan düzeltilir; tip değiştirilemez, çünkü satışı alışa çevirmek
/// yeni bir kayıt girmekle aynı şeydir.
class FaturaFormEkrani extends ConsumerStatefulWidget {
  const FaturaFormEkrani({
    required this.cariId,
    required this.tip,
    this.mevcut,
    super.key,
  });

  final String cariId;
  final IslemTipi tip;

  /// Düzenlenen kayıt. `null` ise yeni fatura girilir.
  final Islem? mevcut;

  @override
  ConsumerState<FaturaFormEkrani> createState() => _FaturaFormEkraniDurumu();
}

class _FaturaFormEkraniDurumu extends ConsumerState<FaturaFormEkrani> {
  final _formAnahtari = GlobalKey<FormState>();
  late final _baslik = TextEditingController(text: _baslikMetni());
  late final _kalemler = <IslemKalemi>[...?widget.mevcut?.kalemler];

  late DateTime _islemTarihi = widget.mevcut?.islemTarihi ?? _bugun();

  bool get _duzenlemeMi => widget.mevcut != null;

  /// Saat bileşeni sıfırlanır: aynı gün girilen iki işlemin sırası saate değil,
  /// belge kimliğine göre belirlenir (bkz. `islem_siralamasi.dart`).
  static DateTime _bugun() {
    final an = DateTime.now();
    return DateTime(an.year, an.month, an.day);
  }

  /// Açıklama kutusunun açılış değeri.
  ///
  /// Kayıtlı başlık kalemlerden türetilmişse kutu **boş** açılır: kullanıcı
  /// açıklamayı yazmamış demektir ve bir satırı değiştirdiğinde başlık da
  /// kendiliğinden yenilenmeli (bkz. [IslemBasligi.turetilmisMi]).
  String _baslikMetni() {
    final mevcut = widget.mevcut;
    if (mevcut == null) return '';

    return IslemBasligi.turetilmisMi(
          baslik: mevcut.baslik,
          kalemler: mevcut.kalemler,
        )
        ? ''
        : mevcut.baslik;
  }

  Kurus get _toplam => FaturaHesaplayici.hesapla(kalemler: _kalemler);

  @override
  void dispose() {
    _baslik.dispose();
    super.dispose();
  }

  Future<void> _kalemEkle() async {
    final kalem = await KalemDialogu.goster(context);
    if (kalem != null) setState(() => _kalemler.add(kalem));
  }

  Future<void> _kalemDuzenle(int sira) async {
    final kalem = await KalemDialogu.goster(context, mevcut: _kalemler[sira]);
    if (kalem != null) setState(() => _kalemler[sira] = kalem);
  }

  void _kalemSil(int sira) => setState(() => _kalemler.removeAt(sira));

  Future<void> _kaydet() async {
    if (!_formAnahtari.currentState!.validate()) return;
    if (_kalemler.isEmpty) {
      _uyariGoster(Metinler.kalemGerekli);
      return;
    }

    final mevcut = widget.mevcut;
    final fatura = Islem.fatura(
      id: mevcut?.id ?? '',
      tip: widget.tip,
      baslik: IslemBasligi.uret(
        yazilan: _baslik.text,
        kalemler: _kalemler,
      ),
      islemTarihi: _islemTarihi,
      kalemler: _kalemler,
    );

    final viewModel = ref.read(islemFormViewModelSaglayici.notifier);
    final basarili = mevcut == null
        ? await viewModel.kaydet(cariId: widget.cariId, islem: fatura)
        : await viewModel.guncelle(
            cariId: widget.cariId,
            eski: mevcut,
            yeni: fatura,
          );

    if (!mounted) return;
    if (basarili) {
      // Ekran kapanıyor; onay mesajı bir üstteki detay sayfasında görünsün.
      if (_duzenlemeMi) _uyariGoster(Metinler.islemGuncellendi);
      Navigator.of(context).pop(true);
    } else {
      final hata = ref.read(islemFormViewModelSaglayici).error;
      _uyariGoster(
        hata is UygulamaHatasi ? hata.mesaj : Metinler.beklenmeyenHata,
      );
    }
  }

  void _uyariGoster(String mesaj) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mesaj)));
  }

  @override
  Widget build(BuildContext context) {
    final islemSuruyor = ref.watch(islemFormViewModelSaglayici).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _duzenlemeMi
              ? '${widget.tip.ad} · ${Metinler.duzenle}'
              : widget.tip.ad,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formAnahtari,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Olculer.sayfaKenari,
              Olculer.bosluk20,
              Olculer.sayfaKenari,
              Olculer.bosluk32,
            ),
            children: <Widget>[
              if (_duzenlemeMi) ...<Widget>[
                const DuzenlemeUyarisi(),
                const SizedBox(height: Olculer.bosluk20),
              ],
              _BilgiBolumu(
                baslik: _baslik,
                islemTarihi: _islemTarihi,
                etkin: !islemSuruyor,
                onIslemTarihi: (tarih) => setState(() => _islemTarihi = tarih),
              ),
              const SizedBox(height: Olculer.bosluk24),
              _KalemBolumu(
                kalemler: _kalemler,
                etkin: !islemSuruyor,
                onEkle: _kalemEkle,
                onDuzenle: _kalemDuzenle,
                onSil: _kalemSil,
              ),
              const SizedBox(height: Olculer.bosluk20),
              FaturaOzeti(toplam: _toplam),
              const SizedBox(height: Olculer.bosluk24),
              Dugme.birincil(
                metin: Metinler.kaydet,
                onBasildi: _kaydet,
                yukleniyor: islemSuruyor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Açıklama ve işlem tarihi.
class _BilgiBolumu extends StatelessWidget {
  const _BilgiBolumu({
    required this.baslik,
    required this.islemTarihi,
    required this.etkin,
    required this.onIslemTarihi,
  });

  final TextEditingController baslik;
  final DateTime islemTarihi;
  final bool etkin;
  final ValueChanged<DateTime> onIslemTarihi;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: baslik,
          enabled: etkin,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: '${Metinler.aciklama} (${Metinler.istegeBagli})',
            hintText: Metinler.aciklamaIpucu,
            prefixIcon: Icon(Icons.description_outlined),
            helperText: Metinler.aciklamaAciklamasi,
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: Olculer.bosluk16),
        TarihAlani(
          etiket: Metinler.islemTarihi,
          tarih: islemTarihi,
          etkin: etkin,
          onSecildi: onIslemTarihi,
        ),
      ],
    );
  }
}

/// Kalem başlığı, listesi ve ekleme düğmesi.
class _KalemBolumu extends StatelessWidget {
  const _KalemBolumu({
    required this.kalemler,
    required this.etkin,
    required this.onEkle,
    required this.onDuzenle,
    required this.onSil,
  });

  final List<IslemKalemi> kalemler;
  final bool etkin;
  final VoidCallback onEkle;
  final ValueChanged<int> onDuzenle;
  final ValueChanged<int> onSil;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        BolumBasligi(
          baslik: Metinler.kalemler,
          eylem: Dugme.sade(
            metin: Metinler.kalemEkle,
            simge: Icons.add,
            kompakt: true,
            onBasildi: etkin ? onEkle : null,
          ),
        ),
        KalemListesi(
          kalemler: kalemler,
          onDuzenle: etkin ? onDuzenle : null,
          onSil: etkin ? onSil : null,
        ),
      ],
    );
  }
}
