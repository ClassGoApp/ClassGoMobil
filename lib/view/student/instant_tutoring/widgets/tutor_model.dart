class TutorResponse {
  final int id;
  final String name;
  final String avatarUrl;
  final bool isVerified;
  final String pricePerHour;
  final double rating;

  TutorResponse({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isVerified,
    required this.pricePerHour,
    required this.rating,
  });
}

// Datos simulados del backend
final List<TutorResponse> dummyFoundTutors = [
  TutorResponse(id: 1, name: 'Carlos Mendoza', avatarUrl: 'https://i.pravatar.cc/150?img=11', isVerified: true, pricePerHour: '50.00 Bs', rating: 4.8),
  TutorResponse(id: 2, name: 'Ana Salazar', avatarUrl: 'https://i.pravatar.cc/150?img=5', isVerified: true, pricePerHour: '45.00 Bs', rating: 4.9),
  TutorResponse(id: 3, name: 'Roberto Gómez', avatarUrl: 'https://i.pravatar.cc/150?img=8', isVerified: false, pricePerHour: '40.00 Bs', rating: 4.5),
];