import '../../../core/config/environment_config.dart';

/// Debug pre-fill data service for local development
/// Provides sample data to pre-fill forms for faster testing
/// Only active when EnvironmentConfig.useDebugPrefill is true
class DebugDataService {
  // Check if debug pre-fill should be used
  static bool get isEnabled => EnvironmentConfig.useDebugPrefill;

  // Debug login credentials
  static const debugEmail = 'test@example.com';
  static const debugPassword = 'Test123!';

  // Debug user profile data
  static const debugUserData = {
    'firstName': 'John',
    'lastName': 'Doe',
    'email': 'test@example.com',
    'phone': '+1234567890',
    'dateOfBirth': '1990-01-01',
    'address': '123 Test Street',
    'city': 'Test City',
    'state': 'Test State',
    'zipCode': '12345',
    'country': 'United States',
  };

  // Debug executor data
  static const debugExecutorData = {
    'name': 'Jane Smith',
    'email': 'jane.smith@example.com',
    'phone': '+1234567891',
    'relationship': 'SIBLING',
    'address': '456 Executor Ave',
  };

  // Debug beneficiary data
  static const debugBeneficiaryData = {
    'name': 'Bob Johnson',
    'email': 'bob.johnson@example.com',
    'phone': '+1234567892',
    'relationship': 'OTHER',
    'percentage': '50',
  };

  // Debug asset data
  static const debugAssetData = {
    'type': 'Property',
    'description': 'Primary Residence',
    'value': '500000',
    'location': '123 Test Street, Test City',
    'accountNumber': 'N/A',
  };

  // Debug will data
  static const debugWillData = {
    'title': 'My Primary Will',
    'notes': 'This is a test will created for debugging purposes.',
  };

  // ── Digital Vault ─────────────────────────────────────────────────────

  // Debug vault message data
  static const debugVaultMessageData = {
    'title': 'A letter to my family',
    'message':
        'To my beloved family — I want you to know how proud I am of each one of you. Always look after one another.',
  };

  // Debug vault asset data
  static const debugVaultAssetData = {
    'name': 'Family Home',
    'location': 'Australia',
    'description': 'Three-bedroom house at 42 Wallaby Way, Sydney.',
  };

  // Debug vault liability data
  static const debugVaultLiabilityData = {
    'name': 'Home Mortgage',
    'location': 'Australia',
    'detail': 'Variable rate mortgage with Commonwealth Bank, approx. \$350k remaining.',
  };

  // Debug vault contact data
  static const debugVaultContactData = {
    'firstName': 'Sarah',
    'lastName': 'Mitchell',
    'email': 'sarah.mitchell@example.com',
    'phone': '+61412345690',
  };

  // Debug vault message recipient data
  static const debugVaultRecipientData = {
    'firstName': 'Emily',
    'lastName': 'Doe',
    'email': 'emily.doe@example.com',
    'mobile': '+61412345691',
  };
}

