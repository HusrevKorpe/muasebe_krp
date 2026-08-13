import 'package:flutter/widgets.dart';

import '../../../../domain/isletme/banka_hesabi.dart';
import '../../../../domain/isletme/isletme.dart';

/// İşletme formundaki metin denetleyicileri.
///
/// Denetleyicileri tek yerde toplamak, alan listesini ekranda elle tekrarlamayı
/// ve unutulan bir `dispose` çağrısını önler.
class IsletmeFormKontrolculeri {
  IsletmeFormKontrolculeri([Isletme? mevcut])
    : ad = TextEditingController(text: mevcut?.ad ?? ''),
      unvan = TextEditingController(text: mevcut?.unvan ?? ''),
      adres = TextEditingController(text: mevcut?.adres ?? ''),
      telefon = TextEditingController(text: mevcut?.telefon ?? '');

  final TextEditingController ad;
  final TextEditingController unvan;
  final TextEditingController adres;
  final TextEditingController telefon;

  /// Formdaki değerleri [temel] kaydın üzerine uygular.
  ///
  /// [bankaHesaplari] ayrı geçilir; hesaplar metin alanı değil, ekranın kendi
  /// listesinde tutulan kayıtlardır.
  Isletme isletmeyeUygula(
    Isletme temel, {
    required List<BankaHesabi> bankaHesaplari,
  }) => temel.kopyala(
    ad: ad.text.trim(),
    unvan: unvan.text.trim(),
    adres: adres.text.trim(),
    telefon: telefon.text.trim(),
    bankaHesaplari: bankaHesaplari,
  );

  void dispose() {
    ad.dispose();
    unvan.dispose();
    adres.dispose();
    telefon.dispose();
  }
}
