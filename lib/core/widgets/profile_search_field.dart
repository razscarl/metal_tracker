// lib/core/widgets/profile_search_field.dart
import 'package:flutter/material.dart';
import 'package:metal_tracker/features/product_profiles/data/models/product_profile_model.dart';

class ProfileSearchField extends StatefulWidget {
  final List<ProductProfile> profiles;
  final ProductProfile?      selected;
  final ValueChanged<ProductProfile> onSelected;
  final VoidCallback? onCreateNew;
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
    _controller = TextEditingController(text: widget.selected?.profileName ?? '');
  }

  @override
  void didUpdateWidget(ProfileSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      final newText = widget.selected?.profileName ?? '';
      if (_controller.text != newText) {
        _controller.text = newText;
        _controller.selection = TextSelection.collapsed(offset: newText.length);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _displayName(ProductProfile p) {
    if (p.metalForm == 'Other' &&
        p.metalFormCustom != null &&
        p.metalFormCustom!.isNotEmpty) {
      return p.profileName.replaceFirst('Other', p.metalFormCustom!);
    }
    return p.profileName;
  }

  List<ProductProfile> _filter(String query) {
    final seen   = <String>{};
    final unique = widget.profiles.where((p) => seen.add(p.id));
    if (query.isEmpty) return unique.toList();
    final q = query.toLowerCase();
    return unique
        .where((p) =>
            _displayName(p).toLowerCase().contains(q) ||
            p.profileName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Autocomplete<ProductProfile>(
      displayStringForOption: _displayName,
      optionsBuilder:         (textValue) => _filter(textValue.text),
      onSelected:             widget.onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmit) {
        return TextFormField(
          controller:  controller,
          focusNode:   focusNode,
          decoration: InputDecoration(
            labelText:  widget.label,
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: widget.selected != null
                ? IconButton(
                    icon:      const Icon(Icons.close, size: 18),
                    onPressed: controller.clear,
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
            elevation:    4,
            color:        cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: optionList.length > 5
                    ? 280
                    : (optionList.length * 56.0) +
                        (widget.onCreateNew != null ? 48.0 : 0),
              ),
              child: ListView(
                padding:    EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  ...optionList.map((profile) => InkWell(
                        onTap: () => onSelected(profile),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _displayName(profile),
                                style: tt.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${profile.metalType} • ${profile.weightDisplay} ${profile.weightUnit} • ${profile.purity}%',
                                style: tt.labelSmall
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      )),
                  if (widget.onCreateNew != null) ...[
                    const Divider(height: 1),
                    InkWell(
                      onTap: widget.onCreateNew,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline,
                                size: 18, color: cs.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Create new product profile',
                              style: tt.bodyMedium?.copyWith(
                                color:      cs.primary,
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
