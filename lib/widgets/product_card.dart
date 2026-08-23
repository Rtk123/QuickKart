import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'product_image.dart';

/// Blinkit-style product card: image tile with a delivery-time pill,
/// name, unit, price + struck MRP, aur green ADD button jo tap karne par
/// quantity stepper ban jaata hai.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.deliveryMinutes = 12});

  final Product product;
  final int deliveryMinutes;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final lang = context.settings.language;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).palette;
    final qty = cart.qtyOf(product.id);
    final discount = product.mrp > product.price
        ? (((product.mrp - product.price) / product.mrp) * 100).round()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ProductImage(product: product, size: 92),
              if (discount > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.brand,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '$discount% OFF',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.bolt, size: 11, color: palette.badgeBg),
              Text(
                '$deliveryMinutes MINS',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: palette.badgeBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            product.displayName(lang),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            product.displayUnit(lang),
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700)),
                    if (discount > 0)
                      Text(
                        '₹${product.mrp.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: scheme.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: 70,
                height: 30,
                child: qty == 0
                    ? OutlinedButton(
                        onPressed: () => cart.add(product),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.addGreen,
                          side: BorderSide(color: palette.addGreen),
                          backgroundColor: palette.addGreen.withValues(alpha: 0.08),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7)),
                        ),
                        child: const Text('ADD',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 12.5)),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: palette.addGreen,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StepButton(
                                icon: Icons.remove,
                                onTap: () => cart.decrement(product)),
                            Text('$qty',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13)),
                            _StepButton(
                                icon: Icons.add, onTap: () => cart.add(product)),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 22,
        height: 30,
        child: Icon(icon, color: Colors.white, size: 15),
      ),
    );
  }
}
