// lib/core/widgets/profile_search_field.dart
import 'package:flutter/material.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/features/product_profiles/data/models/product_profile_model.dart';

/// A searchable autocomplete field for selecting a [ProductProfile].
///
/// Shows matching profiles filtered by [query]. Displays profile name,
/// metal type, weight and purity as subtitle. Optionally shows a
/// "Create new profile" action when [onCreateNew] is provided.
class ProfileSearchField extends StatefulWidget {
  /// All profiles to search within (pre-filtered by metal type if desired).
  final List<ProductProfile> profiles;

  /// Currently selected profile — pre-fills the text field.
  final ProductProfile? selected;

  /// Called when a profile is selected from the list.
  final ValueChanged<ProductProfile> onSelected;

  /// Called when the user taps "Create new profile". If null, the option
  /// is not shown.
  final VoidCallback? onCreateNew;

  /// Label shown on the text field.
  final String label;

  const ProfileSearchField({
    super.key,
    required this.profiles,
    required this.onSelected,
    this.selected,
    this.onCreateNew,
    this.label = 'Product Profile',
  });

  @override
  State<ProfileSearchField> createState() => _ProfileSearchFieldState();
}

class _ProfileSearchFieldState extends State<ProfileSearchField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.selected?.profileName ?? '');
  }

  @override
  void didUpdateWidget(ProfileSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      final newText = widget.selected?.profileName ?? '';
      if (_controller.text != newText) {
        _controller.text = newText;
        _controller.selection =
            TextSelection.collapsed(offset: newText.length);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<ProductProfile> _filter(String query) {
    if (query.isEmpty) return widget.profiles;
    final q = query.toLowerCase();
    return widget.profiles
        .where((p) => p.profileName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<ProductProfile>(
      displayStringForOption: (p) => p.profileName,
      optionsBuilder: (textValue) {
        final matches = _filter(textValue.text);
        return matches;
      },
      onSelected: (profile) {
        widget.onSelected(profile);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmit) {
        // Sync external controller text changes
        if (controller.text != _controller.text &&
            widget.selected?.profileName == null) {
          // keep in sync
        }
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: widget.selected != null
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      controller.clear();
                    },
                  )
                : null,
            hintText: 'Type to search…',
          ),
          onFieldSubmitted: (_) => onFieldSubmit(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final optionList = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: optionList.length > 5
                    ? 280
                    : (optionList.length * 56.0) +
                        (widget.onCreateNew != null ? 48.0 : 0),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  ...optionList.asMap().entries.map((entry) {
                    final profile = entry.value;
                    return InkWell(
                      onTap: () => onSelected(profile),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.profileName,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${profile.metalType} • ${profile.weightDisplay} ${profile.weightUnit} • ${profile.purity}%',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (widget.onCreateNew != null) ...[
                    const Divider(height: 1, color: Colors.white10),
                    InkWell(
                      onTap: widget.onCreateNew,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline,
                                size: 18, color: AppColors.primaryGold),
                            SizedBox(width: 8),
                            Text(
                              'Create new product profile',
                              style: TextStyle(
                                color: AppColors.primaryGold,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
