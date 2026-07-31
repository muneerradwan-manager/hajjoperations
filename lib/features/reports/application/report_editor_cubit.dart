import 'package:equatable/equatable.dart';

import '../../../core/bloc/safe_cubit.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../modules/data/modules_repository.dart';
import '../../modules/domain/reference_item.dart';
import '../../seasons/data/seasons_repository.dart';
import '../../seasons/domain/season.dart';
import '../data/reports_repository.dart';
import '../domain/report.dart';
import '../domain/report_type.dart';

enum EditorStatus { loading, ready, saving, error }

/// A block being written, before it has an id of its own.
class DraftBlock {
  DraftBlock(this.kind, {Map<String, dynamic>? data}) : data = {...?data};

  final ReportBlockKind kind;
  final Map<String, dynamic> data;

  String get text => data['text']?.toString() ?? '';

  List<String> get items => [
    for (final i in (data['items'] as List?) ?? const []) '$i',
  ];

  List<String> get columns => [
    for (final c in (data['columns'] as List?) ?? const []) '$c',
  ];

  List<List<String>> get rows => [
    for (final r in (data['rows'] as List?) ?? const [])
      [for (final c in (r as List? ?? const [])) '$c'],
  ];
}

/// A row being edited, before it has an id of its own.
class DraftRow {
  DraftRow({Map<String, dynamic>? data}) : data = {...?data};
  final Map<String, dynamic> data;

  String value(String key) => data[key]?.toString() ?? '';
}

class ReportEditorState extends Equatable {
  const ReportEditorState({
    this.status = EditorStatus.loading,
    this.types = const [],
    this.seasons = const [],
    this.referenceSets = const [],
    this.typeId,
    this.title = '',
    this.number = '',
    this.seasonId,
    this.data = const {},
    this.rows = const [],
    this.blocks = const [],
    this.isPublished = false,
    this.error,
  });

  final EditorStatus status;
  final List<ReportType> types;
  final List<Season> seasons;
  final List<ReferenceSet> referenceSets;

  final String? typeId;
  final String title;

  /// The reference number it was issued under, when it has one.
  final String number;

  /// Null is GENERAL, and it is where a new report starts. Most of what gets
  /// written down outlives one year.
  final String? seasonId;

  final Map<String, dynamic> data;
  final List<DraftRow> rows;

  /// What a WRITTEN report contains. A type with no table is written rather
  /// than filled in, and these are what it is made of.
  final List<DraftBlock> blocks;

  final bool isPublished;
  final String? error;

  ReportType? get type =>
      types.where((t) => t.id == typeId).firstOrNull;

  ReferenceSet? setById(String? id) =>
      id == null ? null : referenceSets.where((s) => s.id == id).firstOrNull;

  /// The columns to ASK for: a plain declaration once, and one per entry for a
  /// column declared over a master-data list.
  ///
  /// This is the whole point of the expansion. توزيع الوجبات has a count per
  /// تكتل, and the enterer must be given the clusters this season actually has
  /// — not a text box to type a cluster name into, which is how the same
  /// cluster ends up spelled three ways and matching nothing.
  List<({String key, String Function(dynamic) label, ReportColumn column})>
  get columns {
    final t = type;
    if (t == null) return const [];
    final out =
        <({String key, String Function(dynamic) label, ReportColumn column})>[];
    for (final c in t.columns) {
      if (!c.isExpanded) {
        out.add((key: c.key, label: (ctx) => c.label.of(ctx), column: c));
        continue;
      }
      final set = setById(c.sourceSetId);
      if (set == null) continue;
      for (final item in set.itemsForSeason(seasonId)) {
        out.add((key: item.id, label: (ctx) => item.name.of(ctx), column: c));
      }
    }
    return out;
  }

  bool get canSave => title.trim().isNotEmpty && typeId != null;

