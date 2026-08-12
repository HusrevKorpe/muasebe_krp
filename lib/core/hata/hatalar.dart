/// Uygulama içi hata tipleri.
///
/// Firebase'in İngilizce hata kodları kullanıcıya gösterilmez; repository
/// katmanında bu tiplere çevrilir ve ekranda [mesaj] gösterilir.
sealed class UygulamaHatasi implements Exception {
  const UygulamaHatasi(this.mesaj);

  /// Kullanıcıya gösterilecek Türkçe mesaj.
  final String mesaj;

  @override
  String toString() => '$runtimeType: $mesaj';
}

/// Kimlik doğrulama hatası — giriş, kayıt, şifre sıfırlama.
class KimlikHatasi extends UygulamaHatasi {
  const KimlikHatasi(super.mesaj);

  /// Firebase Auth hata kodunu Türkçe mesaja çevirir.
  factory KimlikHatasi.koddan(String kod) => KimlikHatasi(switch (kod) {
        'invalid-email' => 'Geçersiz e-posta adresi.',
        'user-disabled' => 'Bu hesap devre dışı bırakılmış.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'E-posta veya şifre hatalı.',
        'email-already-in-use' => 'Bu e-posta adresi zaten kayıtlı.',
        'weak-password' => 'Şifre en az 6 karakter olmalı.',
        'too-many-requests' =>
          'Çok fazla deneme yapıldı. Bir süre sonra tekrar deneyin.',
        'network-request-failed' =>
          'İnternet bağlantısı yok. Bağlantınızı kontrol edin.',
        'operation-not-allowed' =>
          'E-posta ile giriş bu projede etkin değil.',
        _ => 'Giriş yapılamadı. Lütfen tekrar deneyin.',
      });
}

/// Veri okuma/yazma hatası.
class VeriHatasi extends UygulamaHatasi {
  const VeriHatasi(super.mesaj);

  const VeriHatasi.yazilamadi() : super('Kayıt yapılamadı. Tekrar deneyin.');

  const VeriHatasi.okunamadi() : super('Veriler yüklenemedi. Tekrar deneyin.');

  const VeriHatasi.yetkisiz()
      : super('Bu veriye erişim yetkiniz yok.');

  /// Ekstre, açılış bakiyesi için aralıktan önceki tüm işlemleri okumak
  /// zorundadır ve sayfalanamaz. Okuma sınırı aşılırsa eksik veriyle ekstre
  /// üretmek yerine kullanıcıdan aralığı daraltması istenir — yanlış bakiye
  /// göstermek, ekstre üretememekten kötüdür.
  const VeriHatasi.cokFazlaIslem()
      : super('Bu cari için çok fazla işlem var. Daha dar bir tarih aralığı '
            'seçin.');
}

/// Girdi doğrulama hatası — form alanları için.
class DogrulamaHatasi extends UygulamaHatasi {
  const DogrulamaHatasi(super.mesaj);
}
