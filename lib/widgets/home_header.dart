import 'package:flutter/material.dart';

import '../screens/location_sheet.dart';
import '../screens/settings_screen.dart';
import '../services/location_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

/// Blinkit-style sticky header:
///
/// ```
/// ⚡ QuickKart                              ⚙
/// Delivery in 12 minutes
/// 📍 Sector 12, Noida  ▾
/// [ 🔍 Search groceries, electronics… ]
/// ```
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onSearchChanged,
    this.totalProducts,
  });

  final ValueChanged<String> onSearchChanged;

  /// Catalog mein kitne products match kar rahe hain (search/category ke baad).
  final int? totalProducts;

  static const deliveryMinutes = 12;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final palette = Theme.of(context).palette;
    final location = context.location;
    final current = location.current;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 12),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800),
                    children: [
                      // Gradient ke upar orange brand color padhna mushkil hai,
                      // isliye logo yahan white + warm yellow mein hai.
                      TextSpan(
                          text: 'Quick',
                          style: TextStyle(color: palette.headerFg)),
                      const TextSpan(
                          text: 'Kart',
                          style: TextStyle(color: Color(0xFFFFD166))),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.settings_outlined,
                      size: 21, color: palette.headerFg),
                  tooltip: t.settings,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              t.deliveryInMinutes(deliveryMinutes),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: palette.headerFg,
              ),
            ),
            const SizedBox(height: 2),
            // Location row — tap karke bottom sheet khulti hai.
            InkWell(
              onTap: () => showLocationSheet(context),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 15, color: palette.headerMuted),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        current == null ? t.selectLocation : current.shortLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              current == null ? FontWeight.w600 : FontWeight.w500,
                          color: palette.headerMuted,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down,
                        size: 18, color: palette.headerMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: t.searchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: onSearchChanged,
            ),
            if (totalProducts != null) ...[
              const SizedBox(height: 6),
              Text(
                t.productsAvailable(totalProducts!),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: palette.headerMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
