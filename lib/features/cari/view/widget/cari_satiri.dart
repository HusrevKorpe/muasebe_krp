import 'package:flutter/material.dart';

import '../../../../app/tasarim/bas_harf_karesi.dart';
import '../../../../app/tasarim/bekleme_satiri.dart';
import '../../../../app/tasarim/olculer.dart';
import '../../../../app/tasarim/rozet.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../data/cari/cari_kaydi.dart';
import 'bakiye_metni.dart';

/// Cari listesinin tek satırı: sıra numarası, baş harf, ad, bakiye rozeti.
class CariSatiri extends StatelessWidget {
  const CariSatiri({
    required this.kayit,
    required this.sira,
    required this.onTap,
    this.grubuGoster = false,
    this.eylem,
    super.key,
  });

  /// Sıra numarası sütununun genişliği — üç haneye yetiyor.
  ///
  /// Sabit: numaralar kendi genişliğince yer kaplarsa adlar satırdan satıra
  /// kayar ve liste sallanır.
  static const double _siraGenisligi = 26;

  /// Numara sütununun satır içeriğini sağa itme miktarı.
  static const double _siraSutunu = _siraGenisligi + Olculer.bosluk8;

  /// Ayraç çizgisinin sol girintisi.
  ///
  /// Çizgi baş harf karesinin altından değil adın hizasından başlıyor; tam
  /// genişlikte bir çizgi satırları kesip listeyi tabloya çeviriyordu. Hesap:
  /// satır kenarı + numara sütunu + baş harf karesi + `ListTile`'ın başlıkla
  /// arasındaki aralık (16).
  static const double ayracGirintisi =
      Olculer.sayfaKenari +
      _siraSutunu +
      BasHarfKaresi.varsayilanCap +
      Olculer.bosluk16;

  final CariKaydi kayit;

  /// Satırın listedeki sırası, 1'den başlar.
  ///
  /// Kullanıcının isteği: *"1-2-3 diye sıralasın herkesi... kaç farklı kişi
  /// olduğunu bilelim."* Numara listedeki yerdir, kişinin kimliği değil:
  /// arama yapınca ya da başka bir sekmeye geçince baştan başlar.
  final int sira;

  final VoidCallback onTap;

  /// Fidancı kişilerde ada bitişik küçük bir rozet basılsın mı.
  ///
  /// Yalnızca iki grubun karıştığı listede (Açık Hesaplar, Kaldırılan Kişiler)
  /// açılır; kendi sekmesinde her satıra "Fidancı" yazmak bilgi vermez.
  final bool grubuGoster;

  /// Bakiyenin sağına eklenen düğme — kaldırılan kişiler sayfasındaki "geri al"
  /// böyle geliyor. Bakiyenin yerini almaz: kaldırılmış bir kişinin açık hesabı
  /// varsa bunu görmek, geri almaya karar vermenin ta kendisi.
  final Widget? eylem;

  @override
  Widget build(BuildContext context) {
    final cari = kayit.cari;
    final tema = Theme.of(context);
    final rozetliMi = grubuGoster && cari.grup.fidanciMi;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Olculer.sayfaKenari,
        vertical: Olculer.bosluk8,
      ),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: _siraGenisligi,
            child: Text(
              '$sira',
              textAlign: TextAlign.end,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
                // Sabit genişlikli rakamlar: 9 ile 10 arasında sütun kaymasın.
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: Olculer.bosluk8),
          BasHarfKaresi(ad: cari.ad),
        ],
      ),
      title: rozetliMi
          // Ad `Flexible`: uzun bir adın rozeti ekrandan taşırmaması için
          // kısalan taraf ad olmalı, rozet değil.
          ? Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    cari.ad,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Olculer.bosluk8),
                Rozet(
                  metin: Metinler.cariGrubuFidanci,
                  renk: tema.colorScheme.onSurfaceVariant,
                  stil: tema.textTheme.labelSmall,
                  kalin: false,
                ),
              ],
            )
          : Text(cari.ad, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: kayit.beklemede
          ? const BeklemeSatiri()
          : (cari.altBaslik == null
                ? null
                : Text(
                    cari.altBaslik!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )),
      trailing: eylem == null
          ? BakiyeMetni(bakiye: cari.bakiye, rozet: true)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                BakiyeMetni(bakiye: cari.bakiye, rozet: true),
                eylem!,
              ],
            ),
    );
  }
}
