// lib/core/utils/sort_config.dart

/// Immutable sort entry: one column + direction.
class SortEntry<T> {
  final T column;
  final bool ascending;
  const SortEntry(this.column, {required this.ascending});
}

/// Immutable two-level sort configuration.
///
/// [entries[0]] = primary sort, [entries[1]] = secondary sort (optional).
///
/// Usage:
/// ```dart
/// SortConfig<_Col> _sort = SortConfig.initial(_Col.date, ascending: false);
///
/// void _onHeaderTap(_Col col) {
///   setState(() {
///     _sort = _sort.tap(col, defaultAscending: (c) => c == _Col.name);
///   });
/// }
///
/// items.sort((a, b) => _sort.compare(a, b, _compareByCol));
/// ```
class SortConfig<T> {
  /// Up to 2 sort entries; [0] is primary, [1] is secondary.
  final List<SortEntry<T>> entries;

  const SortConfig(this.entries) : assert(entries.length <= 2);

  /// Creates an initial single-column sort config.
  factory SortConfig.initial(T column, {bool ascending = false}) =>
      SortConfig([SortEntry(column, ascending: ascending)]);

  /// Returns a new config after tapping [col].
  ///
  /// - Same column as primary → toggle direction.
  /// - Different column → promote [col] to primary; old primary becomes secondary.
  ///   [defaultAscending] controls the initial direction for the new primary.
  SortConfig<T> tap(T col, {bool Function(T)? defaultAscending}) {
    if (entries.isNotEmpty && entries[0].column == col) {
      return SortConfig([
        SortEntry(col, ascending: !entries[0].ascending),
        if (entries.length > 1) entries[1],
      ]);
    }
    final newAscending = defaultAscending?.call(col) ?? true;
    return SortConfig([
      SortEntry(col, ascending: newAscending),
      if (entries.isNotEmpty) entries[0],
    ]);
  }

  bool isPrimary(T col)   => entries.isNotEmpty && entries[0].column == col;
  bool isSecondary(T col) => entries.length > 1 && entries[1].column == col;
  bool isActive(T col)    => isPrimary(col) || isSecondary(col);
  bool isAscending(T col) {
    for (final e in entries) {
      if (e.column == col) return e.ascending;
    }
    return true;
  }

  /// 1 = primary, 2 = secondary, 0 = inactive.
  int priority(T col) {
    if (entries.isNotEmpty && entries[0].column == col) return 1;
    if (entries.length > 1 && entries[1].column == col) return 2;
    return 0;
  }

  /// Sorts [items] using [compareByCol] for each active entry in order.
  ///
  /// [compareByCol] returns a raw comparison value (positive/negative/zero);
  /// direction is applied by [compare] itself.
  void sortList<E>(List<E> items, int Function(E a, E b, T col) compareByCol) {
    items.sort((a, b) {
      for (final entry in entries) {
        final cmp = compareByCol(a, b, entry.column);
        if (cmp != 0) return entry.ascending ? cmp : -cmp;
      }
      return 0;
    });
  }
}
