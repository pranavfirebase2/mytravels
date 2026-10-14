import 'package:flutter_test/flutter_test.dart';
import 'package:mytravels/features/auth/data/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AuthService restricts login to authorized email only', () async {
    expect(AuthService.authorizedEmail, 'mytravels@gmail.com');

    // Any other email must be rejected before network call
    final result = await authServiceInstance.login('random@gmail.com', '123456');
    expect(result, isNotNull);
    expect(result, contains('mytravels@gmail.com'));
  });
}
