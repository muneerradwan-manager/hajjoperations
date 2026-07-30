import 'package:equatable/equatable.dart';

/// One counted thing with a name — a trade, a file type, a mission type.
///
/// The label arrives in both languages because the database holds both and the
/// reader picks one; resolving it here would freeze the choice at fetch time
/// and leave a chart in the wrong language after the user switches.
class CountedLabel extends Equatable {
  const CountedLabel({
    required this.labelAr,
    this.labelEn,
    required this.count,
    this.secondary,
  });

  final String labelAr;
  final String? labelEn;
  final int count;

  /// A second number the same row carries — the ACTIVE files of a type, beside
  /// its total.
  final int? secondary;

  static CountedLabel fromMap(Map<String, dynamic> m) => CountedLabel(
    labelAr: (m['label_ar'] ?? m['key'] ?? '') as String,
    labelEn: m['label_en'] as String?,
    count: (m['n'] ?? m['count'] ?? m['total'] ?? 0) as int,
    secondary: m['active'] as int?,
  );

  @override
  List<Object?> get props => [labelAr, labelEn, count, secondary];
}

/// A key the app knows the meaning of — `male`, `administrative`, `unknown` —
/// counted. Unlike [CountedLabel] the name is not in the database at all; it is
/// an enum, and the app owns its wording.
class CountedKey extends Equatable {
  const CountedKey({required this.key, required this.count});

  final String key;
  final int count;

  static CountedKey fromMap(Map<String, dynamic> m) => CountedKey(
    key: m['key'] as String? ?? 'unknown',
    count: m['count'] as int? ?? 0,
  );

  @override
  List<Object?> get props => [key, count];
}

/// The mission's people, on one season.
class PeopleStats extends Equatable {
  const PeopleStats({
    required this.participants,
    required this.withdrawn,
    required this.internal,
    required this.external,
    required this.byMission,
    required this.byGender,
    required this.byJobTitle,
  });

  final int participants;
  final int withdrawn;
  final int internal;
  final int external;
  final List<CountedKey> byMission;
  final List<CountedKey> byGender;
  final List<CountedLabel> byJobTitle;

  static PeopleStats fromMap(Map<String, dynamic> m) => PeopleStats(
    participants: m['participants'] as int? ?? 0,
    withdrawn: m['withdrawn'] as int? ?? 0,
    internal: m['internal'] as int? ?? 0,
    external: m['external'] as int? ?? 0,
    byMission: _keys(m['by_mission']),
    byGender: _keys(m['by_gender']),
    byJobTitle: _labels(m['by_job_title']),
  );

  @override
  List<Object?> get props => [
    participants,
    withdrawn,
    internal,
    external,
    byMission,
    byGender,
    byJobTitle,
  ];
}

/// Everyone waiting at the door, and everyone already through it. Not scoped to
/// a season — somebody waiting to be approved is not on one yet, which is the
/// whole reason they are waiting.
class ApprovalStats extends Equatable {
  const ApprovalStats({
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.incomplete,
  });

  final int pending;
  final int approved;
  final int rejected;
  final int incomplete;

  static ApprovalStats fromMap(Map<String, dynamic> m) => ApprovalStats(
    pending: m['pending'] as int? ?? 0,
    approved: m['approved'] as int? ?? 0,
    rejected: m['rejected'] as int? ?? 0,
    incomplete: m['incomplete'] as int? ?? 0,
  );

  @override
  List<Object?> get props => [pending, approved, rejected, incomplete];
}

/// The season's operational files.
class ModuleStats extends Equatable {
  const ModuleStats({
    required this.total,
    required this.active,
    required this.draft,
    required this.ended,
    required this.running,
    required this.nodes,
    required this.members,
    required this.unstaffed,
    required this.byType,
  });

  final int total;
  final int active;
  final int draft;

  /// Files whose end date is behind us. A file with no end date has not ended
  /// by any date — which is not the same as running forever.
  final int ended;

  final int running;

  /// Sectors, towers, camps — every node of every tree in the season.
  final int nodes;

  /// Distinct people holding a role in at least one file.
  final int members;

  /// Files with nobody in them, which is the one number on this page that is
  /// always worth acting on.
  final int unstaffed;

  final List<CountedLabel> byType;

  static ModuleStats fromMap(Map<String, dynamic> m) => ModuleStats(
    total: m['total'] as int? ?? 0,
    active: m['active'] as int? ?? 0,
    draft: m['draft'] as int? ?? 0,
    ended: m['ended'] as int? ?? 0,
    running: m['running'] as int? ?? 0,
    nodes: m['nodes'] as int? ?? 0,
    members: m['members'] as int? ?? 0,
    unstaffed: m['unstaffed'] as int? ?? 0,
    byType: _labels(m['by_type']),
  );

  @override
  List<Object?> get props => [
    total,
    active,
    draft,
    ended,
    running,
    nodes,
    members,
    unstaffed,
    byType,
  ];
}

