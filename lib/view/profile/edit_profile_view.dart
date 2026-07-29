import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_projects/l10n/app_localizations.dart';
import 'package:flutter_projects/view/tutor/features/widgets/tutor_header.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class EditProfileView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController descriptionController;

  final bool isLoading;
  final bool isVideoLoading;
  final double? uploadProgress;
  final String? profileImageUrl;
  final String? profileVideoUrl;
  final String userName;
  final bool isVerified;
  final bool isStudent;

  final Widget profileImageWidget;
  final Widget videoPlayerWidget;
  final Widget videoPlaceholderWidget;

  final VoidCallback onClose;
  final VoidCallback onPickImage;
  final VoidCallback onSelectVideo;
  final VoidCallback onDeleteVideo; 
  final VoidCallback onSave;
  final Function(String) onPhoneChanged;

  const EditProfileView({
    Key? key,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.descriptionController,
    required this.isLoading,
    required this.isVideoLoading,
    this.uploadProgress = 0.0,
    required this.profileImageUrl,
    required this.profileVideoUrl,
    required this.userName,
    required this.isVerified,
    required this.isStudent,
    required this.profileImageWidget,
    required this.videoPlayerWidget,
    required this.videoPlaceholderWidget,
    required this.onClose,
    required this.onPickImage,
    required this.onSelectVideo,
    required this.onDeleteVideo,
    required this.onSave,
    required this.onPhoneChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final scaffoldBg = isDark ? AppColors.blackColor : AppColors.whiteColor; 
    final cardBgColor = isDark ? const Color(0xFF1E222A) : const Color(0xFFF4F6F9);
    final mainTextColor = isDark ? AppColors.whiteColor : AppColors.brandBlue;
    final double progress = uploadProgress ?? 0.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: scaffoldBg,
        body: SafeArea(
          top: false, 
          child: Column(
            children: [
              TutorHeader(
                title: AppLocalizations.of(context)!.edit.toUpperCase(),
                subtitle: AppLocalizations.of(context)!.updateYourData.toUpperCase(),
                onBackTap: onClose,
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark 
                                  ? [const Color(0xFF16181D), const Color(0xFF232833)] 
                                  : [AppColors.brandBlue, const Color(0xFF1A5A7A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: (isDark ? Colors.black : AppColors.brandBlue).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: onPickImage,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      width: 85, height: 85,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: profileImageWidget,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: -5, right: -5,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.brandOrange,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName.toUpperCase(),
                                      style: const TextStyle(fontFamily: 'outfit', color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1.1),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isStudent 
                                                ? Icons.school_rounded
                                                :
                                            isVerified
                                                ? Icons.verified_rounded
                                                : Icons.hourglass_empty_rounded,
                                            color: (isVerified || isStudent)
                                                ? AppColors.brandCyan
                                                : Colors.grey[400],
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isStudent 
                                                ? AppLocalizations.of(context)!.student.toUpperCase()
                                                : isVerified
                                                  ? AppLocalizations.of(context)!.verifiedTutor.toUpperCase()
                                                  : AppLocalizations.of(context)!.pendingVerification.toUpperCase(),
                                            style: TextStyle(
                                              fontFamily: 'manrope',
                                              color: (isVerified || isStudent) ? Colors.white: Colors.grey[400],
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.blackColor : AppColors.whiteColor,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextField(
                                  controller: firstNameController,
                                  label: AppLocalizations.of(context)!.firstName.toUpperCase(),
                                  hint: AppLocalizations.of(context)!.yourFirstName,
                                  icon: Icons.person_outline,
                                  fillColor: cardBgColor,
                                  textColor: mainTextColor,
                                  validator: (value) => value == null || value.trim().isEmpty ? AppLocalizations.of(context)!.requiredField : null,
                                ),
                                const SizedBox(height: 16),
                                
                                _buildTextField(
                                  controller: lastNameController,
                                  label: AppLocalizations.of(context)!.lastName.toUpperCase(),
                                  hint: AppLocalizations.of(context)!.yourLastName,
                                  icon: Icons.person_outline,
                                  fillColor: cardBgColor,
                                  textColor: mainTextColor,
                                  validator: (value) => value == null || value.trim().isEmpty ? AppLocalizations.of(context)!.requiredField : null,
                                ),
                                const SizedBox(height: 16),
                                
                                _buildTextField(
                                  controller: phoneController,
                                  label: AppLocalizations.of(context)!.cellphone.toUpperCase(),
                                  hint: AppLocalizations.of(context)!.enterYourCellphone,
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  fillColor: cardBgColor,
                                  textColor: mainTextColor,
                                  onChanged: onPhoneChanged,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) return AppLocalizations.of(context)!.requiredField;
                                    return null; 
                                  },
                                ),
                                const SizedBox(height: 16),

                                if (!isStudent) ...[
                                  _buildTextField(
                                    controller: descriptionController,
                                    label: AppLocalizations.of(context)!.description.toUpperCase(),
                                    hint: AppLocalizations.of(context)!.tellUsAboutYou,
                                    icon: Icons.description_outlined,
                                    maxLines: 4,
                                    fillColor: cardBgColor,
                                    textColor: mainTextColor,
                                  ),
                                  const SizedBox(height: 15),

                                  Text(AppLocalizations.of(context)!.presentationVideoOptional.toUpperCase(), style: TextStyle(fontFamily: 'outfit', color: mainTextColor, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                              
                                  Stack(
                                    children: [
                                      if (profileVideoUrl != null && profileVideoUrl!.isNotEmpty)
                                        videoPlayerWidget
                                      else
                                        videoPlaceholderWidget,
                                      if (isVideoLoading)
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    width: 48,
                                                    height: 48,
                                                    child: CircularProgressIndicator(
                                                      value: progress / 100.0,
                                                      strokeWidth: 4,
                                                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandCyan),
                                                      backgroundColor: Colors.white24,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    progress > 0.0
                                                        ? '${AppLocalizations.of(context)!.uploading}... ${progress.toStringAsFixed(0)}%'
                                                        : AppLocalizations.of(context)!.processing,
                                                    style: const TextStyle(
                                                      fontFamily: 'outfit',
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 50,
                                          child: OutlinedButton.icon(
                                            onPressed: isVideoLoading ? null : onSelectVideo,
                                            icon: isVideoLoading 
                                              ? SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    value: progress / 100.0,
                                                    strokeWidth: 2,
                                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandCyan),
                                                  ),
                                                )
                                              : const Icon(Icons.video_library, size: 18),
                                            label: Text(isVideoLoading 
                                              ? (progress > 0.0
                                                  ? '${AppLocalizations.of(context)!.uploading} ${progress.toStringAsFixed(0)}%'
                                                  : AppLocalizations.of(context)!.updating)
                                              : AppLocalizations.of(context)!.changeVideo),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.brandCyan,
                                              side: const BorderSide(color: AppColors.brandCyan),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (profileVideoUrl != null && profileVideoUrl!.isNotEmpty) ...[
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          height: 50,
                                          width: 50,
                                          child: OutlinedButton(
                                            onPressed: isVideoLoading ? null : onDeleteVideo,
                                            style: OutlinedButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              foregroundColor: Colors.redAccent,
                                              side: const BorderSide(color: Colors.redAccent),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            ),
                                            child: const Icon(Icons.delete_outline, size: 22),
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),

                                ],
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton.icon(
                                    onPressed: isLoading ? null : onSave,
                                    icon: isLoading 
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                                    label: Text(isLoading ? AppLocalizations.of(context)!.saving.toUpperCase() : AppLocalizations.of(context)!.saveChanges.toUpperCase(), style: const TextStyle(fontFamily: 'outfit', color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.brandCyan,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color fillColor,
    required Color textColor,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(label, style: const TextStyle(fontFamily: 'manrope', color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w800)),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          style: TextStyle(fontFamily: 'manrope', color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
            filled: true,
            fillColor: fillColor, 
            prefixIcon: Icon(icon, color: Colors.grey, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            errorStyle: const TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }
}