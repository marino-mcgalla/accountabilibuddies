import 'package:flutter/material.dart';
import 'goal_form_model.dart';

class GoalForm extends StatefulWidget {
  final GoalFormModel model;
  final Function(GoalFormModel) onFormChanged;

  const GoalForm({
    required this.model,
    required this.onFormChanged,
    Key? key,
  }) : super(key: key);

  @override
  GoalFormState createState() => GoalFormState();
}

class GoalFormState extends State<GoalForm> {
  late GoalFormModel _model;

  @override
  void initState() {
    super.initState();
    _model = widget.model;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _model.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Goal type toggle
          ToggleButtons(
            isSelected: _model.selectedGoalType,
            onPressed: (index) {
              setState(() {
                _model.updateGoalType(index);
                widget.onFormChanged(_model);
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Total'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Weekly'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Goal name
          TextFormField(
            initialValue: _model.goalName,
            decoration: const InputDecoration(labelText: 'Goal Name'),
            validator: _model.validateName,
            onChanged: (value) {
              setState(() {
                _model.goalName = value;
                widget.onFormChanged(_model);
              });
            },
          ),
          const SizedBox(height: 16),

          // Goal frequency
          if (_model.goalType == 'total')
            TextFormField(
              initialValue: _model.goalFrequency.toString(),
              decoration:
                  const InputDecoration(labelText: 'Goal Target (Total)'),
              keyboardType: TextInputType.number,
              validator: _model.validateFrequency,
              onChanged: (value) {
                if (value.isNotEmpty && int.tryParse(value) != null) {
                  setState(() {
                    _model.goalFrequency = int.parse(value);
                    widget.onFormChanged(_model);
                  });
                }
              },
            )
          else
            Column(
              children: [
                Text('Goal Frequency: ${_model.goalFrequency} days/week'),
                Slider(
                  value: _model.goalFrequency.toDouble(),
                  min: 1,
                  max: 7,
                  divisions: 6,
                  label: _model.goalFrequency.toString(),
                  onChanged: (value) {
                    setState(() {
                      _model.goalFrequency = value.toInt();
                      widget.onFormChanged(_model);
                    });
                  },
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Goal criteria
          TextFormField(
            initialValue: _model.goalCriteria,
            decoration: const InputDecoration(labelText: 'Goal Criteria'),
            onChanged: (value) {
              setState(() {
                _model.goalCriteria = value;
                widget.onFormChanged(_model);
              });
            },
          ),
        ],
      ),
    );
  }
}
