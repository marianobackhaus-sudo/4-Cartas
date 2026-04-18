import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/design_tokens.dart';

/// Picks an image (camera or gallery) and uploads it to Firebase Storage.
/// Returns the download URL, or null if cancelled.
Future<String?> pickAndUploadAvatar(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SourceSheet(),
  );
  if (source == null) return null;

  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: source,
    imageQuality: 75,
    maxWidth: 512,
  );
  if (picked == null) return null;

  final uid = FirebaseAuth.instance.currentUser!.uid;
  final storageRef = FirebaseStorage.instance.ref('profile_photos/$uid.jpg');
  final task = await storageRef.putFile(
    File(picked.path),
    SettableMetadata(contentType: 'image/jpeg'),
  );
  if (task.state != TaskState.success) {
    throw Exception('Upload failed: ${task.state}');
  }
  return storageRef.getDownloadURL();
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.xl2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SourceTile(
            icon: Icons.camera_alt_rounded,
            label: 'Tomar foto',
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          const Divider(height: 1, color: AppColors.border),
          _SourceTile(
            icon: Icons.photo_library_rounded,
            label: 'Elegir de galería',
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.base,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar circle that shows [photoUrl] if set, otherwise a person icon.
/// Wraps with an upload-button badge when [onTap] is provided.
class AvatarCircle extends StatelessWidget {
  final String? photoUrl;
  final double size;
  final VoidCallback? onTap;
  final bool loading;

  const AvatarCircle({
    super.key,
    this.photoUrl,
    this.size = 100,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
              image: (photoUrl != null && !loading)
                  ? DecorationImage(
                      image: NetworkImage(photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (photoUrl == null && !loading)
                ? Icon(Icons.person_rounded, color: AppColors.textMuted, size: size * 0.52)
                : loading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
          ),
          if (onTap != null)
            Positioned(
              bottom: 2, right: 2,
              child: Container(
                width: size * 0.30,
                height: size * 0.30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bgDeepest, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.onPrimary,
                  size: size * 0.15,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
