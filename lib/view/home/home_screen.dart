import 'package:flutter/material.dart';
import 'package:flutter_projects/helpers/auth_helper.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/view/home/widgets/categories_carousel.dart';
import 'package:flutter_projects/view/home/widgets/home_drawer.dart';
import 'package:flutter_projects/view/home/widgets/home_header.dart';
import 'package:flutter_projects/view/home/widgets/pet_banner.dart';
import 'package:flutter_projects/view/home/widgets/quick_actions_section.dart';
import 'package:flutter_projects/view/home/widgets/trust_actions_row.dart';
import 'package:flutter_projects/view/profile/profile_screen.dart';
import 'package:flutter_projects/view/student/serch_Tutor/search_tutors_screen.dart'; 
import 'package:flutter_projects/view/home/widgets/stats_bar.dart';
import 'package:flutter_projects/view/home/widgets/whatsapp_button.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: Navigator.canPop(context),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.backgroundLight,
        drawer: const HomeDrawer(),
        floatingActionButton: const WhatsAppButton(),
        body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          HomeHeader(
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            onProfileTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(),
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25),

                QuickActionsRow(
                  onInstantTutorTap: () {
                    if (!AuthHelper.requireAuth(context,
                        customTitle: l10n.accessToInstantTutorTitle,
                        customMessage: l10n.accessToInstantTutorMessage)) {
                      return;
                    }
                  },
                  onScheduleTap: () {
                    if (!AuthHelper.requireAuth(context,
                        customTitle: l10n.scheduleTutoringTitle,
                        customMessage: l10n.scheduleTutoringMessage)) {
                      return;
                    }

                    debugPrint("Usuario verificado. Navegando a Agendar...");
                  },
                  
                  onExploreTap: () {
                    debugPrint("Navegando a Explorar Tutores (Vista Pública)...");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchTutorsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 25),
                const MascotBanner(),
                const SizedBox(height: 25),
                const StatsBar(),

                const SizedBox(height: 30),
                const CategoriesCarousel(),

                const SizedBox(height: 35),
                const TrustActionsRow(),
               
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
