import 'package:flutter/material.dart';

class GroceryListSheet extends StatefulWidget {
  const GroceryListSheet({super.key, required this.groceryList});

  final Map<String, dynamic> groceryList;

  @override
  State<GroceryListSheet> createState() => _GroceryListSheetState();
}

class _GroceryListSheetState extends State<GroceryListSheet> {
  final Set<String> _checkedItems = {};

  String _itemKey({
    required String category,
    required String name,
    required String qty,
    required int index,
  }) {
    return '$category::$name::$qty::$index';
  }

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, dynamic>>.from(
      widget.groceryList['items'] as List,
    );
    final notes = widget.groceryList['notes'] is List
        ? List<String>.from(widget.groceryList['notes'] as List)
        : const <String>[];

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final category = (item['category']?.toString() ?? 'Other').trim();
      grouped.putIfAbsent(category, () => <Map<String, dynamic>>[]).add(item);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Grocery list',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final entry in grouped.entries) ...[
                    Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    for (var i = 0; i < entry.value.length; i++) ...[
                      Builder(
                        builder: (context) {
                          final item = entry.value[i];
                          final name = item['name']?.toString() ?? 'Item';
                          final qty = item['quantity']?.toString() ?? '';
                          final id = _itemKey(
                            category: entry.key,
                            name: name,
                            qty: qty,
                            index: i,
                          );
                          final isChecked = _checkedItems.contains(id);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                setState(() {
                                  if (isChecked) {
                                    _checkedItems.remove(id);
                                  } else {
                                    _checkedItems.add(id);
                                  }
                                });
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: isChecked,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _checkedItems.add(id);
                                        } else {
                                          _checkedItems.remove(id);
                                        }
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            color: Colors.black87,
                                            decoration: isChecked
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                          ),
                                        ),
                                        if (qty.isNotEmpty)
                                          Text(
                                            qty,
                                            style: TextStyle(
                                              color: Colors.black45,
                                              fontSize: 12,
                                              decoration: isChecked
                                                  ? TextDecoration.lineThrough
                                                  : TextDecoration.none,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Notes',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    ...notes.map(
                      (note) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(note),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
