import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hata/hatalar.dart';
import '../../../core/metin/metinler.dart';
import '../../../core/para/kurus.dart';
import '../../../domain/cari/cari.dart';
import '../../../domain/cari/cari_dogrulama.dart';
import '../viewmodel/cari_form_viewmodel.dart';

/// Cari ekleme ve düzenleme formu.
///
/// [mevcut] `null` ise yeni kayıt açılır. Ekleme ve düzenleme aynı ekranda:
/// alanlar birebir aynı, tek fark başlık ve kaydetme yolu.
class CariFormEkrani extends ConsumerStatefulWidget {
  const CariFormEkrani({this.mevcut, super.key});

  final Cari? mevcut;

  @override
  ConsumerState<CariFormEkrani> createState() => _CariFormEkraniDurumu();
}

class _CariFormEkraniDurumu extends ConsumerState<CariFormEkrani> {
  final _formAnahtari = GlobalKey<FormState>();

  late final Map<_Alan, TextEditingController> _kontrolcular = {
    for (final alan in _Alan.values)
      alan: TextEditingController(text: alan.mevcuttanOku(widget.mevcut)),
  };

  bool get _duzenlemeMi => widget.mevcut != null;

  @override
  void dispose() {
    for (final kontrolcu in _kontrolcular.values) {
      kontrolcu.dispose();
    }
    super.dispose();
  }

  String? _metin(_Alan alan) {
    final deger = _kontrolcular[alan]!.text.trim();
    return deger.isEmpty ? null : deger;
  }

  Cari _formdanCari() {
    final mevcut = widget.mevcut;
    return Cari(
      id: mevcut?.id ?? '',
      ad: _kontrolcular[_Alan.ad]!.text.trim(),
      unvan: _metin(_Alan.unvan),
      sehir: _metin(_Alan.sehir),
      telefon: _metin(_Alan.telefon),
      adres: _metin(_Alan.adres),
      notlar: _metin(_Alan.notlar),
      // Bakiye ve tarihler formdan gelmez; repository bu alanlara dokunmuyor.
      bakiye: mevcut?.bakiye ?? Kurus.sifir,
      sonIslemTarihi: mevcut?.sonIslemTarihi,
      aktif: mevcut?.aktif ?? true,
      olusturmaTarihi: mevcut?.olusturmaTarihi,
      guncellemeTarihi: mevcut?.guncellemeTarihi,
    );
  }

  Future<void> _kaydet() async {
    if (!_formAnahtari.currentState!.validate()) return;

    final basarili = await ref
        .read(cariFormViewModelSaglayici.notifier)
        .kaydet(_formdanCari());

    if (!mounted) return;
    if (basarili) {
      Navigator.of(context).pop(true);
    } else {
      _hatayiGoster();
    }
  }

  Future<void> _pasifeAl() async {
    final onaylandi = await _onayAl(
      baslik: Metinler.cariPasifeAl,
      mesaj: Metinler.cariPasifeAlOnay,
    );
    if (!onaylandi || !mounted) return;

    final basarili = await ref
        .read(cariFormViewModelSaglayici.notifier)
        .pasifeAl(widget.mevcut!.id);

    if (!mounted) return;
    if (basarili) {
      Navigator.of(context).pop(false);
    } else {
      _hatayiGoster();
    }
  }

  Future<bool> _onayAl({required String baslik, required String mesaj}) async {
    final sonuc = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(baslik),
        content: Text(mesaj),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Metinler.vazgec),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(Metinler.tamam),
          ),
        ],
      ),
    );
    return sonuc ?? false;
  }

  void _hatayiGoster() {
    final hata = ref.read(cariFormViewModelSaglayici).error;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            hata is UygulamaHatasi ? hata.mesaj : Metinler.beklenmeyenHata,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final islemSuruyor = ref.watch(cariFormViewModelSaglayici).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_duzenlemeMi ? Metinler.cariDuzenle : Metinler.cariEkle),
        actions: [
          if (_duzenlemeMi)
            IconButton(
              icon: const Icon(Icons.person_off_outlined),
              tooltip: Metinler.cariPasifeAl,
              onPressed: islemSuruyor ? null : _pasifeAl,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formAnahtari,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              for (final alan in _Alan.values) ...[
                _AlanKutusu(
                  alan: alan,
                  kontrolcu: _kontrolcular[alan]!,
                  etkin: !islemSuruyor,
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),
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

/// Formdaki alanlar. Etiket, doğrulama ve klavye tipi tek yerde durur; ekran
/// bunları döngüyle basar — on iki kez tekrarlanan `TextFormField` bloğu yerine.
enum _Alan {
  ad(
    etiket: Metinler.cariAdi,
    ipucu: Metinler.cariAdiIpucu,
    simge: Icons.person_outline,
    zorunlu: true,
  ),
  unvan(etiket: Metinler.cariUnvan, simge: Icons.badge_outlined),
  sehir(
    etiket: Metinler.sehir,
    ipucu: Metinler.sehirIpucu,
    simge: Icons.location_city_outlined,
  ),
  telefon(
    etiket: Metinler.telefon,
    simge: Icons.phone_outlined,
    klavye: TextInputType.phone,
  ),
  adres(etiket: Metinler.adres, simge: Icons.home_outlined, satirSayisi: 2),
  notlar(etiket: Metinler.notlar, simge: Icons.notes_outlined, satirSayisi: 3);

  const _Alan({
    required this.etiket,
    required this.simge,
    this.ipucu,
    this.zorunlu = false,
    this.klavye,
    this.satirSayisi = 1,
  });

  final String etiket;
  final String? ipucu;
  final IconData simge;
  final bool zorunlu;
  final TextInputType? klavye;
  final int satirSayisi;

  /// Zorunlu olmayan alanlarda etikete "(isteğe bağlı)" eklenir; kullanıcı
  /// hangi alanı boş bırakabileceğini formu göndermeden görsün.
  String get tamEtiket =>
      zorunlu ? etiket : '$etiket (${Metinler.istegeBagli})';

  String? Function(String?)? get dogrulayici => switch (this) {
    _Alan.ad => CariDogrulama.ad,
    _Alan.telefon => CariDogrulama.telefon,
    _ => null,
  };

  String mevcuttanOku(Cari? cari) {
    if (cari == null) return '';
    return switch (this) {
      _Alan.ad => cari.ad,
      _Alan.unvan => cari.unvan ?? '',
      _Alan.sehir => cari.sehir ?? '',
      _Alan.telefon => cari.telefon ?? '',
      _Alan.adres => cari.adres ?? '',
      _Alan.notlar => cari.notlar ?? '',
    };
  }
}

class _AlanKutusu extends StatelessWidget {
  const _AlanKutusu({
    required this.alan,
    required this.kontrolcu,
    required this.etkin,
  });

  final _Alan alan;
  final TextEditingController kontrolcu;
  final bool etkin;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: kontrolcu,
      enabled: etkin,
      validator: alan.dogrulayici,
      keyboardType: alan.klavye,
      maxLines: alan.satirSayisi,
      textCapitalization: alan.klavye == null
          ? TextCapitalization.words
          : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: alan.tamEtiket,
        hintText: alan.ipucu,
        prefixIcon: Icon(alan.simge),
      ),
    );
  }
}
