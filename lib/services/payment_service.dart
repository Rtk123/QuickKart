import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';

/// Yeh service ab seedha Supabase Edge Functions ko call karta hai —
/// alag se Node.js backend host karne ki zaroorat nahi. Cashfree secret key
/// Supabase Edge Function secrets mein rehti hai (Flutter app mein kabhi nahi).
class PaymentService {
  static Uri _fn(String name) =>
      Uri.parse('${Env.supabaseUrl}/functions/v1/$name');

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Env.supabaseAnonKey}',
        'apikey': Env.supabaseAnonKey,
      };

  static Future<Map<String, dynamic>> createCashfreeOrder({
    required String orderRef,
    required double amount,
    required String name,
    required String phone,
    required String email,
  }) async {
    final res = await http.post(
      _fn('create-order'),
      headers: _headers,
      body: jsonEncode({
        'client_order_ref': orderRef,
        'amount': amount,
        'customer': {'name': name, 'phone': phone, 'email': email},
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Order create nahi ho paaya: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<String> checkStatus(String cashfreeOrderId) async {
    final res = await http.get(
      Uri.parse('${_fn('order-status')}?order_id=$cashfreeOrderId'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('Status check fail');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['order_status'] as String?) ?? 'UNKNOWN';
  }
}
