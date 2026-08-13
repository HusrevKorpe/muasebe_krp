import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
class FaturaFormEkrani extends ConsumerStatefulWidget {
  const FaturaFormEkrani({
    required this.cariId,
    required this.tip,
    super.key,
  });

  final String cariId;
  final IslemTipi tip;

  @override
  ConsumerState<FaturaFormEkrani> createState() => _FaturaFormEkraniDurumu();
}

class _FaturaFormEkraniDurumu extends ConsumerState<FaturaFormEkrani> {
  final _formAnahtari = GlobalKey<FormState>();
  final _baslik = TextEditingController();
  final _kalemler = <IslemKalemi>[];

  late DateTime _islemTarihi = _bugun();

  /// Saat bileşeni sıfırlanır: aynı gün girilen iki işlemin sırası saate değil,
  /// belge kimliğine göre belirlenir (bkz. `islem_siralamasi.dart`).
  static DateTime _bugun() {
    final an = DateTime.now();
    return DateTime(an.year, an.month, an.day);
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

    final fatura = Islem.fatura(
      tip: widget.tip,
      baslik: IslemBasligi.uret(
        yazilan: _baslik.text,
        kalemler: _kalemler,
      ),
      islemTarihi: _islemTarihi,
      kalemler: _kalemler,
    );

    final basarili = await ref
        .read(islemFormViewModelSaglayici.notifier)
        .kaydet(cariId: widget.cariId, islem: fatura);

    if (!mounted) return;
    if (basarili) {
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
      appBar: AppBar(title: Text(widget.tip.ad)),
      body: SafeArea(
        child: Form(
          key: _formAnahtari,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _BilgiBolumu(
                baslik: _baslik,
                islemTarihi: _islemTarihi,
                etkin: !islemSuruyor,
                onIslemTarihi: (tarih) => setState(() => _islemTarihi = tarih),
              ),
              const SizedBox(height: 24),
              _KalemBolumu(
                kalemler: _kalemler,
                etkin: !islemSuruyor,
                onEkle: _kalemEkle,
                onDuzenle: _kalemDuzenle,
                onSil: _kalemSil,
              ),
              const SizedBox(height: 24),
              FaturaOzeti(toplam: _toplam),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: islemSuruyor ? null : _kaydet,
                child: islemSuruyor
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(Metinler.kaydet),
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
        const SizedBox(height: 16),
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
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Metinler.kalemler,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              onPressed: etkin ? onEkle : null,
              icon: const Icon(Icons.add),
              label: const Text(Metinler.kalemEkle),
            ),
          ],
        ),
        const SizedBox(height: 8),
        KalemListesi(
          kalemler: kalemler,
          onDuzenle: etkin ? onDuzenle : null,
          onSil: etkin ? onSil : null,
        ),
      ],
    );
  }
}
