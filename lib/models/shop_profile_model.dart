/// Shop details printed on every bill, plus the default tax rate.
class ShopProfile {
  final String name;
  final String address;
  final String phone;
  final String footerNote;
  final double defaultTaxPercent;

  const ShopProfile({
    this.name = 'My Shop',
    this.address = '',
    this.phone = '',
    this.footerNote = 'Thank you for shopping with us!',
    this.defaultTaxPercent = 10,
  });

  ShopProfile copyWith({
    String? name,
    String? address,
    String? phone,
    String? footerNote,
    double? defaultTaxPercent,
  }) => ShopProfile(
    name: name ?? this.name,
    address: address ?? this.address,
    phone: phone ?? this.phone,
    footerNote: footerNote ?? this.footerNote,
    defaultTaxPercent: defaultTaxPercent ?? this.defaultTaxPercent,
  );
}
