import 'package:flutter/material.dart';

import '../models/product.dart';

/// Product ki asli photo dikhata hai, teen safe fallbacks ke saath:
///
/// * `imageUrl` null ho          -> emoji
/// * photo load ho rahi ho       -> halka shimmer-jaisa placeholder
/// * photo load fail ho jaaye    -> emoji (network off, 404, CORS block, etc.)
///
/// Isliye card kabhi khaali ya toota hua nahi dikhta.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.product,
    required this.size,
    this.emojiSize,
    this.borderRadius = 8,
  });

  final Product product;

  /// Image tile ki height (width hamesha full available hoti hai).
  final double size;
  final double? emojiSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = product.imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: size,
        width: double.infinity,
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: url == null
            ? _emoji()
            : Image.network(
                url,
                fit: BoxFit.contain,
                // Wikimedia thumbnails 500px ke hain; cacheWidth se decode
                // sasta ho jaata hai aur scrolling smooth rehti hai.
                cacheWidth: 400,
                filterQuality: FilterQuality.medium,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.outlineVariant,
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stack) => _emoji(),
              ),
      ),
    );
  }

  Widget _emoji() => Text(
        product.icon,
        style: TextStyle(fontSize: emojiSize ?? size * 0.42),
      );
}
