import 'dart:io';

import 'package:fidancari/domain/ekstre/ekstre_araligi.dart';
import 'package:fidancari/domain/ekstre/ekstre_olusturucu.dart';
import 'package:fidancari/features/ekstre/view/pdf/ekstre_belgesi.dart';
import 'package:fidancari/features/ekstre/view/pdf/ekstre_fontlari.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../ornek/ornek_isletme.dart';
import '../../ornek/referans_ekstre.dart';

/// Referans işlemlerden örnek PDF üretip diske yazar — göze bakmak için.
///
/// Hedef dosya `ORNEK_PDF` ortam değişkeniyle verilir; verilmezse test atlanır
/// ve normal koşuyu yavaşlatmaz:
///
/// ```bash
/// ORNEK_PDF=/tmp/ekstre.pdf flutter test test/features/ekstre/ornek_pdf_uret_test.dart
/// ```
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final hedef = Platform.environment['ORNEK_PDF'];

  test('örnek ekstre PDF üret', skip: hedef == null, () async {
    final baytlar = await EkstreBelgesi.uret(
      ekstre: EkstreOlusturucu.olustur(
        isletme: ornekIsletme,
        cari: ornekCari,
        aralik: const EkstreAraligi.tumu(),
        islemler: referansIslemleri,
        hazirlanmaTarihi: DateTime(2025, 5, 24),
      ),
      fontlar: await EkstreFontlari.yukle(),
    );

    await File(hedef!).writeAsBytes(baytlar);
    expect(File(hedef).existsSync(), isTrue);
  });
}
