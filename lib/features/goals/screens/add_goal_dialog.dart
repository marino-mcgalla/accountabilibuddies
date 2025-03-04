import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/goals_provider.dart';
import '../models/goal_form_model.dart';
import '../widgets/goal_form_widget.dart';
import '../../common/widgets/form_dialog.dart';
import '../../time_machine/providers/time_machine_provider.dart';

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
    // Get screen size for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    // For mobile, use a more appropriate full-screen dialog
    if (isSmallScreen) {
      return Dialog.fullscreen(
        child: Scaffold(
          resizeToAvoidBottomInset:
              false, // This prevents resize when keyboard appears
          appBar: AppBar(
            title: const Text('Add Goal'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: _saveGoal,
                  child: const Text(
                    'SAVE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
            ],
          ),
          body: SafeArea(
            // Use SingleChildScrollView to allow scrolling when keyboard appears
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GoalForm(
                  model: _model,
                  onFormChanged: _onFormChanged,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Desktop version
    return FormDialog(
      title: 'Add Goal',
      isLoading: _isLoading,
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: _saveGoal,
      submitText: 'Add',
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          minWidth: 300,
        ),
        child: GoalForm(
          model: _model,
          onFormChanged: _onFormChanged,
        ),
      ),
    );
  }
}
