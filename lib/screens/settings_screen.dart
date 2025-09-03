import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kai/models/onboarding_data.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DateTime? dateOfBirth;
  double weightKg = 70;
  double heightCm = 175;
  String gender = "male";
  String activityLevel = "Moderate";
  String goal = "Maintain";
  String diet = "No Preference";

  bool _loading = true;

  final TextStyle valueStyle = const TextStyle(fontSize: 16);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .get();

    if (doc.exists) {
      final data = doc.data() ?? {};
      setState(() {
        dateOfBirth = DateTime.tryParse(data["dateOfBirth"]);
        weightKg = (data["weightKg"] ?? 70).toDouble();
        heightCm = (data["heightCm"] ?? 175).toDouble();
        gender = data["gender"] ?? "male";
        activityLevel = data["activityLevel"] ?? "Moderate";
        goal = data["goal"] ?? "Maintain";
        diet = data["dietPreference"] ?? "No Preference";
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveUser() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final updatedUser = {
      "dateOfBirth": dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      "weightKg": weightKg,
      "heightCm": heightCm,
      "gender": gender,
      "activityLevel": activityLevel,
      "goal": goal,
      "diet": diet,
      "lastUpdated": DateTime.now().toIso8601String(),
    };

    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .update(updatedUser);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile updated ✅")));
    }
  }

  void _editDouble(String label, double current, Function(double) onSave) {
    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: current.toString());
        return AlertDialog(
          title: Text("Edit $label"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                onSave(double.tryParse(controller.text) ?? current);
                Navigator.pop(ctx);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _editChoice(
    String label,
    String current,
    Map<String, String> options,
    Function(String) onSave,
  ) {
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
                  onTap: () {
                    onSave(entry.key);
                    Navigator.pop(ctx);
                  },
                ),
              )
              .toList(),
        );
      },
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
            ),
          ),
          ListTile(
            title: const Text("Height"),
            trailing: Text("$heightCm cm", style: valueStyle),
            onTap: () => _editDouble(
              "Height (cm)",
              heightCm,
              (val) => setState(() => heightCm = val),
            ),
          ),
          ListTile(
            title: const Text("Gender"),
            trailing: Text(gender, style: valueStyle),
            onTap: () => _editChoice("Gender", gender, {
              "male": "",
              "female": "",
            }, (val) => setState(() => gender = val)),
          ),
          ListTile(
            title: const Text("Activity Level"),
            trailing: Text(activityLevel, style: valueStyle),
            onTap: () => _editChoice(
              "Activity Level",
              activityLevel,
              activityLevels,
              (val) => setState(() => activityLevel = val),
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
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              onPressed: _saveUser,
              label: const Text("Save & Recalculate"),
            ),
          ),
        ],
      ),
    );
  }
}
