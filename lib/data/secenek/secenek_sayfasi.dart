import 'secenek_kaydi.dart';

/// Tür, çeşit ya da anaç listesinin tek bir sayfası.
///
/// Liste küçük kalması beklenen bir listedir ama yine de sayfalanır: sayının
/// küçük kalacağı bir varsayımdır, Firestore okuması ise ücrettir
/// (KURALLAR.md §4.3).
class SecenekSayfasi {
  const SecenekSayfasi({required this.kayitlar, required this.dahaVar});

  static const SecenekSayfasi bos = SecenekSayfasi(
    kayitlar: <SecenekKaydi>[],
    dahaVar: false,
  );

  final List<SecenekKaydi> kayitlar;

  /// Okunacak kayıt kaldı mı. Sorgunun sınırı kadar kayıt geldiyse devamı
  /// olduğu varsayılır.
  final bool dahaVar;
}
