import '../../../core/l10n/localized_name.dart';
import 'module_type.dart';

/// One admin-managed master-data list (hotels, clusters, cities, …).
///
/// A set carries its own item schema in [fields], the same way a module type
/// carries a field schema — which is what lets "manage hotels" and "manage
/// clusters" be one screen reading two different shapes.
class ReferenceSet {
  const ReferenceSet({
    required this.id,
    required this.code,
    required this.name,
    this.fields = const [],
    this.items = const [],
  });

  final String id;
  final String code;
  final LocalizedName name;
  final List<ModuleField> fields;
  final List<ReferenceItem> items;

  ReferenceSet copyWith({List<ReferenceItem>? items}) => ReferenceSet(
    id: id,
    code: code,
    name: name,
    fields: fields,
    items: items ?? this.items,
  );

  factory ReferenceSet.fromMap(Map<String, dynamic> map) {
    final fields = ((map['reference_set_fields'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .toList();
    fields.sort(
      (a, b) => ((a['sort_order'] as int?) ?? 0).compareTo(
        (b['sort_order'] as int?) ?? 0,
      ),
    );
    final items = ((map['reference_items'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ReferenceItem.fromMap)
        .toList();
    items.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.name.ar.compareTo(b.name.ar);
    });
    return ReferenceSet(
      id: map['id'] as String,
      code: map['code'] as String,
      name: LocalizedName.fromMap(map),
      fields: fields.map(ModuleField.fromMap).toList(),
      items: items,
    );
  }
}

/// One entry in a set: its name, plus the values of whatever fields its set
/// defines, keyed by field key.
class ReferenceItem {
  const ReferenceItem({
    required this.id,
    required this.setId,
    required this.name,
    this.data = const {},
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String id;
  final String setId;
  final LocalizedName name;
  final Map<String, dynamic> data;
  final bool isActive;
  final int sortOrder;

  factory ReferenceItem.fromMap(Map<String, dynamic> map) => ReferenceItem(
    id: map['id'] as String,
    setId: map['set_id'] as String,
    name: LocalizedName.fromMap(map),
    data: Map<String, dynamic>.from(
      (map['data'] as Map?) ?? const <String, dynamic>{},
    ),
    isActive: (map['is_active'] as bool?) ?? true,
    sortOrder: (map['sort_order'] as int?) ?? 0,
  );
}
