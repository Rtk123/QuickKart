import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/payment_service.dart';
import '../services/settings_service.dart';

/// Cashfree ka hosted checkout page ek webview mein kholta hai.
/// Cashfree Flutter SDK (native) bhi use kiya ja sakta hai for a smoother
/// experience — https://docs.cashfree.com/docs/flutter — yeh webview
/// approach simplest cross-platform tareeka hai.
class PaymentWebviewScreen extends StatefulWidget {
  final String paymentSessionId;
  final String orderId;

  const PaymentWebviewScreen({
    super.key,
    required this.paymentSessionId,
    required this.orderId,
  });

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();

    // Cashfree ka drop-in checkout page seedha payment_session_id se khulta hai.
    final checkoutUrl =
        'https://payments.cashfree.com/order/#${widget.paymentSessionId}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (request) {
            // Cashfree payment complete hone par apne return_url par redirect karta hai
            // (create-order function mein return_url order-status function ka URL hai).
            if (request.url.contains('order-status') && !_resolved) {
              _resolved = true;
              _checkFinalStatus();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(checkoutUrl));
  }

  Future<void> _checkFinalStatus() async {
    try {
      final status = await PaymentService.checkStatus(widget.orderId);
      if (!mounted) return;
      Navigator.pop(context, status == 'PAID');
    } catch (_) {
      if (mounted) Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t.payment),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
