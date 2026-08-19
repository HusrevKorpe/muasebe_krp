import 'package:flutter/material.dart';

import '../../../../app/tasarim/olculer.dart';
import '../../../../domain/islem/islem_tipi.dart';
import 'islem_tipi_gorunumu.dart';

/// Kişi sayfasının altındaki dört giriş düğmesi.
///
/// Önceden tek bir "İşlem ekle" düğmesi vardı ve tip bir alt sayfada
/// seçiliyordu. Dört tip doğrudan burada duruyor: kullanıcı ne yaptığını zaten
/// biliyor, araya bir seçim ekranı koymak fazladan dokunuş.
///
/// Dört tip birlikte sunulur: bir cari hem müşteri hem tedarikçi olabilir, bu
/// yüzden aynı kişiye hem satış hem alış girilebilmeli (bkz. KURALLAR.md §3.4).
///
/// Liste `IslemTipi.values` değil [IslemTipi.girisTipleri]: hesap görme kaydı
/// da bir işlem tipidir ama tutarını kullanıcı girmez, kişi sayfasının menüsünden
/// bakiyeye bakılarak kaydedilir.
///
/// Simgeler renkli bir karenin içinde: dört düğme yan yana dururken yalnızca
/// renkli simge ve yazıdan oluşan hâlleri, dokunulabilir olduklarını
/// söylemiyordu — çubuk bir açıklama satırı gibi okunuyordu.
class IslemDugmeleri extends StatelessWidget {
  const IslemDugmeleri({required this.onSecildi, super.key});

  final ValueChanged<IslemTipi> onSecildi;

  @override
  Widget build(BuildContext context) {
    final sema = Theme.of(context).colorScheme;

    // `Material`, `DecoratedBox` değil: dokunma dalgası en yakın `Material`'ın
    // üstüne çiziliyor. Zemin bir kutuyla boyansaydı dalga onun *altında*
    // kalırdı ve düğmeler dokunmaya cevap vermiyor gibi görünürdü.
    return Material(
      color: sema.surfaceContainerLowest,
      shape: Border(top: BorderSide(color: sema.outlineVariant)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Olculer.bosluk8,
            Olculer.bosluk12,
            Olculer.bosluk8,
            Olculer.bosluk8,
          ),
          child: Row(
            children: <Widget>[
              for (final tip in IslemTipi.girisTipleri)
                Expanded(child: _Dugme(tip: tip, onBasildi: onSecildi)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dugme extends StatelessWidget {
  const _Dugme({required this.tip, required this.onBasildi});

  static const double _kareBoyu = 42;

  final IslemTipi tip;
  final ValueChanged<IslemTipi> onBasildi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final renk = tip.renk(tema.brightness);

    return InkWell(
      onTap: () => onBasildi(tip),
      borderRadius: Olculer.koseOrta,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Olculer.bosluk8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: _kareBoyu,
              height: _kareBoyu,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tip.zemin(tema.brightness),
                borderRadius: Olculer.koseOrta,
              ),
              child: Icon(tip.simge, size: 21, color: renk),
            ),
            const SizedBox(height: Olculer.bosluk8),
            Text(
              tip.ad,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: tema.textTheme.labelMedium?.copyWith(
                color: tema.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
