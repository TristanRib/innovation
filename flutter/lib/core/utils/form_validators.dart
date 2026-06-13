class FormValidators {
  static String? email(String? v) =>
      v == null || !v.contains('@') ? 'Email invalide' : null;
  static String? password(String? v) =>
      v == null || v.length < 6 ? 'Minimum 6 caractères' : null;
  static String? pseudo(String? v) =>
      v == null || v.trim().length < 2 ? 'Minimum 2 caractères' : null;
}

String authErrorMessage(String e) {
  if (e.contains('user-not-found') ||
      e.contains('wrong-password') ||
      e.contains('invalid-credential')) {
    return 'Email ou mot de passe incorrect.';
  }
  if (e.contains('too-many-requests')) return 'Trop de tentatives. Réessayez plus tard.';
  if (e.contains('email-already-in-use')) return 'Cet email est déjà utilisé.';
  if (e.contains('weak-password')) return 'Mot de passe trop faible.';
  return 'Une erreur est survenue.';
}
