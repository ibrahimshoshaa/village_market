import 'package:flutter/material.dart';

/// Shell for the driver role's screens. Starts minimal — expand with a
/// bottom nav (الرئيسية / التوصيلات / الأرباح) once driver_dashboard
/// screens beyond the placeholder are implemented.
class DriverShell extends StatelessWidget {
  final Widget child;
  const DriverShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child);
  }
}
