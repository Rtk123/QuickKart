import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_strings.dart';

enum UserRole { customer, admin, deliveryPartner }

class AppUser {
  final String id;
  final String email;
  final String? fullName;
  final UserRole role;

  AppUser({required this.id, required this.email, this.fullName, required this.role});

  factory AppUser.fromProfile(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String?,
      role: _roleFromString(map['role'] as String? ?? 'customer'),
    );
  }

  static UserRole _roleFromString(String r) {
    switch (r) {
      case 'admin':
        return UserRole.admin;
      case 'delivery_partner':
        return UserRole.deliveryPartner;
      default:
        return UserRole.customer;
    }
  }
}

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  /// Auth state changes (login/logout) ko sunne ke liye — UI isse listen karke
  /// automatically login/home screen ke beech switch kar sakti hai.
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Naya account banata hai.
  ///
  /// Return value batati hai ki user turant logged-in ho gaya ya nahi:
  /// * `true`  — session mil gaya (project mein email confirmation off hai),
  ///             AuthGate khud Home par le jaayega.
  /// * `false` — Supabase ne confirmation email bheji hai; user ko pehle
  ///             apna email confirm karna hoga tabhi login chalega.
  static Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'role': 'customer'},
    );
    if (res.user == null) {
      throw Exception('Sign-up failed, please try again');
    }
    return res.session != null;
  }

  static Future<void> signIn({required String email, required String password}) async {
    final res = await _client.auth.signInWithPassword(email: email, password: password);
    if (res.user == null) {
      throw Exception('Email or password is incorrect');
    }
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Supabase ki raw exception ko user ke padhne laayak message mein badalta hai.
  ///
  /// Iske bina login screen par seedha
  /// `AuthApiException(message: Email not confirmed, statusCode: 400, ...)`
  /// jaisa text dikh jaata hai.
  static String describeError(Object error, AppStrings t) {
    // Network error — dart:io ka SocketException yahan use nahi kar sakte,
    // kyunki app web par bhi chalti hai (wahan dart:io available nahi hota).
    if (error is AuthRetryableFetchException) return t.errNetwork;

    if (error is AuthApiException) {
      switch (error.code) {
        case 'email_not_confirmed':
          return t.errEmailNotConfirmed;
        case 'invalid_credentials':
        case 'invalid_grant':
          return t.errInvalidCredentials;
        case 'user_already_exists':
        case 'email_exists':
          return t.errEmailExists;
        case 'weak_password':
          return t.errWeakPassword;
        case 'over_request_rate_limit':
        case 'over_email_send_rate_limit':
          return t.errTooManyRequests;
      }
      // Koi anjaan code ho to bhi Supabase ka `message` padhne laayak hota hai
      // ("Email not confirmed"), poora exception dump nahi.
      return error.message;
    }
    if (error is AuthException) return error.message;

    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('ClientException') ||
        text.contains('Failed host lookup')) {
      return t.errNetwork;
    }
    if (error is Exception) return text.replaceFirst('Exception: ', '');
    return t.errGeneric;
  }

  /// Logged-in user ki profile (naam + role) Supabase se fetch karta hai.
  static Future<AppUser?> fetchCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final data = await _client.from('profiles').select().eq('id', user.id).single();
    return AppUser.fromProfile(data);
  }
}
