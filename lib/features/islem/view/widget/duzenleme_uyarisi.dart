import 'package:flutter/material.dart';

import '../../../../app/tasarim/olculer.dart';
import '../../../../core/metin/metinler.dart';

/// Kayıtlı bir işlem düzenlenirken formun başında duran not.
///
/// Değişiklik bakiyeye anında yansıyor ve müşteriye daha önce gönderilmiş PDF
/// ekstre bu kaydı eski hâliyle gösteriyor olabilir. Kullanıcı düzeltmeyi
/// yaparken bunu bilmeli — uyarı engellemez, hatırlatır.
///
/// Rengi kiremit (`tertiary`), kırmızı değil: bu bir hata değil, dikkat
/// çekilmesi gereken bir bilgi. Hata rengi kullanılırsa kullanıcı düzeltmekten
/// vazgeçiyor.
class DuzenlemeUyarisi extends StatelessWidget {
  const DuzenlemeUyarisi({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Olculer.bosluk16),
      decoration: BoxDecoration(
        color: tema.colorScheme.tertiaryContainer,
        borderRadius: Olculer.koseOrta,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 20,
            color: tema.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: Olculer.bosluk12),
          Expanded(
            child: Text(
              Metinler.islemDuzenlemeUyarisi,
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
