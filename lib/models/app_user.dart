// Usuario con sesión iniciada.
class AppUser {
  const AppUser({required this.uid, required this.email, required this.displayName});

  final String uid;
  final String email;
  final String displayName;
}
