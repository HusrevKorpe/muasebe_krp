import 'package:flutter/material.dart';

import '../../../../app/tasarim/bas_harf_karesi.dart';
import '../../../../app/tasarim/bekleme_satiri.dart';
import '../../../../app/tasarim/olculer.dart';
import '../../../../data/cari/cari_kaydi.dart';
import 'bakiye_metni.dart';

/// Cari listesinin tek satırı: baş harf, ad, bakiye rozeti.
class CariSatiri extends StatelessWidget {
  const CariSatiri({required this.kayit, required this.onTap, super.key});

  final CariKaydi kayit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cari = kayit.cari;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Olculer.sayfaKenari,
        vertical: Olculer.bosluk8,
      ),
      leading: BasHarfKaresi(ad: cari.ad),
      title: Text(cari.ad, maxLines: 1, overflow: TextOverflow.ellipsis),
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
