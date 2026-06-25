class CustomizationCartModel {
  final List<CustomizationCartItem> items;
  final double subtotal;

  const CustomizationCartModel({required this.items, required this.subtotal});

  factory CustomizationCartModel.fromJson(dynamic json) {
    final root = _asMap(json);
    final rawItems = _firstList([
      root['cartItems'],
      root['items'],
      root['data'] is Map ? (root['data'] as Map)['cartItems'] : null,
      root['data'] is Map ? (root['data'] as Map)['items'] : null,
    ]);
    final items = rawItems.map((e) => CustomizationCartItem.fromJson(e)).toList();
    final total = _num([
      root['totalCartPrice'],
      root['subtotal'],
      root['total'],
      root['data'] is Map ? (root['data'] as Map)['totalCartPrice'] : null,
    ]);
    return CustomizationCartModel(
      items: items,
      subtotal: total > 0 ? total : items.fold(0, (s, i) => s + i.totalPrice),
    );
  }
}

class CustomizationCartItem {
  final String id;
  final String designImageUrl;
  final String photoUrl;
  final String shape;
  final String size;
  final String flavor;
  final String piping;
  final int quantity;
  final double totalPrice;
  final double basePrice;
  final String message;
  final String note;
  final List<String> colors;
  final List<String> toppings;
  final List<String> extras;
  final Map<String, dynamic> raw;

  const CustomizationCartItem({
    required this.id,
    required this.designImageUrl,
    required this.photoUrl,
    required this.shape,
    required this.size,
    required this.flavor,
    required this.piping,
    required this.quantity,
    required this.totalPrice,
    required this.basePrice,
    required this.message,
    required this.note,
    required this.colors,
    required this.toppings,
    required this.extras,
    required this.raw,
  });

  factory CustomizationCartItem.fromJson(dynamic json) {
    final m = _asMap(json);
    final size = _asMap(m['size'] ?? m['productSize']);
    final flavor = _asMap(m['flavor']);
    final shape = _asMap(m['shape']);
    final piping = _asMap(m['piping']);
    return CustomizationCartItem(
      id: _str([m['id'], m['cartItemId'], m['customizationCartItemId']]),
      designImageUrl: _str([m['designImageUrl'], m['finalDesignImage'], m['imageUrl']]),
      photoUrl: _str([m['photoUrl'], m['uploadedPhotoUrl'], m['userPhotoUrl']]),
      shape: _name(shape, fallback: _str([m['shapeName'], m['shape']])),
      size: _name(size, fallback: _str([m['sizeName'], m['size']])),
      flavor: _name(flavor, fallback: _str([m['flavorName'], m['flavor']])),
      piping: _name(piping, fallback: _str([m['pipingName'], m['piping']])),
      quantity: _num([m['quantity']]).round().clamp(1, 999).toInt(),
      totalPrice: _num([m['totalPrice'], m['total'], m['price'], m['basePrice']]),
      basePrice: _num([m['basePrice']]),
      message: _str([m['customMessage'], m['message']]),
      note: _str([m['note']]),
      colors: _strings(m['colors'] ?? m['selectedColors'] ?? [m['baseColor'], m['topColor'], m['decorationColor']]),
      toppings: _strings(m['toppings'] ?? m['toppingSelections']),
      extras: _strings(m['extras'] ?? m['extraIds']),
      raw: m,
    );
  }
}

class CustomizationOrderModel {
  final String id;
  final String orderNumber;
  final String status;
  final String designImageUrl;
  final bool isDelivery;
  final String date;
  final double total;
  final Map<String, dynamic> raw;

  const CustomizationOrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.designImageUrl,
    required this.isDelivery,
    required this.date,
    required this.total,
    required this.raw,
  });

  factory CustomizationOrderModel.fromJson(dynamic json) {
    final m = _asMap(json);
    final firstItem = _firstList([m['items'], m['orderItems'], m['cartItems']]).isNotEmpty
        ? _asMap(_firstList([m['items'], m['orderItems'], m['cartItems']]).first)
        : <String, dynamic>{};
    return CustomizationOrderModel(
      id: _str([m['id'], m['orderId']]),
      orderNumber: _str([m['orderNumber'], m['number'], m['id']]),
      status: _str([m['status'], m['orderStatus']], fallback: 'Pending'),
      designImageUrl: _str([m['designImageUrl'], firstItem['designImageUrl'], firstItem['imageUrl']]),
      isDelivery: _str([m['deliveryType'], m['orderType']]).toLowerCase().contains('delivery') || m['isDelivery'] == true,
      date: _str([m['date'], m['deliveryDate'], m['pickupDate'], m['createdAt']]),
      total: _num([m['finalTotal'], m['totalPrice'], m['total'], m['subtotal']]),
      raw: m,
    );
  }
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return <String, dynamic>{};
}

List<dynamic> _firstList(List<dynamic> values) {
  for (final v in values) {
    if (v is List) return v;
  }
  return const [];
}

String _str(List<dynamic> values, {String fallback = ''}) {
  for (final v in values) {
    final s = v?.toString().trim();
    if (s != null && s.isNotEmpty && s != 'null') return s;
  }
  return fallback;
}

double _num(List<dynamic> values) {
  for (final v in values) {
    if (v is num) return v.toDouble();
    final parsed = double.tryParse(v?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return 0;
}

String _name(Map<String, dynamic> map, {String fallback = ''}) {
  return _str([map['nameAr'], map['nameEn'], map['name'], map['label']], fallback: fallback);
}

List<String> _strings(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((e) {
    if (e is Map) return _name(Map<String, dynamic>.from(e), fallback: _str([e['name'], e['id'], e['toppingId']]));
    return e?.toString() ?? '';
  }).where((e) => e.trim().isNotEmpty).toList();
}
