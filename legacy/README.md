# Legacy AccountabiliBuddies Codebase

This directory contains the original AccountabiliBuddies Flutter app code that was moved here during the complete rebuild process.

## What's in this folder:

- **Complete Flutter project** - All original source code, including:
  - `lib/` - Original Dart source code with feature-based organization
  - `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` - Platform-specific code
  - `pubspec.yaml` - Original dependencies and configuration
  - Firebase configuration files

- **Test files** - Original test files (`test_goal_instances.dart`, `test_goal_types.dart`)

## Why it was moved:

The original codebase had accumulated technical debt and architectural issues that made it difficult to maintain and extend. Key problems included:
- Inconsistent state management patterns
- Lack of comprehensive testing
- Frequent breakage during feature development
- Unclear data models and business logic separation

## Rebuild approach:

Rather than attempting to refactor the existing code (which had proven problematic), we decided to:
1. **Preserve the original** - Move everything to `legacy/` to keep as reference
2. **Start fresh** - Create a new Flutter project with clean architecture
3. **Test-driven development** - Build comprehensive tests from the ground up
4. **Follow the updated planning documents** - Use the corrected understanding of weekly cycles and flexible goal parameters

## Reference value:

This legacy code contains valuable information about:
- Working Firebase integration patterns
- UI/UX implementations that were successful
- Business logic that can be referenced during the rebuild
- Integration patterns with third-party packages

The rebuild will reference this code where helpful while implementing the improved architecture defined in the planning documents.

---

*Legacy code preserved on: July 18, 2025*
*Rebuild started with clean architecture and comprehensive testing*