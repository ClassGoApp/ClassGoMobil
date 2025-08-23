import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../provider/auth_provider.dart';
import '../../styles/app_styles.dart';
import '../../base_components/custom_snack_bar.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPhoneValid = true;
  String? _profileImageUrl;
  bool _isImageLoading = false;
  
  @override
  void initState() {
    super.initState();
    print('DEBUG - EditProfileScreen initState iniciado');
    
    // Cargar perfil inmediatamente
    _loadCurrentProfile();
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  

  
  void _loadCurrentProfile() async {
    print('DEBUG - Iniciando carga del perfil...');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.userData == null) {
      print('DEBUG - userData es null');
      return;
    }
    
    if (authProvider.userData!['user'] == null) {
      print('DEBUG - user es null');
      return;
    }
    
    final profile = authProvider.userData!['user']['profile'];
    if (profile == null) {
      print('DEBUG - profile es null');
      return;
    }
    
    print('DEBUG - Profile encontrado: $profile');
    
    _firstNameController.text = profile['first_name'] ?? '';
    _lastNameController.text = profile['last_name'] ?? '';
    _phoneController.text = profile['phone_number'] ?? '';
    _descriptionController.text = profile['description'] ?? '';
    
    // Cargar imagen de perfil usando EXACTAMENTE la misma API que el dashboard
    await _loadProfileImageFromDashboard();
    
    // La UI se actualizará automáticamente cuando se asigne _profileImageUrl
    print('DEBUG - Perfil cargado completamente');
  }
  

  
  Future<void> _loadProfileImageFromDashboard() async {
    try {
      print('DEBUG - Cargando imagen de perfil usando API del dashboard...');
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.userData?['user']['id'];
      
      if (token != null && userId != null) {
        print('DEBUG - Token y userId obtenidos, llamando API...');
        
        // Usar EXACTAMENTE la misma API que el dashboard
        final response = await http.get(
          Uri.parse('https://classgoapp.com/api/user/$userId/profile-image'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        
        print('DEBUG - Respuesta del servidor: ${response.statusCode} - ${response.body}');
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          print('DEBUG - Respuesta parseada: $responseData');
          
          // La respuesta viene directamente con los datos, no en {success: true, data: {...}}
          final profileImageUrl = responseData['profile_image'];
          
                     if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
             if (mounted) {
               setState(() {
                 _profileImageUrl = profileImageUrl;
               });
             }
             
             // También actualizar en el AuthProvider para mantener sincronización
             authProvider.updateProfileImage(profileImageUrl);
             
             print('DEBUG - Imagen cargada exitosamente desde dashboard: $_profileImageUrl');
           } else {
             print('DEBUG - No hay URL de imagen en la respuesta');
           }
        } else {
          print('DEBUG - Error en la respuesta: ${response.statusCode}');
        }
      } else {
        print('DEBUG - No hay token o userId disponible');
      }
    } catch (e) {
      print('DEBUG - Error cargando imagen desde dashboard: $e');
    }
  }
  
  bool _validatePhone(String phone) {
    // Validación básica para números de teléfono
    return phone.length >= 8 && phone.length <= 15;
  }
  
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userData?['user']['id'];
      final token = authProvider.token;
      
      if (userId == null || token == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Preparar los datos en formato x-www-form-urlencoded
      final body = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'description': _descriptionController.text.trim(),
        'full_name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      };
      
      // Debug: imprimir los datos que se van a enviar
      print('DEBUG - Datos a enviar: $body');
      print('DEBUG - URL: https://classgoapp.com/api/user/$userId/profile');
      
      final response = await http.put(
        Uri.parse('https://classgoapp.com/api/user/$userId/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
      
      print('DEBUG - Status code: ${response.statusCode}');
      print('DEBUG - Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Actualizar el perfil localmente
        await authProvider.updateUserProfiles(body);
        
        // Mostrar mensaje de éxito
        _showCustomToast('Perfil actualizado exitosamente', true);
        
        // Regresar a la pantalla anterior y forzar actualización
        Navigator.pop(context, true); // Pasar true para indicar que se actualizó la imagen
        
        // Forzar actualización del provider para asegurar que la UI se actualice
        Future.delayed(Duration(milliseconds: 100), () {
          authProvider.notifyListeners();
        });
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Error al actualizar el perfil');
      }
    } catch (e) {
      print('DEBUG - Error: $e');
      _showCustomToast('Error: ${e.toString()}', false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showCustomToast(String message, bool isSuccess) {
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100.0,
        left: 16.0,
        right: 16.0,
        child: CustomToast(
          message: message,
          isSuccess: isSuccess,
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
  


  @override
  Widget build(BuildContext context) {
    print('DEBUG - Build ejecutado, _profileImageUrl: $_profileImageUrl');
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.blurprimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.whiteColor),
          onPressed: () {
            // Forzar actualización antes de regresar
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            authProvider.notifyListeners();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Editar Perfil',
          style: TextStyle(
            color: AppColors.whiteColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icono
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.navbar, AppColors.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                                         GestureDetector(
                       onTap: () => _showImageOptions(),
                       child: Container(
                         width: 80,
                         height: 80,
                         decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           border: Border.all(
                             color: AppColors.whiteColor.withOpacity(0.3),
                             width: 3,
                           ),
                           boxShadow: [
                             BoxShadow(
                               color: Colors.black.withOpacity(0.2),
                               blurRadius: 8,
                               offset: Offset(0, 4),
                             ),
                           ],
                         ),
                         child: Stack(
                           children: [
                             ClipOval(
                               child: AnimatedSwitcher(
                                 key: ValueKey(_profileImageUrl ?? 'no-image'),
                                 duration: Duration(milliseconds: 300),
                                 transitionBuilder: (Widget child, Animation<double> animation) {
                                   return FadeTransition(
                                     opacity: animation,
                                     child: child,
                                   );
                                 },
                                 child: _buildProfileImage(),
                               ),
                             ),
                             Positioned(
                               bottom: 0,
                               right: 0,
                               child: Container(
                                 padding: EdgeInsets.all(4),
                                 decoration: BoxDecoration(
                                   color: AppColors.navbar,
                                   shape: BoxShape.circle,
                                   border: Border.all(
                                     color: AppColors.whiteColor,
                                     width: 2,
                                   ),
                                 ),
                                 child: Icon(
                                   Icons.camera_alt,
                                   color: AppColors.whiteColor,
                                   size: 16,
                                 ),
                               ),
                             ),
                           ],
                         ),
                       ),
                     ),
                                           SizedBox(height: 16),
                      Text(
                        'Actualiza tu información personal',
                        style: TextStyle(
                          color: AppColors.whiteColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                                             // Mostrar mensaje de éxito si la imagen se actualizó
                       if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                         Column(
                           children: [
                             Container(
                               margin: EdgeInsets.only(top: 8),
                               padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                               decoration: BoxDecoration(
                                 color: AppColors.navbar.withOpacity(0.2),
                                 borderRadius: BorderRadius.circular(20),
                                 border: Border.all(
                                   color: AppColors.navbar.withOpacity(0.5),
                                   width: 1,
                                 ),
                               ),
                               child: Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   Icon(
                                     Icons.check_circle,
                                     color: AppColors.navbar,
                                     size: 16,
                                   ),
                                   SizedBox(width: 6),
                                   Text(
                                     'Imagen actualizada y mostrada',
                                     style: TextStyle(
                                       color: AppColors.navbar,
                                       fontSize: 12,
                                       fontWeight: FontWeight.w500,
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                            SizedBox(height: 12),
                            // Botón para regresar al dashboard
                            GestureDetector(
                              onTap: () {
                                // Regresar indicando que se actualizó la imagen
                                Navigator.pop(context, true);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.navbar,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_back,
                                      color: AppColors.whiteColor,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Regresar al Dashboard',
                                      style: TextStyle(
                                        color: AppColors.whiteColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                  ],
                ),
              ),
              
              SizedBox(height: 32),
              
              // Campo Nombre
              _buildTextField(
                controller: _firstNameController,
                label: 'Nombre',
                hint: 'Ingresa tu nombre',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 20),
              
              // Campo Apellido
              _buildTextField(
                controller: _lastNameController,
                label: 'Apellido',
                hint: 'Ingresa tu apellido',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El apellido es requerido';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 20),
              
              // Campo Número de Teléfono
              _buildTextField(
                controller: _phoneController,
                label: 'Número de Celular',
                hint: 'Ingresa tu número de celular',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El número de celular es requerido';
                  }
                  if (!_validatePhone(value.trim())) {
                    return 'Ingresa un número de celular válido';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _isPhoneValid = _validatePhone(value);
                  });
                },
              ),
              
              SizedBox(height: 20),
              
                             // Campo Descripción
               _buildTextField(
                 controller: _descriptionController,
                 label: 'Descripción (opcional)',
                 hint: 'Cuéntanos sobre ti...',
                 icon: Icons.description_outlined,
                 maxLines: 4,
                 validator: (value) {
                   // La descripción es opcional, no hay validación obligatoria
                   return null;
                 },
               ),
              
              SizedBox(height: 40),
              
              // Botón de Actualizar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navbar,
                    foregroundColor: AppColors.whiteColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                                             ? SizedBox(
                           height: 24,
                           width: 24,
                           child: CircularProgressIndicator(
                             strokeWidth: 2,
                             valueColor: AlwaysStoppedAnimation<Color>(
                               AppColors.navbar,
                             ),
                           ),
                         )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_outlined, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Actualizar Perfil',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              SizedBox(height: 20),
              
                             // Información adicional
               Container(
                 padding: EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: AppColors.darkBlue.withOpacity(0.8),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(
                     color: AppColors.navbar.withOpacity(0.5),
                   ),
                 ),
                 child: Row(
                   children: [
                     Icon(
                       Icons.info_outline,
                       color: AppColors.navbar,
                       size: 20,
                     ),
                     SizedBox(width: 12),
                     Expanded(
                       child: Text(
                         'Los cambios se guardarán automáticamente en tu perfil',
                         style: TextStyle(
                           color: AppColors.whiteColor,
                           fontSize: 14,
                         ),
                       ),
                     ),
                   ],
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileImage() {
    if (_isImageLoading) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.darkBlue,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.navbar),
              ),
              SizedBox(height: 4),
              Text(
                'Actualizando...',
                style: TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Usar la variable local _profileImageUrl que se carga en _loadCurrentProfile
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      print('DEBUG - Construyendo imagen con URL: $_profileImageUrl');
      
      // Usar CachedNetworkImage directamente (como en el dashboard)
      return CachedNetworkImage(
        imageUrl: _profileImageUrl!,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.darkBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_outline,
            color: AppColors.whiteColor,
            size: 32,
          ),
        ),
        errorWidget: (context, url, error) {
          print('DEBUG - Error cargando imagen: $error');
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.darkBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              color: AppColors.whiteColor,
              size: 32,
            ),
          );
        },
      );
    }
    
    print('DEBUG - No hay imagen disponible, mostrando placeholder');
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_outline,
        color: AppColors.whiteColor,
        size: 32,
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGreyColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
              ListTile(
                leading: Icon(Icons.visibility, color: AppColors.navbar),
                title: Text(
                  'Ver imagen',
                  style: TextStyle(color: AppColors.whiteColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showImagePreview();
                },
              ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.navbar),
              title: Text(
                'Cambiar imagen',
                style: TextStyle(color: AppColors.whiteColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showImagePreview() {
    if (_profileImageUrl != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: _profileImageUrl!,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  color: AppColors.darkBlue,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.navbar),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.darkBlue,
                  child: Icon(
                    Icons.error,
                    color: AppColors.redColor,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _uploadImage(image);
      }
    } catch (e) {
      print('Error picking image: $e');
      _showCustomToast('Error al seleccionar la imagen', false);
    }
  }

  Future<void> _uploadImage(XFile imageFile) async {
    setState(() {
      _isImageLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userData?['user']['id'];
      final token = authProvider.token;
      
      if (userId == null || token == null) {
        throw Exception('Usuario no autenticado');
      }
      
                    // Crear la petición multipart con el endpoint correcto
       final request = http.MultipartRequest(
         'POST',
         Uri.parse('https://classgoapp.com/api/user/$userId/profile-files'),
       );
       
       print('DEBUG - URL de subida: ${request.url}');
       print('DEBUG - Método: ${request.method}');
       print('DEBUG - User ID: $userId');
       
       // Agregar headers
       request.headers['Authorization'] = 'Bearer $token';
       print('DEBUG - Headers: ${request.headers}');
      
             // Agregar la imagen
       final imageBytes = await imageFile.readAsBytes();
       print('DEBUG - Tamaño de imagen: ${imageBytes.length} bytes');
       print('DEBUG - Nombre de archivo: ${imageFile.name}');
       
       final imageField = http.MultipartFile.fromBytes(
         'image',
         imageBytes,
         filename: imageFile.name,
       );
       request.files.add(imageField);
       print('DEBUG - Archivo agregado: ${request.files.length} archivos');
      
      // Enviar la petición
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      print('DEBUG - Upload status: ${response.statusCode}');
      print('DEBUG - Upload response: $responseData');
      
             if (response.statusCode == 200 || response.statusCode == 201) {
         try {
           final jsonResponse = json.decode(responseData);
           
           if (jsonResponse['success'] == true || jsonResponse['status'] == 'success') {
             // Actualizar la imagen localmente
             String? newImageUrl;
             
             // Intentar diferentes estructuras de respuesta
             if (jsonResponse['data'] != null) {
               newImageUrl = jsonResponse['data']['image'] ?? 
                            jsonResponse['data']['profile']?['image'] ??
                            jsonResponse['data']['url'];
             } else if (jsonResponse['image'] != null) {
               newImageUrl = jsonResponse['image'];
             } else if (jsonResponse['url'] != null) {
               newImageUrl = jsonResponse['url'];
             }
             
             if (newImageUrl != null) {
               // Actualizar en el provider PRIMERO para que se sincronice en toda la app
               authProvider.updateProfileImage(newImageUrl);
               
               // Luego actualizar localmente
               setState(() {
                 _profileImageUrl = newImageUrl;
               });
               
               // Forzar actualización inmediata del provider
               authProvider.notifyListeners();
               
                               _showCustomToast('Imagen actualizada exitosamente', true);
                
                print('DEBUG - Imagen actualizada exitosamente: $newImageUrl');
                
                // Recargar la imagen desde la API para mostrar la nueva imagen
                print('DEBUG - Recargando imagen desde API después de actualización...');
                await _loadProfileImageFromDashboard();
             } else {
               throw Exception('No se pudo obtener la URL de la imagen actualizada');
             }
           } else {
             throw Exception(jsonResponse['message'] ?? 'Error al actualizar la imagen');
           }
         } catch (jsonError) {
           // Si no es JSON válido, verificar si es una respuesta de éxito simple
           if (responseData.contains('success') || responseData.contains('Success')) {
             _showCustomToast('Imagen actualizada exitosamente', true);
           } else {
             throw Exception('Respuesta del servidor no válida: $responseData');
           }
         }
       } else {
         // Manejar diferentes tipos de errores
         String errorMessage = 'Error al actualizar la imagen (${response.statusCode})';
         
         try {
           if (responseData.isNotEmpty) {
             final errorData = json.decode(responseData);
             errorMessage = errorData['message'] ?? errorMessage;
           }
         } catch (e) {
           // Si no es JSON, usar la respuesta como está
           if (responseData.isNotEmpty && responseData.length < 200) {
             errorMessage = responseData;
           }
         }
         
         throw Exception(errorMessage);
       }
    } catch (e) {
      print('Error uploading image: $e');
      _showCustomToast('Error: ${e.toString()}', false);
    } finally {
      setState(() {
        _isImageLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.whiteColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkBlue,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.navbar.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.lightGreyColor.withOpacity(0.7),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.navbar,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: TextStyle(
              color: AppColors.whiteColor,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
