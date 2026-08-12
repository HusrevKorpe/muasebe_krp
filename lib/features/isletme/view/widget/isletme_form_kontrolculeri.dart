import 'package:flutter/widgets.dart';

import '../../../../domain/isletme/banka_hesabi.dart';
import '../../../../domain/isletme/isletme.dart';

/// İşletme formundaki metin denetleyicileri.
///
/// Kurulum ve profil düzenleme ekranı birebir aynı alanları gösteriyor.
/// Denetleyicileri tek yerde toplamak, iki ekranda da yedi alanlık listeyi
/// elle tekrarlamayı ve birinde unutulan `dispose` çağrısını önler.
class IsletmeFormKontrolculeri {
  IsletmeFormKontrolculeri([Isletme? mevcut])
    : ad = TextEditingController(text: mevcut?.ad ?? ''),
      unvan = TextEditingController(text: mevcut?.unvan ?? ''),
      adres = TextEditingController(text: mevcut?.adres ?? ''),
      telefon = TextEditingController(text: mevcut?.telefon ?? ''),
      faks = TextEditingController(text: mevcut?.faks ?? ''),
      vergiDairesi = TextEditingController(text: mevcut?.vergiDairesi ?? ''),
      vergiNo = TextEditingController(text: mevcut?.vergiNo ?? '');

  final TextEditingController ad;
  final TextEditingController unvan;
  final TextEditingController adres;
  final TextEditingController telefon;
  final TextEditingController faks;
  final TextEditingController vergiDairesi;
  final TextEditingController vergiNo;

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
    faks: faks.text.trim().isEmpty ? null : faks.text.trim(),
    vergiDairesi: vergiDairesi.text.trim(),
    vergiNo: vergiNo.text.trim(),
    bankaHesaplari: bankaHesaplari,
  );

  void dispose() {
    ad.dispose();
    unvan.dispose();
    adres.dispose();
    telefon.dispose();
    faks.dispose();
    vergiDairesi.dispose();
    vergiNo.dispose();
  }
}
