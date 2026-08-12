import 'package:flutter/material.dart';

import '../../../../app/tema.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../domain/islem/islem_tipi.dart';

/// [IslemTipi]'nin ekrandaki karşılıkları: ad, simge ve renk.
///
/// Domain tarafı işlemin muhasebe yönünü bilir; adının nasıl yazıldığı ve hangi
/// renkle gösterildiği görünüm bilgisidir ve bu yüzden burada durur
/// (bkz. KURALLAR.md §1.3).
extension IslemTipiGorunumu on IslemTipi {
  /// Kullanıcıya gösterilen ad.
  String get ad => switch (this) {
    IslemTipi.satisFaturasi => Metinler.satisFaturasi,
    IslemTipi.alisFaturasi => Metinler.alisFaturasi,
    IslemTipi.tahsilat => Metinler.tahsilat,
    IslemTipi.odeme => Metinler.odeme,
  };

  /// Yeni kayıt ekranının başlığı.
  String get formBasligi => switch (this) {
    IslemTipi.satisFaturasi => Metinler.yeniSatisFaturasi,
    IslemTipi.alisFaturasi => Metinler.yeniAlisFaturasi,
    IslemTipi.tahsilat => Metinler.yeniTahsilat,
    IslemTipi.odeme => Metinler.yeniOdeme,
  };

  /// Yeni kayıtta açıklama alanına gelen varsayılan metin.
  String get varsayilanBaslik => switch (this) {
    IslemTipi.tahsilat => Metinler.musteridenTahsilat,
    IslemTipi.odeme => Metinler.cariyeOdeme,
    _ => '',
  };

  IconData get simge => switch (this) {
    IslemTipi.satisFaturasi || IslemTipi.alisFaturasi =>
      Icons.receipt_long_outlined,
    IslemTipi.tahsilat => Icons.payments_outlined,
    IslemTipi.odeme => Icons.account_balance_wallet_outlined,
  };

  /// Borç işlemleri bakiyeyi artırır ve borç rengiyle, alacak işlemleri
  /// azaltır ve alacak rengiyle gösterilir.
  Color renk(Brightness parlaklik) =>
      borcMu ? Tema.borcRengi(parlaklik) : Tema.alacakRengi(parlaklik);

  /// Tutarın hangi kolona yazıldığını anlatan etiket.
  String get kolonEtiketi => borcMu ? Metinler.borc : Metinler.alacak;
}