  ReportEditorState copyWith({
    EditorStatus? status,
    List<ReportType>? types,
    List<Season>? seasons,
    List<ReferenceSet>? referenceSets,
    Object? typeId = _unset,
    String? title,
    String? number,
    Object? seasonId = _unset,
    Map<String, dynamic>? data,
    List<DraftRow>? rows,
    List<DraftBlock>? blocks,
    bool? isPublished,
    String? error,
  }) => ReportEditorState(
    status: status ?? this.status,
    types: types ?? this.types,
    seasons: seasons ?? this.seasons,
    referenceSets: referenceSets ?? this.referenceSets,
    typeId: typeId == _unset ? this.typeId : typeId as String?,
    title: title ?? this.title,
    number: number ?? this.number,
    // Null means general, so it cannot be defaulted away with `??`.
    seasonId: seasonId == _unset ? this.seasonId : seasonId as String?,
    data: data ?? this.data,
    rows: rows ?? this.rows,
    blocks: blocks ?? this.blocks,
    isPublished: isPublished ?? this.isPublished,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    types,
    seasons,
    referenceSets,
    typeId,
    title,
    number,
    seasonId,
    data,
    rows,
    blocks,
    isPublished,
    error,
  ];
}

const Object _unset = Object();

/// Entering a report, and correcting one.
class ReportEditorCubit extends SafeCubit<ReportEditorState> {
  ReportEditorCubit(this._repo, this._modules, this._seasons, {this.existing})
    : super(const ReportEditorState()) {
    _load();
  }

  final ReportsRepository _repo;
  final ModulesRepository _modules;
  final SeasonsRepository _seasons;

  /// The report being corrected, or null when a new one is being entered.
  final Report? existing;

  /// The columns as the form must ask for them — the state works them out.
  List<({String key, String Function(dynamic) label, ReportColumn column})>
  get columns => state.columns;

  Future<void> _load() async {
    try {
      final types = await _repo.fetchTypes();
      final seasons = await _seasons.fetchSeasons();
      final sets = await _modules.fetchReferenceSets(activeOnly: false);
      final e = existing;
      emit(
        ReportEditorState(
          status: EditorStatus.ready,
          types: types,
          seasons: seasons,
          referenceSets: sets,
          typeId: e?.reportTypeId,
          title: e?.title ?? '',
          number: e?.number ?? '',
          seasonId: e?.seasonId,
          data: {...?e?.data},
          rows: [for (final r in e?.rows ?? const []) DraftRow(data: r.data)],
          blocks: [
            for (final b in e?.blocks ?? const [])
              DraftBlock(b.kind, data: b.data),
          ],
          isPublished: e?.isPublished ?? false,
        ),
      );
    } catch (err) {
      emit(
        ReportEditorState(
          status: EditorStatus.error,
          error: err.toString(),
        ),
      );
    }
  }

  void setType(String? id) => emit(state.copyWith(typeId: id, rows: const []));
  void setTitle(String v) => emit(state.copyWith(title: v));
  void setNumber(String v) => emit(state.copyWith(number: v));
  void setSeason(String? id) => emit(state.copyWith(seasonId: id));
  void setPublished(bool v) => emit(state.copyWith(isPublished: v));

  void setField(String key, dynamic value) {
    final data = {...state.data};
    if (value == null || (value is String && value.isEmpty)) {
      data.remove(key);
    } else {
      data[key] = value;
    }
    emit(state.copyWith(data: data));
  }

  void addRow() => emit(state.copyWith(rows: [...state.rows, DraftRow()]));

  // ------------------------------------------------------------- the blocks

  void addBlock(ReportBlockKind kind) => emit(
    state.copyWith(blocks: [...state.blocks, DraftBlock(kind)]),
  );

  void removeBlock(int index) {
    final blocks = [...state.blocks]..removeAt(index);
    emit(state.copyWith(blocks: blocks));
  }

  /// Up or down by one. A notice is written in the order it is read, and the
  /// order is the thing most often got wrong on the first pass.
  void moveBlock(int index, int delta) {
    final to = index + delta;
    if (to < 0 || to >= state.blocks.length) return;
    final blocks = [...state.blocks];
    final moved = blocks.removeAt(index);
    blocks.insert(to, moved);
    emit(state.copyWith(blocks: blocks));
  }

  void setBlockValue(int index, String key, Object? value) {
    final blocks = [...state.blocks];
    final data = {...blocks[index].data};
    if (value == null || (value is String && value.isEmpty)) {
      data.remove(key);
    } else {
      data[key] = value;
    }
    blocks[index] = DraftBlock(blocks[index].kind, data: data);
    emit(state.copyWith(blocks: blocks));
  }

