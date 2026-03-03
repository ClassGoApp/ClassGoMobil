import 'package:flutter/material.dart';
import 'package:flutter_projects/view/tutor/profile/video_presentation_modal.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_projects/styles/app_styles.dart';

// PROVIDERS Y WIDGETS
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/view/tutor/dashboard/widgets/tutor_header-.dart';

class TutorProfileScreen extends StatelessWidget {
  const TutorProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Extracción de datos
    final user = authProvider.userData?['user'];
    final String userName = user != null ? (user['name'] ?? 'Sarah Jenkins') : 'Sarah Jenkins';
    String? photoUrl = user?['profile']?['image'] ?? user['profile']?['profile_image'];

    // --- COLORES EXACTOS PARA EL EFECTO "ISLA FLOTANTE" ---
    // Fondo de la App: Negro puro en oscuro, Grisáceo en claro
    final scaffoldBg = isDark ? const Color(0xFF0C0E12) : const Color(0xFFF4F6F9); 
    // Contenedor Isla: Gris oscuro mate en oscuro, Blanco puro en claro
    final cardBgColor = isDark ? const Color(0xFF16181D) : Colors.white; 
    
    final mainTextColor = isDark ? Colors.white : AppColors.brandBlue;


String _getShortName(String fullName) {
  if (fullName.trim().isEmpty) return "Tutor";
  
  // Dividimos el nombre por espacios en una lista de palabras
  List<String> parts = fullName.trim().split(RegExp(r'\s+'));
  
  // CASO 1: Solo puso un nombre (Ej: "Diego")
  if (parts.length == 1) {
    return parts[0]; 
  } 
  // CASO 2: Puso nombre y un apellido (Ej: "Diego Perez")
  else if (parts.length == 2) {
    return "${parts[0]} ${parts[1]}"; 
  } 
  // CASO 3: Tiene 3 o más palabras (Ej: "Diego Armando Perez" o "Diego Armando Perez Garcia")
  else {
    // Tomamos la 1ra palabra (Nombre) y la 3ra palabra (Primer Apellido)
    // parts[0] = "Diego", parts[1] = "Armando", parts[2] = "Perez", parts[3] = "Garcia"
    return "${parts[0]} ${parts[2]}"; 
  }
}

// Lo aplicamos a nuestra variable
final String shortName = _getShortName(userName);
    return Scaffold(
      backgroundColor: scaffoldBg, // Fondo principal (Pantalla)
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER (Separado en la parte superior)
            TutorHeader(
              title: "Mi Perfil",
              onBackTap: () => Navigator.maybePop(context),
              onLogoutTap: () {
                print("Cerrar Sesión");
                // authProvider.logout();
              },
            ),

            // 2. CONTENIDO DESPLAZABLE CON LA ISLA FLOTANTE
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                // Margen inferior para el navbar flotante
                padding: const EdgeInsets.only(bottom: 120), 
                child: Padding(
                  // MÁRGENES LATERALES PARA QUE EL CONTENEDOR FLOTE (El espacio del croquis)
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      // --- A. EL CONTENEDOR FLOTANTE (ISLA) ---
                      Container(
                        margin: const EdgeInsets.only(top: 60), // Empuja la caja hacia abajo para que la foto sobresalga arriba
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(40), // Bordes redondeados en TODOS los lados
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 80, 20, 40), // Padding interno (el top es grande por la foto)
                          child: Column(
                            children: [
                              // 1. NOMBRE Y LÁPIZ
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      shortName,
                                      style: TextStyle(
                                        color: mainTextColor,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900, // Black font
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.edit_outlined, color: AppColors.brandCyan, size: 20),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 6),
                              
                              // 2. SUBTÍTULO
                              const Text(
                                "EXPERT MATH TUTOR • +1 (555) 012-3456",
                                style: TextStyle(
                                  color: AppColors.brandCyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),

                              const SizedBox(height: 36),

                              // 3. BOTONES DE ACCIÓN (Video, Certs, Pagos)
                              // 3. BOTONES DE ACCIÓN
                              // ... dentro de tu build ...
                              // 3. BOTONES DE ACCIÓN
                              _ActionCard(
                                icon: Icons.videocam_outlined,
                                title: "VIDEO DE PRESENTACIÓN",
                                themeColor: AppColors.brandCyan,
                                scaffoldBg: scaffoldBg,
                                onTap: () {
                                  // AQUÍ ESTÁ EL CAMBIO CLAVE:
                                  showDialog(
                                    context: context,
                                    // Flutter usa una animación de fade/escala por defecto para los diálogos
                                    builder: (context) => const VideoPresentationDialog(),
                                  );
                                },
                              ),
// ... resto del código ...
                              const SizedBox(height: 16),
                              _ActionCard(
                                icon: Icons.workspace_premium_outlined,
                                title: "CERTIFICACIONES",
                                themeColor: AppColors.brandOrange, // Naranja
                                scaffoldBg: scaffoldBg,
                                onTap: () {},
                              ),
                              const SizedBox(height: 16),
                              _ActionCard(
                                icon: Icons.credit_card_outlined,
                                title: "MÉTODOS DE PAGO",
                                themeColor: AppColors.brandCyan,
                                scaffoldBg: scaffoldBg,
                                onTap: () {},
                              ),

                              const SizedBox(height: 40),

                              // 4. DESCRIPCIÓN
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "DESCRIPCIÓN",
                                    style: TextStyle(
                                      color: mainTextColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "“Experta en Matemáticas y Física con más de 5 años de experiencia ayudando a estudiantes de secundaria y universidad a comprender conceptos complejos de forma sencilla.”",
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : Colors.grey[600],
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // --- B. LA FOTO (Posicionada arriba, mitad fuera y mitad dentro) ---
                      Positioned(
                        top: 0,
                        child: _ProfileAvatarSquare(
                          photoUrl: photoUrl,
                          cardBgColor: cardBgColor, // Color para el borde que hace el recorte
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 🧩 WIDGETS INTERNOS
// =============================================================================

// Foto CUADRADA CON BORDES REDONDEADOS (Squircle)
class _ProfileAvatarSquare extends StatelessWidget {
  final String? photoUrl;
  final Color cardBgColor;

  const _ProfileAvatarSquare({required this.photoUrl, required this.cardBgColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Contenedor principal de la foto
        Container(
          width: 120, 
          height: 120,
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(32), // Borde cuadrado redondeado
            border: Border.all(color: cardBgColor, width: 6), // Borde grueso del color de la isla
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26), // Radio interno
            child: photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[800]),
                    errorWidget: (_, __, ___) => const Icon(Icons.person, size: 60, color: Colors.grey),
                  )
                : const Icon(Icons.person_rounded, size: 60, color: Colors.grey),
          ),
        ),
        
        // Botón Cámara (Naranja)
        Positioned(
          bottom: -4, 
          right: -4,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brandOrange, // Color Naranja
              borderRadius: BorderRadius.circular(14), // Forma ligeramente cuadrada
              border: Border.all(color: cardBgColor, width: 4), // Borde separador
            ),
            child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color themeColor;
  final Color scaffoldBg;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.themeColor,
    required this.scaffoldBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Fondo de los botones: En dark mode es igual al scaffold (negro puro)
    final buttonBg = isDark ? scaffoldBg : Colors.white;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: buttonBg, 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            // Borde muy sutil del color del ícono
            color: isDark ? themeColor.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: themeColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.brandBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white30 : Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }
}