import 'package:flutter_projects/view/student/services/text_normalization.dart';

/// Ordena la lista de tutores según la opción proporcionada.
/// Retorna una nueva lista (no modifica el original).
List<Map<String, dynamic>> sortTutors(
    List<Map<String, dynamic>> tutors, String? sortOption) {
  if (sortOption == null || sortOption == 'Sin ordenar')
    return List.from(tutors);

  final list = List<Map<String, dynamic>>.from(tutors);

  String _nameOf(Map<String, dynamic> tutor) {
    try {
      final profile = tutor['profile'] as Map<String, dynamic>?;
      return (profile != null && profile['full_name'] != null)
          ? profile['full_name'].toString()
          : '';
    } catch (_) {
      return '';
    }
  }

  String _firstValidSubject(Map<String, dynamic> tutor) {
    try {
      final subjects = tutor['subjects'] as List<dynamic>?;
      if (subjects == null) return '';
      final valid = subjects
          .where((s) =>
              s != null && s['status'] == 'active' && s['deleted_at'] == null)
          .map((s) => s['name'].toString())
          .toList();
      return valid.isNotEmpty ? valid.first : '';
    } catch (_) {
      return '';
    }
  }

  switch (sortOption) {
    case 'Nombre (A-Z)':
      list.sort(
          (a, b) => normalize(_nameOf(a)).compareTo(normalize(_nameOf(b))));
      break;
    case 'Nombre (Z-A)':
      list.sort(
          (a, b) => normalize(_nameOf(b)).compareTo(normalize(_nameOf(a))));
      break;
    case 'Materia (A-Z)':
      list.sort((a, b) => normalize(_firstValidSubject(a))
          .compareTo(normalize(_firstValidSubject(b))));
      break;
    case 'Materia (Z-A)':
      list.sort((a, b) => normalize(_firstValidSubject(b))
          .compareTo(normalize(_firstValidSubject(a))));
      break;
    case 'Mejor Valorado':
    case 'Mayor calificación':
    case 'Menor calificación': {
      final bool desc = sortOption == 'Mejor Valorado' || sortOption == 'Mayor calificación';
      list.sort((a, b) {
        final ratingA = (a['avg_rating'] ?? 0) is num
            ? (a['avg_rating'] ?? 0).toDouble()
            : double.tryParse((a['avg_rating'] ?? '0').toString()) ?? 0;
        final ratingB = (b['avg_rating'] ?? 0) is num
            ? (b['avg_rating'] ?? 0).toDouble()
            : double.tryParse((b['avg_rating'] ?? '0').toString()) ?? 0;
        return desc
            ? ratingB.compareTo(ratingA)
            : ratingA.compareTo(ratingB);
      });
      break;
    }
    case 'Precio':
    case 'Más barato':
    case 'Menor precio':
    case 'Más caro':
    case 'Mayor precio': {
      final bool asc = sortOption == 'Precio' || sortOption == 'Más barato' || sortOption == 'Menor precio';
      list.sort((a, b) {
        final priceA = (a['profile']?['price'] ?? 0) is num
            ? (a['profile']?['price'] ?? 0).toDouble()
            : double.tryParse((a['profile']?['price'] ?? '0').toString()) ?? 0;
        final priceB = (b['profile']?['price'] ?? 0) is num
            ? (b['profile']?['price'] ?? 0).toDouble()
            : double.tryParse((b['profile']?['price'] ?? '0').toString()) ?? 0;
        return asc
            ? priceA.compareTo(priceB)
            : priceB.compareTo(priceA);
      });
      break;
    }
    default:
      break;
  }

  return list;
}
