import '../l10n/app_strings.dart';

/// DB mein har naam do columns mein rehta hai: `name` (English, default) aur
/// `name_hi` (Hindi). Settings -> Language ke hisaab se sahi wala dikhta hai;
/// Hindi missing ho to English par fallback ho jaata hai.
class Category {
  final String id;
  final String name;
  final String? nameHi;

  Category({required this.id, required this.name, this.nameHi});

  String displayName(AppLang lang) =>
      lang == AppLang.hi ? (nameHi ?? name) : name;

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      nameHi: map['name_hi'] as String?,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String? nameHi;
  final String unit;
  final String? unitHi;
  final String categoryId;
  final double price;
  final double mrp;

  /// Emoji fallback — jab `imageUrl` null ho ya photo load na ho paaye.
  final String icon;

  /// Asli product photo ka URL. Null ho sakta hai.
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    this.nameHi,
    required this.unit,
    this.unitHi,
    required this.categoryId,
    required this.price,
    required this.mrp,
    required this.icon,
    this.imageUrl,
  });

  String displayName(AppLang lang) =>
      lang == AppLang.hi ? (nameHi ?? name) : name;

  String displayUnit(AppLang lang) =>
      lang == AppLang.hi ? (unitHi ?? unit) : unit;

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      nameHi: map['name_hi'] as String?,
      unit: map['unit'] as String,
      unitHi: map['unit_hi'] as String?,
      categoryId: map['category_id'] as String,
      price: (map['price'] as num).toDouble(),
      mrp: (map['mrp'] as num).toDouble(),
      icon: (map['icon'] as String?) ?? '📦',
      imageUrl: (map['image_url'] as String?)?.trim().isEmpty ?? true
          ? null
          : (map['image_url'] as String).trim(),
    );
  }
}
