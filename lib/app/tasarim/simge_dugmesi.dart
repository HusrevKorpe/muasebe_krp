import 'package:flutter/material.dart';

/// Yalnızca simge taşıyan düğme — üst çubuk eylemleri, satır sonu düğmeleri,
/// metin kutusunun içindeki temizleme çarpısı.
///
/// [ipucu] zorunlu: simge tek başına ne yaptığını söylemiyor. Uzun basınca
/// çıkan ipucu aynı zamanda ekran okuyucunun okuduğu etiket oluyor.
class SimgeDugmesi extends StatelessWidget {
  const SimgeDugmesi({
    required this.simge,
    required this.ipucu,
    required this.onBasildi,
    this.vurgulu = false,
    this.tehlikeli = false,
    super.key,
  });

  final IconData simge;

  /// Uzun basınca görünen ve ekran okuyucunun okuduğu metin.
  final String ipucu;

  /// `null` ise düğme pasiftir.
  final VoidCallback? onBasildi;

  /// Ana renkle çizilir — bir eylemin öne çıkması gerektiğinde.
  final bool vurgulu;

  /// Hata rengiyle çizilir — silme, iptal etme.
  final bool tehlikeli;

  @override
  Widget build(BuildContext context) {
    final sema = Theme.of(context).colorScheme;

    return IconButton(
      icon: Icon(simge),
      tooltip: ipucu,
      onPressed: onBasildi,
      color: tehlikeli
          ? sema.error
          : vurgulu
          ? sema.primary
          : sema.onSurfaceVariant,
    );
  }
}
