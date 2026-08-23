import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/delivery_location.dart';
import '../services/location_service.dart';
import '../services/settings_service.dart';
import '../services/supabase_service.dart';

/// Location picker — teen chhote steps mein:
///
///   State  ->  District  ->  Pincode
///
/// Har step ki list Supabase se aati hai (`pincodes` table, GeoNames dataset).
/// Saved locations sabse upar dikhti hain taaki ek tap mein chun sakein.
Future<void> showLocationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => const _LocationSheet(),
  );
}

enum _Step { state, district, pincode }

class _LocationSheet extends StatefulWidget {
  const _LocationSheet();

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  final _searchCtrl = TextEditingController();

  _Step _step = _Step.state;
  String _query = '';

  String? _state;
  String? _district;

  List<String> _options = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load(Future<List<String>> Function() fetch) async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await fetch();
      if (!mounted) return;
      setState(() { _options = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadStates() => _load(SupabaseService.fetchStates);

  void _clearSearch() {
    _searchCtrl.clear();
    _query = '';
  }

  Future<void> _pickState(String state) async {
    setState(() { _state = state; _step = _Step.district; _clearSearch(); });
    await _load(() => SupabaseService.fetchDistricts(state));
  }

  Future<void> _pickDistrict(String district) async {
    setState(() { _district = district; _step = _Step.pincode; _clearSearch(); });
    await _load(() => SupabaseService.fetchPincodes(_state!, district));
  }

  Future<void> _pickPincode(String pincode) async {
    await _select(DeliveryLocation(
      state: _state!,
      district: _district!,
      pincode: pincode,
    ));
  }

  Future<void> _select(DeliveryLocation location) async {
    await context.read<LocationService>().select(location);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _back() async {
    if (_step == _Step.pincode) {
      setState(() { _step = _Step.district; _district = null; _clearSearch(); });
      await _load(() => SupabaseService.fetchDistricts(_state!));
    } else if (_step == _Step.district) {
      setState(() { _step = _Step.state; _state = null; _clearSearch(); });
      await _loadStates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final scheme = Theme.of(context).colorScheme;
    final saved = context.location.saved;

    final title = switch (_step) {
      _Step.state => t.selectState,
      _Step.district => t.selectDistrict,
      _Step.pincode => t.selectPincode,
    };
    final hint = switch (_step) {
      _Step.state => t.searchState,
      _Step.district => t.searchDistrict,
      _Step.pincode => t.searchPincode,
    };

    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _options
        : _options.where((o) => o.toLowerCase().contains(q)).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Row(
                  children: [
                    if (_step != _Step.state)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _back,
                      )
                    else
                      const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                            fontSize: 16.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              if (_state != null) _buildBreadcrumb(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: hint,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  keyboardType: _step == _Step.pincode
                      ? TextInputType.number
                      : TextInputType.text,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: _loading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 10),
                            Text(t.loadingLocations,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline,
                                      color: scheme.error, size: 36),
                                  const SizedBox(height: 8),
                                  Text(t.locationLoadFailed,
                                      textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          )
                        : ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            children: [
                              // Saved locations sirf pehle step par, aur tabhi
                              // jab user kuch search na kar raha ho.
                              if (_step == _Step.state &&
                                  q.isEmpty &&
                                  saved.isNotEmpty) ...[
                                _SectionLabel(t.savedAddresses),
                                ...saved.map((l) => _SavedTile(
                                      location: l,
                                      selected: context.location.current
                                              ?.sameAs(l) ??
                                          false,
                                      onTap: () => _select(l),
                                      onRemove: () => context
                                          .read<LocationService>()
                                          .remove(l),
                                    )),
                                const SizedBox(height: 10),
                                _SectionLabel(t.state),
                              ],
                              if (filtered.isEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 30),
                                  child: Center(
                                    child: Text(t.noLocationMatch,
                                        style: TextStyle(
                                            color: scheme.onSurfaceVariant)),
                                  ),
                                )
                              else
                                ...filtered.map(_buildOptionTile),
                            ],
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// "Uttar Pradesh › Gautam Buddha Nagar" — chuni hui values wapas dikhata hai.
  Widget _buildBreadcrumb() {
    final scheme = Theme.of(context).colorScheme;
    final parts = [if (_state != null) _state!, if (_district != null) _district!];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Icon(Icons.place_outlined, size: 14, color: scheme.primary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              parts.join('  ›  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(String value) {
    final scheme = Theme.of(context).colorScheme;
    final isPincode = _step == _Step.pincode;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      onTap: () => switch (_step) {
        _Step.state => _pickState(value),
        _Step.district => _pickDistrict(value),
        _Step.pincode => _pickPincode(value),
      },
      leading: Icon(
        isPincode ? Icons.markunread_mailbox_outlined : Icons.place_outlined,
        size: 19,
        color: scheme.onSurfaceVariant,
      ),
      title: Text(value, style: const TextStyle(fontSize: 14)),
      trailing: isPincode
          ? null
          : Icon(Icons.chevron_right, size: 18, color: scheme.outlineVariant),
    );
  }
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({
    required this.location,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  final DeliveryLocation location;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      onTap: onTap,
      leading: Icon(
        selected ? Icons.location_on : Icons.location_on_outlined,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(
        location.shortLine,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: selected ? scheme.primary : scheme.onSurface,
        ),
      ),
      subtitle: Text(
        location.state,
        style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline,
            size: 19, color: scheme.onSurfaceVariant),
        tooltip: context.t.removeAddress,
        onPressed: onRemove,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
