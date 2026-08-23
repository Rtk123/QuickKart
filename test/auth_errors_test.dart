import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:quickkart/l10n/app_strings.dart';
import 'package:quickkart/services/auth_service.dart';

/// `AuthService.describeError` ka kaam yeh hai ki Supabase ki raw exception
/// kabhi bhi user ko na dikhe — jaise
/// `AuthApiException(message: Email not confirmed, statusCode: 400, ...)`.
void main() {
  const t = AppStrings(AppLang.en);

  test('email_not_confirmed -> saaf message, raw dump nahi', () {
    const err = AuthApiException('Email not confirmed',
        statusCode: '400', code: 'email_not_confirmed');
    final msg = AuthService.describeError(err, t);

    expect(msg, t.errEmailNotConfirmed);
    expect(msg, isNot(contains('AuthApiException')));
    expect(msg, isNot(contains('statusCode')));
  });

  test('galat password -> friendly message', () {
    const err = AuthApiException('Invalid login credentials',
        statusCode: '400', code: 'invalid_credentials');
    expect(AuthService.describeError(err, t), t.errInvalidCredentials);
  });

  test('duplicate signup -> login karne ko kehta hai', () {
    const err = AuthApiException('User already registered',
        statusCode: '422', code: 'user_already_exists');
    expect(AuthService.describeError(err, t), t.errEmailExists);
  });

  test('rate limit -> wait karne ko kehta hai', () {
    const err = AuthApiException('Email rate limit exceeded',
        statusCode: '429', code: 'over_email_send_rate_limit');
    expect(AuthService.describeError(err, t), t.errTooManyRequests);
  });

  test('anjaan auth code -> Supabase ka plain message, poora dump nahi', () {
    const err = AuthApiException('Something specific went wrong',
        statusCode: '400', code: 'some_future_code');
    final msg = AuthService.describeError(err, t);

    expect(msg, 'Something specific went wrong');
    expect(msg, isNot(contains('AuthApiException')));
  });

  test('network error -> connection wala message', () {
    expect(
      AuthService.describeError(
          Exception('ClientException: Failed host lookup'), t),
      t.errNetwork,
    );
  });

  test('plain Exception se "Exception:" prefix hat jaata hai', () {
    expect(
      AuthService.describeError(Exception('You need to be logged in'), t),
      'You need to be logged in',
    );
  });

  test('Hindi mein bhi translated message aata hai', () {
    const hi = AppStrings(AppLang.hi);
    const err = AuthApiException('Email not confirmed',
        statusCode: '400', code: 'email_not_confirmed');
    final msg = AuthService.describeError(err, hi);

    expect(msg, hi.errEmailNotConfirmed);
    expect(msg, isNot(t.errEmailNotConfirmed));
  });
}