/// A day, and how many reports accounted for it.
class ReportDay extends Equatable {
  const ReportDay({required this.day, required this.count});

  final DateTime day;
  final int count;

  @override
  List<Object?> get props => [day, count];
}

/// The reports a season filed — the one genuine time series this schema holds.
class ReportStats extends Equatable {
  const ReportStats({
    required this.total,
    required this.authors,
    required this.series,
  });

  final int total;
  final int authors;

  /// The last thirty days, by the period each report ACCOUNTS for rather than
  /// the moment it was typed: a Monday report filed on Tuesday belongs to
  /// Monday, and the database normalises that.
  final List<ReportDay> series;

  static ReportStats fromMap(Map<String, dynamic> m) => ReportStats(
    total: m['total'] as int? ?? 0,
    authors: m['authors'] as int? ?? 0,
    series: [
      for (final row in (m['series'] as List? ?? const []))
        ReportDay(
          day: DateTime.parse((row as Map)['day'] as String),
          count: row['n'] as int? ?? 0,
        ),
    ],
  );

  @override
  List<Object?> get props => [total, authors, series];
}

/// What the people who worked a file said about each other. Counts and an
/// average only — the verdicts themselves are anonymous by design.
class RatingStats extends Equatable {
  const RatingStats({
    required this.count,
    required this.ratedPeople,
    required this.average,
    required this.distribution,
  });

  final int count;
  final int ratedPeople;
  final double? average;

  /// Five entries, ones first.
  final List<int> distribution;

  static RatingStats fromMap(Map<String, dynamic> m) {
    final byStar = <int, int>{};
    for (final row in (m['distribution'] as List? ?? const [])) {
      byStar[(row as Map)['stars'] as int] = row['count'] as int? ?? 0;
    }
    return RatingStats(
      count: m['count'] as int? ?? 0,
      ratedPeople: m['rated_people'] as int? ?? 0,
      average: (m['average'] as num?)?.toDouble(),
      distribution: [for (var s = 1; s <= 5; s++) byStar[s] ?? 0],
    );
  }

  @override
  List<Object?> get props => [count, ratedPeople, average, distribution];
}

/// The season a dashboard is pointed at.
class DashboardSeason extends Equatable {
  const DashboardSeason({
    required this.id,
    required this.hijriYear,
    this.gregorianLabel,
    required this.isCurrent,
  });

  final String id;
  final int hijriYear;
  final String? gregorianLabel;
  final bool isCurrent;

  static DashboardSeason fromMap(Map<String, dynamic> m) => DashboardSeason(
    id: m['id'] as String,
    hijriYear: m['hijri_year'] as int,
    gregorianLabel: m['gregorian_label'] as String?,
    isCurrent: m['is_current'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [id, hijriYear, gregorianLabel, isCurrent];
}

/// A season, from above.
///
/// Every section is nullable, and that is the design rather than an accident:
/// the function computes what it likes and then hands back only the parts this
/// reader is allowed to ask about. A missing section is "you may not ask",
/// which is a different statement from a zero — and the screen draws neither
/// rather than drawing a zero and lying.
class DashboardStats extends Equatable {
  const DashboardStats({
    this.season,
    this.people,
    this.approvals,
    this.modules,
    this.reports,
    this.ratings,
  });

  final DashboardSeason? season;
  final PeopleStats? people;
  final ApprovalStats? approvals;
  final ModuleStats? modules;
  final ReportStats? reports;
  final RatingStats? ratings;

  /// Whether there is anything at all to draw. A reader holding none of the
  /// permissions gets a season and nothing else, and should be told so plainly
  /// instead of shown an empty page.
  bool get isEmpty =>
      people == null &&
      approvals == null &&
      modules == null &&
      reports == null &&
      ratings == null;

  static DashboardStats fromMap(Map<String, dynamic> m) => DashboardStats(
    season: _sub(m['season'], DashboardSeason.fromMap),
    people: _sub(m['people'], PeopleStats.fromMap),
    approvals: _sub(m['approvals'], ApprovalStats.fromMap),
    modules: _sub(m['modules'], ModuleStats.fromMap),
    reports: _sub(m['reports'], ReportStats.fromMap),
    ratings: _sub(m['ratings'], RatingStats.fromMap),
  );

  @override
  List<Object?> get props => [
    season,
    people,
    approvals,
    modules,
    reports,
    ratings,
  ];
}

T? _sub<T>(Object? value, T Function(Map<String, dynamic>) parse) =>
    value is Map ? parse(Map<String, dynamic>.from(value)) : null;

List<CountedKey> _keys(Object? rows) => [
  for (final r in (rows as List? ?? const []))
    CountedKey.fromMap(Map<String, dynamic>.from(r as Map)),
];

List<CountedLabel> _labels(Object? rows) => [
  for (final r in (rows as List? ?? const []))
    CountedLabel.fromMap(Map<String, dynamic>.from(r as Map)),
];
