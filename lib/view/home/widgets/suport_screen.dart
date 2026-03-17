import 'package:flutter/material.dart';
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

  final List<String> faqs = [
    '¿Cómo funcionan las sesiones?',
    '¿Cómo encuentro a un tutor?',
    '¿Es seguro el pago?',
    '¿Puedo ser tutor si soy estudiante?',
    '¿Qué necesito para tomar una clase?',
  ];

  @override
  Widget build(BuildContext context) {
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
        physics: const BouncingScrollPhysics(),
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
                    // Mensaje de Tugo
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
                          '¡Hola! Soy Tugo. Estoy aquí para resolver todas tus dudas sobre ClassGo. ¿Cómo puedo ayudarte hoy?',
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Preguntas Frecuentes'.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'outfit',
                  fontSize: 12, 
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightGreyColor,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ...faqs
                .map((pregunta) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.dividerLight),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        title: Text(
                          pregunta,
                          style: const TextStyle(
                            fontFamily: 'manrope',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandBlue,
                          ),
                        ),
                        trailing: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.lightGreyColor, size: 28),
                        iconColor: AppColors.brandCyan,
                        collapsedIconColor: AppColors.lightGreyColor,
                        children: const [
                          Padding(
                            padding: EdgeInsets.only(
                                left: 16, right: 16, bottom: 20),
                            child: Text(
                              'Esta es una respuesta simulada. Aquí irá la explicación detallada de la pregunta frecuente correspondiente. ¡Muy pronto lo conectaremos a la base de datos!',
                              style: TextStyle(
                                fontFamily: 'manrope',
                                fontSize: 14,
                                color: AppColors.textLightSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            const SizedBox(height: 35),
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
                    onTap: () => debugPrint('Ir a WhatsApp'),
                    color: const Color(0xFF25D366),
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'WhatsApp',
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: AnimatedScaleButton(
                    onTap: () => debugPrint('Ir a Correo'),
                    color: AppColors.brandBlue,
                    icon: Icons.email_outlined,
                    label: 'Correo',
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
}

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
              offset: Offset(0, _isPressed ? 2 : 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'outfit',
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
