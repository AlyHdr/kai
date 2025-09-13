import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kai/models/onboarding_data.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  DateTime? dateOfBirth;
  double weightKg = 70;
  double heightCm = 175;
  String gender = "male";
  String activityLevel = "Moderate";
  String goal = "Maintain";
  String diet = "No Preference";

  // --- Manual macros (advanced)
  int macrosCalories = 0;
  int macrosCarbs = 0;
  int macrosProteins = 0;
  int macrosFats = 0;

  // Keep a copy to detect changes (for snackbar message)
  int _origCalories = 0;
  int _origCarbs = 0;
  int _origProteins = 0;
  int _origFats = 0;

  bool _loading = true;

  final TextStyle valueStyle = const TextStyle(fontSize: 16);

  bool get _macrosChanged =>
      macrosCalories != _origCalories ||
      macrosCarbs != _origCarbs ||
      macrosProteins != _origProteins ||
      macrosFats != _origFats;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  double _toDouble(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  Future<void> _loadUser() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .get();

    if (doc.exists) {
      final data = doc.data() ?? {};

      // dateOfBirth might be Timestamp or String
      final dobRaw = data["dateOfBirth"];
      DateTime? dob;
      if (dobRaw is Timestamp) {
        dob = dobRaw.toDate();
      } else if (dobRaw is String) {
        dob = DateTime.tryParse(dobRaw);
      }

      // macros subobject
      final Map<String, dynamic> macros =
          (data["macros"] as Map<String, dynamic>?) ?? {};
      final cals = _toInt(macros["calories"]);
      final carbs = _toInt(macros["carbs"]);
      final prots = _toInt(macros["proteins"]);
      final fats = _toInt(macros["fats"]);

      setState(() {
        dateOfBirth = dob;
        weightKg = _toDouble(data["weightKg"], fallback: 70);
        heightCm = _toDouble(data["heightCm"], fallback: 175);
        gender = (data["gender"] ?? "male") as String;
        activityLevel = (data["activityLevel"] ?? "Moderate") as String;
        goal = (data["goal"] ?? "Maintain") as String;
        diet =
            (data["dietPreference"] ?? data["diet"] ?? "No Preference")
                as String;

        macrosCalories = cals;
        macrosCarbs = carbs;
        macrosProteins = prots;
        macrosFats = fats;

        _origCalories = cals;
        _origCarbs = carbs;
        _origProteins = prots;
        _origFats = fats;

        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  // Persist the whole user doc based on current state.
  Future<void> _saveUser() async {
    // Basic validation: no negative macros
    if (macrosCalories < 0 ||
        macrosCarbs < 0 ||
        macrosProteins < 0 ||
        macrosFats < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Macros can’t be negative.")),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser!.uid;

    final updatedUser = {
      "dateOfBirth": dateOfBirth?.toIso8601String(),
      "weightKg": weightKg,
      "heightCm": heightCm,
      "gender": gender,
      "activityLevel": activityLevel,
      "goal": goal,
      "dietPreference": diet,
      "lastUpdated": DateTime.now().toIso8601String(),
      "macros": {
        "calories": macrosCalories,
        "carbs": macrosCarbs,
        "proteins": macrosProteins,
        "fats": macrosFats,
      },
    };

    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .update(updatedUser);

    // Refresh originals after save
    setState(() {
      _origCalories = macrosCalories;
      _origCarbs = macrosCarbs;
      _origProteins = macrosProteins;
      _origFats = macrosFats;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _macrosChanged
                ? "Saved. Meal plans will reflect manual macro targets ✅"
                : "Saved ✅",
          ),
        ),
      );
    }
  }

  // Generic editors that can "save immediately" after user taps Save
  void _editDouble(
    String label,
    double current,
    Function(double) onApply, {
    bool saveImmediately = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: current.toString());
        return AlertDialog(
          title: Text("Edit $label"),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final value = double.tryParse(controller.text) ?? current;
                onApply(value);
                Navigator.pop(ctx);
                if (saveImmediately) await _saveUser();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _editInt(
    String label,
    int current,
    Function(int) onApply, {
    int? min,
    int? max,
    bool saveImmediately = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: current.toString());
        String? error;
        return StatefulBuilder(
          builder: (ctx, setSB) {
            return AlertDialog(
              title: Text("Edit $label"),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  final v = int.tryParse(controller.text);
                  if (v == null) {
                    setSB(() => error = "Enter a whole number");
                  } else if (min != null && v < min) {
                    setSB(() => error = "Must be ≥ $min");
                  } else if (max != null && v > max) {
                    setSB(() => error = "Must be ≤ $max");
                  } else {
                    setSB(() => error = null);
                  }
                },
                decoration: InputDecoration(errorText: error),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final v = int.tryParse(controller.text);
                    if (v == null) return;
                    if (min != null && v < min) return;
                    if (max != null && v > max) return;
                    onApply(v);
                    Navigator.pop(ctx);
                    if (saveImmediately) await _saveUser();
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Choice picker; save immediately after selection when requested
  void _editChoice(
    String label,
    String current,
    Map<String, String> options,
    Function(String) onApply, {
    bool saveImmediately = false,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return ListView(
          children: options.entries
              .map(
                (entry) => ListTile(
                  title: Text(entry.key),
                  subtitle: Text(entry.value),
                  trailing: entry.key == current
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () async {
                    onApply(entry.key);
                    Navigator.pop(ctx);
                    if (saveImmediately) await _saveUser();
                  },
                ),
              )
              .toList(),
        );
      },
    );
  }

  // Show macros-only warning BEFORE editing a macros value
  Future<void> _warnThenEditMacro({
    required String fieldLabel,
    required int current,
    required void Function(int) onApply,
    int? min,
    int? max,
  }) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Manual Macros Warning"),
        content: const Text(
          "Manual updates to calories/macros are for advanced users. "
          "They override automatic calculations and WILL affect future meal plan generation.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Proceed"),
          ),
        ],
      ),
    );
    if (proceed != true) return;

    // Open the actual number editor; saving will persist immediately.
    _editInt(
      fieldLabel,
      current,
      onApply,
      min: min,
      max: max,
      saveImmediately: true,
    );
  }

  void _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => dateOfBirth = picked);
      await _saveUser(); // save immediately
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Profile",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text("Date of Birth"),
            trailing: Text(
              dateOfBirth != null
                  ? "${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}"
                  : "Not set",
              style: valueStyle,
            ),
            onTap: _pickDateOfBirth,
          ),
          ListTile(
            title: const Text("Weight"),
            trailing: Text("$weightKg kg", style: valueStyle),
            onTap: () => _editDouble(
              "Weight (kg)",
              weightKg,
              (val) => setState(() => weightKg = val),
              saveImmediately: true,
            ),
          ),
          ListTile(
            title: const Text("Height"),
            trailing: Text("$heightCm cm", style: valueStyle),
            onTap: () => _editDouble(
              "Height (cm)",
              heightCm,
              (val) => setState(() => heightCm = val),
              saveImmediately: true,
            ),
          ),
          ListTile(
            title: const Text("Gender"),
            trailing: Text(gender, style: valueStyle),
            onTap: () => _editChoice(
              "Gender",
              gender,
              {"male": "", "female": ""},
              (val) => setState(() => gender = val),
              saveImmediately: true,
            ),
          ),
          ListTile(
            title: const Text("Activity Level"),
            trailing: Text(activityLevel, style: valueStyle),
            onTap: () => _editChoice(
              "Activity Level",
              activityLevel,
              activityLevels,
              (val) => setState(() => activityLevel = val),
              saveImmediately: true,
            ),
          ),
          ListTile(
            title: const Text("Diet"),
            trailing: Text(diet, style: valueStyle),
            onTap: () => _editChoice(
              "Diet",
              diet,
              diets,
              (val) => setState(() => diet = val),
              saveImmediately: true,
            ),
          ),
          ListTile(
            title: const Text("Goal"),
            trailing: Text(goal, style: valueStyle),
            onTap: () => _editChoice(
              "Goal",
              goal,
              goals,
              (val) => setState(() => goal = val),
              saveImmediately: true,
            ),
          ),

          // --- Manual Macros (Advanced) section
          const SizedBox(height: 12),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              "Manual Macros (Advanced)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text("Calories"),
            subtitle: const Text("kcal/day"),
            trailing: Text(macrosCalories.toString(), style: valueStyle),
            onTap: () => _warnThenEditMacro(
              fieldLabel: "Calories (kcal/day)",
              current: macrosCalories,
              onApply: (v) => setState(() => macrosCalories = v),
              min: 0,
              max: 10000,
            ),
          ),
          ListTile(
            title: const Text("Carbs"),
            subtitle: const Text("grams/day"),
            trailing: Text(macrosCarbs.toString(), style: valueStyle),
            onTap: () => _warnThenEditMacro(
              fieldLabel: "Carbs (g/day)",
              current: macrosCarbs,
              onApply: (v) => setState(() => macrosCarbs = v),
              min: 0,
              max: 1000,
            ),
          ),
          ListTile(
            title: const Text("Proteins"),
            subtitle: const Text("grams/day"),
            trailing: Text(macrosProteins.toString(), style: valueStyle),
            onTap: () => _warnThenEditMacro(
              fieldLabel: "Proteins (g/day)",
              current: macrosProteins,
              onApply: (v) => setState(() => macrosProteins = v),
              min: 0,
              max: 600,
            ),
          ),
          ListTile(
            title: const Text("Fats"),
            subtitle: const Text("grams/day"),
            trailing: Text(macrosFats.toString(), style: valueStyle),
            onTap: () => _warnThenEditMacro(
              fieldLabel: "Fats (g/day)",
              current: macrosFats,
              onApply: (v) => setState(() => macrosFats = v),
              min: 0,
              max: 300,
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
