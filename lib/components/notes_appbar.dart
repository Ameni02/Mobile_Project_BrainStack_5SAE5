import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// AppBar personnalisée pour la page des notes (style Google Keep)
class NotesAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBack;

  const NotesAppBar({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: AppColors.background,
      scrolledUnderElevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        tooltip: 'Back',
      ),
      centerTitle: true,
      title: const Text(
        'Notes',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

