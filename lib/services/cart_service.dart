import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartService extends ChangeNotifier {
  final Map<String, int> _quantities = {}; // productId -> qty
  final Map<String, Product> _productLookup = {};

  Map<String, int> get quantities => _quantities;

  int qtyOf(String productId) => _quantities[productId] ?? 0;

  int get itemCount => _quantities.values.fold(0, (a, b) => a + b);

  double get itemTotal {
    double total = 0;
    _quantities.forEach((id, qty) {
      final p = _productLookup[id];
      if (p != null) total += p.price * qty;
    });
    return total;
  }

  double get deliveryFee => itemTotal > 0 ? (itemTotal >= 299 ? 0 : 25) : 0;

  double get grandTotal => itemTotal + deliveryFee;

  List<Product> get cartProducts =>
      _quantities.keys.map((id) => _productLookup[id]!).toList();

  void add(Product product) {
    _productLookup[product.id] = product;
    _quantities[product.id] = (_quantities[product.id] ?? 0) + 1;
    notifyListeners();
  }

  void decrement(Product product) {
    final current = _quantities[product.id] ?? 0;
    if (current <= 1) {
      _quantities.remove(product.id);
    } else {
      _quantities[product.id] = current - 1;
    }
    notifyListeners();
  }

  void clear() {
    _quantities.clear();
    notifyListeners();
  }
}
