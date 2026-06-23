class Shop {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String category;
  final String? logoUrl;
  final String? coverUrl;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final bool isApproved;
  final String address;
  final String phoneNumber;
  final Map<String, String> workingHours; // e.g. {'saturday': '8:00-22:00'}
  final DateTime createdAt;

  const Shop({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.category,
    this.logoUrl,
    this.coverUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isActive = true,
    this.isApproved = false,
    required this.address,
    required this.phoneNumber,
    this.workingHours = const {},
    required this.createdAt,
  });
}
