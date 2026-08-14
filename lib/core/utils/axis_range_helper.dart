// lib/core/utils/axis_range_helper.dart

import 'dart:math';

/// Clean Y-axis bounds and interval for a chart.
class AxisRange {
  final double min;
  final double max;
  final double interval;

  const AxisRange({
    required this.min,
    required this.max,
    required this.interval,
  });
}

/// Calculates clean, readable axis values for fl_chart charts.
///
/// Y-axis: rounds min DOWN and max UP to the next clean increment,
/// ensuring tolerance lines are always visible inside the axis bounds.
///
/// X-axis: calculates a label interval so dates never bunch or overlap.
class AxisRangeHelper {
  /// Calculates Y-axis [min], [max], and [interval] for the given data.
  ///
  /// [values]: the data points being plotted — must not be empty.
  /// [thresholds]: tolerance / guide lines that must always be visible.
  /// [targetDivisions]: how many grid divisions to aim for (default 5).
  static AxisRange calculate({
    required List<double> values,
    List<double> thresholds = const [],
    int targetDivisions = 5,
  }) {
    assert(values.isNotEmpty, 'AxisRangeHelper.calculate: values must not be empty');

    final allValues = [...values, ...thresholds];
    final rawMin = allValues.reduce(min);
    final rawMax = allValues.reduce(max);

    final rawRange = rawMax - rawMin;
    final safeRange = rawRange == 0 ? 2.0 : rawRange;

    final interval = _niceNumber(safeRange / targetDivisions);

    // Snap to interval grid — min rounds DOWN, max rounds UP
    final snappedMin = (rawMin / interval).floor() * interval;
    final snappedMax = (rawMax / interval).ceil() * interval;

    // Guarantee threshold lines are inside the axis (add one interval of clearance)
    final finalMin = thresholds.isEmpty
        ? snappedMin
        : min(snappedMin, thresholds.reduce(min) - interval);
    final finalMax = thresholds.isEmpty
        ? snappedMax
        : max(snappedMax, thresholds.reduce(max) + interval);

    return AxisRange(min: finalMin, max: finalMax, interval: interval);
  }

  /// Returns the step between labelled X-axis points so at most
  /// [maxLabels] date labels appear — prevents bunching and overlap.
  static int dateInterval(int pointCount, {int maxLabels = 5}) {
    if (pointCount <= maxLabels) return 1;
    return (pointCount / maxLabels).ceil();
  }

  /// Rounds [value] up to the nearest "nice" number (1, 2, 5, 10, 20, …).
  static double _niceNumber(double value) {
    if (value <= 0) return 1.0;
    final exp = (log(value) / log(10)).floor();
    final magnitude = pow(10.0, exp).toDouble();
    final normalized = value / magnitude;
    if (normalized < 1.5) return magnitude;
    if (normalized < 3.5) return 2.0 * magnitude;
    if (normalized < 7.5) return 5.0 * magnitude;
    return 10.0 * magnitude;
  }
}
