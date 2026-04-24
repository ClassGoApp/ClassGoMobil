import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

const String _kTitleFont = 'outfit';
const String _kBodyFont = 'manrope';

class PaymentMethodDetailModal extends StatefulWidget {
  final String type; // 'qr' o 'transfer'

  const PaymentMethodDetailModal({Key? key, required this.type}) : super(key: key);

  @override
  State<PaymentMethodDetailModal> createState() => _PaymentMethodDetailModalState();
}

class _PaymentMethodDetailModalState extends State<PaymentMethodDetailModal> {
  // Controladores para los datos
  final TextEditingController _priceController = TextEditingController(text: "50");
  final TextEditingController _timeController = TextEditingController(text: "20");

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1D24) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Línea superior de arrastre
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            Text(
              widget.type == 'qr' ? "GESTIONAR QR" : "DATOS BANCARIOS",
              style: TextStyle(
                fontFamily: _kTitleFont,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.brandBlue,
              ),
            ),
            const SizedBox(height: 25),

            // 🎯 SECCIÓN: DEFINIR PRECIO POR TIEMPO
            _buildSectionTitle("CONFIGURAR TARIFA", Icons.timer_outlined),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: "Precio (Bs)",
                    controller: _priceController,
                    icon: Icons.payments_outlined,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    label: "Minutos",
                    controller: _timeController,
                    icon: Icons.history_toggle_off,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // 🎯 SECCIÓN: GESTIÓN ESPECÍFICA (QR o Datos)
            if (widget.type == 'qr') ...[
              _buildSectionTitle("TU CÓDIGO QR", Icons.qr_code_2),
              _buildQRManager(isDark),
            ] else ...[
              _buildSectionTitle("INFORMACIÓN DE CUENTA", Icons.account_balance_outlined),
              _buildInputField(label: "Banco", icon: Icons.home_work_outlined, isDark: isDark),
              _buildInputField(label: "Tipo de Cuenta", icon: Icons.category_outlined, isDark: isDark),
              _buildInputField(label: "Nombre del Titular", icon: Icons.person_outline, isDark: isDark),
              _buildInputField(label: "Número de Cuenta", icon: Icons.numbers, isDark: isDark),
            ],

            const SizedBox(height: 30),

            // Botón de Guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.type == 'qr' ? AppColors.brandCyan : AppColors.brandOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  "GUARDAR CAMBIOS",
                  style: TextStyle(fontFamily: _kTitleFont, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para manejar el QR (Subir/Eliminar)
  Widget _buildQRManager(bool isDark) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            "Toca para subir o cambiar QR",
            style: TextStyle(fontFamily: _kBodyFont, color: Colors.grey[500], fontSize: 12),
          ),
          // Aquí podrías poner un botón pequeño rojo de "Eliminar" si ya existe un QR
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.brandCyan),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: _kTitleFont,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required String label, required IconData icon, required bool isDark, TextEditingController? controller}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontFamily: _kBodyFont, color: isDark ? Colors.white : AppColors.brandBlue, fontSize: 14),
        decoration: InputDecoration(
          icon: Icon(icon, size: 18, color: Colors.grey),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}