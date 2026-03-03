// lib/features/product_profiles/presentation/providers/product_profiles_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../data/models/product_profile_model.dart';

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