  void removeRow(int index) {
    final rows = [...state.rows]..removeAt(index);
    emit(state.copyWith(rows: rows));
  }

  /// The value a computed column works out for a row.
  ///
  /// One arrangement, named rather than expressed in a formula language nobody
  /// else will write in: the total of a distribution row is the sum of its
  /// expanded columns — the clusters. Recomputed on every read, so it cannot
  /// drift from the numbers it is a total of.
  int computedFor(int index, ReportColumn column) {
    if (!column.isComputed) return 0;
    final expanded = {
      for (final c in columns)
        if (c.column.isExpanded) c.key,
    };
    var total = 0;
    state.rows[index].data.forEach((key, value) {
      if (expanded.contains(key)) {
        total += int.tryParse('$value'.trim()) ?? 0;
      }
    });
    return total;
  }

  void setCell(int index, String key, String value) {
    final rows = [...state.rows];
    final data = {...rows[index].data};
    if (value.isEmpty) {
      data.remove(key);
    } else {
      data[key] = value;
    }
    rows[index] = DraftRow(data: data);
    emit(state.copyWith(rows: rows));
    _recompute(index);
  }

  /// Writes the computed columns of a row after one of its cells changed.
  ///
  /// Stored rather than left to the reader: the report is read by people who
  /// never open this editor, and by a screen that draws whatever is in the row.
  void _recompute(int index) {
    final computed = [
      for (final c in columns)
        if (c.column.isComputed) c,
    ];
    if (computed.isEmpty) return;
    final rows = [...state.rows];
    final data = {...rows[index].data};
    for (final c in computed) {
      data[c.key] = '${computedFor(index, c.column)}';
    }
    rows[index] = DraftRow(data: data);
    emit(state.copyWith(rows: rows));
  }

  /// Saves and returns the report's id, or null with [state.error] set.
  ///
  /// The rows are replaced wholesale rather than diffed. A report's table is
  /// small and entered as one thing; matching row against row to write three
  /// updates instead of a delete and an insert would be more code and more
  /// ways to leave it half-written.
  Future<String?> save() async {
    if (!state.canSave) return null;
    emit(state.copyWith(status: EditorStatus.saving, error: null));
    try {
      final payload = {
        'report_type_id': state.typeId,
        'season_id': state.seasonId,
        'title': state.title.trim(),
        // Empty is NULL, not an empty string: a report without a number has
        // none, and '' would sort and search as though it did.
        'number': state.number.trim().isEmpty ? null : state.number.trim(),
        'data': state.data,
        'is_published': state.isPublished,
      };

      String id;
      if (existing == null) {
        final row = await supabase
            .from('reports')
            .insert({...payload, 'created_by': supabase.auth.currentUser?.id})
            .select('id')
            .single();
        id = row['id'] as String;
      } else {
        id = existing!.id;
        await supabase.from('reports').update(payload).eq('id', id);
        await supabase.from('report_rows').delete().eq('report_id', id);
      }

      final rows = [
        for (var i = 0; i < state.rows.length; i++)
          if (state.rows[i].data.isNotEmpty)
            {'report_id': id, 'data': state.rows[i].data, 'sort_order': i + 1},
      ];
      if (rows.isNotEmpty) {
        await supabase.from('report_rows').insert(rows);
      }

      // Same wholesale replacement the rows get, and for the same reason: a
      // notice is written as one thing, and diffing block against block would
      // be more code and more ways to leave it half-written.
      if (existing != null) {
        await supabase.from('report_blocks').delete().eq('report_id', id);
      }
      final blocks = [
        for (var i = 0; i < state.blocks.length; i++)
          {
            'report_id': id,
            'kind': state.blocks[i].kind.db,
            'data': state.blocks[i].data,
            'sort_order': i + 1,
          },
      ];
      if (blocks.isNotEmpty) {
        await supabase.from('report_blocks').insert(blocks);
      }

      emit(state.copyWith(status: EditorStatus.ready));
      return id;
    } catch (e) {
      emit(state.copyWith(status: EditorStatus.ready, error: e.toString()));
      return null;
    }
  }
}
