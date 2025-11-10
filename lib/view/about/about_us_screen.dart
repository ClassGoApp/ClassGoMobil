import 'package:flutter/material.dart';
import '../../styles/app_styles.dart';

class AboutUsScreen extends StatefulWidget {
  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late AnimationController _scrollAnimationController;
  final List<Animation<double>> _fadeAnimations = [];
  final Map<String, double> _scrollPositions = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _scrollAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    // Crear animaciones para diferentes secciones
    for (int i = 0; i < 11; i++) {
      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(i * 0.08, (i * 0.08) + 0.25, curve: Curves.easeOut),
          ),
        ),
      );
    }

    _animationController.forward();
    // Iniciar animación pulsante infinita después de un delay
    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) {
        _scrollAnimationController.repeat(reverse: true);
      }
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    setState(() {
      _scrollPositions['offset'] = offset;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    _scrollAnimationController.dispose();
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

          // Hero Section - ¿Quiénes Somos?
          SliverToBoxAdapter(
            child: _buildWhoWeAreSection(),
          ),

          // Sección Misión
          SliverToBoxAdapter(
            child: _buildMissionSection(),
          ),

          // Sección Visión
          SliverToBoxAdapter(
            child: _buildVisionSection(),
          ),

          // Sección Nuestro Equipo
          SliverToBoxAdapter(
            child: _buildTeamSection(),
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
          'Nosotros',
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

  Widget _buildWhoWeAreSection() {
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
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Quiénes Somos?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Somos una plataforma de tutorías en línea que conecta a estudiantes de todas las edades con tutores expertos. Ofrecemos una experiencia accesible y de calidad, independientemente de tu ubicación u horario.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 16,
                            height: 1.6,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 32),
                        // Mascota águila (imagen placeholder) con animación de flotación
                        Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(seconds: 2),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 10 * (value - 0.5).abs()),
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.verified_user,
                                    size: 100,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
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

  Widget _buildMissionSection() {
    return AnimatedBuilder(
      animation: _fadeAnimations[2],
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimations[2].value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - _fadeAnimations[2].value)),
            child: Container(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Misión',
                    style: TextStyle(
                      color: AppColors.darkBlue.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Plataforma educativa de tutorías virtuales para compartir conocimientos.',
                    style: TextStyle(
                      color: AppColors.darkBlue,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Proporcionamos una plataforma educativa de tutorías virtuales accesibles las 24 horas, dirigida a toda persona que quiera compartir su conocimiento, con contenidos que abarcan desde nivel universitario hasta habilidades técnicas.',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 15,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 32),
                  // Layout con imagen y badge
                  Stack(
                    children: [
                      // Imagen de misión (primero en el Stack, queda atrás)
                      Container(
                        margin: EdgeInsets.only(right: 60),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            'https://www.classgoapp.com/images/home/mision.webp',
                            width: double.infinity,
                            height: 300,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: double.infinity,
                                height: 300,
                                color: Colors.grey[200],
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
                                width: double.infinity,
                                height: 300,
                                color: Colors.grey[200],
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 100,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Badge circular con animación pulsante (último en el Stack, queda arriba)
                      Positioned(
                        right: 0,
                        top: -20,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 800),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Anillo pulsante infinito
                                AnimatedBuilder(
                                  animation: _scrollAnimationController,
                                  builder: (context, child) {
                                    final animatedValue = 0.8 + (_scrollAnimationController.value * 0.4);
                                    final opacity = 0.3 * (1 - (_scrollAnimationController.value * 0.5));
                                    return Transform.scale(
                                      scale: animatedValue,
                                      child: Container(
                                        width: 140,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Color(0xFF00B4D8).withOpacity(opacity),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Badge principal
                                Transform.scale(
                                  scale: value,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF00B4D8),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFF00B4D8).withOpacity(0.4),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '+200',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Tutorías\ndisponibles',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisionSection() {
    return AnimatedBuilder(
      animation: _fadeAnimations[3],
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimations[3].value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - _fadeAnimations[3].value)),
            child: Container(
              padding: EdgeInsets.all(24),
              color: Colors.grey[50],
              child: MediaQuery.of(context).size.width > 600
                  ? Row(
                      children: [
                        // Imagen a la izquierda
                        Expanded(
                          flex: 3,
                          child: Stack(
                            children: [
                        Container(
                          height: 350,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              'https://www.classgoapp.com/images/home/vision.webp',
                              width: double.infinity,
                              height: 350,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: double.infinity,
                                  height: 350,
                                  color: Colors.grey[200],
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
                                  width: double.infinity,
                                  height: 350,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 120,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Efecto de capas
                        Positioned(
                          right: -10,
                          top: 10,
                          child: Container(
                            width: 150,
                            height: 280,
                            decoration: BoxDecoration(
                              color: (Colors.grey[300] ?? Colors.grey).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -20,
                          top: 20,
                          child: Container(
                            width: 150,
                            height: 280,
                            decoration: BoxDecoration(
                              color: (Colors.grey[400] ?? Colors.grey).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                        SizedBox(width: 24),
                        // Texto a la derecha
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Visión',
                                style: TextStyle(
                                  color: AppColors.darkBlue.withOpacity(0.7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Impulsar el crecimiento del aprendizaje.',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: AppColors.darkBlue,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Ser la plataforma líder en tutorías virtuales, fomentando el aprendizaje continuo y la accesibilidad educativa en todas las áreas del conocimiento.',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 15,
                                  height: 1.6,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Texto primero en móvil
                        Text(
                          'Visión',
                          style: TextStyle(
                            color: AppColors.darkBlue.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Impulsar el crecimiento del aprendizaje.',
                          style: TextStyle(
                            color: AppColors.darkBlue,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Ser la plataforma líder en tutorías virtuales, fomentando el aprendizaje continuo y la accesibilidad educativa en todas las áreas del conocimiento.',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 15,
                            height: 1.6,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 24),
                        // Imagen después en móvil
                        Stack(
                          children: [
                            Container(
                              height: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  'https://www.classgoapp.com/images/home/vision.webp',
                                  width: double.infinity,
                                  height: 300,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: double.infinity,
                                      height: 300,
                                      color: Colors.grey[200],
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
                                      width: double.infinity,
                                      height: 300,
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 100,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            // Efecto de capas
                            Positioned(
                              right: -10,
                              top: 10,
                              child: Container(
                                width: 150,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: (Colors.grey[300] ?? Colors.grey).withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                            Positioned(
                              right: -20,
                              top: 20,
                              child: Container(
                                width: 150,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: (Colors.grey[400] ?? Colors.grey).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamSection() {
    return AnimatedBuilder(
      animation: _fadeAnimations[4],
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimations[4].value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - _fadeAnimations[4].value)),
            child: Container(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Nuestro equipo',
                    style: TextStyle(
                      color: AppColors.darkBlue,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Los creadores de la página y app de ClassGo, dedicados a revolucionar la educación.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 32),
                  // Grid de miembros del equipo
                  _buildTeamMemberCard(
                    name: 'Gabriel Alpiry Hurtado',
                    role: 'CEO & Founder',
                    imageUrl: 'https://www.classgoapp.com/images/team/gabriel.jpeg',
                    index: 5,
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildTeamMemberCard(
                          name: 'Daniel',
                          role: 'General Coordinador',
                          imageUrl: 'https://www.classgoapp.com/images/team/daniel.webp',
                          index: 6,
                          isSmall: true,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildTeamMemberCard(
                          name: 'Alvaro Rojas',
                          role: 'Mobile Developer',
                          imageUrl: 'https://www.classgoapp.com/images/team/alvaro.webp',
                          index: 7,
                          isSmall: true,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildTeamMemberCard(
                          name: 'Carlos Mamani Torrez',
                          role: 'Frontend Developer',
                          imageUrl: 'https://www.classgoapp.com/images/team/carlos.webp',
                          index: 8,
                          isSmall: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  _buildTeamMemberCard(
                    name: 'Jhonny',
                    role: 'Team Member',
                    imageUrl: 'https://www.classgoapp.com/images/team/jhonny.webp',
                    index: 9,
                    isSmall: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamMemberCard({
    required String name,
    required String role,
    required int index,
    String? imageUrl,
    bool isSmall = false,
  }) {
    return AnimatedBuilder(
      animation: _fadeAnimations[index],
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimations[index].value,
          child: Transform.scale(
            scale: 0.8 + (_fadeAnimations[index].value * 0.2),
            child: Container(
              margin: EdgeInsets.only(bottom: isSmall ? 0 : 16),
              child: Column(
                children: [
                  Container(
                    width: isSmall ? 100 : 150,
                    height: isSmall ? 100 : 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.lightBlueColor,
                          Color(0xFF00B4D8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.lightBlueColor.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              width: isSmall ? 100 : 150,
                              height: isSmall ? 100 : 150,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: isSmall ? 100 : 150,
                                  height: isSmall ? 100 : 150,
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: AppColors.lightBlueColor,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.person,
                                    size: isSmall ? 50 : 80,
                                    color: Colors.grey[400],
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                size: isSmall ? 50 : 80,
                                color: Colors.grey[400],
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.darkBlue,
                      fontSize: isSmall ? 14 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    role,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isSmall ? 12 : 14,
                      fontWeight: FontWeight.w500,
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

