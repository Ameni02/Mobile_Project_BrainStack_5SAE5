import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum NotesSortType { dateDesc, dateAsc, titleAsc, titleDesc, importance }

extension NotesSortTypeLabel on NotesSortType {
  String get label {
    switch (this) {
      case NotesSortType.dateDesc:
        return 'Date (recent)';
      case NotesSortType.dateAsc:
        return 'Date (oldest)';
      case NotesSortType.titleAsc:
        return 'Title (A-Z)';
      case NotesSortType.titleDesc:
        return 'Title (Z-A)';
      case NotesSortType.importance:
        return 'Important';
    }
  }

  IconData get icon {
    switch (this) {
      case NotesSortType.dateDesc:
        return Icons.schedule;
      case NotesSortType.dateAsc:
        return Icons.schedule;
      case NotesSortType.titleAsc:
        return Icons.sort_by_alpha;
      case NotesSortType.titleDesc:
        return Icons.sort_by_alpha;
      case NotesSortType.importance:
        return Icons.priority_high;
    }
  }
}

/// Barre d'actions : tri + toggle vue grille / liste
class NotesSortAndViewBar extends StatelessWidget {
  final NotesSortType currentSort;
  final bool isGrid;
  final ValueChanged<NotesSortType> onSortChanged;
  final VoidCallback onToggleView;

  const NotesSortAndViewBar({
    super.key,
    required this.currentSort,
    required this.isGrid,
    required this.onSortChanged,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Bouton de tri avec PopupMenu
        _SortButton(
          currentSort: currentSort,
          onSelected: onSortChanged,
        ),
        const SizedBox(width: 12),
        // Toggle grille / liste
        _ViewToggleButton(
          isGrid: isGrid,
          onToggle: onToggleView,
        ),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  final NotesSortType currentSort;
  final ValueChanged<NotesSortType> onSelected;

  const _SortButton({required this.currentSort, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<NotesSortType>(
      tooltip: 'Sort notes',
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      color: AppColors.card,
      itemBuilder: (context) => NotesSortType.values
          .map(
            (type) => PopupMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(
                    type.icon,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    type.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: type == currentSort ? FontWeight.w600 : FontWeight.w400,
                      color: type == currentSort ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  if (type == currentSort) ...[
                    const Spacer(),
                    const Icon(Icons.check, size: 18, color: AppColors.accent),
                  ]
                ],
              ),
            ),
          )
          .toList(),
      child: _BaseActionChip(
        icon: Icons.sort,
        label: currentSort.label,
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final bool isGrid;
  final VoidCallback onToggle;

  const _ViewToggleButton({required this.isGrid, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: _BaseActionChip(
        icon: isGrid ? Icons.view_list : Icons.grid_view,
        label: isGrid ? 'List' : 'Grid',
      ),
    );
  }
}

/// Composant de base stylisé pour les actions (similaire aux chips Google Keep)
class _BaseActionChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BaseActionChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

