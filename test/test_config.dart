/// Test configuration for AccountabiliBuddies
/// 
/// This file contains test-specific configuration and constants
/// used across all test files.
class TestConfig {
  /// Test timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(minutes: 2);
  static const Duration shortTimeout = Duration(seconds: 5);

  /// Test delays
  static const Duration defaultDelay = Duration(milliseconds: 100);
  static const Duration longDelay = Duration(milliseconds: 500);
  static const Duration shortDelay = Duration(milliseconds: 10);

  /// Test data
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'testPassword123';
  static const String testUsername = 'testuser';
  static const String testPartyName = 'Test Party';
  static const String testGoalName = 'Test Goal';

  /// Test keys
  static const String testKeyPrefix = 'test_';
  
  /// Mock data
  static const Map<String, dynamic> mockUserData = {
    'id': 'test_user_id',
    'email': testEmail,
    'username': testUsername,
    'displayName': 'Test User',
    'createdAt': '2024-01-01T00:00:00Z',
  };

  static const Map<String, dynamic> mockGoalData = {
    'id': 'test_goal_id',
    'name': testGoalName,
    'description': 'Test goal description',
    'type': 'weekly',
    'frequency': 3,
    'active': true,
  };

  static const Map<String, dynamic> mockPartyData = {
    'id': 'test_party_id',
    'name': testPartyName,
    'leaderId': 'test_user_id',
    'members': ['test_user_id'],
    'createdAt': '2024-01-01T00:00:00Z',
  };

  /// Test environment flags
  static const bool isTestEnvironment = true;
  static const bool enableMocking = true;
  static const bool enableLogging = false;
  static const bool enableAnalytics = false;

  /// Test database configuration
  static const String testDatabaseName = 'test_accountabilibuddies';
  static const String testCollectionPrefix = 'test_';
}

/// Test tags for organizing tests
class TestTags {
  static const String unit = 'unit';
  static const String widget = 'widget';
  static const String integration = 'integration';
  static const String slow = 'slow';
  static const String fast = 'fast';
  static const String firebase = 'firebase';
  static const String offline = 'offline';
  static const String ui = 'ui';
  static const String core = 'core';
  static const String feature = 'feature';
}

/// Test utilities for common test operations
class TestUtils {
  /// Generates a unique test ID
  static String generateTestId() {
    return '${TestConfig.testKeyPrefix}${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Creates a test key
  static String createTestKey(String suffix) {
    return '${TestConfig.testKeyPrefix}$suffix';
  }

  /// Checks if running in test environment
  static bool get isTestEnvironment => TestConfig.isTestEnvironment;

  /// Creates mock data with overrides
  static Map<String, dynamic> createMockData(
    Map<String, dynamic> baseData,
    Map<String, dynamic> overrides,
  ) {
    final result = Map<String, dynamic>.from(baseData);
    result.addAll(overrides);
    return result;
  }
}