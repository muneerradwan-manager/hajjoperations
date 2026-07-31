/// What a written report is made of.
///
/// A special report is TYPED — its type declares the columns and the enterer
/// fills them. A general one is written, so its content is a sequence of these:
/// a heading, some prose, a list, a table, a link, a code, in whatever order
/// the thing being said needs.
enum ReportBlockKind {
  heading,
  subheading,
  paragraph,
  bullets,
  numbers,
  table,
  url,
  qr,
  note,
  divider;

  static ReportBlockKind fromDb(String? v) => switch (v) {
    'heading' => ReportBlockKind.heading,
    'subheading' => ReportBlockKind.subheading,
    'bullets' => ReportBlockKind.bullets,
    'numbers' => ReportBlockKind.numbers,
    'table' => ReportBlockKind.table,
    'url' => ReportBlockKind.url,
    'qr' => ReportBlockKind.qr,
    'note' => ReportBlockKind.note,
    'divider' => ReportBlockKind.divider,
    _ => ReportBlockKind.paragraph,
  };

  String get db => name;

  /// Whether the block is a single piece of prose — which decides both the
  /// editor's field and whether an empty one is worth keeping.
  bool get isText =>
      this == heading ||
      this == subheading ||
      this == paragraph ||
      this == note;

  bool get isList => this == bullets || this == numbers;
}

/// One block of a written report.
class ReportBlock {
  const ReportBlock({
    required this.id,
    required this.kind,
    this.data = const {},
    this.sortOrder = 0,
  });

  final String id;
  final ReportBlockKind kind;
  final Map<String, dynamic> data;
  final int sortOrder;

  String get text => data['text']?.toString() ?? '';
  String get url => data['url']?.toString() ?? '';
  String get value => data['value']?.toString() ?? '';
  String get label => data['label']?.toString() ?? '';

  List<String> get items => [
    for (final i in (data['items'] as List?) ?? const [])
      if ('$i'.trim().isNotEmpty) '$i',
  ];

  List<String> get columns => [
    for (final c in (data['columns'] as List?) ?? const []) '$c',
  ];

  /// Rows as they are stored: a list of lists, one value per column.
  List<List<String>> get rows => [
    for (final r in (data['rows'] as List?) ?? const [])
      [for (final c in (r as List? ?? const [])) '$c'],
  ];

  /// Whether there is anything to draw. An empty block is not an error — it is
  /// a line somebody added and did not fill — so it is skipped rather than
  /// rendered as a gap.
  bool get isEmpty => switch (kind) {
    ReportBlockKind.divider => false,
    _ when kind.isText => text.trim().isEmpty,
    _ when kind.isList => items.isEmpty,
    ReportBlockKind.table => columns.isEmpty && rows.isEmpty,
    ReportBlockKind.url => url.trim().isEmpty,
    ReportBlockKind.qr => value.trim().isEmpty,
    _ => true,
  };

  factory ReportBlock.fromMap(Map<String, dynamic> map) => ReportBlock(
    id: map['id'] as String,
    kind: ReportBlockKind.fromDb(map['kind'] as String?),
    data: Map<String, dynamic>.from(
      (map['data'] as Map?) ?? const <String, dynamic>{},
    ),
    sortOrder: (map['sort_order'] as int?) ?? 0,
  );
}
