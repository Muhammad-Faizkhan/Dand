import 'package:dandcollection/core/api/api_client.dart';
import 'package:dandcollection/core/api/auth_api.dart';
import 'package:dandcollection/core/api/token_store.dart';
import 'package:dandcollection/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots to the splash screen', (tester) async {
    final client = ApiClient(tokens: MemoryTokenStore());
    await tester.pumpWidget(DanDCollectionApp(client: client, authApi: AuthApi(client)));
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('DAN D'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
