import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final settings = context.settings;
    final t = settings.t;
    final scheme = Theme.of(context).colorScheme;
    final products = cart.cartProducts;

    return Scaffold(
      appBar: AppBar(title: Text(t.yourCart)),
      body: products.isEmpty
          ? Center(child: Text(t.cartEmpty))
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: products.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = products[i];
                final qty = cart.qtyOf(p.id);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 46,
                        child: ProductImage(
                            product: p, size: 46, emojiSize: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.displayName(settings.language),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13.5)),
                            Text(
                              '₹${p.price.toStringAsFixed(0)} × $qty = ₹${(p.price * qty).toStringAsFixed(0)}',
                              style: TextStyle(
                                  fontSize: 12, color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                            color: AppTheme.brand,
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => cart.decrement(p),
                              icon: const Icon(Icons.remove, color: Colors.white, size: 16),
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                              padding: EdgeInsets.zero,
                            ),
                            Text('$qty',
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold)),
                            IconButton(
                              onPressed: () => cart.add(p),
                              icon: const Icon(Icons.add, color: Colors.white, size: 16),
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: products.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _billRow(t.itemTotal, '₹${cart.itemTotal.toStringAsFixed(0)}'),
                    _billRow(
                        t.deliveryFee,
                        cart.deliveryFee == 0
                            ? t.free
                            : '₹${cart.deliveryFee.toStringAsFixed(0)}'),
                    const Divider(),
                    _billRow(t.totalPayable, '₹${cart.grandTotal.toStringAsFixed(0)}',
                        bold: true),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                        ),
                        child: Text(t.checkout),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _billRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: bold ? 15 : 13.5,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 15 : 13.5,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
