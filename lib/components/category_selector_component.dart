import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/Notes_data.dart';

class CategorySelectorComponent extends StatelessWidget {
  final List<CategorieNote> categories;
  final CategorieNote? selectedCategory;
  final Function(CategorieNote) onCategorySelected;
  final VoidCallback onAddCategory;
  final VoidCallback onClose;
  // Nouveaux callbacks pour actions
  final Function(CategorieNote) onEditCategory;
  final Function(CategorieNote) onDeleteCategory;

  const CategorySelectorComponent({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onAddCategory,
    required this.onClose,
    required this.onEditCategory,
    required this.onDeleteCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: onClose,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Select a category',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Liste des catégories
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Bouton "Ajouter une catégorie"
                  _buildAddCategoryButton(),
                  const SizedBox(height: 8),

                  // Divider
                  const Divider(height: 24, color: AppColors.borderLight),

                  // Liste des catégories existantes
                  ...categories.map((category) => _buildCategoryItem(context, category)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryButton() {
    return InkWell(
      onTap: onAddCategory,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Add a category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, CategorieNote category) {
    final isSelected = selectedCategory?.id == category.id;

    return InkWell(
      onTap: () => onCategorySelected(category),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Cercle de couleur
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _hexToColor(category.couleurHex),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _hexToColor(category.couleurHex).withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Nom de la catégorie
            Expanded(
              child: Text(
                category.nom,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),

            // Actions: Modifier / Supprimer
            Row(
              children: [
                // Modifier
                _ActionIcon(
                  icon: Icons.edit_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  tooltip: 'Edit',
                  onTap: () => onEditCategory(category),
                ),
                const SizedBox(width: 8),
                // Supprimer
                _ActionIcon(
                  icon: Icons.delete_outline,
                  color: Colors.red.shade400,
                  tooltip: 'Delete',
                  onTap: () => onDeleteCategory(category),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}
