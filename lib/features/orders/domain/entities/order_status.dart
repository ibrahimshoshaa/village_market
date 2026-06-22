import 'package:flutter/material.dart';

enum OrderStatus {
  pending,
  accepted,
  preparing,
  inTransit,
  delivered,
  cancelled;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == value || s.firestoreValue == value,
      orElse: () => OrderStatus.pending,
    );
  }

  String get firestoreValue => switch (this) {
        OrderStatus.inTransit => 'in_transit',
        _ => name,
      };

  String get arabicLabel => switch (this) {
        OrderStatus.pending => 'قيد الانتظار',
        OrderStatus.accepted => 'تم القبول',
        OrderStatus.preparing => 'جاري التجهيز',
        OrderStatus.inTransit => 'في الطريق',
        OrderStatus.delivered => 'تم التوصيل',
        OrderStatus.cancelled => 'ملغي',
      };

  Color get color => switch (this) {
        OrderStatus.pending => const Color(0xFF9E9E9E),
        OrderStatus.accepted => const Color(0xFF2E7D32),
        OrderStatus.preparing => const Color(0xFFE8A33D),
        OrderStatus.inTransit => const Color(0xFF1565C0),
        OrderStatus.delivered => const Color(0xFF1B7A43),
        OrderStatus.cancelled => const Color(0xFFC62828),
      };

  IconData get icon => switch (this) {
        OrderStatus.pending => Icons.hourglass_empty,
        OrderStatus.accepted => Icons.check_circle_outline,
        OrderStatus.preparing => Icons.restaurant_outlined,
        OrderStatus.inTransit => Icons.local_shipping_outlined,
        OrderStatus.delivered => Icons.done_all,
        OrderStatus.cancelled => Icons.cancel_outlined,
      };

  bool get isActive =>
      this != OrderStatus.delivered && this != OrderStatus.cancelled;
}
