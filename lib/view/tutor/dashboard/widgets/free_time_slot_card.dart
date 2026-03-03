import "package:flutter/material.dart";
import 'package:flutter_projects/styles/app_styles.dart';

class FreeTimeSlotCard extends StatelessWidget {
  final String startTime;
  final String endTime;
  final String? description;
  final VoidCallback? onDelete;
  final bool isPreview;

  const FreeTimeSlotCard({
    Key? key,
    required this.startTime,
    required this.endTime,
    this.description,
    this.onDelete,
    this.isPreview = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 15,
    );
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkBlue.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightBlueColor.withOpacity(0.3),
          // width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildTimeIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoColumn(textStyle),
          ),
          if (onDelete != null) _buildDeleteButton()
        ],
      ),
    );
  }

  Widget _buildTimeIcon() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.lightBlueColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.access_time,
        color: AppColors.lightBlueColor,
        size: 18,
      ),
    );
  }

  Widget _buildInfoColumn(TextStyle mainStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$startTime - $endTime', style: mainStyle),
        if (description != null && description!.isNotEmpty)
          Text(
            description!,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildDeleteButton() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.redColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(
          Icons.close,
          color: AppColors.redColor,
          size: 16,
        ),
        onPressed: onDelete,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: 24,
          minHeight: 24,
        ),
      ),
    );
  }
}
