import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/components/video_widget.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> featuredTutors = [];
  bool isLoadingTutors = true;
  VideoPlayerController? _activeController;
  bool _isVideoLoading = true;
  int _playingIndex = -1;

  // Define las rutas base
    final String baseImageUrl = 'http://192.168.0.199:8000/storage/profile_images/';
    final String baseVideoUrl = 'http://192.168.0.199:8000/storage/profile_videos/';

  @override
  void initState() {
    super.initState();
    print('*** INICIO DE LA VISTA HOME ***');
    debugPrint('*** INICIO DE LA VISTA HOME (debugPrint) ***');
    fetchFeaturedTutors();
  }

  Future<void> fetchFeaturedTutors() async {
    setState(() {
      isLoadingTutors = true;
    });
    try {
      print('*** OBTENIENDO TUTORES ***');
      debugPrint('*** OBTENIENDO TUTORES (debugPrint) ***');
      final response = await findTutors(null, perPage: 1000); // Eliminar perPage: 5 para traer todos
      print('Respuesta de la API de tutores:');
      print(response);
      if (response.containsKey('data') && response['data']['list'] is List) {
        final tutors = response['data']['list'];
        for (var tutor in tutors) {
          final profile = tutor['profile'] ?? {};
          final name = profile['full_name'] ?? 'Sin nombre';
          final imagePath = profile['image'] ?? '';
          final videoPath = profile['intro_video'] ?? '';
          final imageUrl = getFullUrl(imagePath, baseImageUrl);
          final videoUrl = getFullUrl(videoPath, baseVideoUrl);
          debugPrint('TUTOR: $name');
          debugPrint('Ruta imagen: $imageUrl');
          debugPrint('Ruta video: $videoUrl');
        }
        setState(() {
          featuredTutors = tutors;
        });
        print('Tutores obtenidos:');
        print(featuredTutors);
      } else {
        print('La respuesta no contiene la lista de tutores esperada.');
      }
    } catch (e, stack) {
      print('Error al obtener tutores:');
      print(e);
      print(stack);
      // Puedes mostrar un error si quieres
    } finally {
      setState(() {
        isLoadingTutors = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_pattern.png', // Cambia la ruta si tu asset es diferente
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.menu, color: Colors.white, size: 32),
                        Image.asset(
                          'assets/images/logo_classgo.png',
                          height: 38, // Ajusta el tamaño según tu diseño
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.person_outline, color: Colors.white, size: 26),
                        ),
                      ],
                    ),
                  ),
                  // Mensaje principal
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aprende con\nTutorías en Línea',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Alcanza tus metas con tutorías personalizadas de los mejores expertos. Conéctate con tutores dedicados para asegurar tu éxito.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 18),
                        // Barra de búsqueda
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: TextField(
                                    style: TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Buscar Tutores',
                                      hintStyle: TextStyle(color: Colors.white70),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.search, color: Colors.white),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mascota/Ilustración animada (GIF)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: SizedBox(
                        height: 300, // Más grande
                        child: Image.asset(
                          'assets/images/ave_animada.gif',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  // Tutores destacados
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color(0xFF062B3A),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tutores destacados',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Conoce a Nuestros Tutores\nCuidadosamente Seleccionados',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            height: 220,
                            child: isLoadingTutors
                                ? Center(child: CircularProgressIndicator(color: Colors.white))
                                : featuredTutors.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No hay tutores disponibles',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      )
                                    : ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: featuredTutors.length,
                                        separatorBuilder: (_, __) => SizedBox(width: 12),
                                        itemBuilder: (context, index) {
                                          try {
                                          final tutor = featuredTutors[index];
                                          final profile = tutor['profile'] ?? {};
                                          final name = profile['full_name'] ?? 'Sin nombre';
                                          final subjects = tutor['subjects'];
                                          String specialty = 'Sin especialidad';
                                          if (subjects is List && subjects.isNotEmpty && subjects[0] != null && subjects[0]['name'] != null) {
                                            specialty = subjects[0]['name'];
                                          }
                                            final rating = double.tryParse(tutor['avg_rating']?.toString() ?? '0.0') ?? 0.0;
                                            final imagePath = profile['image'] ?? '';
                                            final videoPath = profile['intro_video'] ?? '';
                                            final imageUrl = getFullUrl(imagePath, baseImageUrl);
                                            final videoUrl = getFullUrl(videoPath, baseVideoUrl);
                                            return Column(
                                              children: [
                                                Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    Container(
                                                      width: 200,
                                                      decoration: BoxDecoration(
                                                        color: Colors.transparent,
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            width: 200,
                                                            decoration: BoxDecoration(
                                                              color: Colors.white,
                                                              border: Border.all(color: AppColors.lightBlueColor, width: 4),
                                                              borderRadius: BorderRadius.circular(16),
                                                            ),
                                                            child: Column(
                                                              children: [
                                                                ClipRRect(
                                                                  borderRadius: BorderRadius.only(
                                                                    topLeft: Radius.circular(12),
                                                                    topRight: Radius.circular(12),
                                                                  ),
                                                                  child: Container(
                                                                    width: 200,
                                                                    height: 100,
                                                                    color: Colors.grey[300],
                                                                    child: _playingIndex == index && _activeController != null
                                                                        ? _isVideoLoading
                                                                            ? Center(child: CircularProgressIndicator(color: AppColors.lightBlueColor))
                                                                            : VideoPlayer(_activeController!)
                                                                        : FutureBuilder<Uint8List?>(
                                                                            future: VideoThumbnail.thumbnailData(
                                                                              video: videoUrl,
                                                                              imageFormat: ImageFormat.JPEG,
                                                                              maxWidth: 200,
                                                                              quality: 50,
                                                                            ),
                                                                            builder: (context, snapshot) {
                                                                              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                                                                return Stack(
                                                                                  children: [
                                                                                    Image.memory(
                                                                                      snapshot.data!,
                                                                                      width: 200,
                                                                                      height: 100,
                                                                                      fit: BoxFit.cover,
                                                                                    ),
                                                                                    Center(child: Icon(Icons.play_circle_outline, size: 50, color: AppColors.lightBlueColor)),
                                                                                    Positioned.fill(
                                                                                      child: Material(
                                                                                        color: Colors.transparent,
                                                                                        child: InkWell(
                                                                                          onTap: () {
                                                                                            _playVideo(videoUrl, index);
                                                                                          },
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                );
                                                                              } else {
                                                                                return Stack(
                                                                                  children: [
                                                                                    Container(
                                                                                      color: Colors.grey[300],
                                                                                      width: 200,
                                                                                      height: 100,
                                                                                    ),
                                                                                    Center(child: Icon(Icons.play_circle_outline, size: 50, color: AppColors.lightBlueColor)),
                                                                                    Positioned.fill(
                                                                                      child: Material(
                                                                                        color: Colors.transparent,
                                                                                        child: InkWell(
                                                                                          onTap: () {
                                                                                            _playVideo(videoUrl, index);
                                                                                          },
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                );
                                                                              }
                                                                            },
                                                                          ),
                                                                  ),
                                                                ),
                                                                Container(
                                                                  width: double.infinity,
                                                                  height: 20,
                                                                  decoration: BoxDecoration(
                                                                    color: AppColors.lightBlueColor,
                                                                    borderRadius: BorderRadius.only(
                                                                      bottomLeft: Radius.circular(12),
                                                                      bottomRight: Radius.circular(12),
                                                                    ),
                                                                  ),
                                                                  alignment: Alignment.centerLeft,
                                                                  padding: EdgeInsets.only(left: 44, right: 8),
                                                                  child: Text(
                                                                    name,
                                                                    style: TextStyle(
                                                                      color: Colors.white,
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 14,
                                                                    ),
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Positioned(
                                                      bottom: -18,
                                                      left: 8,
                                                      child: CircleAvatar(
                                                        radius: 20,
                                                        backgroundColor: Colors.white,
                                                        child: CircleAvatar(
                                                          radius: 17,
                                                          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                                                          backgroundColor: Colors.grey[300],
                                                          child: imageUrl.isEmpty ? Icon(Icons.person, size: 18, color: Colors.grey[600]) : null,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 18),
                                                Container(
                                                  width: 200,
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Especialidad: $specialty',
                                                        style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Text(rating.toStringAsFixed(2), style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                                                          SizedBox(width: 6),
                                                          Row(
                                                            children: List.generate(5, (i) {
                                                              if (rating >= i + 1) {
                                                                return Icon(Icons.star, color: Colors.amber, size: 16);
                                                              } else if (rating > i && rating < i + 1) {
                                                                return Icon(Icons.star_half, color: Colors.amber, size: 16);
                                                              } else {
                                                                return Icon(Icons.star_border, color: Colors.amber, size: 16);
                                                              }
                                                            }),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          } catch (e, stack) {
                                            print('Error en itemBuilder de tutor:');
                                            print(e);
                                            print(stack);
                                            return Container(
                                              width: 200,
                                              height: 120,
                                              color: Colors.red[100],
                                              child: Center(child: Text('Error al mostrar tutor', style: TextStyle(color: Colors.red))),
                                            );
                                          }
                                        },
                                      ),
                          ),
                          SizedBox(height: 18),
                          // Guía paso a paso
                          Text(
                            'Una guía paso a paso',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Desbloquea tu potencial con pasos sencillos',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            height: 180,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _StepCard(
                                  step: 'Paso 1',
                                  title: 'Inscríbete',
                                  description: 'Crea tu cuenta rápidamente para comenzar a utilizar nuestra plataforma',
                                  buttonText: 'Empezar',
                                  imageUrl: 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308',
                                ),
                                SizedBox(width: 12),
                                _StepCard(
                                  step: 'Paso 2',
                                  title: 'Encuentra tu tutor',
                                  description: 'Busca y selecciona tutores calificados para tus necesidades',
                                  buttonText: 'Buscar',
                                  imageUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61',
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 18),
                          // ¿Por qué elegirnos?
                          Text(
                            '¿Por qué Elegirnos?',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Por el acceso rápido, 24/7, a tutorías personalizadas que potencian tu aprendizaje',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Accede a sesiones cortas y prácticas, diseñadas por tutores expertos para ser tus pequeños salvavidas en el aprendizaje',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• Acceso 24/7', style: TextStyle(color: Colors.white, fontSize: 14)),
                                Text('• Tutores Expertos', style: TextStyle(color: Colors.white, fontSize: 14)),
                                Text('• Tarifas asequibles', style: TextStyle(color: Colors.white, fontSize: 14)),
                              ],
                            ),
                          ),
                          SizedBox(height: 12),
                          Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFF9900),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              ),
                              onPressed: () {},
                              child: Text('Comienza Ahora', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          SizedBox(height: 18),
                          // Imagen de grupo
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1464983953574-0892a716854b',
                              height: 90,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 18),
                          // Alianzas
                          Text('Alianzas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _AllianceCard(
                                  logoUrl: 'https://i.ibb.co/0j1Yw1v/logo-ejemplo1.png',
                                  name: 'Ingeniería Petrolera',
                                  color: Color(0xFF0B9ED9),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _AllianceCard(
                                  logoUrl: 'https://i.ibb.co/0j1Yw1v/logo-ejemplo1.png',
                                  name: 'Club "Tacuara" Debate y Oratoria',
                                  color: Color(0xFFF9A825),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 30),
                        ],
                      ),
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

  Future<VideoPlayerController> _initializeVideoController(String url) async {
    final controller = VideoPlayerController.network(url);
    await controller.initialize();
    controller.setVolume(0);
    controller.setLooping(true);
    return controller;
  }

  void _playVideo(String url, int index) async {
    setState(() {
      _playingIndex = index;
      _isVideoLoading = true;
    });
    final controller = await _initializeVideoController(url);
    setState(() {
      _activeController = controller;
      _isVideoLoading = false;
    });
  }

  // Función para obtener la URL completa de imagen o video
  String getFullUrl(String path, String base) {
    if (path.startsWith('http')) {
      return path;
    }
    return base + path;
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String description;
  final String buttonText;
  final String imageUrl;

  const _StepCard({
    required this.step,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.network(
              imageUrl,
              height: 80,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF9900),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(step, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                SizedBox(height: 6),
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0B3C5D))),
                SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.black87)),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF9900),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  ),
                  onPressed: () {},
                  child: Text(buttonText, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllianceCard extends StatelessWidget {
  final String logoUrl;
  final String name;
  final Color color;

  const _AllianceCard({
    required this.logoUrl,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image.network(logoUrl, width: 40, height: 40),
          ),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 