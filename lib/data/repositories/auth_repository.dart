import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract interface over Supabase auth operations.
/// Allows injection of a fake in tests without touching Flutter platform channels.
abstract interface class SupabaseAuthApi {
  Future<void> sendOtp(String phone);
  Future<bool> verifyOtp({required String phone, required String token});
  String? get accessToken;
  Future<void> signOut();
}

class _RealSupabaseAuthApi implements SupabaseAuthApi {
  @override
  Future<void> sendOtp(String phone) async {
    await Supabase.instance.client.auth.signInWithOtp(phone: phone);
  }

  @override
  Future<bool> verifyOtp({required String phone, required String token}) async {
    final res = await Supabase.instance.client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
    return res.session != null;
  }

  @override
  String? get accessToken =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  @override
  Future<void> signOut() => Supabase.instance.client.auth.signOut();
}

class AuthRepository {
  final SupabaseAuthApi _api;

  AuthRepository([SupabaseAuthApi? api]) : _api = api ?? _RealSupabaseAuthApi();

  Future<void> sendOtp(String phone) => _api.sendOtp(phone);

  Future<bool> verifyOtp({required String phone, required String token}) =>
      _api.verifyOtp(phone: phone, token: token);

  String? get accessToken => _api.accessToken;

  Future<void> signOut() => _api.signOut();
}
