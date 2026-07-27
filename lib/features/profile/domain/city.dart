import '../../../core/l10n/localized_name.dart';

/// A Syrian city an employee may be from.
///
/// Its own small type rather than the master-data `ReferenceItem`: the profile
/// form needs an id and a name and nothing else the catalog carries, and this
/// keeps the profile feature from depending on the modules one for it. The rows
/// are the same rows — the admin-editable `syrian_cities` list seeded in 0023.
class City {
  const City({required this.id, required this.name});

  final String id;
  final LocalizedName name;

  factory City.fromMap(Map<String, dynamic> map) =>
      City(id: map['id'] as String, name: LocalizedName.fromMap(map));
}
