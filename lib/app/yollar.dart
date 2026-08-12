/// Uygulama gezinme yolları. Metin sabitleri tek yerde tutulur.
abstract final class Yollar {
  static const String acilis = '/acilis';
  static const String giris = '/giris';
  static const String kayit = '/kayit';
  static const String ana = '/';

  /// Kimlik doğrulaması gerektirmeyen yollar.
  static const Set<String> kimliksizYollar = {acilis, giris, kayit};
}
