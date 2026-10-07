/// State categories for each registration stage
enum PushDiagnosticState {
  unknown,
  pending,
  available,
  missing,
  success,
  failed,
  notAttempted,
  timeout,
}

/// Strongly typed report for the iOS Push Registration chain
class PushRegistrationReport {
  final PushDiagnosticState permission;
  final PushDiagnosticState apnsRegistration;
  final PushDiagnosticState apnsToken;
  final PushDiagnosticState fcmToken;
  final PushDiagnosticState userId;
  final PushDiagnosticState supabaseSync;
  final String? lastError;
  final DateTime? lastAttempt;

  const PushRegistrationReport({
    this.permission = PushDiagnosticState.unknown,
    this.apnsRegistration = PushDiagnosticState.notAttempted,
    this.apnsToken = PushDiagnosticState.unknown,
    this.fcmToken = PushDiagnosticState.unknown,
    this.userId = PushDiagnosticState.unknown,
    this.supabaseSync = PushDiagnosticState.notAttempted,
    this.lastError,
    this.lastAttempt,
  });

  PushRegistrationReport copyWith({
    PushDiagnosticState? permission,
    PushDiagnosticState? apnsRegistration,
    PushDiagnosticState? apnsToken,
    PushDiagnosticState? fcmToken,
    PushDiagnosticState? userId,
    PushDiagnosticState? supabaseSync,
    String? lastError,
    DateTime? lastAttempt,
  }) {
    return PushRegistrationReport(
      permission: permission ?? this.permission,
      apnsRegistration: apnsRegistration ?? this.apnsRegistration,
      apnsToken: apnsToken ?? this.apnsToken,
      fcmToken: fcmToken ?? this.fcmToken,
      userId: userId ?? this.userId,
      supabaseSync: supabaseSync ?? this.supabaseSync,
      lastError: lastError ?? this.lastError,
      lastAttempt: lastAttempt ?? this.lastAttempt,
    );
  }

  @override
  String toString() {
    return 'PushRegistrationReport(perm: $permission, apnsReg: $apnsRegistration, apns: $apnsToken, fcm: $fcmToken, user: $userId, supabase: $supabaseSync)';
  }
}
