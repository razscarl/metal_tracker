// lib/features/settings/presentation/providers/settings_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_providers.g.dart';

const _kLowGsrMark = 'gsr_low_mark';
const _kHighGsrMark = 'gsr_high_mark';

class GsrSettings {
  final double lowMark;
  final double highMark;

  const GsrSettings({required this.lowMark, required this.highMark});

  GsrSettings copyWith({double? lowMark, double? highMark}) => GsrSettings(
        lowMark: lowMark ?? this.lowMark,
        highMark: highMark ?? this.highMark,
      );
}

@Riverpod(keepAlive: true)
class GsrSettingsNotifier extends _$GsrSettingsNotifier {
  @override
  Future<GsrSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return GsrSettings(
      lowMark: prefs.getDouble(_kLowGsrMark) ?? 60.0,
      highMark: prefs.getDouble(_kHighGsrMark) ?? 70.0,
    );
  }

  Future<void> setLowMark(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLowGsrMark, value);
    final current = await future;
    state = AsyncData(current.copyWith(lowMark: value));
  }

  Future<void> setHighMark(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kHighGsrMark, value);
    final current = await future;
    state = AsyncData(current.copyWith(highMark: value));
  }
}
