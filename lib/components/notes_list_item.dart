import 'package:flutter/material.dart';
import '../models/Notes_data.dart';
import '../theme/app_colors.dart';

/// Widget représentant une note en mode liste.
class NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback? onDelete;
  // Nouveau: callback lors d'un tap pour ouvrir l'édition
  final VoidCallback? onTap;

  const NoteListItem({super.key, required this.note, this.onDelete, this.onTap});

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
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
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
              color: borderColor.withValues(alpha: 0.15),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (note.isImportant)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.star, size: 16, color: AppColors.accent),
                  ),
                if (note.isPinned)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.push_pin, size: 16, color: AppColors.textSecondary),
                  ),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.25,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatRelativeDate(note.updatedAt ?? note.createdAt),
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
                if (note.categorie != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: borderColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      note.categorie!.nom,
                      style: TextStyle(
                        fontSize: 12,
                        color: borderColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
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
