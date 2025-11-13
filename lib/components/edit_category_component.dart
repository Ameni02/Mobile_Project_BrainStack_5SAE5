import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/Notes_data.dart';
import '../services/colormind_service.dart';

class EditCategoryComponent extends StatefulWidget {
  final CategorieNote category;
  final Function(CategorieNote) onCategoryUpdated;
  final VoidCallback onClose;
  const EditCategoryComponent({super.key, required this.category, required this.onCategoryUpdated, required this.onClose});
  @override
  State<EditCategoryComponent> createState() => _EditCategoryComponentState();
}

class _EditCategoryComponentState extends State<EditCategoryComponent> {
  late TextEditingController _nameController;
  late Color _originalColor; // couleur initiale de la catégorie
  Color? _selectedColor; // couleur choisie (peut être l'ancienne ou une nouvelle)
  List<Color> _suggestedColors = [];
  bool _isLoadingColors = false;
  DateTime _lastInputTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.nom);
    _originalColor = _hexToColor(widget.category.couleurHex);
    _selectedColor = _originalColor; // sélection par défaut
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final now = DateTime.now();
    if (now.difference(_lastInputTime).inMilliseconds < 500) return; // debounce 500ms
    _lastInputTime = now;
    if (_nameController.text.trim().isEmpty) return;
    _fetchPalette();
  }

  Future<void> _fetchPalette() async {
    setState(() => _isLoadingColors = true);
    try {
      final palette = await ColormindService.getPalette();
      if (!mounted) return;
      setState(() {
        _suggestedColors = palette;
        // Ne change pas la sélection si déjà définie, sauf si null
        _selectedColor ??= palette.isNotEmpty ? palette.first : null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to retrieve colors. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingColors = false);
    }
  }

  void _saveUpdates() {
    FocusScope.of(context).unfocus(); // fermer le clavier avant sauvegarde
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }
    if (_selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a color')),
      );
      return;
    }
    final updated = CategorieNote(
      id: widget.category.id,
      nom: name,
      couleurHex: _colorToHex(_selectedColor!),
    );
    widget.onCategoryUpdated(updated);
  }

  String _colorToHex(Color c) {
    String to2(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#${to2(c.red)}${to2(c.green)}${to2(c.blue)}';
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
              decoration: BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ]),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      FocusScope.of(context).unfocus(); // fermer le clavier avant retour
                      widget.onClose();
                    },
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Edit category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Generate colors',
                    onPressed: _isLoadingColors ? null : _fetchPalette,
                    icon: _isLoadingColors
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.palette_outlined),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Category name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'E.g.: Work, Personal...',
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

                  const Text('Previous color', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedColor = _originalColor),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: _originalColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (_selectedColor == _originalColor)
                              BoxShadow(color: _originalColor.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2),
                          ],
                          border: _selectedColor == _originalColor ? Border.all(color: Colors.white, width: 4) : null,
                        ),
                        child: _selectedColor == _originalColor
                            ? const Icon(Icons.check, color: Colors.white, size: 32)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text('Suggested colors', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  if (_suggestedColors.isEmpty && !_isLoadingColors)
                    const Text('Enter a name or use the palette to generate colors.', style: TextStyle(color: AppColors.textMuted)),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isLoadingColors
                        ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                        : GridView.builder(
                            key: ValueKey(_suggestedColors.length),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1,
                            ),
                            itemCount: _suggestedColors.length,
                            itemBuilder: (context, index) {
                              final color = _suggestedColors[index];
                              final isSelected = color == _selectedColor;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedColor = color),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      if (isSelected)
                                        BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2),
                                    ],
                                    border: isSelected ? Border.all(color: Colors.white, width: 4) : null,
                                  ),
                                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 32) : null,
                                ),
                              );
                            },
                          ),
                  ),
                ]),
              ),
            ),

            // Footer bouton sauvegarde
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2)),
              ]),
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
                  child: const Text('Save changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
