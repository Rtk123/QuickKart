import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App ke saare environment values ek hi jagah se aate hain.
/// `.env` file `main()` mein `Env.load()` se load hoti hai, uske baad
/// kahin se bhi `Env.supabaseUrl` / `Env.supabaseAnonKey` use kar sakte hain.
class Env {
  const Env._();

  /// `.env` ko app assets se padhta hai (pubspec.yaml ke assets mein listed hai).
  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get supabaseUrl => _read('SUPABASE_URL');

  static String get supabaseAnonKey => _read('SUPABASE_ANON_KEY');

  static String _read(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError(
        '$key .env file mein nahi mila. '
        '.env.example ko copy karke .env banayein aur values bharein.',
      );
    }
    return value;
  }
}
