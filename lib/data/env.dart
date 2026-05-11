import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');
  static String get apiBaseUrl => _require('API_BASE_URL');

  static String _require(String key) {
    final v = dotenv.env[key];
    if (v == null || v.isEmpty) {
      throw StateError('missing env: $key');
    }
    return v;
  }
}
