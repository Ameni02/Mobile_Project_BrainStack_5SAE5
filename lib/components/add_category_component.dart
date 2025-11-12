import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/colormind_service.dart';

class AddCategoryComponent extends StatefulWidget {
  final Function(Map<String, String>) onCategoryCreated;
  final VoidCallback onClose;

  const AddCategoryComponent({
    super.key,
    required this.onCategoryCreated,
    required this.onClose,
  });

  @override
  State<AddCategoryComponent> createState() => _AddCategoryComponentState();
}

class _AddCategoryComponentState extends State<AddCategoryComponent> {
  final TextEditingController _nameController = TextEditingController();
  Color? _selectedColor; // Couleur choisie
  List<Color> _suggestedColors = [];
  bool _isLoadingColors = false;
  DateTime _lastInputTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
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
    // Debounce ~500ms
    if (now.difference(_lastInputTime).inMilliseconds < 500) return;
    _lastInputTime = now;
    if (_nameController.text.trim().isEmpty) return;
    _fetchPalette();
  }

  Future<void> _fetchPalette() async {
    setState(() {
      _isLoadingColors = true;
    });
    try {
      final palette = await ColormindService.getPalette();
      if (!mounted) return;
      setState(() {
        _suggestedColors = palette;
        // Pré-sélectionner la première si aucune sélection
        _selectedColor ??= palette.isNotEmpty ? palette.first : null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de récupérer les couleurs. Réessayez.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingColors = false;
        });
      }
    }
  }

  void _saveCategory() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom de catégorie')),
      );
      return;
    }
    if (_selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une couleur')),
      );
      return;
    }
    widget.onCategoryCreated({
      'nom': name,
      'couleurHex': _colorToHex(_selectedColor!),
    });
  }

  String _colorToHex(Color c) => '#${c.value.toRadixString(16).substring(2).toUpperCase()}';

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
                    onPressed: widget.onClose,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Ajouter une catégorie',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Générer des couleurs',
                    onPressed: _isLoadingColors ? null : _fetchPalette,
                    icon: _isLoadingColors
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.palette_outlined),
                  )
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
                    // Champ nom
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
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ex: Travail, Personnel...',
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textMuted,
                        ),
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

                    // Sélection de couleur
                    const Text(
                      'Couleurs suggérées',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_suggestedColors.isEmpty && !_isLoadingColors)
                      const Text(
                        'Saisissez un nom ou appuyez sur la palette pour générer des couleurs.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isLoadingColors
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
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
                                  onTap: () {
                                    setState(() => _selectedColor = color);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        if (isSelected)
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.5),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                      ],
                                      border: isSelected
                                          ? Border.all(color: Colors.white, width: 4)
                                          : null,
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, color: Colors.white, size: 32)
                                        : null,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Bouton Enregistrer
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
                  onPressed: _saveCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
}
