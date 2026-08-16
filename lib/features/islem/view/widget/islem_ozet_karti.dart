import 'package:flutter/material.dart';

import '../../../../app/tasarim/olculer.dart';
import '../../../../app/tasarim/rozet.dart';
import '../../../../core/metin/metinler.dart';
import '../../../../core/para/para_bicimi.dart';
import '../../../../core/tarih/tarih_bicimi.dart';
import '../../../../data/islem/islem_kaydi.dart';
import 'islem_tipi_gorunumu.dart';

/// İşlem detayının üst kartı: tip rozeti, açıklama, tutar ve tarihler.
///
/// Tutar kartın en büyük öğesi — sayfayı açan kişinin aradığı şey o. Tipin
/// rengi hem rozette hem tutarda görünüyor: iptalli kayıtta ikisi de griye
/// düşüyor, böylece "bu kayıt sayılmıyor" tek bakışta okunuyor.
class IslemOzetKarti extends StatelessWidget {
  const IslemOzetKarti({required this.kayit, super.key});

  final IslemKaydi kayit;

  @override
  Widget build(BuildContext context) {
    final islem = kayit.islem;
    final tema = Theme.of(context);
    final iptalli = islem.iptalMi;
    final renk = iptalli
        ? tema.colorScheme.onSurfaceVariant
        : islem.tip.renk(tema.brightness);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Olculer.bosluk20),
      decoration: BoxDecoration(
        color: iptalli
            ? tema.colorScheme.surfaceContainer
            : islem.tip.zemin(tema.brightness),
        borderRadius: Olculer.koseBuyuk,
        border: Border.all(color: renk.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(islem.tip.simge, size: 18, color: renk),
              const SizedBox(width: Olculer.bosluk8),
              Expanded(
                child: Text(
                  islem.tip.ad,
                  style: tema.textTheme.labelLarge?.copyWith(color: renk),
                ),
              ),
              // Tutarın hesap dökümünde hangi kolona yazıldığı: "Borç" ya da
              // "Alacak". Ekranda günlük dil kullanılıyor ("Sattım"), müşteriye
              // giden belgede muhasebe dili — ikisi burada yan yana duruyor.
              Rozet(
                metin: islem.tip.kolonEtiketi,
                renk: renk,
                zemin: tema.colorScheme.surfaceContainerLowest,
              ),
            ],
          ),
          const SizedBox(height: Olculer.bosluk12),
          Text(
            islem.toplam.bicimli,
            style: tema.textTheme.headlineMedium?.copyWith(
              color: renk,
              decoration: iptalli ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: Olculer.bosluk4),
          Text(
            islem.baslik,
            style: tema.textTheme.titleMedium?.copyWith(
              color: tema.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: Olculer.bosluk16),
          _Satir(etiket: Metinler.islemTarihi, deger: uzunTarih(islem.islemTarihi)),
          // Sonradan düzeltilmiş kayıt bunu göstermeli: müşterinin elindeki
          // eski ekstre bu satırı başka tutarla basmış olabilir.
          if (islem.guncellemeTarihi != null)
            _Satir(
              etiket: Metinler.sonDuzenleme,
              deger: uzunTarih(islem.guncellemeTarihi!),
            ),
          if (islem.iptalNedeni != null)
            _Satir(etiket: Metinler.iptalNedeni, deger: islem.iptalNedeni!),
          if (kayit.beklemede) ...<Widget>[
            const SizedBox(height: Olculer.bosluk12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 15,
                  color: tema.colorScheme.tertiary,
                ),
                const SizedBox(width: Olculer.bosluk8),
                Expanded(
                  child: Text(
                    Metinler.kaydedilmediAciklama,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Kartın altındaki etiket–değer satırı.
class _Satir extends StatelessWidget {
  const _Satir({required this.etiket, required this.deger});

  final String etiket;
  final String deger;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Olculer.bosluk4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            etiket,
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Olculer.bosluk12),
          Flexible(
            child: Text(
              deger,
              textAlign: TextAlign.end,
              style: tema.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
