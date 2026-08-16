import 'package:flutter/material.dart';

import '../../../../app/tasarim/dugme.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../core/para/para_bicimi.dart';
import '../../../../core/para/para_girisi.dart';
import '../../../../domain/islem/islem_kalemi.dart';
import '../../../../domain/islem/kalem_giris_modu.dart';
import '../../../../domain/secenek/secenek_tipi.dart';
import '../../../secenek/view/secenek_listesi_ekrani.dart';
import '../../../urun/view/urun_secim_sayfasi.dart';
import 'kalem_alanlari.dart';

/// Fatura kalemi ekleme/düzenleme kutusu.
///
/// Fidan kimliği üç ayrı kutuya giriliyor — Tür, Çeşit, Anaç — ve her satışta
/// yeniden yazılabiliyor. Kutuların gerekçesi [KalemAlanlari]'nda anlatılıyor.
///
/// Kullanıcı tutarı iki uçtan da girebilir: birim fiyattan ya da toplamdan.
/// İkinci mod zorunludur, çünkü kullanıcı yuvarlak toplam üzerinden çalışır —
/// referans ekstredeki `1.650 Adet × 18,79 ₺ = 31.000 ₺` satırı yalnızca böyle
/// tutar (bkz. [KalemGirisModu]).
///
/// Kalem iki ayrı yoldan doldurulabilir. **Üründen seç** hazır bir kombinasyonu
/// getirir ve fiyatı da ön dolgu yapar. Üç kutunun kendi liste düğmeleri ise
/// parçaları ayrı ayrı getirir: kullanıcı türleri, çeşitleri ve anaçları bir
/// kez giriyor, sonra `Elma` + `Scarlet` + `M9` diye tıklıyor. Katalogdaki
/// kayıt tam kombinasyon olduğu için kombinasyon sayısı çarpım kadar; hepsini
/// ürün olarak girmek pratikte yürümüyordu (bkz. [SecenekTipi]).
///
/// İkisi de **zorunlu değil**, serbest giriş korunur: "nakliye" gibi kalemler
/// hiçbir listede yer almaz ve seçim zorunlu olsaydı kullanıcı tezgahta
/// tıkanırdı (bkz. `fazlar/faz-3-katalog.md`).
class KalemDialogu extends StatefulWidget {
  const KalemDialogu({this.mevcut, super.key});

  final IslemKalemi? mevcut;

  /// Kutuyu açar. Kullanıcı vazgeçerse `null` döner.
  static Future<IslemKalemi?> goster(
    BuildContext context, {
    IslemKalemi? mevcut,
  }) => showDialog<IslemKalemi>(
    context: context,
    builder: (context) => KalemDialogu(mevcut: mevcut),
  );

  @override
  State<KalemDialogu> createState() => _KalemDialoguDurumu();
}

class _KalemDialoguDurumu extends State<KalemDialogu> {
  final _formAnahtari = GlobalKey<FormState>();
  late final TextEditingController _tur;
  late final TextEditingController _cesit;
  late final TextEditingController _anac;
  late final TextEditingController _miktar;
  late final TextEditingController _deger;

  KalemGirisModu _mod = KalemGirisModu.birimFiyat;

  /// Listeden seçilen ürünün kimliği. Serbest girişte `null` kalır ve daha önce
  /// girilmiş eski kalemler bu hâliyle bozulmadan açılır.
  String? _urunId;

  bool get _duzenlemeMi => widget.mevcut != null;

  @override
  void initState() {
    super.initState();
    final mevcut = widget.mevcut;
    _urunId = mevcut?.urunId;
    // Düzenlemede toplam gösterilir: kayıtta esas olan tutardır, birim fiyat
    // ondan türetilmiş olabilir.
    _mod = mevcut != null && mevcut.birimFiyatYuvarlanmisMi
        ? KalemGirisModu.toplam
        : KalemGirisModu.birimFiyat;
    _tur = TextEditingController(text: mevcut?.tur ?? '');
    _cesit = TextEditingController(text: mevcut?.cesit ?? '');
    _anac = TextEditingController(text: mevcut?.anac ?? '');
    _miktar = TextEditingController(
      text: mevcut == null ? '' : miktarBicimle(mevcut.miktar),
    );
    _deger = TextEditingController(
      text: mevcut == null
          ? ''
          : kurusMetni(
              _mod == KalemGirisModu.toplam ? mevcut.tutar : mevcut.birimFiyat,
            ),
    );
  }

