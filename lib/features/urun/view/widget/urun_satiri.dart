import 'package:flutter/material.dart';

import '../../../../app/tasarim/bekleme_satiri.dart';
import '../../../../app/tasarim/olculer.dart';
import '../../../../app/tasarim/rozet.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../core/para/para_bicimi.dart';
import '../../../../data/urun/urun_kaydi.dart';

/// Ürün listesinin tek satırı: adı ve fiyatı.
///
/// Fiyat kolonu sayesinde liste aynı zamanda **fiyat listesidir** — ayrı bir
/// ekran açmaya gerek kalmıyor (bkz. `fazlar/faz-3-katalog.md`).
class UrunSatiri extends StatelessWidget {
  const UrunSatiri({required this.kayit, required this.onTap, super.key});

  static const double _kareBoyu = 40;

  final UrunKaydi kayit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final urun = kayit.urun;
    final tema = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Olculer.sayfaKenari,
        vertical: Olculer.bosluk8,
      ),
      leading: Container(
        width: _kareBoyu,
        height: _kareBoyu,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tema.colorScheme.secondaryContainer,
          borderRadius: Olculer.koseOrta,
        ),
        child: Icon(
          Icons.local_florist_outlined,
          size: 20,
          color: tema.colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(urun.ad, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: kayit.beklemede ? const BeklemeSatiri() : null,
      // Fiyatı olmayan ürün rozetsiz kalıyor: "Fiyat girilmedi" bir tutar değil,
      // bir eksiklik — hap biçiminde basılırsa tutar gibi okunuyor.
      trailing: urun.fiyat.sifirMi
          ? Text(
              Metinler.fiyatYok,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            )
          : Rozet(
              metin: urun.fiyat.bicimli,
              renk: tema.colorScheme.onSurface,
              zemin: tema.colorScheme.surfaceContainer,
              stil: tema.textTheme.titleSmall,
            ),
    );
  }
}
