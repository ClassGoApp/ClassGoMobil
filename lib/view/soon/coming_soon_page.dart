import 'package:flutter/material.dart';

import '../../styles/app_styles.dart';
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key});

  @override
  Widget build(BuildContext context) {

    final height = MediaQuery.of(context).size.height;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.primaryGreen,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logoespecial.png'),
            Text(
              'Ingresa a la Pagina para verificar la reserva',
              style: TextStyle(
                fontFamily: 'SF-Pro-Text',
                fontWeight: FontWeight.w700,
                fontSize: FontSize.scale(context, 24),
                color: AppColors.whiteColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: height * 0.01),
            Text(
              'La funcionalidad de Pago estara disponible pronto',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF-Pro-Text',
                fontWeight: FontWeight.w400,
                fontSize: FontSize.scale(context, 16),
                color: AppColors.whiteColor,
              ),
            ),
            Text(
              'Te recomendamos reiniciar la aplicacion',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF-Pro-Text',
                fontWeight: FontWeight.w400,
                fontSize: FontSize.scale(context, 16),
                color: AppColors.whiteColor,
              ),
            ),

          ],
        ),
      ),
    );
  }
}
