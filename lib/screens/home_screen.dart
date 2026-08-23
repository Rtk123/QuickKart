import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import '../services/cart_service.dart';
import '../services/location_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/home_header.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'location_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();

  List<Category> _categories = [];
  List<Product> _products = [];
  String _activeCat = 'all';
  String _search = '';
  bool _loading = true;
  String? _error;

  /// Pagination state — catalog 30k+ ka hai, isliye 30-30 karke aata hai.
  int _page = 0;
  int _total = 0;
  bool _loadingMore = false;
  bool _hasMore = true;

  /// Har keystroke par query na chale, isliye chhota debounce.
  Timer? _searchDebounce;

  /// Category tiles ke liye emoji — DB mein categories ka apna icon column
  /// nahi hai, isliye id se map kar lete hain.
  static const _categoryIcons = {
    'all': '🛍️',
    'grocery': '🥬',
    'electronics': '🎧',
    'fashion': '👕',
    'home': '🍳',
    'beauty': '🧴',
    'baby': '🍼',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAll();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// List ke end ke paas pahunchte hi agla page laane lagta hai.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      _loadMore();
    }
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cats = await SupabaseService.fetchCategories();
      final page = await SupabaseService.fetchProducts();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _products = page.items;
        _total = page.total;
        _page = 0;
        _hasMore = page.items.length >= SupabaseService.pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  /// Category ya search badalne par list ko page 0 se dobara bharta hai.
  Future<void> _reloadProducts() async {
    try {
      final page = await SupabaseService.fetchProducts(
        categoryId: _activeCat == 'all' ? null : _activeCat,
        search: _search,
      );
      if (!mounted) return;
      setState(() {
        _products = page.items;
        _total = page.total;
        _page = 0;
        _hasMore = page.items.length >= SupabaseService.pageSize;
      });
      // Nayi list upar se shuru honi chahiye.
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final next = await SupabaseService.fetchProducts(
        categoryId: _activeCat == 'all' ? null : _activeCat,
        search: _search,
        page: _page + 1,
      );
      if (!mounted) return;
      setState(() {
        _products = [..._products, ...next.items];
        _page = next.page;
        _total = next.total;
        _hasMore = next.items.length >= SupabaseService.pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// Har keystroke par 30k rows query karna theek nahi — 350ms ka debounce.
  void _onSearchChanged(String value) {
    _search = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      _reloadProducts,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final t = context.t;

    return Scaffold(
      body: Column(
        children: [
          HomeHeader(
            onSearchChanged: _onSearchChanged,
            totalProducts: _loading ? null : _total,
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : RefreshIndicator(
                        onRefresh: _loadAll,
                        child: CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            SliverToBoxAdapter(child: _buildLocationBanner()),
                            SliverToBoxAdapter(child: _buildCategoryGrid()),
                            SliverToBoxAdapter(child: _buildHeroBanner()),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                              sliver: _products.isEmpty
                                  ? SliverToBoxAdapter(
                                      child: Padding(
                                        padding: const EdgeInsets.all(40),
                                        child: Center(
                                            child: Text(t.noProductsFound)),
                                      ),
                                    )
                                  : SliverGrid(
                                      gridDelegate:
                                          const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 200,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                        childAspectRatio: 0.60,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, i) =>
                                            ProductCard(product: _products[i]),
                                        childCount: _products.length,
                                      ),
                                    ),
                            ),
                            SliverToBoxAdapter(child: _buildListFooter()),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: cart.itemCount > 0
          ? FloatingActionButton.extended(
              backgroundColor: Theme.of(context).palette.addGreen,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                t.cartSummary(cart.itemCount, cart.grandTotal.toStringAsFixed(0)),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  /// Location na chuni ho to ek halka prompt — Blinkit bhi pehli baar
  /// location maangta hai.
  Widget _buildLocationBanner() {
    final location = context.location;
    if (location.hasLocation) return const SizedBox.shrink();

    final t = context.t;
    final palette = Theme.of(context).palette;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.warningBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off_outlined, size: 18, color: palette.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t.selectLocation,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: palette.warning),
            ),
          ),
          TextButton(
            onPressed: () => showLocationSheet(context),
            style: TextButton.styleFrom(
              foregroundColor: palette.warning,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
            ),
            child: Text(t.changeLocation,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// Grid ke neeche: "loading more" spinner, ya catalog khatam hone ka note.
  Widget _buildListFooter() {
    final t = context.t;
    final scheme = Theme.of(context).colorScheme;

    if (_products.isEmpty) return const SizedBox(height: 90);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
      child: Center(
        child: _loadingMore
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Text(t.loadingMore,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              )
            : !_hasMore
                ? Text(t.endOfCatalog,
                    style:
                        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))
                : const SizedBox(height: 8),
      ),
    );
  }

  Widget _buildError() {
    final t = context.t;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(t.loadFailed(_error ?? ''), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadAll, child: Text(t.retry)),
          ],
        ),
      ),
    );
  }

  /// Blinkit-jaisa category grid — emoji tile + naam.
  Widget _buildCategoryGrid() {
    final settings = context.settings;
    final scheme = Theme.of(context).colorScheme;
    final all = [Category(id: 'all', name: settings.t.all), ..._categories];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final c in all)
            GestureDetector(
              onTap: () {
                _activeCat = c.id;
                setState(() {});
                _reloadProducts();
              },
              child: SizedBox(
                width: 74,
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: c.id == _activeCat
                            ? AppTheme.brand.withValues(alpha: 0.14)
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: c.id == _activeCat
                              ? AppTheme.brand
                              : Colors.transparent,
                          width: 1.4,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(_categoryIcons[c.id] ?? '📦',
                          style: const TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.displayName(settings.language),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        height: 1.15,
                        fontWeight: c.id == _activeCat
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: c.id == _activeCat
                            ? AppTheme.brand
                            : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    final t = context.t;
    final palette = Theme.of(context).palette;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.heroBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.heroTitle,
                    style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: palette.heroTitle)),
                const SizedBox(height: 4),
                Text(t.heroSubtitle,
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: palette.badgeBg, borderRadius: BorderRadius.circular(8)),
            child: Text(t.deliveryBadge,
                style: TextStyle(
                    color: palette.badgeFg,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
