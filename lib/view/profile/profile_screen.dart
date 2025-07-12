import 'dart:math';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/auth/login_screen.dart';
import 'package:flutter_projects/view/billing/billing_information.dart';
import 'package:flutter_projects/view/insights/insights_screen.dart';
import 'package:flutter_projects/view/invoice/invoice_screen.dart';
import 'package:flutter_projects/view/payouts/payout_history.dart';
import 'package:flutter_projects/view/profile/profile_setting_screen.dart';
import 'package:flutter_projects/view/profile/skeleton/profile_image_skeleton.dart';
import 'package:flutter_projects/view/settings/account_settings.dart';
import 'package:flutter_projects/view/tutor/certificate/certificate_detail.dart';
import 'package:flutter_projects/view/tutor/education/education_details.dart';
import 'package:flutter_projects/view/tutor/experience/experience_detail.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../provider/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profileData;
  String? profileImageUrl;
  bool isLoading = true;
  List<Map<String, dynamic>> _completedSessions = [];
  int _totalHours = 0;
  String _favoriteSubject = 'Sin materia';
  String? _favoriteSubjectId;
  int _totalTutorias = 0;
  Map<String, dynamic>? _lastSession;

  // Mapa de ejemplo para materias (ahora con claves String)
  final Map<String, String> subjectNames = {
    '200': 'Matemáticas',
    '201': 'Inglés',
    '202': 'Física',
    '203': 'Química',
    '204': 'Historia',
    // ... agrega más según tu base de datos
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProfile();
      _fetchBookings();
    });
  }

  Future<void> _fetchProfile() async {
    print('ENTRANDO A _fetchProfile');
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('authProvider: $authProvider');
      final token = authProvider.token;
      final userId = authProvider.userData?['user']?['id'];
      print('token: $token, userId: $userId');
      if (token != null && userId != null) {
        try {
          final response = await getProfile(token, userId);
          final data = response['data'];
          // Obtener imagen real de perfil
          final imageUrl = await _fetchProfileImage(userId);
          setState(() {
            profileData = data;
            profileImageUrl = imageUrl;
            isLoading = false;
          });
        } catch (e) {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('ERROR EN _fetchProfile: $e');
    }
  }

  Future<String?> _fetchProfileImage(int userId) async {
    try {
      final url = 'https://classgoapp.com/api/user/$userId/profile-image';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['profile_image'];
      }
    } catch (_) {}
    return null;
  }

  Future<void> _fetchBookings() async {
    print('ENTRANDO A _fetchBookings');
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('authProvider: $authProvider');
      final token = authProvider.token;
      final userId = authProvider.userData?['user']?['id'];
      print('token: $token, userId: $userId');
      if (token != null && userId != null) {
        try {
          final url = 'https://classgoapp.com/api/user/$userId/bookings';
          final response = await http.get(Uri.parse(url), headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          });
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            print('RESPONSE BODY:');
            print(response.body);
            print('DECODED DATA:');
            print(data);
            final List bookings = data;
            print('BOOKINGS:');
            print(bookings);
            for (var b in bookings) {
              print(
                  'Status: "${b['status']}" - subject_id: ${b['subject_id']}');
            }
            // Filtrar solo las tutorías completadas
            final completed = bookings.where((b) {
              final status = (b['status'] ?? '').toString().toLowerCase();
              return status == 'completado';
            }).toList();
            print('COMPLETED:');
            print(completed);
            // Calcular total de horas (20 min por tutoría)
            int totalTutorias = completed.length;
            int totalMinutes = totalTutorias * 20;
            // Contar materias por subject_id
            print('ANTES DE CONTAR MATERIAS');
            Map<String, int> subjectCount = {};
            for (var b in completed) {
              final subjectId = b['subject_id']?.toString();
              if (subjectId != null) {
                subjectCount[subjectId] = (subjectCount[subjectId] ?? 0) + 1;
              }
            }
            print('subjectCount: $subjectCount');

            print('ANTES DE BUSCAR MATERIA FAVORITA');
            String? favSubjectId;
            int maxCount = 0;
            subjectCount.forEach((k, v) {
              if (v > maxCount) {
                favSubjectId = k;
                maxCount = v;
              }
            });
            print('favSubjectId: $favSubjectId');

            print('ANTES DE ORDENAR COMPLETED');
            Map<String, dynamic>? lastSession;
            if (completed.isNotEmpty) {
              completed.sort((a, b) {
                final aDate =
                    DateTime.tryParse(a['end_time'] ?? a['start_time'] ?? '') ??
                        DateTime(2000);
                final bDate =
                    DateTime.tryParse(b['end_time'] ?? b['start_time'] ?? '') ??
                        DateTime(2000);
                return bDate.compareTo(aDate);
              });
              lastSession = completed.first;
            }
            print('lastSession: $lastSession');
            // Actualizar nombre real de materia favorita
            if (favSubjectId != null) {
              _fetchSubjectName(favSubjectId!).then((realName) {
                if (mounted) {
                  setState(() {
                    _favoriteSubject = realName;
                    _favoriteSubjectId = favSubjectId;
                  });
                }
              });
            } else {
              setState(() {
                _favoriteSubject = 'Sin materia';
                _favoriteSubjectId = null;
              });
            }
            // Materia favorita
            String favSubject = favSubjectId != null
                ? (subjectNames[favSubjectId!] ?? 'Materia $favSubjectId')
                : 'Sin materia';
            setState(() {
              _completedSessions = List<Map<String, dynamic>>.from(completed);
              _totalHours = (totalMinutes / 60).floor();
              _favoriteSubject = favSubject;
              _totalTutorias = totalTutorias;
              _lastSession = lastSession;
            });
          }
        } catch (e) {
          print('ERROR EN _fetchBookings (API): $e');
        }
      }
    } catch (e) {
      print('ERROR EN _fetchBookings: $e');
    }
  }

  Future<String> _fetchSubjectName(String subjectId) async {
    try {
      final url = 'https://classgoapp.com/api/subject/$subjectId/name';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['name'] ?? 'Materia $subjectId';
      }
    } catch (_) {}
    return 'Materia $subjectId';
  }

  Future<void> _onAvatarTap() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading:
                      Icon(Icons.visibility, color: AppColors.lightBlueColor),
                  title: Text('Ver foto de perfil',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _verFotoPerfil();
                  },
                ),
                ListTile(
                  leading:
                      Icon(Icons.photo_camera, color: AppColors.yellowColor),
                  title: Text('Cambiar foto de perfil',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _cambiarFotoPerfil();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _verFotoPerfil() {
    if ((profileImageUrl ?? '').isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(profileImageUrl!, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cambiarFotoPerfil() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userData?['user']?['id'];
    if (userId == null) return;
    try {
      final uri =
          Uri.parse('https://classgoapp.com/api/user/$userId/profile-image');
      final request = http.MultipartRequest('POST', uri);
      request.files
          .add(await http.MultipartFile.fromPath('image', picked.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        // Recargar la imagen
        final imageUrl = await _fetchProfileImage(userId);
        setState(() {
          profileImageUrl = imageUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto de perfil actualizada')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar la foto de perfil')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la foto de perfil')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('BUILD PROFILE');
    final user = profileData;
    final profile = user?['profile'] ?? {};
    final avatarUrl = profileImageUrl ?? profile['image'] ?? '';
    final nombre =
        (profile['first_name'] ?? '') + ' ' + (profile['last_name'] ?? '');
    final email = user?['email'] ?? '';
    final nivel = profile['level']?.toString() ?? '1';
    final progreso = (profile['progress'] ?? 0) / 100.0;
    final badges = profile['badges'] ?? [];
    final tutoriasCompletadas =
        profile['completed_sessions']?.toString() ?? '0';
    final racha = profile['streak']?.toString() ?? '0';
    final diasActivos = profile['active_days']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: isLoading
          ? Container(
              width: double.infinity,
              height: double.infinity,
              color: AppColors.primaryGreen,
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.6,
                  child: Image.asset(
                    'assets/images/cargando.gif',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header colorido y avatar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.lightBlueColor,
                              AppColors.primaryGreen,
                              AppColors.yellowColor.withOpacity(0.7)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(50),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.lightBlueColor.withOpacity(0.18),
                              blurRadius: 30,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 38.0),
                            child: Text(
                              'Mi Perfil',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 120,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _onAvatarTap,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryGreen
                                        .withOpacity(0.25),
                                    blurRadius: 18,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white,
                                  width: 5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 56,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 52,
                                  backgroundImage: avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl.isEmpty
                                      ? Icon(Icons.person,
                                          size: 54,
                                          color: AppColors.lightBlueColor)
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                      height:
                          70), // Espacio para que el avatar no tape el contenido
                  Text(
                    nombre.trim().isEmpty ? 'Usuario' : nombre,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightBlueColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    email,
                    style:
                        TextStyle(color: AppColors.primaryGreen, fontSize: 15),
                  ),
                  SizedBox(height: 18),
                  // Progreso y resumen de actividad visual
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18.0, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            '¡Sigue aprendiendo, ${nombre.split(' ').first}!',
                            style: TextStyle(
                              color: AppColors.yellowColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ActivityCard(
                              icon: Icons.access_time,
                              color: AppColors.lightBlueColor,
                              title: '${_totalHours}h',
                              subtitle: 'Aprendidas',
                            ),
                            SizedBox(width: 10),
                            _ActivityCard(
                              icon: Icons.star,
                              color: AppColors.yellowColor,
                              title: _favoriteSubject,
                              subtitle: 'Favorita',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 22),
                  // Estadísticas rápidas
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatCard(
                            icon: Icons.check_circle,
                            label: 'Tutorías',
                            value: _totalTutorias.toString()),
                        _StatCard(
                            icon: Icons.local_fire_department,
                            label: 'Racha',
                            value: '$racha días'),
                        _StatCard(
                            icon: Icons.calendar_today,
                            label: 'Días activo',
                            value: diasActivos),
                      ],
                    ),
                  ),
                  SizedBox(height: 28),
                  // Acciones rápidas
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        _ActionButton(
                          icon: Icons.edit,
                          label: 'Editar perfil',
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ProfileSettingsScreen()));
                          },
                          background: AppColors.darkBlue,
                          textColor: Colors.white,
                        ),
                        _ActionButton(
                          icon: Icons.lock,
                          label: 'Cambiar contraseña',
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AccountSettings()));
                          },
                          background: AppColors.darkBlue,
                          textColor: Colors.white,
                        ),
                        _ActionButton(
                          icon: Icons.logout,
                          label: 'Cerrar sesión',
                          onTap: () {
                            final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false);
                            authProvider.clearToken();
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginScreen()));
                          },
                          color: Colors.red,
                          background: AppColors.darkBlue,
                          textColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 36),
                  SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      color: AppColors.lightBlueColor.withOpacity(0.93),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        child: Column(
          children: [
            Icon(icon, color: AppColors.yellowColor, size: 28),
            SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? background;
  final Color? textColor;
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color,
      this.background,
      this.textColor});
  @override
  Widget build(BuildContext context) {
    return Card(
      color: background ?? Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color ?? AppColors.primaryGreen),
        title: Text(label,
            style: TextStyle(
                color: textColor ?? color ?? AppColors.primaryGreen,
                fontWeight: FontWeight.bold)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _ActivityCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.13),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 6),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
