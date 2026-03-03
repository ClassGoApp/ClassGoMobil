import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/home/presentation/widgets/search_modal.dart';
import 'presentation/widgets/tutor_card.dart';
import 'presentation/widgets/buscador.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/provider/auth_provider.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: AppColors.primaryColor, 
            ),
          ),
          Positioned.fill(
            child: Image.asset(
              'assets/images/home/Elipse.png', 
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                  
                        // --- LOGO (Imagen) ---
                        Center(
                          child: Image.asset(
                            'assets/images/logo_classgo.png',
                            height: 38,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
              
                        // --- SI INICIÓ SESIÓN SE MOSTRARÁ EL NOMBRE DEL PERFIL O EL TITULO POR DEFECTO ---
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.person, color: Colors.white, size: 35),
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Hola, Aron!',//Extraer del usario Logeado 
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Estudiante', 
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // const Text(
                        //   'Aprende con\nTutorías en Línea',
                        //   style: TextStyle(
                        //     color: Colors.white,
                        //     fontSize: 28,
                        //     fontWeight: FontWeight.bold,
                        //     height: 1.2,
                        //   ),
                        // ),
              
                        const SizedBox(height: 30),

                        // --- BARRA DE BÚSQUEDA -----
                        Buscador(
                          onTap: () {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            if (authProvider.token == null) {
                              _showLoginRequiredDialog(context);
                              return;
                            }
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => SearchSubjectModal(
                                initialSubjects: [],
                                onSearch: (keyword) async {
                                  //Llamar a Api
                                  return [];
                                },
                                onSubjectSelected: (subject) {
                                  // Lógica cuando el usuario selecciona una materia
                                },
                              ),
                            );
                          },
                        ),
                      ]
                    ),
                  ),
                  
                  const SizedBox(height: 40),
        
                  // Mascota/Ilustración animada (GIF)
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(vertical: 16.0),
                  //   child: Center(
                  //     child: SizedBox(
                  //       height: 300, // Más grande
                  //       child: Image.asset(
                  //         'assets/images/ave_animada.gif',
                  //         fit: BoxFit.contain,
                  //       ),
                  //     ),
                  //   ),
                  // ),
              
                  // --- TÍTULO SECCIÓN ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: const Text(
                      'Tutores destacados',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              
                  const SizedBox(height: 20,),
              
                  // LISTA TUTORES DESTACADOS
                  SizedBox(
                    height: 350,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: 5, // Número de tutores a mostrar
                      itemBuilder: (context, index) {
                        return const TutorCard();
                      },
                    ),
                  ),
        
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: const Text(
                      'Tutores de Matemáticas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20,),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: 5, // Número de tutores a mostrar
                      itemBuilder: (context, index) {
                        return const TutorCard();
                      },
                    ),
                  ),
                  
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Inicio de sesión requerido'),
          content: const Text('Debes iniciar sesión para acceder a esta función.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}