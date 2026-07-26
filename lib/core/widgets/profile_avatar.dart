import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Circular avatar that loads a network photo with a graceful initials fallback.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.photoUrl, this.name, this.radius = 26});

  final String? photoUrl;
  final String? name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = _initials(name);

    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      ),
    );

    if (photoUrl == null || photoUrl!.isEmpty) return fallback;

    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.surfaceContainerHighest,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (_, _) => const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (_, _, _) => fallback,
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '؟';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1);
    return parts.first.substring(0, 1) + parts[1].substring(0, 1);
  }
}
