class Tutor {
  final num id;
  final String nombre;
  final String materia;

  Tutor({
    required this.id,
    required this.nombre,
    required this.materia,
  });

  factory Tutor.fromJson(Map<String, dynamic> json) {
    return Tutor(
      id: json['id'] as num,
      nombre: json['nombre'] as String,
      materia: json['materia'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'materia': materia,
    };
  }
}
