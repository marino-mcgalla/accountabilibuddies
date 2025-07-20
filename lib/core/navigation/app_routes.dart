class AppRoutes {
  // Root paths
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  
  // Authentication routes
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authForgotPassword = '/auth/forgot-password';
  
  // Main navigation routes
  static const String dashboard = '/dashboard';
  static const String goals = '/goals';
  static const String party = '/party';
  static const String profile = '/profile';
  
  // Settings routes
  static const String settings = '/settings';
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsPrivacy = '/settings/privacy';
  static const String settingsAbout = '/settings/about';
  
  // Route names (for type-safe navigation)
  static const String splashName = 'splash';
  static const String onboardingName = 'onboarding';
  
  // Authentication route names
  static const String authLoginName = 'auth-login';
  static const String authRegisterName = 'auth-register';
  static const String authForgotPasswordName = 'auth-forgot-password';
  
  // Main navigation route names
  static const String dashboardName = 'dashboard';
  static const String goalsName = 'goals';
  static const String partyName = 'party';
  static const String profileName = 'profile';
  
  // Goals sub-route names
  static const String goalsCreateName = 'goals-create';
  static const String goalsEditName = 'goals-edit';
  static const String goalsDetailsName = 'goals-details';
  static const String goalsProofName = 'goals-proof';
  
  // Party sub-route names
  static const String partyCreateName = 'party-create';
  static const String partyJoinName = 'party-join';
  static const String partyInviteName = 'party-invite';
  static const String partyMembersName = 'party-members';
  static const String partyApprovalsName = 'party-approvals';
  static const String partyDetailName = 'party-detail';
  
  // Profile sub-route names
  static const String profileEditName = 'profile-edit';
  
  // Settings route names
  static const String settingsName = 'settings';
  static const String settingsNotificationsName = 'settings-notifications';
  static const String settingsPrivacyName = 'settings-privacy';
  static const String settingsAboutName = 'settings-about';
}

// Type-safe navigation extensions
extension AppRoutesExtension on AppRoutes {
  // Goals routes with parameters
  static String goalsEdit(String goalId) => '/goals/edit/$goalId';
  static String goalsDetails(String goalId) => '/goals/$goalId/details';
  static String goalsProof(String goalId) => '/goals/$goalId/proof';
  
  // Party routes with parameters
  static String partyDetail(String partyId) => '/party/$partyId';
  static String partyInvite(String partyId) => '/party/invite/$partyId';
}