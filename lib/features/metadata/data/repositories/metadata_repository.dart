// lib/features/metadata/data/repositories/metadata_repository.dart: Centralized Metadata Repository
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MetadataRepository {
  final SupabaseClient _supabase;

  MetadataRepository(this._supabase);

  // ==========================================
  // PURITY MAPPINGS
  // ==========================================

  /// Fetches the standardized purity (e.g., 99.99) from an input string (e.g., "999").
  Future<double?> getPurityValue(String inputValue) async {
    try {
      final response = await _supabase
          .from('purity_mappings')
          .select('stored_value')
          .eq('input_value', inputValue)
          .maybeSingle();

      if (response != null) {
        return (response['stored_value'] as num).toDouble();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching purity mapping: $e');
      return null;
    }
  }

  // ==========================================
  // DYNAMIC CONFIGURATION (FUTURE TABLES)
  // ==========================================

  Future<List<Map<String, dynamic>>> getActiveConfig(String tableName) async {
    try {
      return await _supabase
          .from(tableName)
          .select()
          .eq('is_active', true)
          .order('name');
    } catch (e) {
      debugPrint('Error fetching $tableName: $e');
      return [];
    }
  }
}
