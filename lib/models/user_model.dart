class User {
  final String id;
  final String name;
  final String apellido;
  final String email;
  final String direccion;
  final String telefono;
  final String ciudad;
  final String pais;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.apellido,
    required this.email,
    this.direccion = '',
    this.telefono = '',
    this.ciudad = '',
    this.pais = '',
    required this.role,
  });

  bool get isAdmin => role == 'admin';
  
  // Método para crear una copia del usuario con campos actualizados
  User copyWith({
    String? id,
    String? name,
    String? apellido,
    String? email,
    String? direccion,
    String? telefono,
    String? ciudad,
    String? pais,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      apellido: apellido ?? this.apellido,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      ciudad: ciudad ?? this.ciudad,
      pais: pais ?? this.pais,
      role: role ?? this.role,
    );
  }
}

