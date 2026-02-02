import 'package:flutter/material.dart';

class GroceryListSheet extends StatelessWidget {
  const GroceryListSheet({super.key, required this.groceryList});

  final Map<String, dynamic> groceryList;

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, dynamic>>.from(
      groceryList['items'] as List,
    );
    final notes = groceryList['notes'] is List
        ? List<String>.from(groceryList['notes'] as List)
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
                    ...entry.value.map((item) {
                      final name = item['name']?.toString() ?? 'Item';
                      final qty = item['quantity']?.toString() ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          qty.isEmpty ? name : '$name · $qty',
                          style: const TextStyle(color: Colors.black87),
                        ),
                      );
                    }).toList(),
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
