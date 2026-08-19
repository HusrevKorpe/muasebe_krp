import 'package:flutter/material.dart';

import '../../../../app/tasarim/bas_harf_karesi.dart';
import '../../../../app/tasarim/bekleme_satiri.dart';
import '../../../../app/tasarim/olculer.dart';
import '../../../../app/tasarim/rozet.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../data/cari/cari_kaydi.dart';
import 'bakiye_metni.dart';

/// Cari listesinin tek satırı: baş harf, ad, bakiye rozeti.
class CariSatiri extends StatelessWidget {
  const CariSatiri({
    required this.kayit,
    required this.onTap,
    this.grubuGoster = false,
    super.key,
  });

  final CariKaydi kayit;
  final VoidCallback onTap;

  /// Fidancı kişilerde ada bitişik küçük bir rozet basılsın mı.
  ///
  /// Yalnızca iki grubun karıştığı listede (Açık Hesaplar) açılır; kendi
  /// sekmesinde her satıra "Fidancı" yazmak bilgi vermez.
  final bool grubuGoster;

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
      leading: BasHarfKaresi(ad: cari.ad),
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
      trailing: BakiyeMetni(bakiye: cari.bakiye, rozet: true),
    );
  }
}
