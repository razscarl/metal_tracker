// lib/features/spot_prices/data/services/global_spot_price_service_factory.dart

import 'package:metal_tracker/features/spot_prices/data/services/base_global_spot_price_service.dart';
import 'package:metal_tracker/features/spot_prices/data/services/metal_price_api_service.dart';

class GlobalSpotPriceServiceFactory {
  GlobalSpotPriceServiceFactory._();

  static final Map<String, BaseGlobalSpotPriceService> _registry = {
    'metalpriceapi': MetalPriceApiService(),
    // To add a new API: import its service class and add one line here, e.g.:
    // 'metaldev': MetalDevService(),
  };

  static List<BaseGlobalSpotPriceService> get all =>
      _registry.values.toList();

  static BaseGlobalSpotPriceService forType(String? type) =>
      _registry[type] ?? _registry.values.first;

  static String displayNameFor(String? type) => forType(type).displayName;
}
