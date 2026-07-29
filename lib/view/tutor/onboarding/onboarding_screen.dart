import 'package:flutter/material.dart';
import 'package:flutter_projects/provider/onboarding_provider.dart';
import 'package:flutter_projects/provider/tutor_subjects_provider.dart';
import 'package:flutter_projects/view/components/role_based_navigation.dart';
import 'package:flutter_projects/view/tutor/dashboard_tutor.dart';
import 'package:flutter_projects/view/tutor/features/home/tutor_home_screen.dart';
import 'package:flutter_projects/view/tutor/onboarding/widgets/step_one_subjects..dart';
import 'package:provider/provider.dart';

import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/base_components/custom_snack_bar.dart'; 
// Asegúrate de usar las rutas correctas a tus archivos
import 'package:flutter_projects/view/tutor/onboarding/widgets/step_three_docs.dart';
import 'package:flutter_projects/view/tutor/onboarding/widgets/step_two_personal.dart';
import 'package:flutter_projects/provider/auth_provider.dart';

const String _kTitleFont = 'outfit';

class OnboardingScreen extends StatefulWidget {
  final String role; // 'tutor' o 'student'

  const OnboardingScreen({
    super.key, 
    required this.role,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  List<Widget> _activeSteps = [];
  int _totalPages = 0;
  bool _isLoadingSteps = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSteps();
    });
  }

  Future<void> _loadSteps() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final subjectsProvider = Provider.of<TutorSubjectsProvider>(context, listen: false);

    await Future.wait([
      subjectsProvider.loadGroups(auth.token!),
      subjectsProvider.loadTutorSubjects(auth),
    ]);

    if (mounted) {
      setState(() {
        _buildSteps();
        _isLoadingSteps = false;
      });
    }
  }

  void _buildSteps() {
    _activeSteps = [];
    final subjectsProvider = Provider.of<TutorSubjectsProvider>(context, listen: false);
    final hasSubjects = subjectsProvider.subjects.isNotEmpty;

    if (widget.role == 'tutor' && !hasSubjects) {
      _activeSteps.add(const StepOneSubjects());
    }
    _activeSteps.add(const StepTwoPersonal());
    _activeSteps.add(StepThreeDocs(role: widget.role));
    _totalPages = _activeSteps.length;
    _currentPage = 0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(OnboardingProvider provider) async {
    final freshProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final currentWidget = _activeSteps[_currentPage];

    print("🔍 DIAGNÓSTICO BOTÓN SIGUIENTE:");
    print("🔍 Materias guardadas: ${freshProvider.tempSelectedSubjects}");
    print("🔍 ¿Es válido?: ${freshProvider.isStepOneValid}");
    
    if (currentWidget is StepOneSubjects) {
      if (!freshProvider.isStepOneValid) {
        CustomToast.show(context, "Selecciona al menos una materia", isSuccess: false);
        return;
      }
    } else if (currentWidget is StepTwoPersonal) {
      if (freshProvider.dateOfBirth == null) {
        CustomToast.show(context, "Ingresa tu fecha de nacimiento", isSuccess: false);
        return;
      }
      if (freshProvider.selectedCountryId == null) {
        CustomToast.show(context, "Selecciona tu país", isSuccess: false);
        return;
      }
      if (freshProvider.gender == null) {
        CustomToast.show(context, "Selecciona tu género", isSuccess: false);
        return;
      }
      if (freshProvider.countryHasStates && freshProvider.selectedStateId == null) {
        CustomToast.show(context, "Selecciona tu departamento", isSuccess: false);
        return;
      }
      if (freshProvider.profilePhoto == null) {
        CustomToast.show(context, "Sube tu foto de perfil", isSuccess: false);
        return;
      }
    }

    // Avanzar o Finalizar
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Barrera Final: Documentos
      if (!provider.isStepThreeValid) {
        CustomToast.show(context, "Sube los documentos requeridos", isSuccess: false);
        return;
      }
      await _submitData(provider);
    }
  }

  Future<void> _submitData(OnboardingProvider provider) async {
    provider.setLoading(true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final Map<String, dynamic>? userData = authProvider.userData;
    final profile = userData?['user']?['profile'] ?? {};
    final String firstName = profile['first_name'] ?? userData?['user']?['first_name'] ?? '';
    final String lastName = profile['last_name'] ?? userData?['user']?['last_name'] ?? '';
    final String phoneNumber = profile['phone_number'] ?? '';

    final response = await provider.submitFullOnboarding(
      token: authProvider.token ?? '',
      role: widget.role,
      userId: authProvider.userId ?? 0,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
    );

    provider.setLoading(false);

    if (response['success'] == true) {
      provider.clearData();

      await authProvider.setIdentityStatus('pending');
      await authProvider.refreshProfile();

      if (mounted) {
        CustomToast.show(
          context,
          "¡Tus datos han sido enviados para verificación!",
          isSuccess: true,
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DashboardTutor()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        CustomToast.show(context, response['message'] ?? 'Ocurrió un error al enviar.', isSuccess: false);
      }
    }
  }
  // Future<void> _submitData(OnboardingProvider provider) async {
  //   provider.setLoading(true);

  //   final authProvider = Provider.of<AuthProvider>(context, listen: false);

  //   final response = await provider.submitFullOnboarding(
  //     token: authProvider.token!,
  //     role: widget.role,
  //     userId: authProvider.userId!,
  //   );

  //   provider.setLoading(false);

  //   provider.setLoading(false);

  //   if (response['success'] == true) {
  //     provider.clearData();
  //     if (mounted) {
  //       CustomToast.show(context, "Documentos enviados a revisión", isSuccess: true);
  //       Navigator.of(context).pop(); 
  //     }
  //   } else {
  //     if (mounted) {
  //       CustomToast.show(context, response['message'] ?? 'Ocurrió un error', isSuccess: false);
  //     }
  //   }
  // }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Provider.of<OnboardingProvider>(context, listen: false).clearData();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleBasedNavigation()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OnboardingProvider>(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.grey),
          onPressed: () {
            provider.clearData();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const RoleBasedNavigation()),
              (route) => false,
            );
          }
        ),
        title: const Text(
          'Configura tu Perfil',
          style: TextStyle(fontFamily: _kTitleFont, color: AppColors.brandBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: _isLoadingSteps ? null : PreferredSize(
          preferredSize: const Size.fromHeight(6.0),
          child: _buildProgressBar(),
        ),
      ),
      body: _isLoadingSteps
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandBlue))
          : Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (int page) {
                      setState(() => _currentPage = page);
                    },
                    children: _activeSteps,
                  ),
                ),
                _buildBottomControls(provider),
              ],
            ),
    );
  }

  Widget _buildProgressBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double progressWidth = _totalPages > 0 ? width * ((_currentPage + 1) / _totalPages) : 0;
        
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

  Widget _buildBottomControls(OnboardingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0 && !provider.isLoading)
            TextButton(
              onPressed: _previousPage,
              child: const Text('Atrás', style: TextStyle(color: Colors.grey, fontSize: 16, fontFamily: _kTitleFont)),
            )
          else
            const SizedBox(width: 60), 
            
          ElevatedButton(
            onPressed: provider.isLoading ? null : () => _nextPage(provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: provider.isLoading
                ? const SizedBox(
                    width: 20, height: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                  )
                : Text(
                    _currentPage == _totalPages - 1 ? 'Finalizar' : 'Siguiente',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: _kTitleFont, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}