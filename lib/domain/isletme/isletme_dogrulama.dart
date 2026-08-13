import '../cari/cari_dogrulama.dart';
import 'iban.dart';

/// İşletme profili ve banka hesabı doğrulamaları.
///
/// Profil alanlarının **hiçbiri zorunlu değil**: bilgiler yalnızca ekstre
/// başlığına basılıyor ve boş bırakılırsa başlık sade çıkar. Kullanıcıyı
/// uygulamayı kullanmadan önce form doldurmaya zorlamıyoruz — telefon yalnızca
/// yazıldıysa biçim açısından yoklanır.
///
/// Banka hesabı ayrı: bir hesap eklemek isteğe bağlı, ama eklenen hesabın
/// bankası ve IBAN'ı dolu olmalı — yarım IBAN müşteriye giden belgede
/// eksik bilgiden kötüdür.
abstract final class IsletmeDogrulama {
  static String? telefon(String? deger) => CariDogrulama.telefon(deger);

  static String? bankaAdi(String? deger) {
    final metin = (deger ?? '').trim();
    if (metin.isEmpty) return 'Banka adı gerekli.';
    return null;
  }

  static String? iban(String? deger) {
    final metin = (deger ?? '').trim();
    if (metin.isEmpty) return 'IBAN gerekli.';
    if (!Iban.gecerliMi(metin)) {
      return 'IBAN geçersiz. TR ile başlayan 26 hane girin.';
    }
    return null;
  }
}
