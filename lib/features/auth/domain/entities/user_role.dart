/// The four roles in the system. `unknown` is the transient state for a
/// freshly-created user document before they've completed role selection
/// (see Phase 1.4 / Phase 3.1 of the blueprint).
enum UserRole {
  unknown,
  villager,
  vendor,
  driver,
  admin;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.unknown,
    );
  }
}
