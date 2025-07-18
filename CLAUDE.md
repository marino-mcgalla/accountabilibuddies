# Coding Guidelines & Standards
# AccountabiliBuddies Flutter Rebuild

## 1. Project Philosophy

### 1.1 Core Principles
- **Clarity over Cleverness**: Write code that is immediately understandable
- **Test-Driven Development**: Write tests first, then implement features
- **Separation of Concerns**: Clear boundaries between UI, business logic, and data
- **Offline-First**: Design with offline capability as a primary requirement
- **Real-time by Design**: Architecture must support instant synchronization

### 1.2 Code Quality Standards
- **Zero Tolerance for Technical Debt**: Address issues immediately, don't defer
- **Documentation as Code**: Self-documenting code with minimal but effective comments
- **Performance by Default**: Optimize for mobile performance from the start
- **Security First**: Implement security measures proactively, not reactively

## 2. Dart & Flutter Coding Standards

### 2.1 Code Style
Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) with these additions:

#### File Organization
```dart
// File header structure
// 1. Dart/Flutter imports
import 'dart:async';
import 'package:flutter/material.dart';

// 2. Package imports (alphabetical)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. Local imports (alphabetical)
import '../models/goal.dart';
import '../services/goal_service.dart';
import 'widgets/goal_card.dart';
```

#### Naming Conventions
```dart
// Classes: PascalCase
class GoalService { }
class ProofSubmissionWidget extends StatelessWidget { }

// Variables and functions: camelCase
String goalName;
void submitProof() { }

// Constants: lowerCamelCase with descriptive names
const int maxPhotoSizeBytes = 5 * 1024 * 1024; // 5MB
const Duration syncTimeoutDuration = Duration(seconds: 30);

// Private members: underscore prefix
String _userId;
void _validateInput() { }

// Enums: PascalCase for type, camelCase for values
enum ProofStatus { pending, approved, denied, disputed }
enum GoalType { daily, weekly, monthly }
```

#### Method Organization
```dart
class ExampleWidget extends StatefulWidget {
  // 1. Constructors
  const ExampleWidget({required this.goal, super.key});
  
  // 2. Public fields
  final Goal goal;
  
  // 3. Overrides
  @override
  State<ExampleWidget> createState() => _ExampleWidgetState();
}

class _ExampleWidgetState extends State<ExampleWidget> {
  // 1. Private fields
  bool _isLoading = false;
  
  // 2. Lifecycle methods
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  // 3. Build method
  @override
  Widget build(BuildContext context) {
    return Container();
  }
  
  // 4. Event handlers
  void _onSubmitPressed() { }
  
  // 5. Helper methods
  String _formatDate(DateTime date) { }
}
```

### 2.2 Error Handling

#### Exception Types
```dart
// Custom exceptions for domain-specific errors
class GoalNotFoundException implements Exception {
  const GoalNotFoundException(this.goalId);
  final String goalId;
  
  @override
  String toString() => 'Goal not found: $goalId';
}

class NetworkException implements Exception {
  const NetworkException(this.message);
  final String message;
  
  @override
  String toString() => 'Network error: $message';
}

class OfflineException implements Exception {
  const OfflineException();
  
  @override
  String toString() => 'Operation requires internet connection';
}
```

#### Error Handling Patterns
```dart
// Use Result pattern for operations that can fail
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class Failure<T> extends Result<T> {
  const Failure(this.error);
  final Exception error;
}

// Example usage
Future<Result<Goal>> createGoal(String name) async {
  try {
    final goal = await _goalService.create(name);
    return Success(goal);
  } catch (e) {
    return Failure(GoalCreationException(e.toString()));
  }
}
```

## 3. Architecture Patterns

