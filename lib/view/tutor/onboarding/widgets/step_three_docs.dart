import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class StepThreeDocs extends StatefulWidget {
  final Function(File? profilePic, File? idCard) onImagesSelected;

  const StepThreeDocs({Key? key, required this.onImagesSelected})
      : super(key: key);

  @override
  State<StepThreeDocs> createState() => _StepThreeDocsState();
}

class _StepThreeDocsState extends State<StepThreeDocs> {
  File? _profilePic;
  File? _idCard;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isProfile) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        if (isProfile) {
          _profilePic = File(image.path);
        } else {
          _idCard = File(image.path);
        }
      });
      widget.onImagesSelected(_profilePic, _idCard);
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
            'Sube una foto clara de tu rostro y tu documento de identidad (Carnet).',
            style: TextStyle(
              fontFamily: 'manrope',
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),

          _buildUploadBox(
            title: 'Foto de Perfil',
            icon: Icons.face_retouching_natural_rounded,
            imageFile: _profilePic,
            onTap: () => _pickImage(true),
            isCircle: true,
          ),

          const SizedBox(height: 24),

          _buildUploadBox(
            title: 'Carnet de Identidad (Frente)',
            icon: Icons.badge_rounded,
            imageFile: _idCard,
            onTap: () => _pickImage(false),
            isCircle: false,
          ),
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
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: imageFile != null
                    ? AppColors.primaryGreen
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
                      fit: isCircle
                          ? BoxFit.contain
                          : BoxFit.cover,
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
}
