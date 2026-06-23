import '../../domain/entities/shop.dart';

class ShopModel extends Shop {
  const ShopModel({
    required super.id,
    required super.name,
    required super.description,
    required super.ownerId,
    required super.category,
    super.logoUrl,
    super.coverUrl,
    super.rating,
    super.reviewCount,
    super.isActive,
    super.isApproved,
    required super.address,
    required super.phoneNumber,
    super.workingHours,
    required super.createdAt,
  });

  factory ShopModel.fromMap(Map<String, dynamic> map, String id) {
    return ShopModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      ownerId: map['ownerId'] ?? '',
      category: map['category'] ?? '',
      logoUrl: map['logoUrl'],
      coverUrl: map['coverUrl'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      isApproved: map['isApproved'] ?? false,
      address: map['address'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      workingHours: Map<String, String>.from(map['workingHours'] ?? {}),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'category': category,
      'logoUrl': logoUrl,
      'coverUrl': coverUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
      'isApproved': isApproved,
      'address': address,
      'phoneNumber': phoneNumber,
      'workingHours': workingHours,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
