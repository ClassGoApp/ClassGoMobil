import 'package:flutter/material.dart';
import 'package:flutter_projects/services/link_services.dart';

class SocialButton extends StatelessWidget {
  final String platform;
  final String url;
  final IconData icon;

  const SocialButton({required this.platform, required this.url, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(platform),
      onPressed: () => LinkService.openSocialMediaLink(
        context: context,
        url: url,
        platform: platform,
      ),
    );
  }
}