  @override
  void dispose() {
    _tur.dispose();
    _cesit.dispose();
    _anac.dispose();
    _miktar.dispose();
    _deger.dispose();
    super.dispose();
  }

  /// Girilen değerlerden kalemi kurar. Alanlar geçersizse `null` döner.
  IslemKalemi? _kalemiKur() {
    final miktar = miktarAyristir(_miktar.text);
    final deger = kurusAyristir(_deger.text);
    if (miktar == null || miktar <= 0 || deger == null) return null;

    final tur = _tur.text.trim();
    final cesit = _cesit.text.trim();
    final anac = _anac.text.trim();

    return switch (_mod) {
      KalemGirisModu.birimFiyat => IslemKalemi.birimFiyattan(
        tur: tur,
        cesit: cesit,
        anac: anac,
        miktar: miktar,
        birimFiyat: deger,
        urunId: _urunId,
      ),
      KalemGirisModu.toplam => IslemKalemi.toplamdan(
        tur: tur,
        cesit: cesit,
        anac: anac,
        miktar: miktar,
        toplam: deger,
        urunId: _urunId,
      ),
    };
  }

  void _kaydet() {
    if (!_formAnahtari.currentState!.validate()) return;
    final kalem = _kalemiKur();
    if (kalem == null) return;
    Navigator.of(context).pop(kalem);
  }

  /// Listeden ürün seçer: üç kutu ve birim fiyat ön dolgu gelir.
  ///
  /// Gelen fiyat yalnızca bir başlangıç değeridir; kullanıcı alanı olduğu gibi
  /// değiştirebilir. Faturaya giren tutar listedeki fiyattan bağımsızdır
  /// (bkz. KURALLAR.md §3.2).
  Future<void> _urunSec() async {
    final urun = await UrunSecimSayfasi.goster(context);
    if (urun == null || !mounted) return;

    setState(() {
      _urunId = urun.id;
      _tur.text = urun.tur;
      _cesit.text = urun.cesit;
      _anac.text = urun.anac;
      if (!urun.fiyat.sifirMi) {
        _mod = KalemGirisModu.birimFiyat;
        _deger.text = kurusMetni(urun.fiyat);
      }
    });
  }

  /// Tek bir kutuyu kendi listesinden doldurur.
  ///
  /// Ürün bağı **bozulmaz**: kullanıcı katalogdan seçtiği kalemin yalnızca
  /// anacını değiştiriyor olabilir ve bağ, elle yazınca da kopmuyor
  /// (bkz. [_urunSec]). Bağı kaldırmak rozetin kendi işi.
  Future<void> _secenekSec(SecenekTipi tip) async {
    final ad = await SecenekListesiEkrani.sec(context, tip);
    if (ad == null || !mounted) return;

    setState(() {
      switch (tip) {
        case SecenekTipi.tur:
          _tur.text = ad;
        case SecenekTipi.cesit:
          _cesit.text = ad;
        case SecenekTipi.anac:
          _anac.text = ad;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_duzenlemeMi ? Metinler.kalemDuzenle : Metinler.kalemEkle),
      content: SingleChildScrollView(
        child: Form(
          key: _formAnahtari,
          child: KalemAlanlari(
            tur: _tur,
            cesit: _cesit,
            anac: _anac,
            miktar: _miktar,
            deger: _deger,
            mod: _mod,
            urunBagliMi: _urunId != null,
            tureOdaklan: !_duzenlemeMi,
            onizleme: _kalemiKur(),
            onUrunSec: _urunSec,
            onSecenekSec: _secenekSec,
            onBagiKaldir: () => setState(() => _urunId = null),
            onModDegisti: (mod) => setState(() => _mod = mod),
            onDegisti: () => setState(() {}),
          ),
        ),
      ),
      actions: <Widget>[
        Dugme.sade(
          metin: Metinler.vazgec,
          kompakt: true,
          onBasildi: () => Navigator.of(context).pop(),
        ),
        Dugme.birincil(
          metin: _duzenlemeMi ? Metinler.kaydet : Metinler.ekle,
          kompakt: true,
          onBasildi: _kaydet,
        ),
      ],
    );
  }
}
