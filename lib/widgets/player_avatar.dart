import 'dart:convert';

import 'package:flutter/material.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.name,
    required this.avatarColorValue,
    this.photoUrl,
    this.radius = 18,
  });

  final String name;
  final int avatarColorValue;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageProvider = _imageProviderFromPhotoUrl(photoUrl);
    return CircleAvatar(
      backgroundColor: Color(avatarColorValue),
      foregroundColor: Colors.white,
      radius: radius,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900),
            )
          : null,
    );
  }

  ImageProvider? _imageProviderFromPhotoUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.startsWith('data:image')) {
      final commaIndex = value.indexOf(',');
      if (commaIndex == -1) {
        return null;
      }
      return MemoryImage(base64Decode(value.substring(commaIndex + 1)));
    }
    return NetworkImage(value);
  }
}
