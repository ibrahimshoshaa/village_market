/// Single source of truth for Firestore collection/subcollection names.
/// Never hardcode collection path strings elsewhere — reference these.
abstract class FirestoreCollections {
  static const users = 'users';
  static const shops = 'shops';
  static const products = 'products'; // subcollection of shops
  static const craftsmen = 'craftsmen';
  static const orders = 'orders';
  static const chats = 'chats';
  static const messages = 'messages'; // subcollection of chats
  static const reviews = 'reviews'; // subcollection of shops/craftsmen

  static String shopProducts(String shopId) => '$shops/$shopId/$products';
  static String shopReviews(String shopId) => '$shops/$shopId/$reviews';
  static String craftsmanReviews(String craftsmanId) => '$craftsmen/$craftsmanId/$reviews';
  static String chatMessages(String threadId) => '$chats/$threadId/$messages';
}
