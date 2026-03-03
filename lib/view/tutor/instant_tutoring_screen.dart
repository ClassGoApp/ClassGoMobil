import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';
import 'package:image_picker/image_picker.dart';
import 'payment_qr_screen.dart';

class InstantTutoringScreen extends StatefulWidget {
  final String tutorName;
  final String tutorImage;
  final List<String> subjects;
  final String? selectedSubject;
  final int tutorId;
  final int subjectId;
  // ✅ NUEVO: Parámetros para reserva programada
  final DateTime? scheduledDate;
  final String? scheduledTime;
  final bool isScheduledBooking;

  const InstantTutoringScreen({
    Key? key,
    required this.tutorName,
    required this.tutorImage,
    required this.subjects,
    this.selectedSubject,
    required this.tutorId,
    required this.subjectId,
    // ✅ NUEVO: Parámetros opcionales
    this.scheduledDate,
    this.scheduledTime,
    this.isScheduledBooking = false,
  }) : super(key: key);

  @override
  _InstantTutoringScreenState createState() => _InstantTutoringScreenState();
}

class _InstantTutoringScreenState extends State<InstantTutoringScreen>
    with TickerProviderStateMixin {
  String? _selectedSubject;
  File? _selectedImage;
  final DraggableScrollableController _scrollController =
      DraggableScrollableController();
  final ImagePicker _picker = ImagePicker();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Nuevas variables para el dropdown personalizado
  final GlobalKey _subjectSelectorKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;
  late AnimationController _dropdownAnimController;
  late Animation<double> _dropdownAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // ✅ DEBUG: Mostrar datos recibidos
    print('[InstantTutoringScreen] 🔍 DEBUG - Datos recibidos:');
    print(
        '[InstantTutoringScreen] isScheduledBooking: ${widget.isScheduledBooking}');
    print('[InstantTutoringScreen] scheduledDate: ${widget.scheduledDate}');
    print('[InstantTutoringScreen] scheduledTime: ${widget.scheduledTime}');
    print('[InstantTutoringScreen] selectedSubject: ${widget.selectedSubject}');

    // Selecciona la materia si viene preseleccionada
    if (widget.selectedSubject != null &&
        widget.subjects.contains(widget.selectedSubject)) {
      _selectedSubject = widget.selectedSubject;
    }

    // Iniciar la animación inmediatamente para la primera página
    _animationController.forward();

    _scrollController.addListener(() {
      if (_scrollController.size <= 0.8) {
        if (Navigator.canPop(context)) Navigator.of(context).pop();
      }
    });

    // Controlador de animación para el nuevo dropdown
    _dropdownAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _dropdownAnimation = CurvedAnimation(
      parent: _dropdownAnimController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    _animationController.dispose();
    _dropdownAnimController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    // Cierra el dropdown si ya hay uno abierto (seguridad)
    if (_overlayEntry != null) {
      _closeDropdown();
    }

    final RenderBox renderBox =
        _subjectSelectorKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: _toggleDropdown, // Cierra el dropdown al tocar fuera
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned(
                  left: offset.dx,
                  top: offset.dy + size.height + 8, // 8px de espacio
                  width: size.width,
                  child: FadeTransition(
                    opacity: _dropdownAnimation,
                    child: ScaleTransition(
                      alignment: Alignment.topCenter,
                      scale: _dropdownAnimation,
                      child: _buildDropdownList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
    });
    _dropdownAnimController.forward();
  }

  void _closeDropdown() {
    if (_overlayEntry != null) {
      _dropdownAnimController.reverse().then((value) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        setState(() {
          _isDropdownOpen = false;
        });
      });
    }
  }

  Widget _buildDropdownList() {
    return Container(
      constraints: BoxConstraints(
          maxHeight: 250), // Evita que la lista sea demasiado larga
      decoration: BoxDecoration(
        color: AppColors.darkBlue.withOpacity(0.98),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: ListView.separated(
            itemCount: widget.subjects.length,
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(vertical: 8),
            separatorBuilder: (context, index) => Divider(
              color: Colors.white.withOpacity(0.1),
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final subject = widget.subjects[index];
              final isSelected = subject == _selectedSubject;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedSubject = subject;
                  });
                  _toggleDropdown();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  color: isSelected
                      ? AppColors.lightBlueColor.withOpacity(0.2)
                      : Colors.transparent,
                  child: Row(
                    children: [
                      Icon(
                        Icons.book_outlined,
                        color: isSelected
                            ? AppColors.lightBlueColor
                            : Colors.white70,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          subject,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          color: AppColors.lightBlueColor,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar la imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBlue.withOpacity(0.95),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '¿Cómo quieres añadir la imagen?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Divider(color: Colors.white.withOpacity(0.2)),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.white),
                title:
                    Text('Tomar foto', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.white),
                title: Text('Seleccionar de galería',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return makeDismissible(
      context: context,
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        controller: _scrollController,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.darkBlue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Información del Tutor
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundImage: NetworkImage(widget.tutorImage),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.tutorName,
                                    style: AppTextStyles.heading2
                                        .copyWith(color: Colors.white),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _selectedSubject ?? 'Tutor de ClassGo',
                                    style: AppTextStyles.body
                                        .copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        // ✅ NUEVO: Título dinámico según el tipo de tutoría
                        if (widget.isScheduledBooking) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.lightBlueColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.lightBlueColor
                                      .withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.schedule,
                                    color: AppColors.lightBlueColor, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Reserva Programada',
                                    style: TextStyle(
                                      color: AppColors.lightBlueColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Fecha: ${widget.scheduledDate?.day}/${widget.scheduledDate?.month}/${widget.scheduledDate?.year}',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            'Hora: ${widget.scheduledTime}',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          SizedBox(height: 24),
                        ],
                        // 2. Selector de Materia
                        Text(
                          'Elige la materia',
                          style: AppTextStyles.heading2
                              .copyWith(color: Colors.white, fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        GestureDetector(
                          key: _subjectSelectorKey,
                          onTap: _toggleDropdown,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _isDropdownOpen
                                      ? AppColors.lightBlueColor
                                      : Colors.white.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedSubject ?? 'Seleccionar materia',
                                  style: TextStyle(
                                      color: _selectedSubject != null
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 16),
                                ),
                                AnimatedRotation(
                                  turns: _isDropdownOpen ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(Icons.keyboard_arrow_down,
                                      color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),

                        // 3. Scroll Horizontal para Imagen y Notas
                        Container(
                          height: 280, // Reducida de 320 a 280
                          child: Column(
                            children: [
                              // PageView para el contenido
                              Expanded(
                                child: PageView(
                                  controller: _pageController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentPage = index;
                                    });
                                    // Animación al cambiar página
                                    _animationController.reset();
                                    _animationController.forward();
                                  },
                                  children: [
                                    // Página 1: Subir imagen
                                    AnimatedBuilder(
                                      animation: _fadeAnimation,
                                      builder: (context, child) {
                                        return Opacity(
                                          opacity: _currentPage == 0
                                              ? _fadeAnimation.value
                                              : 1.0,
                                          child: Transform.translate(
                                            offset: Offset(
                                              _currentPage == 0
                                                  ? (1 - _fadeAnimation.value) *
                                                      20
                                                  : 0,
                                              0,
                                            ),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.1)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.lightbulb_outline,
                                                    color: AppColors
                                                        .lightBlueColor,
                                                    size: 18),
                                                SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    '📸 ¡Acelera tu aprendizaje!',
                                                    style: AppTextStyles
                                                        .heading2
                                                        .copyWith(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              'Sube una foto de tu ejercicio. Ayuda al tutor a:\n'
                                              '• Preparar la sesión con anticipación\n'
                                              '• Entender exactamente qué necesitas',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                height: 1.2,
                                              ),
                                            ),
                                            SizedBox(height: 12),

                                            // Vista previa de imagen o botón para subir
                                            if (_selectedImage != null) ...[
                                              Stack(
                                                children: [
                                                  Container(
                                                    width: double.infinity,
                                                    height: 120,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      image: DecorationImage(
                                                        image: FileImage(
                                                            _selectedImage!),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 6,
                                                    right: 6,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          _selectedImage = null;
                                                        });
                                                      },
                                                      child: Container(
                                                        padding:
                                                            EdgeInsets.all(4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.black
                                                              .withOpacity(0.7),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: Icon(Icons.close,
                                                            color: Colors.white,
                                                            size: 14),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                '✅ Imagen añadida correctamente',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.lightBlueColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ] else ...[
                                              GestureDetector(
                                                onTap: _showImageSourceDialog,
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 80,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.2),
                                                      style: BorderStyle.solid,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.add_a_photo,
                                                        color: AppColors
                                                            .lightBlueColor,
                                                        size: 24,
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        'Toca para añadir foto',
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      SizedBox(height: 2),
                                                      Text(
                                                        'Cámara o Galería',
                                                        style: TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Página 2: Notas para el tutor
                                    AnimatedBuilder(
                                      animation: _fadeAnimation,
                                      builder: (context, child) {
                                        return Opacity(
                                          opacity: _currentPage == 1
                                              ? _fadeAnimation.value
                                              : 1.0,
                                          child: Transform.translate(
                                            offset: Offset(
                                              _currentPage == 1
                                                  ? (1 - _fadeAnimation.value) *
                                                      -20
                                                  : 0,
                                              0,
                                            ),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.1)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.edit_note,
                                                    color: AppColors
                                                        .lightBlueColor,
                                                    size: 18),
                                                SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    '✍️ Cuéntale al tutor',
                                                    style: AppTextStyles
                                                        .heading2
                                                        .copyWith(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 6),
                                            Text(
                                              'Describe qué necesitas ayuda:\n'
                                              '• ¿Qué tema quieres repasar?\n'
                                              '• ¿Qué esperas de esta sesión?',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                height: 1.2,
                                              ),
                                            ),
                                            SizedBox(height: 12),

                                            // Campo de texto para notas
                                            TextField(
                                              maxLines: 4,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                              decoration: InputDecoration(
                                                hintText:
                                                    'Ej: "Necesito repasar las leyes de Newton, especialmente la tercera ley..."',
                                                hintStyle: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                  fontSize: 12,
                                                  height: 1.2,
                                                ),
                                                filled: true,
                                                fillColor: Colors.white
                                                    .withOpacity(0.1),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Barra de indicadores del scroll horizontal (ahora debajo)
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      _pageController.animateToPage(
                                        0,
                                        duration: Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    child: _HorizontalStepBar(
                                        isActive: _currentPage == 0,
                                        label: 'Foto'),
                                  ),
                                  SizedBox(width: 20),
                                  GestureDetector(
                                    onTap: () {
                                      _pageController.animateToPage(
                                        1,
                                        duration: Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    child: _HorizontalStepBar(
                                        isActive: _currentPage == 1,
                                        label: 'Notas'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 30), // Reducido de 40 a 30
                      ],
                    ),
                  ),
                ),
                // --- Contenido Fijo en la Parte Inferior ---
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Mensaje de Enlace de Sesión
                      Text(
                        'El enlace de la sesión estará disponible en los detalles de la sesión después del pago.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      SizedBox(height: 16),
                      // 2. Botón de Pago
                      ElevatedButton(
                        onPressed: _selectedSubject != null
                            ? () {
                                // Reemplaza el modal actual con la pantalla de pago
                                Navigator.of(context).pushReplacement(
                                  PageRouteBuilder(
                                    opaque: false,
                                    barrierColor: Colors.black.withOpacity(0.5),
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) {
                                      // ✅ DEBUG: Mostrar datos que se van a pasar a PaymentQRScreen
                                      print(
                                          '[InstantTutoringScreen] 🔍 DEBUG - Datos a pasar a PaymentQRScreen:');
                                      print(
                                          '[InstantTutoringScreen] scheduledDate: ${widget.scheduledDate}');
                                      print(
                                          '[InstantTutoringScreen] scheduledTime: ${widget.scheduledTime}');
                                      print(
                                          '[InstantTutoringScreen] isScheduledBooking: ${widget.isScheduledBooking}');

                                      return PaymentQRScreen(
                                        tutorName: widget.tutorName,
                                        tutorImage: widget.tutorImage,
                                        selectedSubject: _selectedSubject!,
                                        amount: "15 Bs",
                                        sessionDuration: "20 min",
                                        tutorId: widget.tutorId,
                                        subjectId: widget.subjectId,
                                        // ✅ NUEVO: Pasar datos de reserva programada
                                        scheduledDate: widget.scheduledDate,
                                        scheduledTime: widget.scheduledTime,
                                        isScheduledBooking:
                                            widget.isScheduledBooking,
                                      );
                                    },
                                    transitionDuration:
                                        Duration(milliseconds: 400),
                                    reverseTransitionDuration:
                                        Duration(milliseconds: 400),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      const begin = Offset(1.0, 0.0);
                                      const end = Offset.zero;
                                      const curve = Curves.easeOutCubic;

                                      var tween = Tween(begin: begin, end: end)
                                          .chain(CurveTween(curve: curve));
                                      var offsetAnimation =
                                          animation.drive(tween);

                                      // Usa un FadeTransition para que la pantalla anterior no desaparezca bruscamente
                                      return FadeTransition(
                                        opacity: secondaryAnimation
                                            .drive(Tween(begin: 1.0, end: 0.0)),
                                        child: SlideTransition(
                                          position: offsetAnimation,
                                          child: child,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          disabledBackgroundColor:
                              Colors.white.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text(
                          widget.isScheduledBooking
                              ? 'Confirmar Reserva'
                              : 'Pagar e Iniciar en 2-5 min',
                          style: TextStyle(
                            color: AppColors.darkBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // 3. Aviso de Reclamo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.white54, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tendrá la opción de hacer su reclamo respectivo sobre algún problema con la tutoría hasta 3 min terminada la tutoría.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 4. Stepper de Pasos
                Padding(
                  padding: const EdgeInsets.only(bottom: 18, top: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepBar(isActive: true),
                      SizedBox(width: 12),
                      _StepBar(isActive: false),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget makeDismissible(
      {required Widget child, required BuildContext context}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (Navigator.canPop(context)) Navigator.of(context).pop();
      },
      child: GestureDetector(onTap: () {}, child: child),
    );
  }
}

class _StepBar extends StatelessWidget {
  final bool isActive;
  const _StepBar({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: 60,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.lightBlueColor
            : Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _HorizontalStepBar extends StatelessWidget {
  final bool isActive;
  final String label;

  const _HorizontalStepBar({
    required this.isActive,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: Duration(
              milliseconds:
                  400), // Aumentado de 300 a 400 para animación más suave
          curve: Curves.easeInOut, // Añadida curva de animación
          width: isActive
              ? 80
              : 60, // Ancho dinámico: más ancho cuando está activo
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.lightBlueColor
                : Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(6),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.lightBlueColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null, // Sombra solo cuando está activo
          ),
        ),
        SizedBox(height: 8),
        AnimatedDefaultTextStyle(
          duration: Duration(milliseconds: 300),
          style: TextStyle(
            color: isActive ? AppColors.lightBlueColor : Colors.white54,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
          child: Text(label),
        ),
      ],
    );
  }
}
