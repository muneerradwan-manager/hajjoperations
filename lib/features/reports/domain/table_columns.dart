/// Keeping a table's rows under the right headings when its columns change.
///
/// A written report's table stores its rows as lists positioned against its
/// column list, so every change to the columns has to move the cells with them.
/// Get it wrong and the third value starts reading under the second heading,
/// which is the kind of error nobody notices until the numbers are quoted.
///
/// The columns are entered as tags, and that is what makes this subtle: adding,
/// removing and reordering are all visible in the list of names, but a RENAME
/// is not. Removing "اليوم" and adding "التاريخ" produces exactly the same
/// before-and-after as correcting a typo in one heading. So renaming is
/// recognised rather than told: when the count has not changed and exactly one
/// name has, it is treated as that column keeping its data under a new name.
///
/// The heuristic is deliberately narrow. Two names changing at once could be
/// two renames or a swap or four separate edits, and guessing between them
/// would move a column of numbers under the wrong heading on a guess — worse
/// than the honest emptying that happens instead.
List<List<String>> realignRows({
  required List<String> before,
  required List<String> after,
  required List<List<String>> rows,
}) {
  // Nothing to carry.
  if (rows.isEmpty) return const [];

  // A cell's value under the old headings, or '' if there was none.
  String cell(List<String> row, int index) =>
      index >= 0 && index < row.length ? row[index] : '';

  final renamed = _singleRename(before, after);

  return [
    for (final row in rows)
      [
        for (var i = 0; i < after.length; i++)
          if (renamed != null && i == renamed)
            // The one heading that changed — its column stays where it was.
            cell(row, i)
          else
            cell(row, before.indexOf(after[i])),
      ],
  ];
}

/// The position of the single heading that changed, or null.
///
/// Null when the count changed, when nothing changed, or when more than one
/// name differs — all cases where a rename cannot be told from an edit.
int? _singleRename(List<String> before, List<String> after) {
  if (before.length != after.length) return null;
  int? at;
  for (var i = 0; i < before.length; i++) {
    if (before[i] == after[i]) continue;
    // A second difference: this is a reorder or several edits, not a rename.
    if (at != null) return null;
    at = i;
  }
  if (at == null) return null;
  // A name that merely MOVED is not a rename — it is still in the list, and
  // matching it by name puts its data where it went.
  if (before.contains(after[at]) || after.contains(before[at])) return null;
  return at;
}
