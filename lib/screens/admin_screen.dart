import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

/// Sirf role='admin' wale users yahan tak pahunchte hain (AuthGate mein
/// route hota hai). Yahan se admin sab orders dekh sakta hai aur unka
/// status update kar sakta hai (RLS policy 20250101000001_auth_roles.sql mein hai).
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  static const statuses = ['placed', 'packed', 'out_for_delivery', 'delivered', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _client.from('orders').select().order('created_at', ascending: false);
    if (!mounted) return;
    setState(() {
      _orders = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _updateStatus(String orderId, String status) async {
    await _client.from('orders').update({'order_status': status}).eq('id', orderId);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).palette;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.adminAllOrders),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: t.settings,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(child: Text(t.noOrdersYet))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final o = _orders[i];
                      final isPaid = o['payment_status'] == 'paid';
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(o['order_ref'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 13)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isPaid
                                        ? palette.successBg
                                        : palette.warningBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isPaid ? t.paid : t.pending,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isPaid
                                          ? palette.success
                                          : palette.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('${o['customer_name']} · ${o['customer_phone']}',
                                style: const TextStyle(fontSize: 12.5)),
                            Text(o['delivery_address'] ?? '',
                                style: TextStyle(
                                    fontSize: 12, color: scheme.onSurfaceVariant)),
                            const SizedBox(height: 6),
                            Text('₹${o['total_amount']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            DropdownButton<String>(
                              value: statuses.contains(o['order_status'])
                                  ? o['order_status']
                                  : 'placed',
                              isDense: true,
                              items: statuses
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) _updateStatus(o['id'], v);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
