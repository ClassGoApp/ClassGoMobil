import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:flutter_projects/provider/auth_provider.dart';
import 'package:flutter_projects/api_structure/api_service.dart';

const String _kTitleFont = 'outfit';
const String _kBodyFont = 'manrope';

class TutorPriceSection extends StatefulWidget {
  const TutorPriceSection({Key? key}) : super(key: key);

  @override
  State<TutorPriceSection> createState() => _TutorPriceSectionState();
}

class _TutorPriceSectionState extends State<TutorPriceSection> {
  String _price = '0';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialPrice();
      _syncPriceFromServer();
    });
  }

  void _loadInitialPrice() {
    final authData = Provider.of<AuthProvider>(context, listen: false).userData;
    final dynamic savedPrice = authData?['user']?['profile']?['price'] ??
        authData?['profile']?['price'] ??
        authData?['user']?['price'];

    if (savedPrice != null && mounted) {
      setState(() => _price = savedPrice.toString());
    }
  }

  Future<void> _syncPriceFromServer() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (auth.token == null || auth.userId == null) return;

    try {
      final response = await getProfile(auth.token!, auth.userId!);

      final data = response['data'] ?? {};
      final profile = data['profile'] ?? {};
      final serverPrice = profile['price']?.toString();

      if (serverPrice == null || !mounted) return;
      if (serverPrice != _price) {
        setState(() => _price = serverPrice);

        if (auth.userData != null) {
          if (auth.userData!['user']?['profile'] != null)
            auth.userData!['user']['profile']['price'] = serverPrice;
          if (auth.userData!['profile'] != null)
            auth.userData!['profile']['price'] = serverPrice;
        }
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final innerBgColor =
        isDark ? const Color(0xFF1E222A) : const Color(0xFFF4F6F9);
    final mainTextColor = isDark ? Colors.white : AppColors.brandBlue;

    return Container(
      decoration: BoxDecoration(
        color: innerBgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.brandCyan.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.payments_rounded,
              color: AppColors.brandCyan, size: 20),
        ),
        title: const Text(
          "TARIFA POR TUTORÍA",
          style: TextStyle(
              fontFamily: _kTitleFont,
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            "$_price Bs / 20min.",
            style: TextStyle(
                fontFamily: _kTitleFont,
                color: mainTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w900),
          ),
        ),
        trailing: Icon(Icons.edit_rounded,
            color: isDark ? Colors.white70 : AppColors.brandBlue, size: 18),
        onTap: () => _showPriceModal(context, _price),
      ),
    );
  }

  void _showPriceModal(BuildContext context, String currentPrice) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF151A24) : AppColors.whiteColor;
    final inputBg = isDark ? Colors.black26 : const Color(0xFFF4F6F9);
    final textColor = isDark ? AppColors.whiteColor : AppColors.brandBlue;

    TextEditingController priceController =
        TextEditingController(text: currentPrice);
    priceController.selection =
        TextSelection(baseOffset: 0, extentOffset: currentPrice.length);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),
              Text("Definir Tarifa",
                  style: TextStyle(
                      fontFamily: _kTitleFont,
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text(
                  "Ingresa el monto que cobrarás por 20 minutos de tutoría.",
                  style: TextStyle(
                      fontFamily: _kBodyFont,
                      color: Colors.grey,
                      fontSize: 13)),
              const SizedBox(height: 24),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                    fontFamily: _kBodyFont,
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.attach_money_rounded,
                      color: AppColors.brandCyan),
                  suffixText: "Bs / 20min",
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandCyan,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  onPressed: () =>
                      _updatePrice(context, priceController.text.trim()),
                  child: const Text("GUARDAR TARIFA",
                      style: TextStyle(
                          fontFamily: _kTitleFont,
                          color: Colors.white,
                          fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updatePrice(BuildContext context, String newPrice) async {
    if (newPrice.isEmpty || newPrice == _price) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
            child: CircularProgressIndicator(color: AppColors.brandCyan)));

    try {
      final response =
          await updateProfilePrice(auth.token!, auth.userId!, newPrice);

      if (response['success'] == true || response['status'] == 200) {
        if (auth.userData != null) {
          if (auth.userData!['user']?['profile'] != null)
            auth.userData!['user']['profile']['price'] = newPrice;
          if (auth.userData!['profile'] != null)
            auth.userData!['profile']['price'] = newPrice;
        }

        if (mounted) {
          setState(() => _price = newPrice);
          Navigator.pop(context);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Tarifa actualizada correctamente'),
              backgroundColor: AppColors.brandCyan));
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }
}
