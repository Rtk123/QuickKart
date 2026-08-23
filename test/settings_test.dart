import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickkart/l10n/app_strings.dart';
import 'package:quickkart/models/product.dart';
import 'package:quickkart/services/settings_service.dart';

/// Settings (theme/notifications/language) aur language fallback ke tests.
/// Yeh sab pure Dart hai — Supabase initialize karne ki zaroorat nahi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppStrings', () {
    test('English default hai', () {
      const t = AppStrings(AppLang.en);
      expect(t.login, 'Log in');
      expect(t.settings, 'Settings');
      expect(t.totalPayable, 'Total payable');
    });

    test('Hindi select karne par Hindi text aata hai', () {
      const en = AppStrings(AppLang.en);
      const hi = AppStrings(AppLang.hi);
      expect(hi.login, isNot(en.login));
      expect(hi.settings, isNot(en.settings));
    });

    test('product count thousands separator ke saath dikhta hai', () {
      const t = AppStrings(AppLang.en);
      expect(t.productsAvailable(30020), '30,020 products available');
      expect(t.productsAvailable(5004), '5,004 products available');
      expect(t.productsAvailable(201), '201 products available');
      expect(t.productsAvailable(0), '0 products available');
      expect(t.productsAvailable(1000000), '1,000,000 products available');
    });

    test('unknown language code English par fallback karta hai', () {
      expect(AppLang.fromCode(null), AppLang.en);
      expect(AppLang.fromCode('fr'), AppLang.en);
      expect(AppLang.fromCode('hi'), AppLang.hi);
    });
  });

  group('SettingsService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults: system theme, notifications on, English', () async {
      final settings = await SettingsService.load();
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.notificationsEnabled, isTrue);
      expect(settings.language, AppLang.en);
    });

    test('teeno preferences save aur reload hoti hain', () async {
      final settings = await SettingsService.load();
      await settings.setThemeMode(ThemeMode.dark);
      await settings.setLanguage(AppLang.hi);
      await settings.setNotificationsEnabled(false);

      final reloaded = await SettingsService.load();
      expect(reloaded.themeMode, ThemeMode.dark);
      expect(reloaded.language, AppLang.hi);
      expect(reloaded.notificationsEnabled, isFalse);
    });

    test('same value dobara set karne par listener call nahi hota', () async {
      final settings = await SettingsService.load();
      var notifications = 0;
      settings.addListener(() => notifications++);

      await settings.setThemeMode(ThemeMode.dark);
      await settings.setThemeMode(ThemeMode.dark);

      expect(notifications, 1);
    });

    test('language badalne par strings turant switch ho jaati hain', () async {
      final settings = await SettingsService.load();
      expect(settings.t.login, 'Log in');
      await settings.setLanguage(AppLang.hi);
      expect(settings.t.login, isNot('Log in'));
    });
  });

  group('Product/Category language fallback', () {
    Product bread({String? nameHi, String? unitHi}) => Product(
          id: '1',
          name: 'Bread',
          nameHi: nameHi,
          unit: '400 g',
          unitHi: unitHi,
          categoryId: 'grocery',
          price: 35,
          mrp: 40,
          icon: '🍞',
        );

    test('Hindi missing ho to English dikhta hai', () {
      final p = bread();
      expect(p.displayName(AppLang.hi), 'Bread');
      expect(p.displayUnit(AppLang.hi), '400 g');
    });

    test('Hindi maujood ho to Hindi dikhta hai', () {
      final p = bread(nameHi: 'ब्रेड', unitHi: '400 ग्राम');
      expect(p.displayName(AppLang.hi), 'ब्रेड');
      expect(p.displayUnit(AppLang.hi), '400 ग्राम');
      expect(p.displayName(AppLang.en), 'Bread');
      expect(p.displayUnit(AppLang.en), '400 g');
    });

    test('image_url null/khaali ho to imageUrl null hota hai (emoji fallback)',
        () {
      final noImage = Product.fromMap({
        'id': '1',
        'name': 'Face Wash',
        'unit': '100 g',
        'category_id': 'beauty',
        'price': 159,
        'mrp': 220,
        'icon': '🧴',
        'image_url': null,
      });
      expect(noImage.imageUrl, isNull);
      expect(noImage.icon, '🧴');

      final blank = Product.fromMap({
        'id': '2',
        'name': 'Bread',
        'unit': '400 g',
        'category_id': 'grocery',
        'price': 35,
        'mrp': 40,
        'icon': '🍞',
        'image_url': '   ',
      });
      expect(blank.imageUrl, isNull, reason: 'whitespace URL bhi null hona chahiye');
    });

    test('image_url hone par trim hokar aata hai', () {
      final p = Product.fromMap({
        'id': '3',
        'name': 'Tomato',
        'unit': '1 kg',
        'category_id': 'grocery',
        'price': 38,
        'mrp': 45,
        'icon': '🍅',
        'image_url': '  https://example.com/tomato.jpg  ',
      });
      expect(p.imageUrl, 'https://example.com/tomato.jpg');
    });

    test('Category bhi wahi fallback follow karti hai', () {
      final c = Category(id: 'grocery', name: 'Grocery');
      expect(c.displayName(AppLang.hi), 'Grocery');
      expect(
        Category(id: 'grocery', name: 'Grocery', nameHi: 'ग्रोसरी')
            .displayName(AppLang.hi),
        'ग्रोसरी',
      );
    });
  });
}
