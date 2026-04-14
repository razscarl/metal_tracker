// lib/features/spot_prices/data/services/global_spot_price_service_factory.dart

import 'package:metal_tracker/features/spot_prices/data/services/base_global_spot_price_service.dart';
import 'package:metal_tracker/features/spot_prices/data/services/metal_price_api_service.dart';
import 'package:metal_tracker/features/spot_prices/data/services/metals_dev_service.dart';

class GlobalSpotPriceServiceFactory {
  GlobalSpotPriceServiceFactory._();

  static final Map<String, BaseGlobalSpotPriceService> _registry = {
    'metalpriceapi': MetalPriceApiService(),
    'metalsdev': MetalsDevService(),
  };

  static List<BaseGlobalSpotPriceService> get all =>
      _registry.values.toList();

  /// Normalises a provider key for matching — lowercases and strips non-alphanumeric
  /// so 'metals_dev', 'MetalsDev', 'metalsdev' all resolve to the same entry.
  static String _normalise(String key) =>
      key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static BaseGlobalSpotPriceService forType(String? type) {
    if (type == null) return _registry.values.first;
    final normType = _normalise(type);
    for (final entry in _registry.entries) {
      if (_normalise(entry.key) == normType) return entry.value;
    }
    return _registry.values.first;
  }

  static String displayNameFor(String? type) => forType(type).displayName;
}
