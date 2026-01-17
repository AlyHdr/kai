import 'package:flutter/material.dart';
import 'package:kai/models/recipe.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.onAdd,
  });

  final Recipe recipe;
  final Future<void> Function(BuildContext context) onAdd;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              _HeroImage(recipe: recipe),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _InfoPill(
                          label: recipe.mealType,
                          background: Colors.greenAccent,
                        ),
                        const SizedBox(width: 8),
                        _InfoPill(
                          label: '${recipe.timeMinutes} min',
                          background: const Color(0xFFE2E8F0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${recipe.calories} kcal · ${recipe.protein}g protein',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recipe.tags
                          .map((tag) => _InfoPill(
                                label: tag,
                                background: const Color(0xFFF1F5F9),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'About this recipe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A balanced, macro-friendly dish designed to match your'
                      ' weekly plan. Ingredients and steps will appear here once'
                      ' we connect the shared recipe library.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            top: 16,
            child: SafeArea(
              child: _CircleButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => onAdd(context),
            child: const Text(
              'Add to week',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            recipe.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(color: recipe.palette.first);
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(color: recipe.palette.first);
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.35),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.background});

  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.black87),
        ),
      ),
    );
  }
}
