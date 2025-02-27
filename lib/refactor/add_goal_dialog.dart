import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'goals_provider.dart';
import 'goal_form_model.dart';
import 'goal_form_widget.dart';
import 'form_dialog.dart';
import 'time_machine_provider.dart';

class AddGoalDialog extends StatefulWidget {
  const AddGoalDialog({Key? key}) : super(key: key);

  @override
  _AddGoalDialogState createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  late GoalFormModel _model;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = GoalFormModel();
  }

  void _onFormChanged(GoalFormModel updatedModel) {
    setState(() {
      _model = updatedModel;
    });
  }

  Future<void> _saveGoal() async {
    if (_model.formKey.currentState?.validate() == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get the time machine provider to set the correct week start date
        final timeMachineProvider =
            Provider.of<TimeMachineProvider>(context, listen: false);
        _model.weekStartDate = timeMachineProvider.startOfWeek;

        // Create the goal object
        final goal = _model.toGoal();

        // Save it using the provider
        await Provider.of<GoalsProvider>(context, listen: false).addGoal(goal);

        // Close the dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding goal: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Add Goal',
      isLoading: _isLoading,
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: _saveGoal,
      submitText: 'Add',
      child: GoalForm(
        model: _model,
        onFormChanged: _onFormChanged,
      ),
    );
  }
}
