import 'package:flutter/material.dart';
import 'package:flutter_projects/styles/app_styles.dart';

class TutorCard extends StatefulWidget {
  final String name;
  final double rating;
  final int reviews;
  final String imageUrl;
  final VoidCallback onRejectPressed;
  final VoidCallback onAcceptPressed;
  final String tutorProfession;
  final String sessionDuration;
  final bool isFavoriteInitial;
  final ValueChanged<bool> onFavoritePressed;
  final String description;
  final bool isVerified;

  const TutorCard({
    Key? key,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.onRejectPressed,
    required this.onAcceptPressed,
    required this.tutorProfession,
    required this.sessionDuration,
    this.isFavoriteInitial = false,
    required this.onFavoritePressed,
    required this.description,
    required this.isVerified,
  }) : super(key: key);

  @override
  State<TutorCard> createState() => _TutorCardState();
}

class _TutorCardState extends State<TutorCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavoriteInitial;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      color: AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(
                        widget.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.name,
                                    style: AppTextStyles.heading2.copyWith(color: AppColors.blackColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.isVerified)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Icon(
                                      Icons.verified,
                                      color: AppColors.blueColor,
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.star, color: AppColors.starYellow, size: 16),
                          Text(
                            '${widget.rating}',
                            style: AppTextStyles.body.copyWith(color: AppColors.blackColor),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isFavorite = !_isFavorite;
                                widget.onFavoritePressed(_isFavorite);
                              });
                            },
                            child: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? AppColors.blueColor : AppColors.lightGreyColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bs. 15',
                        style: AppTextStyles.heading2.copyWith(color: AppColors.orangeprimary),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.book, color: AppColors.greyColor, size: 20),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    widget.description,
                    style: AppTextStyles.body.copyWith(color: AppColors.greyColor),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onRejectPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      minimumSize: const Size(double.infinity, 35),
                    ),
                    child: Text(
                      'Ver Perfil',
                      style: AppTextStyles.button.copyWith(color: AppColors.whiteColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onAcceptPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orangeprimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      minimumSize: const Size(double.infinity, 35),
                    ),
                    child: Text(
                      'Reservar',
                      style: AppTextStyles.button.copyWith(color: AppColors.whiteColor),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
