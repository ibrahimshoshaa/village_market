import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/shop_providers.dart';
import '../../domain/entities/shop.dart';

class ShopDetailScreen extends ConsumerWidget {
  final String shopId;
  const ShopDetailScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopByIdProvider(shopId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: shopAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
        error: (e, _) => Center(child: Text('حصل خطأ: $e')),
        data: (shop) {
          if (shop == null) {
            return const Center(child: Text('المحل مش موجود'));
          }
          return _ShopDetailBody(shop: shop);
        },
      ),
    );
  }
}

class _ShopDetailBody extends StatelessWidget {
  final Shop shop;
  const _ShopDetailBody({required this.shop});

  Future<void> _callShop() async {
    final uri = Uri(scheme: 'tel', path: shop.phoneNumber);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              shop.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            background: shop.coverUrl != null
                ? Image.network(shop.coverUrl!, fit: BoxFit.cover)
                : Container(
                    color: const Color(0xFF2E7D32),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 80,
                      color: Colors.white38,
                    ),
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        shop.category,
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${shop.rating.toStringAsFixed(1)} (${shop.reviewCount} تقييم)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (shop.description.isNotEmpty) ...[
                  const Text(
                    'عن المحل',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shop.description,
                    style: TextStyle(color: Colors.grey[700], height: 1.5),
                  ),
                  const SizedBox(height: 16),
                ],
                _InfoTile(icon: Icons.location_on_rounded, text: shop.address),
                const SizedBox(height: 8),
                if (shop.workingHours.isNotEmpty) ...[
                  _InfoTile(
                    icon: Icons.access_time_rounded,
                    text: shop.workingHours.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join(' | '),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _callShop,
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text(
                    'اتصل بالتاجر',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'المنتجات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text(
                      'المنتجات هتظهر هنا قريباً',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
        ),
      ],
    );
  }
}
