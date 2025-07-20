import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:accountabilibuddies/shared/widgets/widgets.dart';

void main() {
  group('AppEmptyState', () {
    Widget buildEmptyState({
      required String title,
      required String message,
      IconData? icon,
      String? actionText,
      VoidCallback? onAction,
      String? secondaryActionText,
      VoidCallback? onSecondaryAction,
      bool compact = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            title: title,
            message: message,
            icon: icon,
            actionText: actionText,
            onAction: onAction,
            secondaryActionText: secondaryActionText,
            onSecondaryAction: onSecondaryAction,
            compact: compact,
          ),
        ),
      );
    }

    group('Basic Rendering', () {
      testWidgets('should render title and message', (tester) async {
        await tester.pumpWidget(buildEmptyState(
          title: 'Empty State',
          message: 'Nothing to show here',
        ));

        expect(find.text('Empty State'), findsOneWidget);
        expect(find.text('Nothing to show here'), findsOneWidget);
      });

      testWidgets('should render icon when provided', (tester) async {
        await tester.pumpWidget(buildEmptyState(
          title: 'Empty State',
          message: 'Nothing to show here',
          icon: Icons.inbox,
        ));

        expect(find.byIcon(Icons.inbox), findsOneWidget);
      });

      testWidgets('should not render icon when not provided', (tester) async {
        await tester.pumpWidget(buildEmptyState(
          title: 'Empty State',
          message: 'Nothing to show here',
        ));

        expect(find.byType(Icon), findsNothing);
      });
    });

    group('Actions', () {
      testWidgets('should render primary action when provided', (tester) async {
        await tester.pumpWidget(buildEmptyState(
          title: 'Empty State',
          message: 'Nothing to show here',
          actionText: 'Take Action',
          onAction: () {},
        ));

        expect(find.text('Take Action'), findsOneWidget);
        expect(find.byType(AppButton), findsOneWidget);
      });

      testWidgets('should render secondary action when provided', (tester) async {
        await tester.pumpWidget(buildEmptyState(
          title: 'Empty State',
          message: 'Nothing to show here',
          actionText: 'Primary Action',
          onAction: () {},
          secondaryActionText: 'Secondary Action',
          onSecondaryAction: () {},
        ));

        expect(find.text('Primary Action'), findsOneWidget);
        expect(find.text('Secondary Action'), findsOneWidget);
        expect(find.byType(AppButton), findsNWidgets(2));
      });

      testWidgets('should not render actions when not provided', (tester) async {
        await tester.pumpWidget(buildEmptyState(
          title: 'Empty State',
          message: 'Nothing to show here',
        ));

        expect(find.byType(AppButton), findsNothing);
      });

      testWidgets('should call onAction when primary action is tapped', (tester) async {
        var actionPressed = false;
        
        await tester.pumpWidget(buildEmptyState(
          title: 'Empty State',
          message: 'Nothing to show here',
          actionText: 'Take Action',
          onAction: () => actionPressed = true,
        ));

        await tester.tap(find.text('Take Action'));
        expect(actionPressed, isTrue);
      });

      testWidgets('should call onSecondaryAction when secondary action is tapped', (tester) async {
        var secondaryActionPressed = false;
        
        await tester.pumpWidget(buildEmptyState(
          title: 'Empty State',
          message: 'Nothing to show here',
          actionText: 'Primary Action',
          onAction: () {},
          secondaryActionText: 'Secondary Action',
          onSecondaryAction: () => secondaryActionPressed = true,
        ));

        await tester.tap(find.text('Secondary Action'));
        expect(secondaryActionPressed, isTrue);
      });
    });

    group('Compact Mode', () {
      testWidgets('should render compact empty state', (tester) async {
        await tester.pumpWidget(buildEmptyState(
          title: 'Empty State',
          message: 'Nothing to show here',
          icon: Icons.inbox,
          compact: true,
        ));

        expect(find.text('Empty State'), findsOneWidget);
        expect(find.text('Nothing to show here'), findsOneWidget);
        expect(find.byIcon(Icons.inbox), findsOneWidget);
      });
    });
  });

  group('AppEmptyStates', () {
    Widget buildPredefinedEmptyState(Widget emptyState) {
      return MaterialApp(
        home: Scaffold(
          body: emptyState,
        ),
      );
    }

    testWidgets('should render noData empty state', (tester) async {
      await tester.pumpWidget(buildPredefinedEmptyState(
        AppEmptyStates.noData(),
      ));

      expect(find.text('No Data'), findsOneWidget);
      expect(find.text('There\'s nothing here yet.'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('should render noSearchResults empty state', (tester) async {
      await tester.pumpWidget(buildPredefinedEmptyState(
        AppEmptyStates.noSearchResults(),
      ));

      expect(find.text('No Results'), findsOneWidget);
      expect(find.text('We couldn\'t find anything matching your search.'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('should render noNetwork empty state', (tester) async {
      await tester.pumpWidget(buildPredefinedEmptyState(
        AppEmptyStates.noNetwork(),
      ));

      expect(find.text('No Connection'), findsOneWidget);
      expect(find.text('Check your internet connection and try again.'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should render noGoals empty state', (tester) async {
      await tester.pumpWidget(buildPredefinedEmptyState(
        AppEmptyStates.noGoals(),
      ));

      expect(find.text('No Goals Yet'), findsOneWidget);
      expect(find.text('Create your first goal to get started with your accountability journey.'), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
      expect(find.text('Create Goal'), findsOneWidget);
    });

    testWidgets('should render noParty empty state', (tester) async {
      await tester.pumpWidget(buildPredefinedEmptyState(
        AppEmptyStates.noParty(),
      ));

      expect(find.text('No Party Yet'), findsOneWidget);
      expect(find.text('Create or join a party to start your accountability journey with friends.'), findsOneWidget);
      expect(find.byIcon(Icons.group_outlined), findsOneWidget);
      expect(find.text('Create Party'), findsOneWidget);
      expect(find.text('Join Party'), findsOneWidget);
    });

    testWidgets('should render noProofs empty state', (tester) async {
      await tester.pumpWidget(buildPredefinedEmptyState(
        AppEmptyStates.noProofs(),
      ));

      expect(find.text('No Proofs Yet'), findsOneWidget);
      expect(find.text('Submit your first proof to show your progress.'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      expect(find.text('Submit Proof'), findsOneWidget);
    });

    testWidgets('should render noPendingApprovals empty state', (tester) async {
      await tester.pumpWidget(buildPredefinedEmptyState(
        AppEmptyStates.noPendingApprovals(),
      ));

      expect(find.text('All Caught Up!'), findsOneWidget);
      expect(find.text('No pending proofs to review right now.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('should render noNotifications empty state', (tester) async {
      await tester.pumpWidget(buildPredefinedEmptyState(
        AppEmptyStates.noNotifications(),
      ));

      expect(find.text('No Notifications'), findsOneWidget);
      expect(find.text('You\'re all caught up! No new notifications.'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);
    });

    testWidgets('should render comingSoon empty state', (tester) async {
      await tester.pumpWidget(buildPredefinedEmptyState(
        AppEmptyStates.comingSoon(),
      ));

      expect(find.text('Coming Soon'), findsOneWidget);
      expect(find.text('This feature is coming soon. Stay tuned!'), findsOneWidget);
      expect(find.byIcon(Icons.construction_outlined), findsOneWidget);
    });

    testWidgets('should render maintenance empty state', (tester) async {
      await tester.pumpWidget(buildPredefinedEmptyState(
        AppEmptyStates.maintenance(),
      ));

      expect(find.text('Under Maintenance'), findsOneWidget);
      expect(find.text('We\'re making improvements. Please check back later.'), findsOneWidget);
      expect(find.byIcon(Icons.build_outlined), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });
  });
}