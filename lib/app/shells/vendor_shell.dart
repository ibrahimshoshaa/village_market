import 'package:flutter/material.dart';

/// Shell for the vendor role's screens. Starts minimal (single screen) —
/// expand with a bottom nav (الرئيسية / المنتجات / الطلبات / المحل) once
/// vendor_dashboard screens beyond the placeholder are implemented.
class VendorShell extends StatelessWidget {
  final Widget child;
  const VendorShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child);
  }
}
