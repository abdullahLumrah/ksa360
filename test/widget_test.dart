import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ksa_guide/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('splash shows KSA Guide brand', (WidgetTester tester) async {
    await tester.pumpWidget(const KsaGuideApp());
    expect(find.text('KSA Guide'), findsWidgets);
    await tester.pump(const Duration(seconds: 3));
  });
}
