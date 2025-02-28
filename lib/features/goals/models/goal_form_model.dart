import 'package:flutter/material.dart';
import 'goal_model.dart';
import 'total_goal.dart';
import 'weekly_goal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class to handle goal form data and validation
class GoalFormModel {
  String id;
  String ownerId;
  String goalName;
  String goalType;
  String goalCriteria;
  int goalFrequency;
  bool active;
  DateTime weekStartDate;
  Map<String, dynamic> currentWeekCompletions;

  final formKey = GlobalKey<FormState>();
  final List<bool> selectedGoalType = [true, false]; // Default to 'total'

  GoalFormModel({
    this.id = '',
    this.ownerId = '',
    this.goalName = '',
    this.goalType = 'total',
    this.goalCriteria = '',
    this.goalFrequency = 1,
    this.active = false,
    DateTime? weekStartDate,
    Map<String, dynamic>? currentWeekCompletions,
  })  : weekStartDate = weekStartDate ?? DateTime.now(),
        currentWeekCompletions = currentWeekCompletions ?? {};

  /// Create a form model from an existing goal
  factory GoalFormModel.fromGoal(Goal goal) {
    return GoalFormModel(
      id: goal.id,
      ownerId: goal.ownerId,
      goalName: goal.goalName,
      goalType: goal.goalType,
      goalCriteria: goal.goalCriteria,
      goalFrequency: goal.goalFrequency,
      active: goal.active,
      weekStartDate: goal.weekStartDate,
      currentWeekCompletions: goal.currentWeekCompletions,
    );
  }

  /// Update the goal type and reset frequency if needed
  void updateGoalType(int index) {
    goalType = index == 0 ? 'total' : 'weekly';

    // Set default frequency based on goal type
    if (goalType == 'total') {
      goalFrequency = 1; // Default for total goals
    } else if (goalType == 'weekly') {
      goalFrequency = 4; // Default for weekly goals (4 days per week)
    }

    // Update selected type
    for (int i = 0; i < selectedGoalType.length; i++) {
      selectedGoalType[i] = i == index;
    }
  }

  /// Validates the form data
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a goal name';
    }
    return null;
  }

  /// Validates frequency for total goals
  String? validateFrequency(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a goal frequency';
    }
    if (int.tryParse(value) == null || int.parse(value) <= 0) {
      return 'Please enter a valid number';
    }
    return null;
  }

  /// Create a goal object from the form data
  Goal toGoal() {
    // Generate a new ID if needed
    final String goalId = id.isEmpty
        ? FirebaseFirestore.instance.collection('goals').doc().id
        : id;

    // Get current user ID if needed
    final String userId = ownerId.isEmpty
        ? FirebaseAuth.instance.currentUser?.uid ?? ''
        : ownerId;

    if (goalType == 'total') {
      return TotalGoal(
        id: goalId,
        ownerId: userId,
        goalName: goalName,
        goalCriteria: goalCriteria,
        active: active,
        goalFrequency: goalFrequency,
        weekStartDate: weekStartDate,
        currentWeekCompletions: currentWeekCompletions.cast<String, int>(),
      );
    } else {
      return WeeklyGoal(
        id: goalId,
        ownerId: userId,
        goalName: goalName,
        goalCriteria: goalCriteria,
        active: active,
        goalFrequency: goalFrequency,
        weekStartDate: weekStartDate,
        currentWeekCompletions: currentWeekCompletions.cast<String, String>(),
      );
    }
  }
}
