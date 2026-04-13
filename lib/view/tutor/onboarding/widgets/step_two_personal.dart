import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:intl/intl.dart';

class StepTwoPersonal extends StatefulWidget {
  final Function(Map<String, String>) onDataChanged;

  const StepTwoPersonal({Key? key, required this.onDataChanged})
      : super(key: key);

  @override
  State<StepTwoPersonal> createState() => _StepTwoPersonalState();
}

class _StepTwoPersonalState extends State<StepTwoPersonal> {
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final Map<String, String> _formData = {
    'dob': '',
    'country': '',
    'address': '',
  };

  void _updateData() {
    _formData['dob'] = _dobController.text;
    _formData['country'] = _countryController.text;
    _formData['address'] = _addressController.text;
    widget.onDataChanged(_formData);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now()
          .subtract(const Duration(days: 365 * 18)), // Mayor de 18
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brandBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
        _updateData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Un poco sobre ti',
            style: TextStyle(
              fontFamily: 'outfit',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Necesitamos estos datos para verificar tu identidad y mantener la comunidad segura.',
            style: TextStyle(
              fontFamily: 'manrope',
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),

          _buildTextField(
            controller: _dobController,
            label: 'Fecha de Nacimiento',
            hint: 'YYYY-MM-DD',
            icon: Icons.calendar_today_rounded,
            readOnly: true,
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 20),

          _buildTextField(
            controller: _countryController,
            label: 'País de Residencia',
            hint: 'Ej. Bolivia',
            icon: Icons.public_rounded,
            onChanged: (_) => _updateData(),
          ),
          const SizedBox(height: 20),

          // CAMPO: DIRECCIÓN
          _buildTextField(
            controller: _addressController,
            label: 'Dirección Completa',
            hint: 'Avenida, Calle, Número...',
            icon: Icons.location_on_rounded,
            maxLines: 2,
            onChanged: (_) => _updateData(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontFamily: 'outfit',
              fontWeight: FontWeight.bold,
              color: AppColors.brandBlue,
              fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: 'manrope', fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: AppColors.brandBlue.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.brandBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
