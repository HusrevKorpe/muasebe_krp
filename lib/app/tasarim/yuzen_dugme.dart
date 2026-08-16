import 'package:flutter/material.dart';

/// Liste ekranlarının sağ alt köşesindeki "ekle" düğmesi.
///
/// [kimlik] zorunlu tutuluyor. Alt sekmeler `IndexedStack` ile aynı anda
/// ağaçta duruyor; iki sekmenin yüzen düğmesi varsayılan hero etiketini
/// paylaşırsa Flutter *"multiple heroes share the same tag"* diye patlıyor.
/// Etiketi burada isteğe bağlı bırakmak, hatayı üçüncü liste ekranı eklenene
/// kadar saklamak olurdu.
class YuzenDugme extends StatelessWidget {
  const YuzenDugme({
    required this.kimlik,
    required this.metin,
    required this.simge,
    required this.onBasildi,
    super.key,
  });

  /// Hero etiketi — her ekranda benzersiz olmalı.
  final String kimlik;

  final String metin;
  final IconData simge;
  final VoidCallback onBasildi;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: kimlik,
      onPressed: onBasildi,
      icon: Icon(simge),
      label: Text(metin),
    );
  }
}
