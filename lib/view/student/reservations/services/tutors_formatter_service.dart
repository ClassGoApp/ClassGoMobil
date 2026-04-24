import 'package:flutter_projects/api_structure/api_service.dart';

/// Normaliza la respuesta de getAvailableTutors y devuelve
/// una lista simple con `id`, `name` y `price`.
Future<List<Map<String, dynamic>>> fetchTutorsSimple(
    String? token, String keyword) async {
  final resp = await getAvailableTutors(token, keyword: keyword);

  List<dynamic> raw = [];
  if (resp == null) return [];

  if (resp is Map) {
    if (resp.containsKey('data')) {
      final d = resp['data'];
      if (d is Map && d.containsKey('list'))
        raw = d['list'] ?? [];
      else if (d is List)
        raw = d;
      else if (d is Map && d.containsKey('tutors')) raw = d['tutors'] ?? [];
    } else if (resp.containsKey('list')) {
      raw = resp['list'] ?? [];
    } else {
      // buscar el primer value que sea lista
      try {
        raw = resp.values.firstWhere((v) => v is List, orElse: () => [])
            as List<dynamic>;
      } catch (_) {
        raw = [];
      }
    }
  } else if (resp is List) {
    raw = resp as List<dynamic>;
  }

  return raw.map<Map<String, dynamic>>((e) {
    final Map<String, dynamic> item =
        e is Map ? Map<String, dynamic>.from(e) : {'name': e.toString()};

    final id = item['id'] ?? item['profile']?['id'];

    String name = '';
    if (item['profile'] is Map) {
      final profile = Map<String, dynamic>.from(item['profile']);
      name = profile['full_name'] ??
          profile['name'] ??
          ((profile['first_name'] ?? '') + ' ' + (profile['last_name'] ?? ''))
              .trim();
    }
    if (name.isEmpty)
      name =
          item['name']?.toString() ?? item['full_name']?.toString() ?? 'Tutor';

    dynamic price;
    final possiblePriceKeys = [
      'price',
      'price_per_hour',
      'hourly_rate',
      'price_from',
      'min_price',
      'rate'
    ];
    for (final key in possiblePriceKeys) {
      if (item.containsKey(key) && item[key] != null) {
        price = item[key];
        break;
      }
      if (item['profile'] is Map &&
          item['profile'].containsKey(key) &&
          item['profile'][key] != null) {
        price = item['profile'][key];
        break;
      }
    }

    return {
      'id': id,
      'name': name,
      'price': price,
      'raw': item,
    };
  }).toList();
}
