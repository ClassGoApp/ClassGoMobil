import 'package:flutter/material.dart';
import '../../styles/app_styles.dart';

class HowWeWorkScreen extends StatefulWidget {
  @override
  State<HowWeWorkScreen> createState() => _HowWeWorkScreenState();
}

class _HowWeWorkScreenState extends State<HowWeWorkScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  late AnimationController _animationController;
  final List<Animation<double>> _fadeAnimations = [];

  int _selectedTab = 0; // 0 = Estudiantes, 1 = Tutores

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    // Crear animaciones para diferentes secciones
    // Necesitamos 15 animaciones: 0-1 para tabs/hero, 2-6 para estudiantes, 7-10 para tutores, 12 para footer
    for (int i = 0; i < 15; i++) {
      final start = i * 0.05; // Reducir el intervalo base
      final end = start + 0.25; // Reducir la duración de cada animación
      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              start.clamp(0.0, 0.95), 
              end.clamp(0.0, 1.0), 
              curve: Curves.easeOut
            ),
          ),
        ),
      );
    }

    _animationController.forward();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
          _animationController.reset();
          _animationController.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar con efecto parallax
          _buildParallaxAppBar(),

          // Hero Section con tabs
          SliverToBoxAdapter(
            child: _buildHeroSection(),
          ),

          // Contenido según tab seleccionado
          SliverToBoxAdapter(
            child: _selectedTab == 0
                ? _buildStudentContent()
                : _buildTutorContent(),
          ),

          // Footer
          SliverToBoxAdapter(
            child: _buildFooter(),
          ),

          // Espacio final
          SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildParallaxAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.darkBlue,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Cómo Trabajamos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0E4A63),
                Color(0xFF00B4D8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return AnimatedBuilder(
      animation: _fadeAnimations[1],
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimations[1].value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - _fadeAnimations[1].value)),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0E4A63),
                    Color(0xFF00B4D8),
                  ],
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Curva inferior
                  Positioned(
                    bottom: -1,
                    left: 0,
                    right: 0,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          size: Size(constraints.maxWidth, 50),
                          painter: _CurvedPainter(),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Únete a nuestra comunidad hoy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Únete a nuestra comunidad para compartir tu experiencia como tutor o mejorar tus habilidades como estudiante. Conéctate, aprende y crece con nosotros hoy.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 15,
                            height: 1.6,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 32),
                        // Tabs personalizados
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCustomTab(0, 'Para estudiantes', Icons.school),
                              _buildCustomTab(1, 'Para tutores', Icons.person),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomTab(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _tabController.animateTo(index);
          _animationController.reset();
          _animationController.forward();
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isSelected
              ? Border.all(color: AppColors.orangeColor, width: 2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected && index == 1) ...[
              Icon(icon, color: AppColors.darkBlue, size: 20),
              SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.darkBlue : Colors.white,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentContent() {
    return Column(
      children: [
        _buildStudentStep(
          index: 0,
          icon: Icons.person_add,
          title: 'Completa tus datos y establece tus preferencias de aprendizaje',
          description:
              'Proporciona tus datos personales y establece tus preferencias de aprendizaje para crear un perfil adaptado a tus necesidades educativas. Esto te ayudará a encontrar los tutores más adecuados y optimizar tu experiencia de aprendizaje.',
          imageUrl: 'https://www.classgoapp.com/images/home/Tugotecnol%C3%B3gico.webp',
          hasEagle: true,
        ),
        _buildStudentStep(
          index: 1,
          icon: Icons.search,
          title: 'Utiliza el buscador para ver perfiles detallados de tutores',
          description:
              'Usa la barra de búsqueda para descubrir tutores según el nombre del tutor, la materia o el tema que te interesa. ¡Empieza a escribir y ve cómo aparecen los perfiles que mejor se adaptan a tus necesidades de aprendizaje!',
          imageUrl: 'https://www.classgoapp.com/images/home/Tugoconlaptop.webp',
          isReversed: true,
          hasEagle: true,
        ),
        _buildStudentStep(
          index: 2,
          icon: Icons.calendar_today,
          title: 'Elige un horario conveniente y reserva tu tutoría',
          description:
              'Selecciona un horario disponible y la hora que disponga el tutor. Esto ayuda a mantener tu calendario organizado y asegura que puedas aprender en el momento más conveniente para ti.',
          imageUrl: 'https://www.classgoapp.com/images/home/Tugoprofesor.webp',
          hasEagle: true,
        ),
        _buildStudentStep(
          index: 3,
          icon: Icons.access_time,
          title: 'Inicia tu tutoría a la hora programada y comienza a aprender',
          description:
              'Inicia tu tutoría a la hora programada y únete a la sesión para comenzar a aprender. Conéctate con tu tutor a través de Meet para disfrutar de una tutoría interactiva y atractiva.',
          imageUrl: 'https://www.classgoapp.com/images/home/Tugo_With_Phone.webp',
          isReversed: true,
          hasEagle: true,
        ),
        _buildStudentStep(
          index: 4,
          icon: Icons.star,
          title: 'Rellena un formulario de comentarios rápido después de tu tutoría',
          description:
              'Después de tu tutoría, completa un formulario rápido de feedback para compartir tus opiniones y calificar tu experiencia. Tu feedback nos ayuda a mejorar y garantizar el mejor entorno de aprendizaje para todos.',
          imageUrl: 'https://www.classgoapp.com/images/home/TuGoconMegafono.webp',
          hasEagle: true,
        ),
      ],
    );
  }

  Widget _buildTutorContent() {
    return Column(
      children: [
        _buildTutorStep(
          index: 0,
          icon: Icons.person_add,
          title: 'Crea tu perfil y enumera tus calificaciones',
          description:
              'Crea tu perfil para mostrar tus calificaciones, habilidades y experiencia. Destaca tu formación, experiencia y las materias que enseñas para atraer estudiantes potenciales y generar credibilidad en la plataforma.',
          imageUrl: 'https://www.classgoapp.com/images/home/Tugoprofesor2.webp',
          hasEagle: true,
        ),
        _buildTutorStep(
          index: 1,
          icon: Icons.schedule,
          title: 'Gestiona tu horario para mostrar cuándo estás disponible para enseñar',
          description:
              'Administra fácilmente tu disponibilidad actualizando tu horario con los momentos en los que estás disponible para enseñar. Esto ayuda a los estudiantes a saber cuándo pueden reservar sesiones contigo y mantiene tu calendario organizado.',
          imageUrl: 'https://www.classgoapp.com/images/home/Tugo_With_Glasses2.webp',
          isReversed: true,
          hasEagle: true,
        ),
        _buildTutorStep(
          index: 2,
          icon: Icons.check_circle,
          title: 'Revisa tus reservas',
          description:
              'Mantén un control completo sobre tus sesiones programadas. Revisa las reservas de los estudiantes, gestiona tu calendario y prepárate para cada tutoría con toda la información necesaria.',
          imageUrl: 'https://www.classgoapp.com/images/home/Tugoprofesor.webp',
          hasEagle: true,
        ),
        _buildTutorStep(
          index: 3,
          icon: Icons.video_call,
          title: 'Dirige tu clase con Google Meet',
          description:
              'Conéctate con tus estudiantes a través de Google Meet integrado en nuestra plataforma. Ofrece una experiencia de aprendizaje interactiva y atractiva, utilizando las herramientas de videoconferencia para maximizar el impacto de tus tutorías.',
          imageUrl: 'https://www.classgoapp.com/images/home/Tugo_With_Phone.webp',
          isReversed: true,
          hasEagle: true,
        ),
      ],
    );
  }

  Widget _buildStudentStep({
    required int index,
    required IconData icon,
    required String title,
    required String description,
    String? imageUrl,
    bool isReversed = false,
    bool hasEagle = false,
  }) {
    final animationIndex = index + 2;
    return AnimatedBuilder(
      animation: _fadeAnimations[animationIndex],
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimations[animationIndex].value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - _fadeAnimations[animationIndex].value)),
            child: Container(
              padding: EdgeInsets.all(24),
              color: isReversed ? AppColors.darkBlue : Colors.white,
              child: MediaQuery.of(context).size.width > 600
                  ? (isReversed
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildStepContent(
                                icon: icon,
                                title: title,
                                description: description,
                                isDark: true,
                              ),
                            ),
                            SizedBox(width: 24),
                            Expanded(
                              flex: 3,
                              child: _buildEagleIllustration(imageUrl: imageUrl),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildEagleIllustration(imageUrl: imageUrl),
                            ),
                            SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: _buildStepContent(
                                icon: icon,
                                title: title,
                                description: description,
                                isDark: false,
                              ),
                            ),
                          ],
                        ))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepContent(
                          icon: icon,
                          title: title,
                          description: description,
                          isDark: isReversed,
                        ),
                        SizedBox(height: 24),
                        _buildEagleIllustration(imageUrl: imageUrl),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTutorStep({
    required int index,
    required IconData icon,
    required String title,
    required String description,
    String? imageUrl,
    bool isReversed = false,
    bool hasEagle = false,
  }) {
    final animationIndex = index + 7;
    return AnimatedBuilder(
      animation: _fadeAnimations[animationIndex],
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimations[animationIndex].value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - _fadeAnimations[animationIndex].value)),
            child: Container(
              padding: EdgeInsets.all(24),
              color: isReversed ? AppColors.darkBlue : Colors.white,
              child: MediaQuery.of(context).size.width > 600
                  ? (isReversed
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildStepContent(
                                icon: icon,
                                title: title,
                                description: description,
                                isDark: true,
                              ),
                            ),
                            SizedBox(width: 24),
                            Expanded(
                              flex: 3,
                              child: _buildEagleIllustration(imageUrl: imageUrl),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildEagleIllustration(imageUrl: imageUrl),
                            ),
                            SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: _buildStepContent(
                                icon: icon,
                                title: title,
                                description: description,
                                isDark: false,
                              ),
                            ),
                          ],
                        ))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepContent(
                          icon: icon,
                          title: title,
                          description: description,
                          isDark: isReversed,
                        ),
                        SizedBox(height: 24),
                        _buildEagleIllustration(imageUrl: imageUrl),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepContent({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.lightBlueColor.withOpacity(0.2)
                : AppColors.lightBlueColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isDark ? Colors.white : AppColors.lightBlueColor,
            size: 35,
          ),
        ),
        SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.darkBlue,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.3,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 16),
        Text(
          description,
          style: TextStyle(
            color: isDark
                ? Colors.white.withOpacity(0.9)
                : Colors.grey[700],
            fontSize: 15,
            height: 1.6,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildEagleIllustration({String? imageUrl}) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      height: isMobile ? 220 : 280,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.lightBlueColor,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: isMobile ? 100 : 120,
                        color: Colors.grey[400],
                      ),
                    ),
                  );
                },
              )
            : Container(
                color: Colors.grey[100],
                child: Center(
                  child: Icon(
                    Icons.school,
                    size: isMobile ? 100 : 120,
                    color: Colors.grey[400],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return AnimatedBuilder(
      animation: _fadeAnimations[12],
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimations[12].value,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 60, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF00B4D8),
                  Color(0xFF0E4A63),
                ],
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Garantizamos un proceso de calidad',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Únase a nuestra comunidad hoy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Únase a nuestra comunidad para compartir su experiencia como tutor o mejorar sus habilidades como estudiante.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Conéctese, aprenda y crezca con nosotros hoy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Clase para pintar la curva en la sección hero
class _CurvedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width / 2,
      0,
      size.width,
      size.height,
    );
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

