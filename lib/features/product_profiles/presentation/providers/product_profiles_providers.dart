// lib/features/product_profiles/presentation/providers/product_profiles_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/product_profiles/data/models/product_profile_model.dart';

part 'product_profiles_providers.g.dart';

@riverpod
class ProductProfilesNotifier extends _$ProductProfilesNotifier {
  @override
  Future<List<ProductProfile>> build() async {
    return ref.watch(productProfilesRepositoryProvider).getProductProfiles();
  }

  Future<void> addProfile({
    required String name,
    required String code,
    required String metalType,
    required String metalForm,
    required double weight,
    required String weightUnit,
    required double purity,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(productProfilesRepositoryProvider).createProductProfile(
            profileName: name,
            profileCode: code,
            metalType: metalType,
            metalForm: metalForm,
            weight: weight,
            weightDisplay: "$weight $weightUnit",
            weightUnit: weightUnit,
            purity: purity,
          );
      return ref.read(productProfilesRepositoryProvider).getProductProfiles();
    });
  }

  Future<void> updateProfile(
    String id, {
    required String profileName,
    required String profileCode,
    required String metalType,
    required String metalForm,
    String? metalFormCustom,
    required double weight,
    required String weightDisplay,
    required String weightUnit,
    required double purity,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(productProfilesRepositoryProvider).updateProductProfile(
            id,
            profileName: profileName,
            profileCode: profileCode,
            metalType: metalType,
            metalForm: metalForm,
            metalFormCustom: metalFormCustom,
            weight: weight,
            weightDisplay: weightDisplay,
            weightUnit: weightUnit,
            purity: purity,
          );
      return ref.read(productProfilesRepositoryProvider).getProductProfiles();
    });
  }

  Future<void> deleteProfile(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(productProfilesRepositoryProvider)
          .deleteProductProfile(id);
      return ref.read(productProfilesRepositoryProvider).getProductProfiles();
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Purity parser — converts user input to a percentage value (e.g. 24k → 100.0)
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<double> getPurityValue(GetPurityValueRef ref, String input) async {
  final trimmed = input.trim();

  // 1. Check purity_mappings table first
  final mapped = await ref
      .read(metadataRepositoryProvider)
      .getPurityValue(trimmed);
  if (mapped != null) return mapped;

  // 2. Fall back to inline parsing
  return _parsePurity(trimmed);
}

double _parsePurity(String input) {
  final lower = input.toLowerCase();

  // Karat (24k, 18k, 14k, 22ct, 22CT etc.)
  final karatMatch = RegExp(r'^(\d+)[kKcC][tT]?$').firstMatch(lower);
  if (karatMatch != null) {
    final k = int.parse(karatMatch.group(1)!);
    return (k / 24.0) * 100.0;
  }

  // Strip trailing % if present
  final stripped = lower.replaceAll('%', '').trim();
  final value = double.tryParse(stripped);
  if (value == null) throw FormatException('Cannot parse purity: $input');

  if (value <= 1.0) return value * 100.0;     // 0.9999 → 99.99
  if (value <= 100.0) return value;           // 99.99 already a percentage
  if (value <= 1000.0) return value / 10.0;  // 999 millesimal → 99.9
  if (value <= 9999.0) return value / 100.0; // 9999 four-digit → 99.99
  throw FormatException('Cannot parse purity: $input');
}

// ─────────────────────────────────────────────────────────────────────────────
// Create product profile — tracks loading/error state for the form
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
class CreateProductProfile extends _$CreateProductProfile {
  @override
  AsyncValue<ProductProfile?> build() => const AsyncValue.data(null);

  Future<ProductProfile?> createProfile({
    required String profileName,
    required String profileCode,
    required String metalType,
    required String metalForm,
    String? metalFormCustom,
    required double weight,
    required String weightDisplay,
    required String weightUnit,
    required double purity,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profile = await ref
          .read(productProfilesRepositoryProvider)
          .createProductProfile(
            profileName: profileName,
            profileCode: profileCode,
            metalType: metalType,
            metalForm: metalForm,
            metalFormCustom: metalFormCustom,
            weight: weight,
            weightDisplay: weightDisplay,
            weightUnit: weightUnit,
            purity: purity,
          );
      state = AsyncValue.data(profile);
      return profile;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}