### 3.1 Clean Architecture Structure
```
lib/
├── core/                           # Shared utilities and constants
│   ├── constants/                  # App constants
│   ├── errors/                     # Custom exceptions
│   ├── utils/                      # Utility functions
│   └── services/                   # Core services (logging, analytics)
├── features/                       # Feature-based organization
│   ├── authentication/
│   │   ├── data/                   # Data layer (repositories, data sources)
│   │   ├── domain/                 # Business logic (entities, use cases)
│   │   └── presentation/           # UI layer (widgets, providers)
│   ├── goals/
│   ├── parties/
│   ├── proofs/
│   └── challenges/
├── shared/                         # Shared widgets and utilities
│   ├── widgets/                    # Reusable UI components
│   ├── theme/                      # App theme and styling
│   └── navigation/                 # Navigation configuration
└── main.dart                       # App entry point
```

### 3.2 Feature Structure
Each feature follows clean architecture principles:

```
feature_name/
├── data/
│   ├── datasources/
│   │   ├── feature_local_datasource.dart     # Local storage (Hive, SQLite)
│   │   └── feature_remote_datasource.dart    # Remote API (Firebase, REST)
│   ├── models/                               # Data transfer objects
│   └── repositories/                         # Repository implementations
├── domain/
│   ├── entities/                             # Business entities
│   ├── repositories/                         # Repository interfaces
│   └── usecases/                            # Business logic use cases
└── presentation/
    ├── providers/                            # State management
    ├── pages/                               # Full screen widgets
    └── widgets/                             # Feature-specific widgets
```

### 3.3 State Management with Riverpod
Use Riverpod for state management with clear separation of concerns:

```dart
// Domain layer - Use cases
@riverpod
class CreateGoalUseCase extends _$CreateGoalUseCase {
  @override
  GoalRepository build() => ref.read(goalRepositoryProvider);
  
  Future<Result<Goal>> call(CreateGoalParams params) async {
    return await build().createGoal(params);
  }
}

// Presentation layer - State providers
@riverpod
class GoalListNotifier extends _$GoalListNotifier {
  @override
  AsyncValue<List<Goal>> build() {
    return const AsyncValue.loading();
  }
  
  Future<void> loadGoals() async {
    state = const AsyncValue.loading();
    
    final result = await ref.read(getGoalsUseCaseProvider).call();
    
    result.when(
      success: (goals) => state = AsyncValue.data(goals),
      failure: (error) => state = AsyncValue.error(error, StackTrace.current),
    );
  }
}

// UI layer - Consumer widgets
class GoalListPage extends ConsumerWidget {
  const GoalListPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalListNotifierProvider);
    
    return goalsAsync.when(
      data: (goals) => GoalListView(goals: goals),
      loading: () => const LoadingWidget(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

## 4. Testing Strategy

### 4.1 Testing Pyramid
- **Unit Tests (70%)**: Business logic, use cases, utilities
- **Widget Tests (20%)**: UI components and user interactions
- **Integration Tests (10%)**: Critical user flows and data persistence

### 4.2 Test Organization
```
test/
├── unit/
│   ├── core/
│   └── features/
│       ├── goals/
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   └── usecases/
│       │   └── data/
│       │       ├── models/
│       │       └── repositories/
├── widget/
│   ├── features/
│   └── shared/
│       └── widgets/
├── integration/
│   ├── flows/
│   └── data/
└── helpers/
    ├── fixtures/
    ├── mocks/
    └── test_utils.dart
```

## 5. Approved Packages

### 5.1 Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # Dependency Injection
  get_it: ^7.6.4
  injectable: ^2.3.2
  
  # Navigation
  go_router: ^12.1.3
  
  # Backend & Database
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  firebase_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Networking
  dio: ^5.3.3
  connectivity_plus: ^5.0.2
  
  # Image Handling
  image_picker: ^1.0.4
  cached_network_image: ^3.3.0
  image: ^4.1.3
  
  # Utilities
  equatable: ^2.0.5
  json_annotation: ^4.8.1
  uuid: ^4.2.1
  
  # Logging
  logger: ^2.0.2+1
  
  # Date/Time
  intl: ^0.19.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Testing
  mockito: ^5.4.4
  integration_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.7
  riverpod_generator: ^2.3.9
  injectable_generator: ^2.4.1
  json_serializable: ^6.7.1
  hive_generator: ^2.0.1
  
  # Linting
  flutter_lints: ^3.0.1
  custom_lint: ^0.5.7
  riverpod_lint: ^2.3.7
```

