class User {
  final int id;
  final String name;
  final String email;

  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawName = json['name'];
    final rawEmail = json['email'];

    final id = switch (rawId) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value),
      _ => null,
    };

    if (id == null || rawName is! String || rawEmail is! String) {
      throw const FormatException('Fallo al cargar el usuario');
    }

    return User(
      id: id,
      name: rawName,
      email: rawEmail,
    );
  }
}
