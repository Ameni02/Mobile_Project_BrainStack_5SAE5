import 'package:flutter/material.dart';
import '../DB/DB.dart';
import '../models/Notes_data.dart';
import '../theme/app_colors.dart';
import 'notes_grid_item.dart';
import 'notes_list_item.dart';
import 'confirm_delete_sheet.dart';
import 'notes_sort_buttons.dart';
import 'edit_note_component.dart';
import 'add_note_component.dart';
import 'category_selector_component.dart';
import 'add_category_component.dart';
import 'edit_category_component.dart';

class ArchiveComponent extends StatefulWidget {
  const ArchiveComponent({super.key});
  @override
  State<ArchiveComponent> createState() => _ArchiveComponentState();
}

class _ArchiveComponentState extends State<ArchiveComponent> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isGrid = true;
  NotesSortType _sortType = NotesSortType.dateDesc;
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();
  CategorieNote? _selectedCategory;
  List<CategorieNote> _categories = [];
  bool _showEditNote = false;
  Note? _noteBeingEdited;
  bool _showCategorySelector = false;
  bool _showAddCategory = false;
  bool _showEditCategory = false;
  CategorieNote? _categoryBeingEdited;
  bool _changed = false; // nouveau flag

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _loadCategories();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final rows = await DB.getNotes();
      _notes = rows.map(_mapRowToNote).where((n) => n.isArchived).toList();
      _applySort();
      _filteredNotes = List.from(_notes);
    } catch (_) {
      _notes = [];
      _filteredNotes = [];
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await DB.getAllCategories();
      setState(() => _categories = cats);
    } catch (_) {}
  }

  Note _mapRowToNote(Map<String, dynamic> m) {
    bool _toBool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }
    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }
    return Note(
      id: m['id'] as int,
      title: (m['title'] as String?) ?? '',
      content: (m['content'] as String?) ?? '',
      createdAt: _toDate(m['createdAt']) ?? DateTime.now(),
      updatedAt: _toDate(m['updatedAt']),
      isImportant: _toBool(m['isImportant']),
      isArchived: _toBool(m['isArchived']),
      isPinned: _toBool(m['isPinned']),
      categorie: m['category'] != null && m['category'] is Map
          ? CategorieNote(
              id: (m['category']['id'] as int?) ?? 0,
              nom: m['category']['nom'] as String? ?? '',
              couleurHex: m['category']['couleurHex'] as String? ?? '#2196F3',
            )
          : null,
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

  Future<void> _onChangeSort(NotesSortType t) async {
    setState(() {
      _sortType = t;
      _applySort();
      _filteredNotes = List.from(_notes);
    });
  }

  Future<void> _toggleArchived(Note note) async {
    try {
      await DB.updateNote(note.id, isArchived: false);
      setState(() {
        _notes.remove(note);
        _filteredNotes = List.from(_notes);
        _changed = true; // marquer changement
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note restaurée')));
      await _loadNotes();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur restauration')));
    }
  }

  Future<void> _confirmDeleteNote(Note note) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ConfirmDeleteSheet(
        title: 'Supprimer cette note ?',
        message: 'Cette action est irréversible.',
        onConfirm: () async {
          await DB.deleteNotes(note.id);
          await _loadNotes();
          setState(() { _changed = true; });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note supprimée avec succès')));
        },
        icon: Icons.delete_outline,
      ),
    );
  }

  void _openEditNote(Note n) {
    setState(() {
      _noteBeingEdited = n;
      _titleCtrl.text = n.title;
      _contentCtrl.text = n.content;
      _selectedCategory = n.categorie;
      _showEditNote = true;
    });
  }

  void _closeEditNote() {
    setState(() {
      _showEditNote = false;
      _noteBeingEdited = null;
      _titleCtrl.clear();
      _contentCtrl.clear();
      _selectedCategory = null;
    });
  }

  Future<void> _saveEditedNote() async {
    if (_noteBeingEdited == null) return;
    try {
      await DB.updateNote(_noteBeingEdited!.id, title: _titleCtrl.text.trim(), content: _contentCtrl.text.trim(), categoryId: _selectedCategory?.id);
      await _loadNotes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note mise à jour')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur mise à jour')));
    }
    _closeEditNote();
  }

  void _openCategorySelector() {
    setState(() {
      _showCategorySelector = true;
      _showAddCategory = false;
      _showEditCategory = false;
    });
  }

  void _closeCategorySelector() {
    setState(() => _showCategorySelector = false);
  }

  void _openAddCategory() {
    setState(() {
      _showAddCategory = true;
      _showCategorySelector = false;
      _showEditCategory = false;
    });
  }

  void _closeAddCategory() {
    setState(() {
      _showAddCategory = false;
      _showCategorySelector = true;
    });
  }

  void _openEditCategory(CategorieNote cat) {
    setState(() {
      _categoryBeingEdited = cat;
      _showEditCategory = true;
      _showCategorySelector = false;
      _showAddCategory = false;
    });
  }

  void _closeEditCategory() {
    setState(() {
      _showEditCategory = false;
      _categoryBeingEdited = null;
      _showCategorySelector = true;
    });
  }

  Future<void> _onCategoryCreated(Map<String, String> data) async {
    final c = CategorieNote(id: 0, nom: data['nom'] ?? 'Nouvelle', couleurHex: data['couleurHex'] ?? '#2196F3');
    try {
      final id = await DB.insertCategory(c);
      await _loadCategories();
      setState(() {
        _selectedCategory = _categories.firstWhere((e) => e.id == id, orElse: () => c);
        _showAddCategory = false;
        _showCategorySelector = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catégorie ajoutée')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur création catégorie')));
    }
  }

  Future<void> _updateCategory(CategorieNote updated) async {
    try {
      await DB.updateCategory(updated);
      await _loadCategories();
      setState(() {
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_changed);
        return false; // empêcher pop auto après notre pop manuel
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: NotesSortAndViewBar(
                      currentSort: _sortType,
                      isGrid: _isGrid,
                      onSortChanged: _onChangeSort,
                      onToggleView: () => setState(() => _isGrid = !_isGrid),
                    ),
                  ),
                  Expanded(child: _isLoading ? _buildLoading() : _buildNotesList()),
                ],
              ),
            ),
            _buildEditNoteOverlay(),
            _buildCategorySelectorOverlay(),
            _buildAddCategoryOverlay(),
            _buildEditCategoryOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
      ]),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_changed), // retourner flag
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          const Text(
            'Archives',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  Widget _buildNotesList() {
    if (_filteredNotes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.archive_outlined, size: 48, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text('Aucune note archivée pour le moment.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      if (_isGrid) {
        final cols = width >= 1200 ? 5 : width >= 1000 ? 4 : width >= 700 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: _filteredNotes.length,
          itemBuilder: (context, i) {
            final note = _filteredNotes[i];
            return NoteGridItem(
              note: note,
              onDelete: () => _confirmDeleteNote(note),
              onTap: () => _openEditNote(note),
              onTogglePinned: () {},
              onArchive: () => _toggleArchived(note),
            );
          },
        );
      } else {
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: _filteredNotes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, i) {
              final note = _filteredNotes[i];
              return NoteListItem(
                note: note,
                onDelete: () => _confirmDeleteNote(note),
                onTap: () => _openEditNote(note),
                onTogglePinned: () {},
                onArchive: () => _toggleArchived(note),
              );
            },
        );
      }
    });
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
                },
                onAddCategory: _openAddCategory,
                onClose: _closeCategorySelector,
                onEditCategory: _openEditCategory,
                onDeleteCategory: (_) {},
              ),
            )
          : const SizedBox.shrink(),
    );
  }

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
                onClose: _closeAddCategory,
              ),
            )
          : const SizedBox.shrink(),
    );
  }

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
