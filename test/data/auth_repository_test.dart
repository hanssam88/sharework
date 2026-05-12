import 'package:flutter_test/flutter_test.dart';
import 'package:sharework_mockup/data/repositories/auth_repository.dart';

// Fake implementation of the abstract SupabaseAuthApi for testing
class _FakeAuthApi implements SupabaseAuthApi {
  bool otpSent = false;
  String? lastPhone;
  bool verifyResult = true;
  String? lastToken;
  bool signedOut = false;
  String? _token;

  void setToken(String? token) => _token = token;
  void setVerifyResult(bool result) => verifyResult = result;

  @override
  Future<void> sendOtp(String phone) async {
    lastPhone = phone;
    otpSent = true;
  }

  @override
  Future<bool> verifyOtp({required String phone, required String token}) async {
    lastToken = token;
    return verifyResult;
  }

  @override
  String? get accessToken => _token;

  @override
  Future<void> signOut() async {
    signedOut = true;
    _token = null;
  }
}

void main() {
  group('AuthRepository', () {
    late _FakeAuthApi fakeApi;
    late AuthRepository repo;

    setUp(() {
      fakeApi = _FakeAuthApi();
      repo = AuthRepository(fakeApi);
    });

    test('sendOtp delegates to api and passes phone', () async {
      await repo.sendOtp('+821012345678');

      expect(fakeApi.otpSent, isTrue);
      expect(fakeApi.lastPhone, '+821012345678');
    });

    test('verifyOtp returns true when api returns true', () async {
      fakeApi.setVerifyResult(true);

      final result =
          await repo.verifyOtp(phone: '+821012345678', token: '123456');

      expect(result, isTrue);
      expect(fakeApi.lastToken, '123456');
    });

    test('verifyOtp returns false when api returns false', () async {
      fakeApi.setVerifyResult(false);

      final result =
          await repo.verifyOtp(phone: '+821012345678', token: '000000');

      expect(result, isFalse);
    });

    test('accessToken and signOut delegate to api', () async {
      fakeApi.setToken('tok-abc');
      expect(repo.accessToken, 'tok-abc');

      await repo.signOut();
      expect(fakeApi.signedOut, isTrue);
      expect(repo.accessToken, isNull);
    });
  });
}
