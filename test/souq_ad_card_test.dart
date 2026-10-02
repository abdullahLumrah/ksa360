import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ksa_guide/features/souq/domain/souq_models.dart';
import 'package:ksa_guide/features/souq/presentation/souq_format.dart';
import 'package:ksa_guide/features/souq/presentation/widgets/souq_ad_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('ad card shows title and best offer', (tester) async {
    final ad = Ad(
      id: 'user-1',
      source: AdSource.user,
      categoryId: 'cars',
      title: 'Toyota Camry 2020',
      description: 'Clean owner car',
      city: 'Riyadh',
      isNegotiable: true,
      seller: SellerInfo(
        id: 'me',
        name: 'You',
        memberSince: DateTime(2024),
      ),
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 360,
            child: SouqAdCard(ad: ad),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Toyota Camry 2020'), findsWidgets);
    expect(find.text(SouqFormat.sar(null)), findsOneWidget);
  });
}