### 5.2 Package Usage Guidelines

#### State Management (Riverpod)
- Use `@riverpod` annotation for code generation
- Prefer `AsyncNotifier` for complex state management
- Use `Ref` for dependency injection between providers

#### Database (Firebase + Hive)
- Firebase for remote data and real-time synchronization
- Hive for local caching and offline storage
- Repository pattern to abstract data sources

#### Navigation (GoRouter)
- Declarative routing configuration
- Type-safe route parameters
- Deep linking support for invitations

#### Image Handling
- `image_picker` for camera/gallery access
- `cached_network_image` for displaying remote images
- `image` package for compression and processing

### 5.3 Prohibited Packages
- **Provider** (replaced by Riverpod)
- **Bloc** (replaced by Riverpod)
- **SharedPreferences** (replaced by Hive)
- **http** (replaced by Dio for better features)
- **Any state management other than Riverpod**

## 6. Performance Guidelines

### 6.1 Widget Performance
```dart
// Use const constructors whenever possible
const Icon(Icons.camera);

// Prefer StatelessWidget over StatefulWidget when state isn't needed
class GoalTitle extends StatelessWidget {
  const GoalTitle({required this.title, super.key});
  final String title;
  
  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineMedium);
  }
}

// Use Consumer widgets to limit rebuild scope
Widget build(BuildContext context) {
  return Column(
    children: [
      const StaticHeader(),
      Consumer(
        builder: (context, ref, child) {
          final goals = ref.watch(goalsProvider);
          return GoalsList(goals: goals);
        },
      ),
    ],
  );
}
```

### 6.2 Memory Management
```dart
// Dispose of resources properly
class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  StreamSubscription? _subscription;
  
  @override
  void dispose() {
    _controller?.dispose();
    _subscription?.cancel();
    super.dispose();
  }
}
```

### 6.3 Network Optimization
```dart
// Implement proper caching strategies
@riverpod
Future<List<Goal>> goals(GoalsRef ref) async {
  // Check cache first
  final cached = await ref.read(localGoalCacheProvider).getGoals();
  if (cached.isNotEmpty) {
    return cached;
  }
  
  // Fetch from network
  final remote = await ref.read(goalServiceProvider).fetchGoals();
  
  // Update cache
  await ref.read(localGoalCacheProvider).storeGoals(remote);
  
  return remote;
}
```

## 7. Security Guidelines

### 7.1 Authentication
```dart
// Always validate authentication state
@riverpod
Stream<User?> authState(AuthStateRef ref) {
  return ref.read(authServiceProvider).authStateChanges();
}
```

### 7.2 Data Validation
```dart
// Validate all user inputs
class GoalValidator {
  static String? validateGoalName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Goal name is required';
    }
    
    if (name.length > 100) {
      return 'Goal name must be 100 characters or less';
    }
    
    return null;
  }
}
```

### 7.3 File Upload Security
```dart
// Validate file types and sizes
class ImageUploadValidator {
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png'];
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  
  static Result<void> validateImage(File imageFile) {
    // Check file size and extension
    if (imageFile.lengthSync() > maxFileSizeBytes) {
      return Failure(FileTooLargeException());
    }
    
    final extension = path.extension(imageFile.path).toLowerCase();
    if (!allowedExtensions.contains(extension.substring(1))) {
      return Failure(InvalidFileTypeException());
    }
    
    return Success(null);
  }
}
```

---

*These coding guidelines ensure the AccountabiliBuddies rebuild maintains high code quality, performance, and security standards while being maintainable and testable.*