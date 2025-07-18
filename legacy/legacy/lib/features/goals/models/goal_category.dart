import 'package:flutter/material.dart';

enum GoalCategory {
  fitness('fitness', 'Fitness', Icons.fitness_center, Color(0xFF4CAF50)),
  health('health', 'Health', Icons.favorite, Color(0xFFE91E63)),
  productivity('productivity', 'Productivity', Icons.work, Color(0xFF2196F3)),
  learning('learning', 'Learning', Icons.school, Color(0xFFFF9800)),
  mindfulness('mindfulness', 'Mindfulness', Icons.self_improvement, Color(0xFF9C27B0)),
  social('social', 'Social', Icons.group, Color(0xFF00BCD4)),
  creativity('creativity', 'Creativity', Icons.palette, Color(0xFFFF5722)),
  habits('habits', 'Habits', Icons.check_circle, Color(0xFF607D8B)),
  nutrition('nutrition', 'Nutrition', Icons.restaurant, Color(0xFF8BC34A)),
  sleep('sleep', 'Sleep', Icons.bedtime, Color(0xFF673AB7)),
  finance('finance', 'Finance', Icons.savings, Color(0xFF795548)),
  general('general', 'General', Icons.flag, Color(0xFF9E9E9E));

  const GoalCategory(this.value, this.displayName, this.icon, this.color);

  final String value;
  final String displayName;
  final IconData icon;
  final Color color;

  static GoalCategory fromString(String value) {
    return GoalCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => GoalCategory.general,
    );
  }

  static List<GoalCategory> get popular => [
    GoalCategory.fitness,
    GoalCategory.health,
    GoalCategory.productivity,
    GoalCategory.learning,
    GoalCategory.mindfulness,
    GoalCategory.habits,
  ];

  static List<GoalCategory> get all => GoalCategory.values;

  String get description {
    switch (this) {
      case GoalCategory.fitness:
        return 'Exercise, workouts, sports activities';
      case GoalCategory.health:
        return 'Medical care, wellness, mental health';
      case GoalCategory.productivity:
        return 'Work tasks, organization, efficiency';
      case GoalCategory.learning:
        return 'Education, skills, reading, courses';
      case GoalCategory.mindfulness:
        return 'Meditation, reflection, self-care';
      case GoalCategory.social:
        return 'Relationships, community, networking';
      case GoalCategory.creativity:
        return 'Art, music, writing, crafts';
      case GoalCategory.habits:
        return 'Daily routines, behavior changes';
      case GoalCategory.nutrition:
        return 'Diet, cooking, healthy eating';
      case GoalCategory.sleep:
        return 'Sleep schedule, rest, recovery';
      case GoalCategory.finance:
        return 'Budgeting, saving, investing';
      case GoalCategory.general:
        return 'Other goals and activities';
    }
  }

  List<String> get suggestedGoals {
    switch (this) {
      case GoalCategory.fitness:
        return [
          'Go to gym',
          'Run/jog',
          'Yoga practice',
          'Walk 10,000 steps',
          'Strength training',
          'Play sports',
        ];
      case GoalCategory.health:
        return [
          'Drink 8 glasses of water',
          'Take vitamins',
          'Check blood pressure',
          'Practice good posture',
          'Stretch',
          'Get fresh air',
        ];
      case GoalCategory.productivity:
        return [
          'Complete work tasks',
          'Organize workspace',
          'Review calendar',
          'Clear email inbox',
          'Focus time blocks',
          'Plan next day',
        ];
      case GoalCategory.learning:
        return [
          'Read for 30 minutes',
          'Study new language',
          'Watch educational videos',
          'Practice coding',
          'Take online course',
          'Learn new skill',
        ];
      case GoalCategory.mindfulness:
        return [
          'Meditate',
          'Practice gratitude',
          'Journal writing',
          'Deep breathing',
          'Mindful walking',
          'Self-reflection',
        ];
      case GoalCategory.social:
        return [
          'Call family/friends',
          'Meet new people',
          'Attend social events',
          'Help others',
          'Join community activity',
          'Practice active listening',
        ];
      case GoalCategory.creativity:
        return [
          'Draw/sketch',
          'Write creatively',
          'Play music',
          'Take photos',
          'Craft projects',
          'Try new recipes',
        ];
      case GoalCategory.habits:
        return [
          'Wake up early',
          'Make bed',
          'Limit screen time',
          'Practice daily routine',
          'Avoid bad habits',
          'Build positive habits',
        ];
      case GoalCategory.nutrition:
        return [
          'Eat fruits/vegetables',
          'Cook healthy meals',
          'Track nutrition',
          'Avoid junk food',
          'Meal prep',
          'Try new healthy foods',
        ];
      case GoalCategory.sleep:
        return [
          'Sleep 8 hours',
          'Consistent bedtime',
          'No screens before bed',
          'Create bedtime routine',
          'Wake up without snooze',
          'Improve sleep environment',
        ];
      case GoalCategory.finance:
        return [
          'Track expenses',
          'Save money',
          'Review budget',
          'Invest regularly',
          'Avoid unnecessary purchases',
          'Learn about finance',
        ];
      case GoalCategory.general:
        return [
          'Complete daily tasks',
          'Achieve personal goals',
          'Make progress',
          'Stay consistent',
          'Build momentum',
          'Celebrate wins',
        ];
    }
  }

  @override
  String toString() => displayName;
}