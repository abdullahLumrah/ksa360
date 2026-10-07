import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/school_photos.dart';
import '../models/school.dart';

class SchoolPhoto extends StatelessWidget {
  const SchoolPhoto({
    super.key,
    required this.school,
    this.width,
    this.height = 86,
    this.url,
    this.radius = 16,
  });

  final School school;
  final double? width;
  final double height;
  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = url ?? schoolPhotoFor(school);
    final color = schoolPinColor(school);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: image.isEmpty
            ? _Fallback(color: color)
            : CachedNetworkImage(
                imageUrl: image,
                httpHeaders: schoolPhotoHeaders(image),
                fit: BoxFit.cover,
                placeholder: (_, __) => ColoredBox(
                  color: color.withValues(alpha: 0.18),
                ),
                errorWidget: (_, __, ___) => _Fallback(color: color),
              ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color.withValues(alpha: 0.14),
      child: Icon(Icons.school_rounded, color: color),
    );
  }
}
