import 'package:flutter/material.dart';

Widget buildTutorCard() {
    return Container(
      width: 260, // Ancho de la card
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
      ),
      child: Stack(
        children: [
          // 1. Imagen de Fondo
          ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: Image.network(
              'https://via.placeholder.com/400x600', // Cambia por tu imagen
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // 2. Capa de Degradado (para que se vea el texto)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          // 3. Contenido de la Card
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre y Check de verificado
                Row(
                  children: [
                    Text(
                      'Rubén Segovia',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.check_circle, color: Colors.blue, size: 18),
                  ],
                ),
                Text(
                  'Tutor Verificado por ClassGo',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 15),

                // Fila de Estadísticas (Rating, Materias, Precio)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(Icons.star, '0.0', 'Rating'),
                      _buildStatLine(),
                      _buildStatItem(Icons.menu_book, '22', 'Materias'),
                      _buildStatLine(),
                      _buildStatItem(null, '15Bs', '20 min.', isPrice: true),
                    ],
                  ),
                ),
                SizedBox(height: 15),

                // Botones Inferiores
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Ver perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Icon(Icons.bookmark_border, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widgets auxiliares para los iconos y separadores internos
Widget _buildStatItem(IconData? icon, String value, String label, {bool isPrice = false}) {
  return Column(
    children: [
      Row(
        children: [
          if (icon != null) Icon(icon, color: icon == Icons.star ? Colors.yellow : Colors.white, size: 16),
          Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
      Text(label, style: TextStyle(color: Colors.white60, fontSize: 10)),
    ],
  );
}

Widget _buildStatLine() {
  return Container(height: 20, width: 1, color: Colors.white24);
}
