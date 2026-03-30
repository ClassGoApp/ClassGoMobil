import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/view/components/role_based_navigation.dart';
import 'package:flutter_projects/view/student/widgets/student_bottom_nav.dart';

class InstantTutoringScreen extends StatefulWidget {
  // Parámetros que pueden venir desde otros lugares (como desde Favoritos)
  final String? tutorName;
  final String? tutorImage;
  final List<Map<String, dynamic>>? subjects;
  final dynamic tutorId;
  final int? subjectId;

  const InstantTutoringScreen({
    super.key,
    this.tutorName,
    this.tutorImage,
    this.subjects,
    this.tutorId,
    this.subjectId,
  });

  @override
  State<InstantTutoringScreen> createState() => _InstantTutoringScreenState();
}

class _InstantTutoringScreenState extends State<InstantTutoringScreen> {
  String selectedCategory = 'TODAS';

  final List<String> categories = [
    'TODAS',
    'CIENCIAS EXACTAS',
    'INGENIERÍA AVANZADA',
    'CIENCIAS SOCIALES',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header con botón de volver
            SliverAppBar(
              backgroundColor: const Color(0xFFF8FAFC),
              floating: true,
              snap: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: const Text(
                'Tutoría Instantánea',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Color(0xFF0F172A)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded,
                      color: Color(0xFF64748B)),
                  onPressed: () {
                    // Puedes abrir búsqueda aquí en el futuro
                  },
                ),
              ],
            ),

            // Título principal
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  '¿Qué necesitas aprender\nhoy?',
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.1,
                      ),
                ),
              ),
            ),

            // Subtítulo
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Text(
                  'Más de 600 materias con las que un tutor puede ayudarte ahora',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ),
            ),

            // Barra de búsqueda
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar materia o tutor...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: Color(0xFF64748B)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Chips de categorías
            SliverToBoxAdapter(
              child: SizedBox(
                height: 42,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(
                          cat,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF334155),
                          ),
                        ),
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF1E40AF),
                        elevation: isSelected ? 0 : 1,
                        pressElevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.grey.shade300,
                          ),
                        ),
                        onSelected: (_) {
                          setState(() => selectedCategory = cat);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Sección Ciencias Exactas
            _buildSection(
              context,
              title: 'CIENCIAS EXACTAS',
              items: [
                _SubjectCard(letter: 'F', title: 'Física Aplicada'),
                _SubjectCard(letter: 'M', title: 'Mecánica Aplicada'),
                _SubjectCard(letter: 'T', title: 'Termodinámica Aplicada'),
              ],
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),

            // Sección Ingeniería Avanzada
            _buildSection(
              context,
              title: 'INGENIERÍA AVANZADA',
              items: [
                _SubjectCard(letter: 'E', title: 'Electromagnetismo Avanzado'),
                _SubjectCard(letter: 'C', title: 'Control y Automatización'),
              ],
              isExpanded: true,
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),

            // Sección Ciencias Sociales
            _buildSectionHeader('CIENCIAS SOCIALES Y ECONÓMICAS'),
          ],
        ),
      ),
      bottomNavigationBar: StudentBottomNav(
        currentIndex: -1, // -1 porque no es ninguna pestaña principal
        onTap: (index) {
          // Navegación sin animación brusca
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  RoleBasedNavigation(),
              transitionDuration: Duration.zero,
            ),
            (route) => false,
          );
        },
        onCenterTap: () {
          // Ya estamos en Tutoría Instantánea → no hacer nada o vibrar
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_SubjectCard> items,
    bool isExpanded = false,
  }) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E40AF),
                    letterSpacing: 0.5,
                  ),
                ),
                if (isExpanded)
                  const Icon(Icons.keyboard_arrow_up_rounded,
                      color: Color(0xFF64748B)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// Widget reutilizable para cada materia (sin cambios)
class _SubjectCard extends StatelessWidget {
  final String letter;
  final String title;

  const _SubjectCard({required this.letter, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Navegar a detalle de materia o chat con tutor
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Abrir detalle de: $title')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
