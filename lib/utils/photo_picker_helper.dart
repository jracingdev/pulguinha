import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulguinha/theme/app_colors.dart';

/// Escolhe foto da câmera ou galeria e retorna base64 (JPEG).
Future<String?> pickPhotoBase64(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.neon),
              title: const Text('Galeria', style: TextStyle(color: AppColors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.neon),
              title: const Text('Câmera', style: TextStyle(color: AppColors.white)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    ),
  );

  if (source == null) return null;

  final picker = ImagePicker();
  final file = await picker.pickImage(
    source: source,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 75,
  );
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  return base64Encode(bytes);
}
