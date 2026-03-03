import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/styles/app_styles.dart';

const String kFontFamily = 'outfit';

class SubjectListItem extends StatefulWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  const SubjectListItem({
    Key? key,
    required this.name,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<SubjectListItem> createState() => _SubjectListItemState();
}

class _SubjectListItemState extends State<SubjectListItem> {
  bool _isDeleting = false;

  // 🔥 ESTA ES LA MAGIA QUE ARREGLA EL BUG DEL COLOR CONTAGIOSO
  @override
  void didUpdateWidget(covariant SubjectListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si Flutter recicla esta tarjeta para otra materia, reseteamos la carga
    if (oldWidget.name != widget.name) {
      _isDeleting = false; 
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF16181D) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandBlue;

    // 🔥 ANIMATED OPACITY Y IGNORE POINTER PARA BLOQUEAR TOQUES
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isDeleting ? 0.4 : 1.0, 
      child: IgnorePointer(
        ignoring: _isDeleting,
        child: GestureDetector(
          onTap: () {
            if (!_isDeleting) {
              HapticFeedback.lightImpact();
              widget.onTap();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: widget.isSelected ? AppColors.brandCyan : (isDark ? Colors.white10 : Colors.transparent), 
                width: widget.isSelected ? 2.0 : 1.0
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.isSelected ? AppColors.brandCyan.withOpacity(0.15) : Colors.black.withOpacity(0.03),
                  blurRadius: widget.isSelected ? 20 : 10,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: widget.isSelected ? -0.05 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: AnimatedScale(
                    scale: widget.isSelected ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.brandCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: AppColors.brandCyan, size: 28),
                    ),
                  ),
                ),
                
                const SizedBox(width: 20),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: kFontFamily, height: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : AppColors.brandBlue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "ESPECIALIDAD",
                          style: TextStyle(color: isDark ? Colors.white70 : AppColors.brandBlue.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, fontFamily: kFontFamily),
                        ),
                      ),
                    ],
                  ),
                ),

                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: widget.isSelected 
                    ? Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: GestureDetector(
                          onTap: _isDeleting ? null : () async {
                            HapticFeedback.heavyImpact();
                            setState(() => _isDeleting = true); 
                            await widget.onDelete(); 
                            if (mounted) setState(() => _isDeleting = false); 
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F0),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
                            ),
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutBack,
                                    bottom: _isDeleting ? -4 : 2,
                                    child: Container(
                                      width: 14,
                                      height: 15,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.redAccent, width: 2),
                                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Container(width: 1.5, height: 8, color: Colors.redAccent.withOpacity(0.5)),
                                          Container(width: 1.5, height: 8, color: Colors.redAccent.withOpacity(0.5)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutBack,
                                    top: _isDeleting ? -8 : 3, 
                                    right: _isDeleting ? -6 : 4, 
                                    child: AnimatedRotation(
                                      turns: _isDeleting ? 0.12 : 0.0, 
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.easeOutBack,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 2,
                                            decoration: const BoxDecoration(
                                              color: Colors.redAccent,
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
                                            ),
                                          ),
                                          Container(
                                            width: 18,
                                            height: 2,
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  AnimatedOpacity(
                                    opacity: _isDeleting ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 10,
                                        height: 10,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}