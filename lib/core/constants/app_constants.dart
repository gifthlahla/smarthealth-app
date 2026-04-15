class AppConstants {
  AppConstants._();

  static const String supabaseUrl = 'https://kmzmqdebniekrvqxoqea.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_DPVgHloq1aJBSIrgLsvCog_bN6iqF0i';

  // Storage
  static const String claimDocumentsBucket = 'claim-documents';
  static const String receiptFolder = 'receipts';
  static const String reportFolder = 'reports';

  // Tables
  static const String profilesTable = 'profiles';
  static const String claimsTable = 'claims';
  static const String claimDocumentsTable = 'claim_documents';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxDescriptionLength = 500;
  static const double maxClaimAmount = 999999.99;
}
