import 'package:flutter_projects/api_structure/api_service.dart';

class SubjectFetchResult {
  final List<Map<String, dynamic>> subjects;
  final int currentPage;
  final int lastPage;

  SubjectFetchResult({
    required this.subjects,
    required this.currentPage,
    required this.lastPage
  });
}

class SubjectSearchService {
  static Future<SubjectFetchResult> fetchAvailableSubjects(
    String token,
    Set<int> currentSubjectIds, {
    int startPage = 1,
    int perPage = 50,
    String? keyword,
  }) async {
    final List<Map<String, dynamic>> availableSubjects = [];
    int currentPage = startPage;
    int lastPage = startPage;

    while (true) {
      final response = await getAllSubjects(
        token,
        page: currentPage,
        perPage: perPage,
        keyword: keyword?.trim().isEmpty ?? true ? null : keyword?.trim(),
      );

      if (response['status'] != 200 || response['data'] == null) {
        break;
      }

      final List<dynamic> subjectsData = response['data']['data'];
      lastPage = response['data']['last_page'] ?? currentPage;

      print(
          'DEBUG fetchAvailableSubjects page=$currentPage total=${subjectsData.length} currentSubjectIds=${currentSubjectIds.length}');
      if (subjectsData.isNotEmpty) {
        print('DEBUG first subject raw: ${subjectsData.first}');
      }

      final filtered = subjectsData
          .where((s) => !currentSubjectIds.contains(s['id']))
          .map((s) => {
                'id': s['id'],
                'name': s['name'],
              })
          .toList();

      availableSubjects.addAll(filtered);

      if (currentPage >= lastPage || availableSubjects.isNotEmpty) {
        break;
      }

      currentPage += 1;
    }

    return SubjectFetchResult(
      subjects: availableSubjects,
      currentPage: currentPage,
      lastPage: lastPage,
    );
  }

  static Future<List<Map<String, dynamic>>> searchSubjects(
    String token,
    String query,
    Set<int> currentIds, {
    int perPage = 50,
  }) async {
    final effectiveQuery = query.trim().isEmpty ? null : query.trim();
    final response = await getAllSubjects(
      token,
      page: 1,
      perPage: perPage,
      keyword: effectiveQuery,
    );

    if (response['status'] != 200 || response['data'] == null) {
      return [];
    }

    final List<dynamic> subjectsData = response['data']['data'];
    print(
        'DEBUG searchSubjects query="$query" returned=${subjectsData.length}');
    if (subjectsData.isNotEmpty) {
      print('DEBUG first search raw: ${subjectsData.first}');
    }

    return subjectsData
      .map((s) => {
        'id': s['id'],
        'name': s['name'],
        'isAdded': currentIds.contains(s['id']),
      })
      .toList();
  }
}
