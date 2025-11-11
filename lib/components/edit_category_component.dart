import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/Notes_data.dart';

class EditCategoryComponent extends StatefulWidget {
  final CategorieNote category;
  final Function(CategorieNote) onCategoryUpdated;
  final VoidCallback onClose;

  const EditCategoryComponent({
    super.key,
    required this.category,
    required this.onCategoryUpdated,
    required this.onClose,
  });

  @override
  State<EditCategoryComponent> createState() => _EditCategoryComponentState();
}

class _EditCategoryComponentState extends State<EditCategoryComponent> {
  late TextEditingController _nameController;
  late String _selectedColor;

  final List<String> _colors = const [
    '#2196F3', '#4CAF50', '#FF9800', '#F44336', '#9C27B0', '#E91E63', '#00BCD4', '#FFEB3B',
    '#795548', '#607D8B', '#3F51B5', '#8BC34A', '#FF5722', '#673AB7', '#009688', '#FFC107',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.nom);
    _selectedColor = widget.category.couleurHex;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveUpdates() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom de catégorie')),
      );
      return;
    }
    final updated = CategorieNote(id: widget.category.id, nom: name, couleurHex: _selectedColor);
    widget.onCategoryUpdated(updated);
  }

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
                    onPressed: widget.onClose,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Modifier la catégorie',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nom de la catégorie',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      autofocus: true,
                      style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ex: Travail, Personnel...',
                        hintStyle: const TextStyle(fontSize: 16, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.secondary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Text(
                      'Couleur',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: _colors.length,
                      itemBuilder: (context, index) {
                        final color = _colors[index];
                        final isSelected = color == _selectedColor;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _hexToColor(color),
                              shape: BoxShape.circle,
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: _hexToColor(color).withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                              ],
                              border: isSelected ? Border.all(color: Colors.white, width: 4) : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 32)
                                : null,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Footer bouton sauvegarde
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveUpdates,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Enregistrer les modifications',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

