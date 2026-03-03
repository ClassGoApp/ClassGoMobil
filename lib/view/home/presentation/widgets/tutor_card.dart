import 'package:flutter/material.dart';

class TutorCard extends StatelessWidget {
  const TutorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280, // Ajusta el ancho según tu diseño
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        // Sombra suave para dar profundidad
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // 1. IMAGEN DE FONDO
            Positioned.fill(
              child: Image.network(
                'https://i.pravatar.cc/100', // URL de ejemplo o usa tu asset
                fit: BoxFit.cover,
              ),
            ),

            // 2. DEGRADADO OSCURO (Para legibilidad del texto)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.5, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // 3. CONTENIDO (Textos y Botones)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NOMBRE Y CHECK AZUL
                  Row(
                    children: const [
                      Text(
                        'Gabriel Alpiry',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.verified, color: Colors.blue, size: 20),
                    ],
                  ),
                  
                  // SUBTÍTULO (TEAL)
                  const Text(
                    'GaboFinanzasContabilidad',
                    style: TextStyle(
                      color: Color(0xFFA7FFEB),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // CAJA DE ESTADÍSTICAS (Efecto cristal)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('⭐ 5.0', 'Rating'),
                        _buildDivider(),
                        _buildStat('📖 18', 'Materias'),
                        _buildDivider(),
                        _buildStat('20Bs', '20 min.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // FILA DE BOTONES
                  Row(
                    children: [
                      // BOTÓN NARANJA
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Ver perfil',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // BOTÓN GUARDAR
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2F35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.bookmark_outline, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para las estadísticas
  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  // Divisor vertical sutil
  Widget _buildDivider() {
    return Container(height: 20, width: 1, color: Colors.white24);
  }
}