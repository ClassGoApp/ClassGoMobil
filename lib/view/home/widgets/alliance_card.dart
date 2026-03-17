import 'package:flutter/material.dart';
import 'package:flutter_projects/api_structure/api_service.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class AlliancesScreen extends StatefulWidget {
  const AlliancesScreen({super.key});

  @override
  State<AlliancesScreen> createState() => _AlliancesScreenState();
}

class _AlliancesScreenState extends State<AlliancesScreen> {
  List<dynamic> rawAlliances = [];
  bool isLoading = true;
  String errorMsg = "";

  @override
  void initState() {
    super.initState();
    _fetchMinimalData();
  }

  // ENFOQUE MINIMALISTA EXTREMO: Solo traer y guardar.
  Future<void> _fetchMinimalData() async {
    try {
      debugPrint("🚀 Iniciando llamada al servidor...");
      final response = await fetchAlliances();
      
      if (!mounted) return;
      debugPrint("✅ Respuesta recibida del servidor.");

      if (response.containsKey('data')) {
        setState(() {
          rawAlliances = response['data'];
          isLoading = false;
        });
        debugPrint("📦 Total de alianzas cargadas en RAM: ${rawAlliances.length}");
      } else {
        setState(() {
          errorMsg = "No se encontró el nodo 'data' en el JSON.";
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error crítico en el Fetch: $e");
      if (mounted) {
        setState(() {
          errorMsg = "Error conectando: $e";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Test de Estrés', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (errorMsg.isNotEmpty) {
      return Center(child: Text(errorMsg, style: const TextStyle(color: Colors.red)));
    }

    if (rawAlliances.isEmpty) {
      return const Center(child: Text("La lista llegó vacía del servidor."));
    }

    // LISTVIEW BÁSICO: El widget más ligero de todo Flutter
    return ListView.builder(
      itemCount: rawAlliances.length,
      itemBuilder: (context, index) {
        final item = rawAlliances[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(item['titulo']?.toString() ?? 'Sin Título'),
            subtitle: Text("Cat: ${item['categoria']} | ID: ${item['id']}"),
            leading: const Icon(Icons.star, color: Colors.amber),
          ),
        );
      },
    );
  }
}