import 'package:flutter/material.dart';

import '../../core/metin/metinler.dart';
import 'olculer.dart';
import 'renkler.dart';

/// Uygulamanın açılış ve giriş ekranlarındaki işareti: yaprak simgesi, altında
/// ad ve tanım.
///
/// Simge çıplak bir ikon değil, koyu yeşilden açığa dönen yuvarlatılmış bir
/// karenin içinde. Uygulama ikonu da bu biçimde; açılışta gördüğü şekil,
/// kullanıcının ana ekranda dokunduğu şekille aynı olmalı.
class UygulamaIsareti extends StatelessWidget {
  const UygulamaIsareti({this.aciklamaVar = true, super.key});

  static const double _kareBoyu = 84;

  /// Adın altındaki tanım satırı çizilsin mi.
  final bool aciklamaVar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: _kareBoyu,
          height: _kareBoyu,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: Olculer.koseBuyuk,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Renkler.zeytinAcik, Renkler.zeytinKoyu],
            ),
          ),
          child: const Icon(Icons.park, size: 44, color: Renkler.kagit),
        ),
        const SizedBox(height: Olculer.bosluk20),
        Text(
          Metinler.uygulamaAdi,
          textAlign: TextAlign.center,
          style: tema.textTheme.headlineSmall,
        ),
        if (aciklamaVar) ...<Widget>[
          const SizedBox(height: Olculer.bosluk8),
          Text(
            Metinler.uygulamaTanimi,
            textAlign: TextAlign.center,
            style: tema.textTheme.bodyMedium?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
