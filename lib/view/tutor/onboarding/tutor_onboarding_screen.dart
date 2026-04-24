import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/tutor/onboarding/widgets/step_one_subjects..dart';
import 'package:flutter_projects/view/tutor/onboarding/widgets/step_three_docs.dart';
import 'package:flutter_projects/view/tutor/onboarding/widgets/step_two_personal.dart';

const String _kTitleFont = 'outfit';
const String _kBodyFont = 'manrope';

class TutorOnboardingScreen extends StatefulWidget {
  const TutorOnboardingScreen({super.key});

  @override
  State<TutorOnboardingScreen> createState() => _TutorOnboardingScreenState();
}

class _TutorOnboardingScreenState extends State<TutorOnboardingScreen> {
  final PageController _pageController = PageController();
  List<String> _selectedSubjects = [];
  Map<String, String> _personalData = {};
  
  // Datos del Paso 3
  File? _profilePic;
  File? _idCard;
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // AQUÍ IRÁ LA LLAMADA A LA API FINAL (Tu IdentityController)
      debugPrint("¡Finalizar Onboarding y disparar API!");
      Navigator.of(context).pop(); // Lo mandamos de vuelta al Home
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.grey),
          onPressed: () => Navigator.of(context).pop(), 
        ),
        title: const Text(
          'Configura tu Perfil',
          style: TextStyle(fontFamily: _kTitleFont, color: AppColors.brandBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6.0),
          child: _buildProgressBar(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (int page) {
                setState(() => _currentPage = page);
              },
              children: [
                _buildStepOneSubjects(),
                _buildStepTwoPersonalData(),
                _buildStepThreeDocuments(),
              ],
            ),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double progressWidth = width * ((_currentPage + 1) / _totalPages);
        
        return Stack(
          children: [
            Container(height: 6, width: width, color: Colors.grey.withOpacity(0.2)),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 6,
              width: progressWidth,
              decoration: const BoxDecoration(
                color: AppColors.brandBlue,
                borderRadius: BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: _previousPage,
              child: const Text('Atrás', style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: _kTitleFont)),
            )
          else
            const SizedBox(width: 60), 
            
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              _currentPage == _totalPages - 1 ? 'Finalizar' : 'Siguiente',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: _kTitleFont, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepOneSubjects() {
    return StepOneSubjects(
      onSelectionChanged: (selectedIds) {
        setState(() {
          _selectedSubjects = selectedIds;
        });
      },
    );}

  Widget _buildStepTwoPersonalData() {
    return StepTwoPersonal(
      onDataChanged: (data) {
        setState(() {
          _personalData = data;
        });
      },
    );
  }

  Widget _buildStepThreeDocuments() {
    return StepThreeDocs(
      onImagesSelected: (profile, idCard) {
        setState(() {
          _profilePic = profile;
          _idCard = idCard;
        });
      },
    );
  }
}