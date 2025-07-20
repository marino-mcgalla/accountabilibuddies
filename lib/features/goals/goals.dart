// Goals feature exports
export 'domain/entities/goal.dart';
export 'domain/entities/goal_template.dart' hide GoalType, GoalCategory;
export 'data/models/goal_model.dart';
export 'domain/repositories/goal_repository.dart';
export 'domain/repositories/goal_template_repository.dart';
export 'data/repositories/firebase_goal_repository.dart';
export 'data/repositories/firebase_goal_template_repository.dart';
export 'presentation/providers/goal_providers.dart';
export 'presentation/providers/goal_template_providers.dart';
export 'presentation/pages/goals_page.dart';
export 'presentation/pages/goal_templates_page.dart';
export 'presentation/pages/goal_template_detail_page.dart';
export 'presentation/pages/create_goal_template_page.dart';
export 'presentation/pages/edit_goal_template_page.dart';