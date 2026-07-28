import '../../../core/l10n/localized_name.dart';

/// One entry of the admin-managed job-title list (الوصف الوظيفي).
class JobTitle {
  const JobTitle({required this.id, required this.name, this.isActive = true});

  final String id;

  /// Both languages. The column is `name` rather than `name_ar` — it is the
  /// Arabic source the list was seeded in (0010) — with `name_en` beside it
  /// (0046); a title added without an English name reads in Arabic.
  final LocalizedName name;

  final bool isActive;

  factory JobTitle.fromMap(Map<String, dynamic> map) => JobTitle(
    id: map['id'] as String,
    name: jobTitleName(map),
    isActive: (map['is_active'] as bool?) ?? true,
  );
}

/// Reads a job title's two names out of whatever shape it arrived in.
///
/// `job_titles(name, name_en)` embedded in a profile query, or the flat
/// `job_title_name` / `job_title_name_en` that `assignable_employees` returns.
/// Null when the query did not ask for it at all.
LocalizedName? jobTitleNameOrNull(Map<String, dynamic> map) {
  final joined = map['job_titles'];
  if (joined is Map) return jobTitleName(joined.cast<String, dynamic>());
  final flat = map['job_title_name'] as String?;
  if (flat == null) return null;
  return LocalizedName(ar: flat, en: map['job_title_name_en'] as String?);
}

LocalizedName jobTitleName(Map<String, dynamic> map) => LocalizedName(
  ar: (map['name'] as String?) ?? '',
  en: map['name_en'] as String?,
);
