import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class TeamMember {
  final int id;
  final String name;
  final String lastName;
  final String fullName;
  final String role;
  final int order;
  final String platform;
  final String? platformLink;
  final String? photo;

  TeamMember({
    required this.id,
    required this.name,
    required this.lastName,
    required this.fullName,
    required this.role,
    required this.order,
    required this.platform,
    this.platformLink,
    this.photo,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'],
      name: json['name'],
      lastName: json['last_name'],
      fullName: json['full_name'],
      role: json['role'],
      order: json['order'],
      platform: json['platform'],
      platformLink: json['platform_link'],
      photo: json['photo'],
    );
  }
}

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  static const String _titleFont = 'outfit';
  static const String _bodyFont = 'manrope';

  late Future<List<TeamMember>> _teamFuture;

  @override
  void initState() {
    super.initState();
    _teamFuture = getTeamMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF023047)),
        title: const Text(
          'Sobre Nosotros',
          style: TextStyle(
            fontFamily: _titleFont,
            color: Color(0xFF023047),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF023047), Color(0xFF0E3A4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF023047).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      right: -50,
                      bottom: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.03),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      top: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.03),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 40, horizontal: 24),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/tugo2.webp',
                            height: 140,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 80,
                                width: 80,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFB8500).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFFB8500)
                                          .withOpacity(0.5),
                                      width: 2),
                                ),
                                child: const Icon(Icons.rocket_launch_rounded,
                                    size: 48, color: Color(0xFFFB8500)),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Tu futuro empieza hoy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: _titleFont,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Diseñando la nueva era de la educación',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: _bodyFont,
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      width: 4,
                      height: 80,
                      decoration: BoxDecoration(
                          color: const Color(0xFF219EBC),
                          borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('¿Quiénes Somos?',
                            style: TextStyle(
                                fontFamily: _titleFont,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF023047))),
                        const SizedBox(height: 8),
                        Text(
                          'Somos una plataforma de tutorías en línea que conecta a estudiantes de todas las edades con tutores expertos. Ofrecemos una experiencia accesible y de calidad, independientemente de tu ubicación u horario.',
                          style: TextStyle(
                              fontFamily: _bodyFont,
                              fontSize: 15,
                              height: 1.6,
                              color: Colors.black.withOpacity(0.75)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _buildModernInfoCard(
                icon: Icons.flag_rounded,
                iconColor: const Color(0xFF219EBC),
                title: 'Nuestra Misión',
                subtitle: 'Compartir conocimientos sin barreras.',
                bodyText:
                    'Proporcionamos una plataforma educativa de tutorías virtuales accesibles las 24 horas, dirigida a toda persona que quiera compartir su conocimiento, con contenidos que abarcan desde nivel universitario hasta habilidades técnicas.',
              ),
              _buildModernInfoCard(
                icon: Icons.visibility_rounded,
                iconColor: const Color(0xFFFB8500),
                title: 'Nuestra Visión',
                subtitle: 'Impulsar el crecimiento del aprendizaje.',
                bodyText:
                    'Ser la plataforma líder en tutorías virtuales, fomentando el aprendizaje continuo y la accesibilidad educativa en todas las áreas del conocimiento a nivel global.',
              ),
              const SizedBox(height: 10),
              Divider(color: Colors.grey.withOpacity(0.2), thickness: 1),
              const SizedBox(height: 20),
              const Text('Nuestro Equipo',
                  style: TextStyle(
                      fontFamily: _titleFont,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF023047))),
              const SizedBox(height: 20),
              FutureBuilder<List<TeamMember>>(
                future: _teamFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFFFB8500))));
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 40),
                            const SizedBox(height: 10),
                            Text('Error al cargar el equipo',
                                style: TextStyle(
                                    fontFamily: _bodyFont, color: Colors.red)),
                            TextButton(
                              onPressed: () => setState(
                                  () => _teamFuture = getTeamMembers()),
                              child: const Text("Reintentar"),
                            )
                          ],
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text("Aún no hay miembros registrados."));
                  }

                  final team = snapshot.data!;
                  final sortedTeam = List<TeamMember>.from(team)
                    ..sort((a, b) => a.order.compareTo(b.order));

                  final ceo = sortedTeam.isNotEmpty ? sortedTeam[0] : null;
                  final po = sortedTeam.length > 1 ? sortedTeam[1] : null;
                  final coordinators = sortedTeam.length > 2
                      ? sortedTeam.sublist(2)
                      : <TeamMember>[];

                  return Column(
                    children: [
                      if (ceo != null)
                        _TeamCardHero(
                            member: ceo,
                            titleFont: _titleFont,
                            bodyFont: _bodyFont),
                      const SizedBox(height: 20),
                      if (po != null)
                        _TeamCardListStyle(
                            member: po,
                            titleFont: _titleFont,
                            bodyFont: _bodyFont),
                      const SizedBox(height: 20),
                      if (coordinators.isNotEmpty)
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: coordinators.length,
                          itemBuilder: (context, index) {
                            return _TeamCardGridStyle(
                                member: coordinators[index],
                                titleFont: _titleFont,
                                bodyFont: _bodyFont);
                          },
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoCard(
      {required IconData icon,
      required Color iconColor,
      required String title,
      required String subtitle,
      required String bodyText}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: 4, color: iconColor)),
          Positioned(
              right: -10,
              bottom: -10,
              child: Icon(icon, size: 120, color: iconColor.withOpacity(0.04))),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14)),
                      child: Icon(icon, color: iconColor, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Text(title,
                        style: TextStyle(
                            fontFamily: _titleFont,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF023047))),
                  ],
                ),
                const SizedBox(height: 20),
                Text(subtitle,
                    style: const TextStyle(
                        fontFamily: _titleFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                const SizedBox(height: 8),
                Text(bodyText,
                    style: TextStyle(
                        fontFamily: _bodyFont,
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.black.withOpacity(0.65))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final TeamMember member;
  final double radius;
  final double fontSize;
  // TODO: Cambiar de vuelta a Image.network(member.photo) cuando el backend esté listo
  static const Map<String, String> memberImageMap = {
    'Gabriel': 'assets/images/home/team/Gabriel.jpeg',
    'Jhonny': 'assets/images/home/team/Jhonny.webp',
    'Oscar': 'assets/images/home/team/Oscar.png',
    'Mireya': 'assets/images/home/team/Mireya.png',
    'Sebastian': 'assets/images/home/team/Sebastian.png',
  };

  const _MemberAvatar(
      {required this.member, required this.radius, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE3F2FD),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildAvatarImage(),
    );
  }

  Widget _buildAvatarImage() {
    // Obtener imagen local mapeada por nombre del miembro
    final String? localImage = memberImageMap[member.name];

    if (localImage != null) {
      return Image.asset(
        localImage,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error cargando imagen local: $localImage - $error');
          return _buildInitials();
        },
      );
    }

    // Si no hay mapeo, mostrar iniciales
    return _buildInitials();
  }

  /// Muestra las iniciales del nombre como fallback
  Widget _buildInitials() {
    return Center(
      child: Text(
        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: const Color(0xFF023047),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TeamCardHero extends StatelessWidget {
  final TeamMember member;
  final String titleFont;
  final String bodyFont;

  const _TeamCardHero(
      {required this.member, required this.titleFont, required this.bodyFont});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMemberModal(context, member, titleFont, bodyFont),
      child: Container(
        height: 180,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
              colors: [Color(0xFF023047), Color(0xFF219EBC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF219EBC).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Stack(
          children: [
            Positioned(
                right: -30,
                top: -30,
                child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1)))),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFB8500),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(member.role.toUpperCase(),
                              style: TextStyle(
                                  fontFamily: titleFont,
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0)),
                        ),
                        const SizedBox(height: 12),
                        Text(member.fullName,
                            style: TextStyle(
                                fontFamily: titleFont,
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white),
                    child:
                        _MemberAvatar(member: member, radius: 40, fontSize: 28),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamCardListStyle extends StatelessWidget {
  final TeamMember member;
  final String titleFont;
  final String bodyFont;

  const _TeamCardListStyle(
      {required this.member, required this.titleFont, required this.bodyFont});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showMemberModal(context, member, titleFont, bodyFont),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: const Border(
              left: BorderSide(color: Color(0xFFFB8500), width: 4)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          children: [
            _MemberAvatar(member: member, radius: 32, fontSize: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.fullName,
                      style: TextStyle(
                          fontFamily: titleFont,
                          color: const Color(0xFF023047),
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(member.role,
                      style: TextStyle(
                          fontFamily: bodyFont,
                          color: const Color(0xFF219EBC),
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFF4F4FB),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_forward_ios,
                  color: Color(0xFF023047), size: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamCardGridStyle extends StatelessWidget {
  final TeamMember member;
  final String titleFont;
  final String bodyFont;

  const _TeamCardGridStyle(
      {required this.member, required this.titleFont, required this.bodyFont});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showMemberModal(context, member, titleFont, bodyFont),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 6))
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                    height: 6,
                    decoration: const BoxDecoration(
                        color: Color(0xFF219EBC),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20))))),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF219EBC).withOpacity(0.3),
                            width: 2)),
                    child:
                        _MemberAvatar(member: member, radius: 35, fontSize: 24),
                  ),
                  const SizedBox(height: 16),
                  Text(member.name,
                      style: TextStyle(
                          fontFamily: titleFont,
                          color: const Color(0xFF023047),
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(member.role,
                      style: TextStyle(
                          fontFamily: bodyFont,
                          color: const Color(0xFF585858),
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showMemberModal(BuildContext context, TeamMember member, String titleFont,
    String bodyFont) {
  final bool hasLink =
      member.platformLink != null && member.platformLink!.isNotEmpty;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: const Color(0xFFEAEAEA),
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            _MemberAvatar(member: member, radius: 55, fontSize: 36),
            const SizedBox(height: 16),
            Text(member.fullName,
                style: TextStyle(
                    fontFamily: titleFont,
                    color: const Color(0xFF023047),
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(member.role,
                style: TextStyle(
                    fontFamily: bodyFont,
                    color: const Color(0xFFFB8500),
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasLink
                    ? () async {
                        final Uri url = Uri.parse(member.platformLink!);
                        try {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        } catch (e) {
                          debugPrint('Error al intentar abrir la URL: $e');
                        }
                      }
                    : null,
                icon: Icon(hasLink ? Icons.link : Icons.link_off,
                    color: hasLink ? Colors.white : Colors.grey.shade500),
                label: Text(
                  hasLink
                      ? "Perfil en ${member.platform}"
                      : "Sin enlace configurado",
                  style: TextStyle(
                      fontFamily: titleFont,
                      color: hasLink ? Colors.white : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF023047),
                  disabledBackgroundColor: Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}
