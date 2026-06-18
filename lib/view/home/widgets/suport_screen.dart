import 'package:flutter/material.dart';
import 'package:flutter_projects/helpers/social_media_launcher.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatingController;
  late final Animation<double> _floatingAnimation;

  bool _showForStudents = true;
  int? _expandedIndex;

  final Map<String, List<Map<String, String>>> faqsData = {
    'estudiantes': [
      {
        'q': '¿Cómo encontrar un tutor?',
        'a':
            'Utilice la barra de búsqueda para encontrar tutores disponibles según la materia o tema que necesites.'
      },
      {
        'q': '¿Cómo reservo una sesión?',
        'a':
            'Una vez que encuentres un tutor, consulta su perfil y selecciona un horario disponible que te convenga. Haz clic en "Reservar” y sigue las instrucciones para confirmar tu sesión.'
      },
      {
        'q': '¿Qué pasa si necesito cancelar o reprogramar?',
        'a':
            'Las tutorías no pueden cancelarse una vez reservadas. Si ocurrió algún inconveniente, contáctanos y con gusto te ayudaremos.'
      },
      {
        'q': '¿Cómo pago las sesiones?',
        'a':
            'Los pagos se realizan a través del QR proporcionado en tu reserva o también por transferencia bancaria con los datos que se muestran en pantalla.'
      },
      {
        'q': '¿Qué debo hacer si mi tutor no se presenta?',
        'a':
            'Si tu tutor no se presenta a una sesión programada, comunícate con soporte de inmediato para obtener ayuda y agendar una reprogramación o un reembolso.'
      },
      {
        'q': '¿Cómo puedo dejar comentarios?',
        'a':
            'Entra al perfil del tutor, desliza hacia abajo y dirígete a la sección de reseñas, donde podrás ver las calificaciones y comentarios de los estudiantes.'
      },
    ],
    'tutores': [
      {
        'q': '¿Cómo puedo ser tutor?',
        'a':
            'Crea una cuenta, rellena el formulario y al final selecciona "Tutor". Crea tu perfil y envía la documentación necesaria para su aprobación.'
      },
      {
        'q': '¿Qué cualificaciones necesito para ser tutor?',
        'a':
            'No es requisito tener titulación académica. Si quieres enseñar "algo" puedes hacerlo.'
      },
      {
        'q': '¿Cómo configuro mi disponibilidad?',
        'a':
            'Inicia sesión en tu cuenta, accede a la sección “Administrar tiempo disponible” y actualiza tu calendario con tus franjas horarias disponibles.'
      },
      {
        'q': '¿Qué debo hacer si un estudiante cancela?',
        'a':
            'Los estudiantes no tienen la opción de cancelar una sesión después de reservarla. Si el alumno te informa de algún problema, recomiéndale escribir a nuestro contacto para recibir ayuda.'
      },
    ]
  };

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentFaqs =
        _showForStudents ? faqsData['estudiantes']! : faqsData['tutores']!;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_rounded, color: AppColors.brandBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Centro de Ayuda',
          style: TextStyle(
            fontFamily: 'outfit',
            fontWeight: FontWeight.bold,
            color: AppColors.brandBlue,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(
              height: 140,
              child: AnimatedBuilder(
                animation: _floatingAnimation,
                builder: (context, child) {
                  return Padding(
                    padding: EdgeInsets.only(top: _floatingAnimation.value),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/logoespecial.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.brandCyan.withOpacity(0.08),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(24),
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        child: const Text(
                          '¡Hola! Soy Tugo. Estoy aquí para resolver todas tus dudas sobre ClassGo. ¿Cómo puedo ayudarte?',
                          style: TextStyle(
                            fontFamily: 'manrope',
                            fontSize: 14,
                            color: AppColors.brandBlue,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 35),
            Row(
              children: [
                Expanded(
                  child: _buildRoleSelector(
                    title: 'Estudiantes',
                    icon: Icons.school_rounded,
                    isSelected: _showForStudents,
                    onTap: () => setState(() {
                      _showForStudents = true;
                      _expandedIndex = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRoleSelector(
                    title: 'Tutores',
                    icon: Icons.work_rounded,
                    isSelected: !_showForStudents,
                    onTap: () => setState(() {
                      _showForStudents = false;
                      _expandedIndex = null;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentFaqs.length,
              itemBuilder: (context, index) {
                final faq = currentFaqs[index];
                final isExpanded = _expandedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedIndex = isExpanded ? null : index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isExpanded ? Colors.white : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isExpanded
                            ? AppColors.brandCyan.withOpacity(0.5)
                            : AppColors.dividerLight,
                      ),
                      boxShadow: isExpanded
                          ? [
                              BoxShadow(
                                  color: AppColors.brandBlue.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                faq['q']!,
                                style: TextStyle(
                                  fontFamily: 'manrope',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isExpanded
                                      ? AppColors.brandOrange
                                      : AppColors.brandBlue,
                                ),
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: isExpanded
                                  ? AppColors.brandOrange
                                  : AppColors.lightGreyColor,
                            ),
                          ],
                        ),
                        AnimatedCrossFade(
                          firstChild:
                              const SizedBox(width: double.infinity, height: 0),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              faq['a']!,
                              style: const TextStyle(
                                fontFamily: 'manrope',
                                fontSize: 14,
                                color: AppColors.textLightSecondary,
                                height: 1.6,
                              ),
                            ),
                          ),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 250),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Contacto Directo'.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightGreyColor,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AnimatedScaleButton(
                    onTap: () => LauncherHelper.launchEmail(
                        email: "classgobol@gmail.com"),
                    color: AppColors.brandBlue,
                    icon: Icons.email_outlined,
                    label: 'Correo',
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: AnimatedScaleButton(
                    onTap: () => LauncherHelper.launchWhatsApp(
                        phone: "59177573997",
                        message: "Hola ClassGo! Necesito ayuda con..."),
                    color: const Color(0xFF25D366),
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'WhatsApp',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper para el selector de roles (Estudiante/Tutor)
  Widget _buildRoleSelector(
      {required String title,
      required IconData icon,
      required bool isSelected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandCyan.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? AppColors.brandCyan : AppColors.dividerLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: isSelected
                    ? AppColors.brandCyan
                    : AppColors.lightGreyColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'outfit',
                fontWeight: FontWeight.bold,
                color:
                    isSelected ? AppColors.brandCyan : AppColors.lightGreyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// BOTÓN ANIMADO INTACTO (Sin cambios)
class AnimatedScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color color;
  final IconData icon;
  final String label;

  const AnimatedScaleButton({
    super.key,
    required this.onTap,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  State<AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isPressed ? 0.94 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: widget.color.withOpacity(_isPressed ? 0.1 : 0.25),
                blurRadius: _isPressed ? 5 : 20,
                offset: Offset(0, _isPressed ? 2 : 10)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(widget.label,
                style: const TextStyle(
                    fontFamily: 'outfit',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
