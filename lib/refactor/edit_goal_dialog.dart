import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'goals_provider.dart';
import 'goal_model.dart';
import 'goal_form_model.dart';
import 'goal_form_widget.dart';
import 'form_dialog.dart';

class EditGoalDialog extends StatefulWidget {
  final Goal goal;

  const EditGoalDialog({
    required this.goal,
    Key? key,
  }) : super(key: key);

  @override
  _EditGoalDialogState createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<EditGoalDialog> {
  late GoalFormModel _model;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = GoalFormModel.fromGoal(widget.goal);
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
        // Create the updated goal object
        final updatedGoal = _model.toGoal();

        // Save it using the provider
        await Provider.of<GoalsProvider>(context, listen: false)
            .editGoal(updatedGoal);

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
              content: Text('Error updating goal: $e'),
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
      title: 'Edit Goal',
      isLoading: _isLoading,
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: _saveGoal,
      submitText: 'Save',
      child: GoalForm(
        model: _model,
        onFormChanged: _onFormChanged,
      ),
    );
  }
}
