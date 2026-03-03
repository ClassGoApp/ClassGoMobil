
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_projects/styles/app_styles.dart';

// class AvailabilitySlider extends StatefulWidget {
//   final bool isAvailable;
//   final Function(bool) onStatusChanged;

//   const AvailabilitySlider({
//     Key? key,
//     required this.isAvailable,
//     required this.onStatusChanged,
//   }) : super(key: key);

//   @override
//   State<AvailabilitySlider> createState() => _AvailabilitySliderState();
// }

// class _AvailabilitySliderState extends State<AvailabilitySlider> {
//   double _dragOffset = 0.0;
//   bool _isDragging = false;
//   static const double _buttonWidth = 60.0;
//   static const double _padding = 4.0; 

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final double maxWidth = constraints.maxWidth;
//         final double maxDrag = maxWidth - _buttonWidth - (_padding * 2);

//         final double activePosition = maxDrag;

//         double currentLeft;
//         if (_isDragging) {
//           currentLeft = _dragOffset;
//         } else {
//           currentLeft = widget.isAvailable ? activePosition : 0.0;
//         }

//         return Container(
//           height: 60,
//           decoration: BoxDecoration(
//             color: const Color(0xFF2a2a3e),
//             borderRadius: BorderRadius.circular(30),
//             border: Border.all(
//               color: widget.isAvailable 
//                   ? AppColors.primaryGreen 
//                   : AppColors.orangeprimary,
//               width: 2,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.3),
//                 blurRadius: 8,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(_padding),
//             child: Stack(
//               children: [
//                 AnimatedContainer(
//                   duration: const Duration(milliseconds: 300),
//                   curve: Curves.easeInOut,
//                   width: widget.isAvailable ? maxWidth : 0,
//                   decoration: BoxDecoration(
//                     color: (widget.isAvailable 
//                         ? AppColors.primaryGreen 
//                         : AppColors.orangeprimary).withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                 ),

//                 Center(
//                   child: AnimatedSwitcher(
//                     duration: const Duration(milliseconds: 300),
//                     child: Text(
//                       widget.isAvailable ? 'DISPONIBLE' : 'OFFLINE',
//                       key: ValueKey(widget.isAvailable),
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.9),
//                         fontSize: 16,
//                         fontWeight: FontWeight.w800,
//                         letterSpacing: 1.5,
//                       ),
//                     ),
//                   ),
//                 ),

//                 Positioned(
//                   left: currentLeft,
//                   top: 0,
//                   bottom: 0,
//                   child: GestureDetector(
//                     onHorizontalDragStart: (_) {
//                       setState(() {
//                         _isDragging = true;
//                         _dragOffset = widget.isAvailable ? activePosition : 0.0; 
//                       });
//                       HapticFeedback.lightImpact();
//                     },
//                     onHorizontalDragUpdate: (details) {
//                       setState(() {
//                         double newPos = _dragOffset + details.delta.dx;
//                         _dragOffset = newPos.clamp(0.0, activePosition);
//                       });
//                     },
//                     onHorizontalDragEnd: (_) {
//                       setState(() {
//                         _isDragging = false;
//                       });

//                       if (_dragOffset > (activePosition / 2)) {
//                         if (!widget.isAvailable) {
//                           HapticFeedback.heavyImpact();
//                           widget.onStatusChanged(true); 
//                         }
//                       } else {
//                         if (widget.isAvailable) {
//                           HapticFeedback.heavyImpact();
//                           widget.onStatusChanged(false); 
//                         }
//                       }
//                     },
//                     child: Container(
//                       width: _buttonWidth,
//                       decoration: BoxDecoration(
//                         color: widget.isAvailable 
//                             ? AppColors.primaryGreen 
//                             : AppColors.orangeprimary,
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.3),
//                             blurRadius: 6,
//                             offset: const Offset(0, 3),
//                           ),
//                         ],
//                       ),
//                       child: Center(
//                         child: Icon(
//                           widget.isAvailable ? Icons.check : Icons.close,
//                           color: Colors.white,
//                           size: 28,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }