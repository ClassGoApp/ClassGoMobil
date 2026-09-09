import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart';
import 'package:flutter_projects/provider/onboarding_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:flutter_projects/styles/app_styles.dart';

class StepThreeDocs extends StatefulWidget {
  final String role; // 'tutor' o 'student'

  const StepThreeDocs({Key? key, required this.role}) : super(key: key);

  @override
  State<StepThreeDocs> createState() => _StepThreeDocsState();
}

class _StepThreeDocsState extends State<StepThreeDocs> {
  File? _profilePic;
  File? _documentFile; // Foto frontal del carnet
  File? _documentFileBack; // Foto trasera del carnet (solo para tutores)
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Cargamos las imágenes previas si el usuario retrocedió de página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OnboardingProvider>(context, listen: false);
      // setState(() {
      //   _profilePic = provider.image;
      //   _documentFile = widget.role == 'tutor' 
      //       ? provider.identificationCard 
      //       : provider.transcript;
      // });
    });
  }

  // Método para sincronizar con el cerebro central
  void _syncWithProvider() {
    context.read<OnboardingProvider>().updateDocuments(
      personalPic: _profilePic,
      docFile: _documentFile,
      docFileBack: _documentFileBack,
      role: widget.role,
    );
  }

// 1. EL MENÚ INFERIOR (BottomSheet)
  void _showPickerOptions(BuildContext context, bool isProfile, {bool isBack = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Selecciona una opción', style: TextStyle(fontFamily: 'outfit', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brandBlue)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: AppColors.brandCyan),
                title: const Text('Tomar una foto', style: TextStyle(fontFamily: 'manrope', fontSize: 16)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(isProfile, ImageSource.camera, isBack: isBack); // 👈 Llama a la cámara
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.brandCyan),
                title: const Text('Elegir de la galería', style: TextStyle(fontFamily: 'manrope', fontSize: 16)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(isProfile, ImageSource.gallery, isBack: isBack); // 👈 Llama a la galería
                },
              ),
            ],
          ),
        );
      }
    );
  }

  // 2. TU FUNCIÓN ACTUALIZADA CON VALIDACIONES
  Future<void> _pickImage(bool isProfile, ImageSource source, {bool isBack = false}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source, // <-- Ahora usa la fuente que el usuario eligió
        imageQuality: 70, // <-- Mantienes tu calidad original
        maxWidth: 1500, // <-- Límite extra para evitar fotos excesivamente grandes
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // 👉 VALIDACIÓN 1: FORMATO (Solo JPG, JPEG, PNG)
        final extension = imageFile.path.split('.').last.toLowerCase();
        if (extension != 'jpg' && extension != 'jpeg' && extension != 'png') {
          if (mounted) CustomToast.show(context, 'Solo se permiten imágenes JPG o PNG', isSuccess: false);
          return; // Corta la ejecución si no es válido
        }

        // 👉 VALIDACIÓN 2: PESO (Max 5MB = 5 * 1024 * 1024 bytes)
        final int bytes = await imageFile.length();
        if (bytes > 5242880) { 
          if (mounted) CustomToast.show(context, 'La imagen pesa más de 5MB. Intenta con otra.', isSuccess: false);
          return; // Corta la ejecución
        }

        // 👉 MANTENEMOS TU LÓGICA ORIGINAL INTACTA
        setState(() {
          if (isProfile) {
            _profilePic = imageFile;
          } else if (isBack) {
            _documentFileBack = imageFile;
          } else {
            _documentFile = imageFile;
          }
        });
        _syncWithProvider(); // Todo sigue fluyendo como antes
      }
    } catch (e) {
      if (mounted) CustomToast.show(context, 'Error al acceder a la cámara/galería', isSuccess: false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Textos dinámicos según el rol
    final String docTitleFront = widget.role == 'tutor' 
        ? 'Carnet de Identidad (Frente)' 
        : 'Historial Académico / Matrícula';
    
    final String docTitleBack = 'Carnet de Identidad (Reverso)';
    
    final String docSubtitle = widget.role == 'tutor'
        ? 'Sube una foto personal y ambas caras de tu documento de identidad (Carnet) para verificar tu identidad.'
        : 'Sube una foto personal y un documento que acredite tu matrícula estudiantil.';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seguridad y Confianza',
            style: TextStyle(
              fontFamily: 'outfit',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            docSubtitle,
            style: TextStyle(
              fontFamily: 'manrope',
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),

          _buildUploadBox(
            title: 'Foto Personal',
            icon: Icons.face_retouching_natural_rounded,
            imageFile: _profilePic,
            onTap: () => _pickImage(true, ImageSource.camera),
            isCircle: true,
          ),

          const SizedBox(height: 24),

          // Para tutores: mostrar ambas fotos del carnet en GRID (lado a lado)
          if (widget.role == 'tutor') ...[
            const Text(
              'Documento de Identidad',
              style: TextStyle(
                fontFamily: 'outfit',
                fontWeight: FontWeight.bold,
                color: AppColors.brandBlue,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCompactUploadBox(
                    title: 'Frente',
                    icon: Icons.badge_rounded,
                    imageFile: _documentFile,
                    onTap: () => _showPickerOptions(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactUploadBox(
                    title: 'Reverso',
                    icon: Icons.badge_rounded,
                    imageFile: _documentFileBack,
                    onTap: () => _showPickerOptions(context, false, isBack: true),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Para estudiantes: mantener el diseño original (un solo cuadro grande)
            _buildUploadBox(
              title: docTitleFront,
              icon: Icons.school_rounded,
              imageFile: _documentFile,
              onTap: () => _showPickerOptions(context, false),
              isCircle: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadBox({
    required String title,
    required IconData icon,
    required File? imageFile,
    required VoidCallback onTap,
    required bool isCircle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontFamily: 'outfit',
              fontWeight: FontWeight.bold,
              color: AppColors.brandBlue,
              fontSize: 16),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: imageFile != null
                    ? AppColors.primaryGreen // Si hay foto, se pone verde (Feedback positivo)
                    : AppColors.brandBlue.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(
                      imageFile,
                      fit: isCircle ? BoxFit.contain : BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 40, color: AppColors.brandBlue),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Toca para subir imagen',
                        style: TextStyle(
                            fontFamily: 'manrope',
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'JPG, PNG o WEBP (Máx. 5MB)',
                        style: TextStyle(
                            fontFamily: 'manrope',
                            color: Colors.grey.shade500,
                            fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // Versión compacta para el grid de 2 columnas (fotos del carnet)
  Widget _buildCompactUploadBox({
    required String title,
    required IconData icon,
    required File? imageFile,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: imageFile != null
                ? AppColors.primaryGreen
                : AppColors.brandBlue.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 28, color: AppColors.brandBlue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'outfit',
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toca para subir',
                    style: TextStyle(
                      fontFamily: 'manrope',
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}