import 'package:flutter/material.dart';
import '../models/Notes_data.dart';
import '../theme/app_colors.dart';

/// Widget représentant une note en mode liste.
class NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback? onDelete;
  // Nouveau: callback lors d'un tap pour ouvrir l'édition
  final VoidCallback? onTap;
  final VoidCallback? onTogglePinned; // nouveau

  const NoteListItem({super.key, required this.note, this.onDelete, this.onTap, this.onTogglePinned});

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

    final pinned = note.isPinned;

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
                if (pinned)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.push_pin, size: 16, color: Colors.amber),
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
                    _buildTimeLabel(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                _PinButtonSmall(
                  isPinned: pinned,
                  onPressed: onTogglePinned,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildTimeLabel() {
    final ref = note.updatedAt ?? note.createdAt;
    final isModified = note.updatedAt != null && note.updatedAt != note.createdAt;
    final diff = DateTime.now().difference(ref);
    String rel;
    if (diff.inMinutes < 60) {
      rel = '${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      rel = '${diff.inHours} h';
    } else if (diff.inDays < 7) {
      rel = '${diff.inDays} j';
    } else {
      rel = '${ref.day}/${ref.month}/${ref.year}';
    }
    return (isModified ? 'Modifiée il y a ' : 'Ajoutée il y a ') + rel;
  }
}

class _PinButtonSmall extends StatefulWidget {
  final bool isPinned;
  final VoidCallback? onPressed;
  const _PinButtonSmall({required this.isPinned, this.onPressed});
  @override
  State<_PinButtonSmall> createState() => _PinButtonSmallState();
}

class _PinButtonSmallState extends State<_PinButtonSmall> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    if (widget.isPinned) _ctrl.forward();
  }
  @override
  void didUpdateWidget(covariant _PinButtonSmall oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPinned != widget.isPinned) {
      _ctrl.reset();
      if (widget.isPinned) _ctrl.forward();
    }
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final color = widget.isPinned ? Colors.amber : AppColors.textSecondary;
    return ScaleTransition(
      scale: _scale.drive(Tween(begin: 0.85, end: 1.0)),
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18, color: color),
        ),
      ),
    );
  }
}
