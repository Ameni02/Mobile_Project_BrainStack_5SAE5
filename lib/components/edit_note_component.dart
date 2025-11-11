import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/Notes_data.dart';

/// Composant plein écran pour modifier une note existante.
/// Style et structure alignés sur AddNoteComponent, avec CTA bas de page.
class EditNoteComponent extends StatelessWidget {
  final Note note;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final CategorieNote? selectedCategory;
  final VoidCallback onSave; // action de mise à jour
  final VoidCallback onCancel; // fermeture sans enregistrer
  final VoidCallback onSelectCategory; // ouvrir le sélecteur de catégories

  const EditNoteComponent({
    super.key,
    required this.note,
    required this.titleController,
    required this.contentController,
    required this.selectedCategory,
    required this.onSave,
    required this.onCancel,
    required this.onSelectCategory,
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
                    icon: const Icon(Icons.close),
                    onPressed: onCancel,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Modifier la note',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // Contenu principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Champ titre
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Titre',
                        hintStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                    ),
                    const SizedBox(height: 16),

                    // Zone catégorie (tap pour changer)
                    InkWell(
                      onTap: onSelectCategory,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selectedCategory != null) ...[
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _hexToColor(selectedCategory!.couleurHex),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedCategory!.nom,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ] else ...[
                              const Icon(
                                Icons.label_outline,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Choisir une catégorie',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Champ contenu
                    TextField(
                      controller: contentController,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Contenu de la note...',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                      minLines: 10,
                    ),
                  ],
                ),
              ),
            ),

            // CTA bas de page
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Enregistrer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
