import 'package:flutter/material.dart';

import '../../../../app/tasarim/renkler.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../domain/islem/islem_tipi.dart';

/// [IslemTipi]'nin ekrandaki karşılıkları: ad, simge ve renk.
///
/// Domain tarafı işlemin muhasebe yönünü bilir; adının nasıl yazıldığı ve hangi
/// renkle gösterildiği görünüm bilgisidir ve bu yüzden burada durur
/// (bkz. KURALLAR.md §1.3).
extension IslemTipiGorunumu on IslemTipi {
  /// Uygulamada gösterilen ad — günlük dil.
  ///
  /// Uygulama tek kişinin kendi defteri; düğmede "Satış Faturası" değil
  /// "Sattım" yazıyor. Müşteriye giden belgede kullanılan ad ayrı: [belgeAdi].
  String get ad => switch (this) {
    IslemTipi.satisFaturasi => Metinler.sattim,
    IslemTipi.alisFaturasi => Metinler.aldim,
    IslemTipi.tahsilat => Metinler.paraAldim,
    IslemTipi.odeme => Metinler.paraVerdim,
  };

  /// PDF hesap dökümünde basılan ad — belge dili.
  ///
  /// Döküm müşteriye gidiyor; orada "Sattım — Zeytin-Hurma" yazamayız.
  /// Referans ekstredeki yazım korunuyor (bkz. `ekstreAciklamasi`).
  String get belgeAdi => switch (this) {
    IslemTipi.satisFaturasi => Metinler.satisFaturasi,
    IslemTipi.alisFaturasi => Metinler.alisFaturasi,
    IslemTipi.tahsilat => Metinler.tahsilat,
    IslemTipi.odeme => Metinler.odeme,
  };

  /// Yeni kayıtta açıklama alanına gelen varsayılan metin.
  ///
  /// Belge diliyle yazılır: bu metin doğrudan hesap dökümüne basılıyor.
  String get varsayilanBaslik => switch (this) {
    IslemTipi.tahsilat => Metinler.musteridenTahsilat,
    IslemTipi.odeme => Metinler.cariyeOdeme,
    _ => '',
  };

  IconData get simge => switch (this) {
    IslemTipi.satisFaturasi => Icons.local_shipping_outlined,
    IslemTipi.alisFaturasi => Icons.inventory_2_outlined,
    IslemTipi.tahsilat => Icons.south_west,
    IslemTipi.odeme => Icons.north_east,
  };

  /// Borç işlemleri bakiyeyi artırır ve borç rengiyle, alacak işlemleri
  /// azaltır ve alacak rengiyle gösterilir.
  Color renk(Brightness parlaklik) =>
      borcMu ? Renkler.borc(parlaklik) : Renkler.alacak(parlaklik);

  /// [renk]'in soluk zemini — simgenin arkasındaki daire, giriş düğmeleri.
  Color zemin(Brightness parlaklik) => borcMu
      ? Renkler.borcZemini(parlaklik)
      : Renkler.alacakZemini(parlaklik);

  /// Tutarın hangi kolona yazıldığını anlatan etiket.
  String get kolonEtiketi => borcMu ? Metinler.borc : Metinler.alacak;
}
