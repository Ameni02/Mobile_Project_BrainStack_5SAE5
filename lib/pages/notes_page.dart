import 'package:flutter/material.dart';
import '../DB/DB.dart';
import '../models/Notes_data.dart';
import '../theme/app_colors.dart';
import '../components/notes_appbar.dart';
import '../components/notes_sort_buttons.dart';
import '../components/notes_grid_item.dart';
import '../components/notes_list_item.dart';
import '../home_page.dart';
import '../components/add_note_component.dart';
import '../components/category_selector_component.dart';
import '../components/add_category_component.dart';
import '../components/edit_note_component.dart';
import '../components/edit_category_component.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isGrid = true;
  NotesSortType _sortType = NotesSortType.dateDesc;
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];

  // État pour les composants d'ajout/édition
  bool _showAddNote = false;
  bool _showCategorySelector = false;
  bool _showAddCategory = false;
  bool _showEditCategory = false; // nouvel overlay édition catégorie
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();
  CategorieNote? _selectedCategory;
  CategorieNote? _categoryBeingEdited;
  List<CategorieNote> _categories = [];

  // Filtrage par catégorie
  CategorieNote? _filterCategory;

  // Animation du FAB
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  // Nouveaux états pour l'édition
  bool _showEditNote = false;
  Note? _noteBeingEdited;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOutBack,
    );
    _fabAnimationController.forward();

    _loadNotes();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final rows = await DB.getNotes();
      _notes = rows.map((m) => _mapRowToNote(m)).toList();
      _applySort();
      _applyFilter();
    } catch (_) {
      _notes = [];
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await DB.getAllCategories();
      setState(() => _categories = categories);
    } catch (_) {
      // Garder silencieux
    }
  }

  Note _mapRowToNote(Map<String, dynamic> m) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    bool _toBool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is num) return v.toInt() == 1;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final id = _toInt(m['id']);
    final title = (m['title'] as String?) ?? '';
    final content = (m['content'] as String?) ?? '';
    final createdAt = _toDate(m['createdAt']) ?? DateTime.now();
    final updatedAt = _toDate(m['updatedAt']);

    final isImportant = _toBool(m['isImportant']);
    final isArchived = _toBool(m['isArchived']);
    final isPinned = _toBool(m['isPinned']);

    // Récupérer la catégorie si elle existe
    CategorieNote? categorie;
    if (m['category'] != null && m['category'] is Map) {
      final catMap = m['category'] as Map<String, dynamic>;
      categorie = CategorieNote(
        id: _toInt(catMap['id']),
        nom: catMap['nom'] as String? ?? '',
        couleurHex: catMap['couleurHex'] as String? ?? '#2196F3',
      );
    }

    return Note(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      categorie: categorie,
      isImportant: isImportant,
      isArchived: isArchived,
      isPinned: isPinned,
    );
  }

  void _applySort() {
    switch (_sortType) {
      case NotesSortType.dateDesc:
        _notes.sort((a, b) => (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt));
        break;
      case NotesSortType.dateAsc:
        _notes.sort((a, b) => (a.updatedAt ?? a.createdAt).compareTo(b.updatedAt ?? b.createdAt));
        break;
      case NotesSortType.titleAsc:
        _notes.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case NotesSortType.titleDesc:
        _notes.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case NotesSortType.importance:
        _notes.sort((a, b) {
          if (a.isImportant == b.isImportant) {
            return (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt);
          }
          return b.isImportant ? 1 : -1;
        });
        break;
    }
  }

  void _applyFilter() {
    if (_filterCategory == null) {
      _filteredNotes = List.from(_notes);
    } else {
      _filteredNotes = _notes.where((note) => note.categorie?.id == _filterCategory!.id).toList();
    }
  }

  Future<void> _onChangeSort(NotesSortType type) async {
    setState(() {
      _sortType = type;
      _applySort();
      _applyFilter();
    });
  }

  Future<void> _deleteNote(Note note) async {
    try {
      await DB.deleteNotes(note.id);
      await _loadNotes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note supprimée')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la suppression.')),
      );
    }
  }

  Future<void> _addNote() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note vide ignorée.')),
      );
      return;
    }

    await DB.addNotes(title, content, categoryId: _selectedCategory?.id);
    await _loadNotes();
    _titleCtrl.clear();
    _contentCtrl.clear();
    setState(() {
      _showAddNote = false;
      _selectedCategory = null;
    });
    _fabAnimationController.forward();
  }

  // Ouverture édition
  void _openEditNote(Note note) {
    setState(() {
      _noteBeingEdited = note;
      _titleCtrl.text = note.title;
      _contentCtrl.text = note.content;
      _selectedCategory = note.categorie; // préselection
      _showEditNote = true;
      _showAddNote = false;
      _showCategorySelector = false;
      _showAddCategory = false;
    });
    _fabAnimationController.reverse();
  }

  // Fermeture édition
  void _closeEditNote() {
    setState(() {
      _showEditNote = false;
      _noteBeingEdited = null;
      _titleCtrl.clear();
      _contentCtrl.clear();
      _selectedCategory = null;
    });
    _fabAnimationController.forward();
  }

  // Sauvegarde édition
  Future<void> _saveEditedNote() async {
    if (_noteBeingEdited == null) return;
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note vide ignorée.')),
      );
      return;
    }
    try {
      await DB.updateNote(
        _noteBeingEdited!.id,
        title: title,
        content: content,
        categoryId: _selectedCategory?.id,
      );
      await _loadNotes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note mise à jour')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour.')),
      );
    }
    _closeEditNote();
  }

  void _openAddNote() {
    setState(() {
      _showAddNote = true;
      _showEditNote = false;
      _showCategorySelector = false;
      _showAddCategory = false;
    });
    _fabAnimationController.reverse();
  }

  void _closeAddNote() {
    setState(() {
      _showAddNote = false;
      _showCategorySelector = false;
      _showAddCategory = false;
    });
    _fabAnimationController.forward();
  }

  // Ouvrir sélecteur catégories
  void _openCategorySelector() {
    setState(() {
      _showCategorySelector = true;
      _showAddCategory = false;
      _showEditCategory = false;
    });
    _fabAnimationController.reverse();
  }

  // Fermer sélecteur
  void _closeCategorySelector() {
    setState(() {
      _showCategorySelector = false;
    });
    if (!_showAddNote && !_showEditNote) {
      _fabAnimationController.forward();
    }
  }

  // Ouvrir add catégorie
  void _openAddCategory() {
    setState(() {
      _showAddCategory = true;
      _showCategorySelector = false;
      _showEditCategory = false;
    });
  }

  // Fermer add catégorie retour sélection
  void _closeAddCategory() {
    setState(() {
      _showAddCategory = false;
      _showCategorySelector = true; // retour au sélecteur
    });
  }

  // Après création catégorie
  Future<void> _onCategoryCreated(Map<String, String> data) async {
    final newCat = CategorieNote(
      id: 0,
      nom: data['nom'] ?? 'Nouvelle catégorie',
      couleurHex: data['couleurHex'] ?? '#2196F3',
    );
    try {
      final id = await DB.insertCategory(newCat);
      await _loadCategories();
      final created = _categories.firstWhere((c) => c.id == id, orElse: () => newCat);
      setState(() {
        _selectedCategory = created;
        _showAddCategory = false;
        _showCategorySelector = true; // revenir à la liste
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catégorie ajoutée')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur création catégorie')));
    }
  }

  // Ouvrir édition catégorie
  void _openEditCategory(CategorieNote cat) {
    setState(() {
      _categoryBeingEdited = cat;
      _showEditCategory = true;
      _showCategorySelector = false;
      _showAddCategory = false;
    });
  }

  // Fermer édition catégorie (retour sélecteur)
  void _closeEditCategory() {
    setState(() {
      _showEditCategory = false;
      _categoryBeingEdited = null;
      _showCategorySelector = true; // retour liste
    });
  }

  // Sauvegarde mise à jour catégorie
  Future<void> _updateCategory(CategorieNote updated) async {
    try {
      await DB.updateCategory(updated);
      await _loadCategories();
      setState(() {
        // si la catégorie éditée était sélectionnée, mettre à jour la référence
        if (_selectedCategory?.id == updated.id) {
          _selectedCategory = _categories.firstWhere((c) => c.id == updated.id, orElse: () => updated);
        }
        _showEditCategory = false;
        _categoryBeingEdited = null;
        _showCategorySelector = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catégorie mise à jour')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur mise à jour catégorie')));
    }
  }

  // Suppression catégorie
  Future<void> _deleteCategory(CategorieNote cat) async {
    try {
      await DB.deleteCategory(cat.id);
      await _loadCategories();
      setState(() {
        if (_selectedCategory?.id == cat.id) {
          _selectedCategory = null;
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catégorie supprimée')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur suppression catégorie')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // FAB visible seulement si aucun overlay
    final bool showFAB = !_showAddNote && !_showCategorySelector && !_showAddCategory && !_showEditNote && !_showEditCategory;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Contenu principal de la page
          SafeArea(
            child: Column(
              children: [
                // AppBar personnalisée
                NotesAppBar(
                  onBack: () => Navigator.of(context).pop(),
                ),
                // Boutons de tri et d'affichage
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: NotesSortAndViewBar(
                    currentSort: _sortType,
                    isGrid: _isGrid,
                    onSortChanged: _onChangeSort,
                    onToggleView: () => setState(() => _isGrid = !_isGrid),
                  ),
                ),
                // Filtrage par catégories
                _buildCategoryFilter(),
                // Liste/Grille des notes
                Expanded(
                  child: _isLoading ? _buildLoadingState() : _buildNotesList(),
                ),
              ],
            ),
          ),
          // Overlays animés
          _buildAddNoteOverlay(),
          _buildEditNoteOverlay(),
          _buildCategorySelectorOverlay(),
          _buildAddCategoryOverlay(),
          _buildEditCategoryOverlay(),
        ],
      ),
      // FAB positionné juste au-dessus de la barre de navigation avec animation
      floatingActionButton: showFAB
          ? ScaleTransition(
        scale: _fabScaleAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 70.0),
          child: FloatingActionButton(
            heroTag: 'notesFab',
            onPressed: _openAddNote,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.primaryForeground,
            elevation: 6,
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // Barre de navigation
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        onDestinationSelected: (index) {
          if (index == 3) {
            Navigator.of(context).maybePop();
            return;
          }
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => HomeScreen(initialIndex: index),
            ),
                (route) => false,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money_outlined),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildCategoryFilter() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Option "Toutes"
          _buildCategoryChip(
            label: 'Toutes',
            isSelected: _filterCategory == null,
            onTap: () {
              setState(() {
                _filterCategory = null;
                _applyFilter();
              });
            },
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          // Catégories
          for (final category in _categories) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildCategoryChip(
                label: category.nom,
                isSelected: _filterCategory?.id == category.id,
                onTap: () {
                  setState(() {
                    _filterCategory = category;
                    _applyFilter();
                  });
                },
                color: Color(int.parse('0xFF${category.couleurHex.substring(1)}')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesList() {
    if (_filteredNotes.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (_isGrid) {
          final columns = _computeGridColumns(width);
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: _filteredNotes.length,
            itemBuilder: (context, index) {
              final note = _filteredNotes[index];
              return NoteGridItem(
                note: note,
                onDelete: () => _deleteNote(note),
                onTap: () => _openEditNote(note),
              );
            },
          );
        } else {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: _filteredNotes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final note = _filteredNotes[index];
              return NoteListItem(
                note: note,
                onDelete: () => _deleteNote(note),
                onTap: () => _openEditNote(note),
              );
            },
          );
        }
      },
    );
  }

  int _computeGridColumns(double width) {
    if (width >= 1200) return 5;
    if (width >= 1000) return 4;
    if (width >= 700) return 3;
    return 2;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.note_outlined, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'Aucune note',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Vos notes apparaîtront ici.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNoteOverlay() {
    return AnimatedSlide(
      offset: _showAddNote ? const Offset(0, 0) : const Offset(0, 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: _showAddNote
          ? Align(
        alignment: Alignment.bottomCenter,
        child: AddNoteComponent(
          titleController: _titleCtrl,
          contentController: _contentCtrl,
          selectedCategory: _selectedCategory,
          onSave: _addNote,
          onCancel: _closeAddNote,
          onSelectCategory: _openCategorySelector,
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildEditNoteOverlay() {
    return AnimatedSlide(
      offset: _showEditNote ? const Offset(0, 0) : const Offset(0, 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: _showEditNote && _noteBeingEdited != null
          ? Align(
        alignment: Alignment.bottomCenter,
        child: EditNoteComponent(
          note: _noteBeingEdited!,
          titleController: _titleCtrl,
          contentController: _contentCtrl,
          selectedCategory: _selectedCategory,
          onSave: _saveEditedNote,
          onCancel: _closeEditNote,
          onSelectCategory: _openCategorySelector,
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  // Overlay selector categories avec nouveaux callbacks
  Widget _buildCategorySelectorOverlay() {
    return AnimatedSlide(
      offset: _showCategorySelector ? const Offset(0, 0) : const Offset(1, 0),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: _showCategorySelector
          ? Align(
        alignment: Alignment.bottomCenter,
        child: CategorySelectorComponent(
          categories: _categories,
          selectedCategory: _selectedCategory,
          onCategorySelected: (category) {
            setState(() {
              _selectedCategory = category;
              _showCategorySelector = false;
            });
            if (!_showAddNote && !_showEditNote) {
              _fabAnimationController.forward();
            }
          },
          onAddCategory: _openAddCategory,
          onClose: _closeCategorySelector,
          onEditCategory: _openEditCategory,
          onDeleteCategory: _deleteCategory,
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  // Overlay ajout catégorie (glisser depuis droite)
  Widget _buildAddCategoryOverlay() {
    return AnimatedSlide(
      offset: _showAddCategory ? const Offset(0, 0) : const Offset(1, 0),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: _showAddCategory
          ? Align(
        alignment: Alignment.bottomCenter,
        child: AddCategoryComponent(
          onCategoryCreated: _onCategoryCreated,
          onClose: _closeAddCategory, // retour liste catégories
        ),
      )
          : const SizedBox.shrink(),
    );
  }

  // Overlay édition catégorie (slide bas->haut)
  Widget _buildEditCategoryOverlay() {
    return AnimatedSlide(
      offset: _showEditCategory ? const Offset(0, 0) : const Offset(0, 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: _showEditCategory && _categoryBeingEdited != null
          ? Align(
        alignment: Alignment.bottomCenter,
        child: EditCategoryComponent(
          category: _categoryBeingEdited!,
          onCategoryUpdated: _updateCategory,
          onClose: _closeEditCategory,
        ),
      )
          : const SizedBox.shrink(),
    );
  }
}
