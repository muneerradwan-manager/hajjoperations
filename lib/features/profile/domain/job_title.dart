class JobTitle {
  const JobTitle({required this.id, required this.name, this.isActive = true});

  final String id;
  final String name;
  final bool isActive;

  factory JobTitle.fromMap(Map<String, dynamic> map) => JobTitle(
    id: map['id'] as String,
    name: map['name'] as String,
    isActive: (map['is_active'] as bool?) ?? true,
  );
}
