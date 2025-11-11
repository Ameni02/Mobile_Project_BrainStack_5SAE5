import 'package:flutter/material.dart';
import '../models/Notes_data.dart';
import '../theme/app_colors.dart';

/// Widget représentant une note en mode grille.
class NoteGridItem extends StatelessWidget {
  final Note note;
  final VoidCallback? onDelete;

  const NoteGridItem({super.key, required this.note, this.onDelete});

  @override
  Widget build(BuildContext context) {
    // Déterminer la couleur de la bordure selon la catégorie
    Color borderColor = AppColors.borderLight;
    if (note.categorie != null) {
      try {
        borderColor = Color(int.parse('0xFF${note.categorie!.couleurHex.substring(1)}'));
      } catch (_) {
        borderColor = AppColors.borderLight;
      }
    }

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    note.title.isEmpty ? 'Sans titre' : note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                note.content,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.25,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildMeta(),
          ],
        ),
      ),
    );
  }

  Widget _buildMeta() {
    return Row(
      children: [
        if (note.isImportant) ...[
          const Icon(Icons.star, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
        ],
        if (note.isPinned) ...[
          const Icon(Icons.push_pin, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            _formatRelativeDate(note.updatedAt ?? note.createdAt),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

