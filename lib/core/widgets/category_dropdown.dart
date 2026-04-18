import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/categories_provider.dart';

class CategoryDropdown extends ConsumerWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const CategoryDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final effectiveValue = categories.contains(value) ? value : categories.first;

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: effectiveValue,
            decoration: const InputDecoration(
              prefixIcon: Icon(Symbols.category),
            ),
            items: categories
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c[0].toUpperCase() + c.substring(1)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          icon: const Icon(Symbols.add),
          tooltip: 'Add category',
          onPressed: () => _showAddCategoryDialog(context, ref),
        ),
      ],
    );
  }

  Future<void> _showAddCategoryDialog(
      BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(categoriesProvider.notifier).addCategory(name);
      onChanged(name.trim().toLowerCase());
    }
  }
}
