import 'package:flutter/material.dart';
import 'package:flutter_projects/view/student/reservations/tutor_reservation_screen.dart';
import 'package:flutter_projects/view/student/services/text_normalization.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import '../services/tutors_formatter_service.dart';
import 'package:flutter_projects/helpers/slide_up_route.dart';
import 'package:flutter_projects/provider/auth_provider.dart';

class NewReservationModal extends StatefulWidget {
  const NewReservationModal({Key? key}) : super(key: key);

  @override
  State<NewReservationModal> createState() => _NewReservationModalState();
}

class _NewReservationModalState extends State<NewReservationModal> {
  final List<String> _institutions = ['Colegio', 'Universidad', 'Instituto'];
  String? _selectedInstitution;
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _filteredSubjects = [];
  Map<String, dynamic>? _selectedSubject;
  final TextEditingController _subjectFilterController =
      TextEditingController();
  List<Map<String, dynamic>> _tutors = [];
  bool _loadingTutors = false;
  bool _loading = false;
  VoidCallback? _modalFilterListener;

  @override
  void initState() {
    super.initState();
    _subjectFilterController.addListener(_onSubjectFilterChanged);
  }

  @override
  void dispose() {
    _subjectFilterController.removeListener(_onSubjectFilterChanged);
    _subjectFilterController.dispose();
    super.dispose();
  }

  void _onSubjectFilterChanged() {
    _filterSubjects(_subjectFilterController.text);
  }

  Future<void> _loadSubjectsForInstitution(String institution) async {
    setState(() {
      _loading = true;
      _subjects = [];
      _selectedSubject = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      try {
        final respInst = await getSubjectsForInstitution(token, institution);
        List<dynamic> instData = [];

        if (respInst.containsKey('data')) {
          instData = respInst['data'] ?? [];
        } else if (respInst.containsKey('subjects')) {
          instData = respInst['subjects'] ?? [];
        } else if (respInst is List) {
          instData = respInst as List<dynamic>;
        }

        final parsed = instData
            .map<Map<String, dynamic>>((e) => e is Map
                ? Map<String, dynamic>.from(e)
                : {'name': e.toString()})
            .toList();

        if (mounted)
          setState(() {
            _subjects = parsed;
            _filteredSubjects = List<Map<String, dynamic>>.from(parsed);
            _subjectFilterController.text = '';
            _loading = false;
          });
        return;
      } catch (e) {
        if (mounted)
          setState(() {
            _subjects = [];
            _filteredSubjects = [];
            _loading = false;
          });
        return;
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  void _filterSubjects(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _filteredSubjects = List<Map<String, dynamic>>.from(_subjects);
      });
      return;
    }
    setState(() {
      _filteredSubjects = _subjects.where((s) {
        final raw = (s['name'] ?? s['title'] ?? s['subject'] ?? '').toString();
        final name = normalize(raw);
        return name.contains(normalize(q));
      }).toList();
      // If selectedSubject is filtered out, clear selection
      if (_selectedSubject != null &&
          !_filteredSubjects.contains(_selectedSubject)) {
        _selectedSubject = null;
      }
    });
  }

  Future<void> _loadTutorsForSubject(String keyword) async {
    setState(() {
      _loadingTutors = true;
      _tutors = [];
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      try {
        final parsed = await fetchTutorsSimple(token, keyword);
        if (mounted)
          setState(() {
            _tutors = parsed;
            _loadingTutors = false;
          });
        return;
      } catch (e) {
        if (mounted)
          setState(() {
            _tutors = [];
            _loadingTutors = false;
          });
        return;
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _loadingTutors = false;
        });
    }
  }

  Future<void> _showSubjectsPicker() async {
    // Ensure filteredSubjects initialized
    _filterSubjects(_subjectFilterController.text);
    // We'll attach a modal-scoped listener that calls sheetSetState so
    // the bottom sheet updates live as the controller changes.
    _modalFilterListener = null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(builder: (context, sheetSetState) {
              // attach listener once per modal show
              if (_modalFilterListener == null) {
                _modalFilterListener = () {
                  _filterSubjects(_subjectFilterController.text);
                  try {
                    sheetSetState(() {});
                  } catch (_) {}
                };
                _subjectFilterController.addListener(_modalFilterListener!);
              }

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _subjectFilterController,
                      decoration: InputDecoration(
                        hintText: 'Filtrar materias...',
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: _subjectFilterController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _subjectFilterController.clear();
                                  _filterSubjects('');
                                  try {
                                    sheetSetState(() {});
                                  } catch (_) {}
                                },
                                child: Icon(Icons.clear),
                              )
                            : null,
                      ),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: Builder(builder: (context) {
                        final items =
                            List<Map<String, dynamic>>.from(_filteredSubjects);
                        if (items.isEmpty)
                          return Center(child: Text('No hay materias'));
                        return ListView.separated(
                          controller: scrollController,
                          itemCount: items.length,
                          separatorBuilder: (_, __) => Divider(height: 1),
                          itemBuilder: (context, index) {
                            if (index < 0 || index >= items.length)
                              return const SizedBox.shrink();
                            final s = items[index];
                            final name = s['name']?.toString() ??
                                s['title']?.toString() ??
                                s['subject']?.toString() ??
                                'Materia';
                            return ListTile(
                              title: Text(name),
                              onTap: () {
                                setState(() {
                                  _selectedSubject = s;
                                });
                                Navigator.of(context).pop();
                                // trigger loading tutors
                                _loadTutorsForSubject(name);
                              },
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              );
            });
          },
        );
      },
    );

