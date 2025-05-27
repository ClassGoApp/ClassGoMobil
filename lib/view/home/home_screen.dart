import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> featuredTutors = [];
  bool isLoadingTutors = true;

  @override
  void initState() {
    super.initState();
    fetchFeaturedTutors();
  }

  Future<void> fetchFeaturedTutors() async {
    setState(() {
      isLoadingTutors = true;
    });
    try {
      final response = await findTutors(null, perPage: 5); // Puedes ajustar el perPage
      if (response.containsKey('data') && response['data']['list'] is List) {
        setState(() {
          featuredTutors = response['data']['list'];
        });
      }
    } catch (e) {
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
                            height: 170,
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
                                          final tutor = featuredTutors[index];
                                          final profile = tutor['profile'] ?? {};
                                          final name = profile['full_name'] ?? 'Sin nombre';
                                          final subjects = tutor['subjects'];
                                          String specialty = 'Sin especialidad';
                                          if (subjects is List && subjects.isNotEmpty && subjects[0] != null && subjects[0]['name'] != null) {
                                            specialty = subjects[0]['name'];
                                          }
                                          final rating = tutor['avg_rating']?.toString() ?? '0.0';
                                          final imageUrl = profile['image'] ?? '';
                                          return Container(
                                            width: 200,
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
                                                  child: imageUrl.isNotEmpty
                                                      ? Image.network(
                                                          imageUrl,
                                                          height: 80,
                                                          width: double.infinity,
                                                          fit: BoxFit.cover,
                                                        )
                                                      : Container(
                                                          height: 80,
                                                          color: Colors.grey[300],
                                                          child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
                                                        ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 12,
                                                            backgroundImage: imageUrl.isNotEmpty
                                                                ? NetworkImage(imageUrl)
                                                                : null,
                                                            child: imageUrl.isEmpty
                                                                ? Icon(Icons.person, size: 16, color: Colors.grey[600])
                                                                : null,
                                                          ),
                                                          SizedBox(width: 6),
                                                          Flexible(
                                                            child: Text(
                                                              name,
                                                              style: TextStyle(
                                                                color: Color(0xFF0B3C5D),
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 13,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        'Especialidad: $specialty',
                                                        style: TextStyle(fontSize: 11, color: Colors.black87),
                                                      ),
                                                      SizedBox(height: 2),
                                                      Row(
                                                        children: [
                                                          Text(rating, style: TextStyle(fontSize: 12)),
                                                          SizedBox(width: 4),
                                                          Row(
                                                            children: List.generate(5, (i) => Icon(Icons.star, color: Colors.amber, size: 14)),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
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