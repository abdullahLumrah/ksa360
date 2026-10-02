import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/activity.dart';

class ActivityPhoto extends StatelessWidget {
  const ActivityPhoto({
    super.key,
    required this.url,
    this.kind = 'cinema',
    this.heroTag,
  });

  final String url;
  final String kind;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final color = Color(kindMeta(kind).color);
    final fallback = ColoredBox(
      color: color.withValues(alpha: 0.28),
      child: Center(
        child: Text(kindMeta(kind).icon, style: const TextStyle(fontSize: 36)),
      ),
    );
    final image = CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
    if (heroTag == null) return image;
    return Hero(tag: heroTag!, child: image);
  }
}
