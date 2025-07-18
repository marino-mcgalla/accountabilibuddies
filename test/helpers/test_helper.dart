import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

/// Test helper utilities for AccountabiliBuddies
class TestHelper {
  /// Creates a testable widget with necessary providers
  static Widget createTestableWidget({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  /// Creates a testable widget with router
  static Widget createTestableWidgetWithRouter({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: _createTestRouter(child),
      ),
    );
  }

  /// Creates a simple test router
  static _createTestRouter(Widget child) {
    // This will be implemented when we add GoRouter
    return null;
  }

  /// Pumps and settles with common delays
  static Future<void> pumpAndSettle(
    WidgetTester tester, {
    Duration? duration,
  }) async {
    await tester.pumpAndSettle(duration ?? const Duration(milliseconds: 100));
  }

  /// Finds widget by key with better error messages
  static Finder findByKey(Key key) {
    return find.byKey(key);
  }

  /// Finds widget by text with better error messages
  static Finder findByText(String text) {
    return find.text(text);
  }

  /// Finds widget by type with better error messages
  static Finder findByType<T extends Widget>() {
    return find.byType(T);
  }

  /// Verifies that a widget exists exactly once
  static void expectSingleWidget(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verifies that a widget doesn't exist
  static void expectNoWidget(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verifies that multiple widgets exist
  static void expectMultipleWidgets(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }
}

/// Mock class for testing
class MockFunction extends Mock {
  void call();
}

/// Mock class for testing async functions
class MockAsyncFunction extends Mock {
  Future<void> call();
}

/// Mock class for testing functions with return values
class MockFunctionWithReturn<T> extends Mock {
  T call();
}

/// Mock class for testing async functions with return values
class MockAsyncFunctionWithReturn<T> extends Mock {
  Future<T> call();
}