/// Delivery location ab sirf teen cheezon se banti hai: **State → District →
/// Pincode**. Yeh data Supabase ki `pincodes` table se aata hai (GeoNames ka
/// asli Indian postal dataset — 35 states, 658 districts, 20,609 pincodes),
/// isliye koi GPS ya external geocoding service nahi chahiye.
///
/// Ghar/gali ka detail yahan nahi hai — woh checkout ke address field mein
/// jaata hai, jo is location se prefill ho jaata hai.
class DeliveryLocation {
  const DeliveryLocation({
    required this.state,
    required this.district,
    required this.pincode,
  });

  final String state;
  final String district;
  final String pincode;

  /// Header ke liye sabse chhoti line: "Gautam Buddha Nagar, 201301".
  String get shortLine => '$district, $pincode';

  /// Poori line: "Gautam Buddha Nagar, Uttar Pradesh - 201301".
  String get fullLine => '$district, $state - $pincode';

  String get searchable => '$state $district $pincode'.toLowerCase();

  bool get isValid =>
      state.trim().isNotEmpty &&
      district.trim().isNotEmpty &&
      RegExp(r'^\d{6}$').hasMatch(pincode.trim());

  Map<String, dynamic> toJson() => {
        'state': state,
        'district': district,
        'pincode': pincode,
      };

  factory DeliveryLocation.fromJson(Map<String, dynamic> json) {
    // Purane format (label/address/city) se aayi saved entries bhi na tootein —
    // us format mein city hi district ke sabse kareeb thi.
    final state = (json['state'] as String?) ?? '';
    final district =
        (json['district'] as String?) ?? (json['city'] as String?) ?? '';
    return DeliveryLocation(
      state: state,
      district: district,
      pincode: (json['pincode'] as String?) ?? '',
    );
  }

  bool sameAs(DeliveryLocation other) =>
      pincode.trim() == other.pincode.trim() &&
      district.trim().toLowerCase() == other.district.trim().toLowerCase() &&
      state.trim().toLowerCase() == other.state.trim().toLowerCase();

  @override
  String toString() => fullLine;
}
