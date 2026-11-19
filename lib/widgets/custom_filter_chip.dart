import 'package:flutter/material.dart';

/// Reusable horizontal scrollable filter bar displaying FilterChip for each author/publisher.
class CustomFilterChip extends StatelessWidget {
  final List<String> tags;
  final String? selectedTags;
  final ValueChanged<String?> onSelected;

  const CustomFilterChip({
    super.key,
    required this.tags,
    required this.selectedTags,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: tags.map((tags) {
          final isSelected = selectedTags == tags;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              key: Key('filter_chip_$tags'),
              label: Text(tags),
              selected: isSelected,
              showCheckmark: true,
              checkmarkColor: isSelected
                  ? theme.colorScheme.onPrimary
                  : null,
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : null,
              ),
              onSelected: (selected) {
                if (selected) {
                  onSelected(tags);
                } else {
                  onSelected(null);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}