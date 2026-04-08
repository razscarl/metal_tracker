// lib/features/metadata/presentation/providers/metadata_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/features/metadata/data/models/metadata_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'metadata_providers.g.dart';

@Riverpod(keepAlive: true)
Future<List<MetalTypeRecord>> metalTypes(Ref ref) async {
  final response = await Supabase.instance.client
      .from('metal_types')
      .select()
      .eq('is_active', true)
      .order('name');
  return response.map(MetalTypeRecord.fromJson).toList();
}

@Riverpod(keepAlive: true)
Future<List<MetalFormRecord>> metalForms(Ref ref) async {
  final response = await Supabase.instance.client
      .from('metal_forms')
      .select()
      .eq('is_active', true)
      .order('name');
  return response.map(MetalFormRecord.fromJson).toList();
}
