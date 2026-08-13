import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase servislerinin Riverpod sağlayıcıları.
///
/// Repository'ler bu sağlayıcılardan beslenir; hiçbir yerde
/// `FirebaseFirestore.instance` doğrudan çağrılmaz. Testte bu sağlayıcılar
/// emulator'e bağlı örneklerle değiştirilir — bkz. KURALLAR.md §1.4.
///
/// Oturum ve işletme kimliği burada değil, `data/kimlik/kimlik_repository.dart`
/// içinde: ikisi de sabit hesapla açılan oturuma bağlı.

final firestoreSaglayici = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final kimlikDogrulamaSaglayici = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});
