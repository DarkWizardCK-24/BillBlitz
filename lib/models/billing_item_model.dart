class BillingItem {
  final String name;
  final double price;
  final int quantity;

  const BillingItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  BillingItem copyWith({String? name, double? price, int? quantity}) =>
      BillingItem(
        name: name ?? this.name,
        price: price ?? this.price,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'quantity': quantity,
  };

  factory BillingItem.fromMap(Map<String, dynamic> map) => BillingItem(
    name: map['name'] ?? '',
    price: (map['price'] as num).toDouble(),
    quantity: (map['quantity'] as num).toInt(),
  );
}
