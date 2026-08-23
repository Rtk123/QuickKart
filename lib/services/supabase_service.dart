import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

/// Ek page ke products + poore result ka total count.
class ProductPage {
  const ProductPage({
    required this.items,
    required this.total,
    required this.page,
  });

  final List<Product> items;

  /// Filter/search ke hisaab se kul kitne products match karte hain.
  final int total;
  final int page;

  bool get isEmpty => items.isEmpty;
}

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<List<Category>> fetchCategories() async {
    final data = await _client
        .from('categories')
        .select()
        .order('sort_order', ascending: true);
    return (data as List).map((e) => Category.fromMap(e)).toList();
  }

  /// Catalog mein 30,000+ products hain, isliye kabhi bhi sab ek saath fetch
  /// nahi karte — hamesha ek page (default 30) aata hai. Total count bhi
  /// wapas milta hai taaki UI "30,020 products" dikha sake.
  static const int pageSize = 30;

  static Future<ProductPage> fetchProducts({
    String? categoryId,
    String? search,
    int page = 0,
    int limit = pageSize,
  }) async {
    var query = _client.from('products').select().eq('is_active', true);

    if (categoryId != null && categoryId != 'all') {
      query = query.eq('category_id', categoryId);
    }
    if (search != null && search.trim().isNotEmpty) {
      // `search_text` ek generated column hai (name + name_hi) jiske upar
      // trigram index laga hai — isliye English aur Hindi dono naamon mein
      // search chalta hai, aur 30k rows par bhi tez rehta hai.
      query = query.ilike('search_text', '%${search.trim()}%');
    }

    final from = page * limit;
    final res = await query
        .order('name', ascending: true)
        .range(from, from + limit - 1)
        .count(CountOption.exact);

    final items =
        (res.data as List).map((e) => Product.fromMap(e)).toList();
    return ProductPage(items: items, total: res.count, page: page);
  }

  // ---------------- Location cascade: State -> District -> Pincode ----------------
  // Data `pincodes` table mein hai (GeoNames ka Indian postal dataset).
  // `pincode_states` aur `pincode_districts` distinct-value views hain, isliye
  // dropdown ke liye 20k rows client tak kabhi nahi aate.

  static Future<List<String>> fetchStates() async {
    final data = await _client
        .from('pincode_states')
        .select('state')
        .order('state', ascending: true);
    return (data as List).map((e) => e['state'] as String).toList();
  }

  static Future<List<String>> fetchDistricts(String state) async {
    final data = await _client
        .from('pincode_districts')
        .select('district')
        .eq('state', state)
        .order('district', ascending: true);
    return (data as List).map((e) => e['district'] as String).toList();
  }

  static Future<List<String>> fetchPincodes(String state, String district) async {
    final data = await _client
        .from('pincodes')
        .select('pincode')
        .eq('state', state)
        .eq('district', district)
        .order('pincode', ascending: true);
    return (data as List).map((e) => e['pincode'] as String).toList();
  }

  /// Order ko 'pending' status ke saath Supabase mein likh deta hai.
  /// Payment confirm hone par backend (Cashfree webhook) is row ka
  /// payment_status 'paid' kar dega (service_role key se, RLS ko bypass karke).
  static Future<String> createPendingOrder({
    required String orderRef,
    required String name,
    required String phone,
    required String email,
    required String address,
    required double itemTotal,
    required double deliveryFee,
    required double totalAmount,
    required Map<String, int> cartQuantities,
    required List<Product> products,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You need to be logged in to place an order');
    }

    final orderRow = await _client
        .from('orders')
        .insert({
          'order_ref': orderRef,
          'user_id': userId,
          'customer_name': name,
          'customer_phone': phone,
          'customer_email': email,
          'delivery_address': address,
          'item_total': itemTotal,
          'delivery_fee': deliveryFee,
          'total_amount': totalAmount,
          'payment_status': 'pending',
          'order_status': 'placed',
        })
        .select()
        .single();

    final orderId = orderRow['id'] as String;

    final items = cartQuantities.entries.map((entry) {
      final product = products.firstWhere((p) => p.id == entry.key);
      return {
        'order_id': orderId,
        'product_id': product.id,
        'product_name': product.name,
        'quantity': entry.value,
        'price': product.price,
      };
    }).toList();

    await _client.from('order_items').insert(items);

    return orderId;
  }
}
