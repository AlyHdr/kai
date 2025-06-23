// lib/screens/onboarding/steps/height_weight_step.dart
import 'package:flutter/cupertino.dart';
import '../../../widgets/step_button.dart';

class HeightWeightStep extends StatefulWidget {
  final int initialHeight;
  final int initialWeight;
  final Function(int height, int weight) onNext;

  const HeightWeightStep({
    super.key,
    required this.initialHeight,
    required this.initialWeight,
    required this.onNext,
  });

  @override
  State<HeightWeightStep> createState() => _HeightWeightStepState();
}

class _HeightWeightStepState extends State<HeightWeightStep> {
  late int selectedHeight;
  late int selectedWeight;

  final List<int> heights = List.generate(120, (index) => 100 + index);
  final List<int> weights = List.generate(120, (index) => 30 + index);

  @override
  void initState() {
    super.initState();
    selectedHeight = widget.initialHeight;
    selectedWeight = widget.initialWeight;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 60),
          Text(
            'Height & weight',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('This will be used to calibrate your custom plan.'),
          SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text("Height", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 150,
                    width: 100,
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: heights.indexOf(selectedHeight),
                      ),
                      itemExtent: 32,
                      onSelectedItemChanged: (index) {
                        setState(() => selectedHeight = heights[index]);
                      },
                      children: heights
                          .map((h) => Center(child: Text('$h cm')))
                          .toList(),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 32),
              Column(
                children: [
                  Text("Weight", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 150,
                    width: 100,
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: weights.indexOf(selectedWeight),
                      ),
                      itemExtent: 32,
                      onSelectedItemChanged: (index) {
                        setState(() => selectedWeight = weights[index]);
                      },
                      children: weights
                          .map((w) => Center(child: Text('$w kg')))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Spacer(),
          StepButton(
            onPressed: () => widget.onNext(selectedHeight, selectedWeight),
          ),
        ],
      ),
    );
  }
}
