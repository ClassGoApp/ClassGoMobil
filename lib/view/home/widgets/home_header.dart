import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/student/serch_Tutor/search_tutors_screen.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onProfileTap;

  const HomeHeader({
    Key? key,
    required this.onMenuTap,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      stretch: false,
      expandedHeight: 270.0,
      toolbarHeight: 70.0,
      collapsedHeight: 70.0,
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(60),
          bottomRight: Radius.circular(60),
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.fromARGB(255, 36, 107, 124), AppColors.brandBlue],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: FlexibleSpaceBar(
          background: SafeArea(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(top: 80.0, left: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.65,
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Encuentra tutores\npara tus materias',
                            style: TextStyle(
                              fontFamily: 'outfit',
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardLight,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5)),
                          ],
                        ),
                        child: TextField(
                          textInputAction: TextInputAction.search,
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchTutorsScreen(
                                    initialKeyword: value.trim(),
                                  ),
                                ),
                              );
                            }
                          },
                          style: const TextStyle(
                              fontFamily: 'manrope',
                              color: AppColors.textLightPrimary),
                          decoration: InputDecoration(
                            hintText: '¿En qué materia necesitas ayuda?',
                            hintStyle: const TextStyle(
                                fontFamily: 'manrope',
                                color: AppColors.lightGreyColor,
                                fontSize: 15),
                            prefixIcon: const Icon(Icons.search,
                                color: AppColors.brandCyan, size: 24),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 15,
                  top: 70,
                  child: Image.asset(
                    'assets/images/ave_animada.gif',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onMenuTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.menu, color: Colors.white, size: 24),
            ),
          ),
          Image.asset('assets/images/logo_classgo.png', height: 36),
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.person_outline,
                  color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
