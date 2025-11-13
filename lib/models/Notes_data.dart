class CategorieNote {
  int id;
  String nom;
  String couleurHex;

  CategorieNote({
    required this.id,
    required this.nom,
    required this.couleurHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'couleurHex': couleurHex,
    };
  }

  factory CategorieNote.fromMap(Map<String, dynamic> map) {
    return CategorieNote(
      id: map['id'],
      nom: map['nom'],
      couleurHex: map['couleurHex'],
    );
  }
}

class Note {
  int id;
  String title;
  String content;
  DateTime createdAt;
  DateTime? updatedAt;
  CategorieNote? categorie;
  bool isImportant;
  bool isArchived;
  bool isPinned;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.categorie,
    this.isImportant = false,
    this.isArchived = false,
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'categorie': categorie != null ? categorie!.toMap() : null,
      'isImportant': isImportant,
      'isArchived': isArchived,
      'isPinned': isPinned,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      categorie: map['categorie'] != null
          ? CategorieNote.fromMap(Map<String, dynamic>.from(map['categorie']))
          : null,
      isImportant: map['isImportant'] ?? false,
      isArchived: map['isArchived'] ?? false,
      isPinned: map['isPinned'] ?? false,
    );
  }
}
