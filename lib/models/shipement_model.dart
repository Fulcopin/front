class Shipment {
  final String trackingNumber;
  final String status;
  final String shippingDate;
  final String estimatedDeliveryDate;
  final String deliveryAddress;
  final String shippingMethod;
  final String carrier;
  final List<ShipmentProduct> products;

  Shipment({
    required this.trackingNumber,
    required this.status,
    required this.shippingDate,
    required this.estimatedDeliveryDate,
    required this.deliveryAddress,
    required this.shippingMethod,
    required this.carrier,
    required this.products,
  });

  // Factory method to create Shipment from JSON
  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      trackingNumber: json['trackingNumber'] ?? '',
      status: json['status'] ?? '',
      shippingDate: json['shippingDate'] ?? '',
      estimatedDeliveryDate: json['estimatedDeliveryDate'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? '',
      shippingMethod: json['shippingMethod'] ?? '',
      carrier: json['carrier'] ?? '',
      products: (json['products'] as List?)
          ?.map((product) => ShipmentProduct.fromJson(product))
          .toList() ?? [],
    );
  }
}

class ShipmentProduct {
  final String name;
  final int quantity;

  ShipmentProduct({
    required this.name,
    required this.quantity,
  });

  factory ShipmentProduct.fromJson(Map<String, dynamic> json) {
    return ShipmentProduct(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }
}