    // modal closed: remove modal-specific listener if present
    if (_modalFilterListener != null) {
      try {
        _subjectFilterController.removeListener(_modalFilterListener!);
      } catch (_) {}
      _modalFilterListener = null;
    }
  }

  void _confirm() {
    String? _extractId(dynamic s) {
      if (s == null) return null;
      if (s is Map) {
        if (s['id'] != null) return s['id'].toString();
        if (s['subject_id'] != null) return s['subject_id'].toString();
        if (s['id_subget'] != null) return s['id_subget'].toString();
        if (s['id_subjet'] != null) return s['id_subjet'].toString();
        if (s['subget_id'] != null) return s['subget_id'].toString();
      }
      return null;
    }

    final subjectId = _extractId(_selectedSubject);

    Navigator.of(context).pop({
      'institution': _selectedInstitution,
      'subject': _selectedSubject,
      'subjectId': subjectId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Crear nueva reserva',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedInstitution,
              hint: const Text('Selecciona tipo de institución'),
              isExpanded: true,
              items: _institutions
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _selectedInstitution = v;
                });
                _loadSubjectsForInstitution(v);
              },
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            if (_loading)
              Center(
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator())),
            if (!_loading)
              GestureDetector(
                onTap: () {
                  if (_subjects.isNotEmpty) _showSubjectsPicker();
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    hintText: 'Selecciona materia',
                    suffixIcon: Icon(Icons.arrow_drop_down),
                    isDense: true,
                  ),
                  child: Text(
                    _selectedSubject != null
                        ? ((_selectedSubject!['name'] ??
                                _selectedSubject!['title'] ??
                                _selectedSubject!['subject'])
                            .toString())
                        : 'Seleccione una materia',
                    style: TextStyle(
                        color: _selectedSubject != null
                            ? Colors.black87
                            : Colors.black54),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            // Mostrar tutores para la materia seleccionada
            if (_loadingTutors)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator())),
            if (!_loadingTutors && _tutors.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _tutors.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final t = _tutors[index];
                    final name = t['name']?.toString() ??
                        (t['first_name']?.toString() ?? 'Tutor');
                    final subtitle =
                        t['title']?.toString() ?? t['bio']?.toString() ?? '';
                    final avatarUrl = t['avatar']?.toString();
                    return ListTile(
                      leading: avatarUrl != null && avatarUrl.isNotEmpty
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(avatarUrl))
                          : const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(name),
                      subtitle: subtitle.isNotEmpty
                          ? Text(subtitle,
                              maxLines: 1, overflow: TextOverflow.ellipsis)
                          : null,
                      onTap: () {
                        // Navegar a la pantalla de perfil usando los datos raw si están disponibles
                        final raw = t['raw'] as Map<String, dynamic>?;
                        final profile = raw != null && raw['profile'] is Map
                            ? Map<String, dynamic>.from(raw['profile'])
                            : <String, dynamic>{};

                        final tutorId = (raw != null && raw['id'] != null)
                            ? raw['id'].toString()
                            : (profile['id']?.toString() ?? '');
                        final tutorName =
                            profile['full_name'] ?? profile['name'] ?? name;
                        final tutorImage = profile['image'] ?? '';
                        final tutorVideo = profile['intro_video'] ?? '';
                        final description = profile['description'] ?? '';
                        final ratingVal =
                            raw != null && raw['avg_rating'] != null
                                ? (raw['avg_rating'] is num
                                    ? (raw['avg_rating'] as num).toDouble()
                                    : double.tryParse(
                                            raw['avg_rating'].toString()) ??
                                        0.0)
                                : 0.0;
                        final subjectsList = <Map<String, dynamic>>[];
                        String? _extractId(dynamic s) {
                          if (s is Map) {
                            if (s['id'] != null) return s['id'].toString();
                            if (s['subject_id'] != null)
                              return s['subject_id'].toString();
                            if (s['id_subget'] != null)
                              return s['id_subget'].toString();
                            if (s['id_subjet'] != null)
                              return s['id_subjet'].toString();
                            if (s['subget_id'] != null)
                              return s['subget_id'].toString();
                          }
                          return null;
                        }

                        if (raw != null && raw['subjects'] is List) {
                          for (final s in raw['subjects']) {
                            if (s is Map && s['name'] != null) {
                              final subjectMap = Map<String, dynamic>.from(s);
                              if (subjectMap['id'] == null) {
                                subjectMap['id'] = _extractId(s);
                              }
                              subjectsList.add(subjectMap);
                            } else if (s is String) {
                              subjectsList.add({'id': null, 'name': s});
                            }
                          }
                        } else if (profile['subjects'] is List) {
                          for (final s in profile['subjects']) {
                            if (s is Map && s['name'] != null) {
                              final subjectMap = Map<String, dynamic>.from(s);
                              if (subjectMap['id'] == null) {
                                subjectMap['id'] = _extractId(s);
                              }
                              subjectsList.add(subjectMap);
                            } else if (s is String) {
                              subjectsList.add({'id': null, 'name': s});
                            }
                          }
                        }
                        final completedCourses = raw != null &&
                                raw['completed_courses_count'] != null
                            ? (raw['completed_courses_count'] is int
                                ? raw['completed_courses_count']
                                : int.tryParse(raw['completed_courses_count']
                                        .toString()) ??
                                    0)
                            : 0;
                        Navigator.push(
                          context,
                          SlideUpRoute(
                            page: ReservationTutorProfileScreen(
                              tutorId: tutorId,
                              tutorName: tutorName,
                              tutorImage:
                                  tutorImage.isNotEmpty ? tutorImage : '',
                              tutorVideo: tutorVideo ?? '',
                              description: description ?? '',
                              rating: ratingVal,
                              subjects: subjectsList,
                              completedCourses: completedCourses,
                              tagline: profile['tagline'] ?? '',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'))),
                const SizedBox(width: 12),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
