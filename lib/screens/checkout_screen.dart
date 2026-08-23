import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../services/location_service.dart';
import '../services/settings_service.dart';
import '../services/supabase_service.dart';
import '../services/payment_service.dart';
import 'payment_webview_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  bool _placing = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    // Header mein chuni hui delivery location se address prefill kar dete hain —
    // user chahe to yahan edit kar sakta hai.
    final selected = context.read<LocationService>().current;
    if (selected != null && selected.fullLine.isNotEmpty) {
      _addrCtrl.text = selected.fullLine;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final t = context.t;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.deliveryDetails)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _field(_nameCtrl, t.fullName, t.nameHint, TextInputType.name,
                  (v) => (v == null || v.trim().length < 2) ? t.enterName : null),
              const SizedBox(height: 12),
              _field(_phoneCtrl, t.phone, t.phoneHint, TextInputType.phone,
                  (v) => (v == null || !RegExp(r'^[6-9]\d{9}$').hasMatch(v))
                      ? t.invalidPhone
                      : null,
                  maxLength: 10),
              const SizedBox(height: 12),
              _field(_emailCtrl, t.email, t.emailHint, TextInputType.emailAddress,
                  (v) => (v == null ||
                          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v))
                      ? t.invalidEmail
                      : null),
              const SizedBox(height: 12),
              _field(_addrCtrl, t.deliveryAddress, t.addressHint,
                  TextInputType.streetAddress,
                  (v) => (v == null || v.trim().length < 8) ? t.invalidAddress : null,
                  maxLines: 2),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t.totalPayable),
                    Text('₹${cart.grandTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              if (_errorMsg != null) ...[
                const SizedBox(height: 12),
                Text(_errorMsg!,
                    style: TextStyle(color: scheme.error, fontSize: 12.5)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _placing ? null : () => _submit(cart),
                  child: _placing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(t.payWithCashfree),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, TextInputType type,
      String? Function(String?) validator, {int? maxLength, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLength: maxLength,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
      ),
      validator: validator,
    );
  }

  Future<void> _submit(CartService cart) async {
    if (!_formKey.currentState!.validate()) return;

    final settings = context.read<SettingsService>();
    final t = settings.t;

    setState(() { _placing = true; _errorMsg = null; });

    final orderRef = 'QK${DateTime.now().millisecondsSinceEpoch}';

    try {
      // 1. Supabase mein order 'pending' status ke saath save karo
      await SupabaseService.createPendingOrder(
        orderRef: orderRef,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        address: _addrCtrl.text.trim(),
        itemTotal: cart.itemTotal,
        deliveryFee: cart.deliveryFee,
        totalAmount: cart.grandTotal,
        cartQuantities: cart.quantities,
        products: cart.cartProducts,
      );

      // 2. Supabase Edge Function se Cashfree payment session banwao
      final result = await PaymentService.createCashfreeOrder(
        orderRef: orderRef,
        amount: cart.grandTotal,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );

      final paymentSessionId = result['payment_session_id'] as String;
      final cfOrderId = result['order_id'] as String;

      if (!mounted) return;

      // 3. Cashfree ka hosted payment page webview mein kholo
      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebviewScreen(
            paymentSessionId: paymentSessionId,
            orderId: cfOrderId,
          ),
        ),
      );

      if (success == true) {
        cart.clear();
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
          // Settings -> Notifications -> Order updates band ho to alert nahi dikhta.
          if (settings.notificationsEnabled && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.paymentSuccess)),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _errorMsg = t.checkoutFailed(e));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }
}
