import '../config/environment_config.dart';

/// Debug configuration for development and testing
class DebugConfig {
  // Set to true to prepopulate forms with test data (controlled by environment)
  static bool get usePrepopulatedData => EnvironmentConfig.useDebugPrefill;

  // Set to true to skip payment/subscription flow (useful for testing)
  static bool skipPayment = false;

  // Test data for sign up
  static const Map<String, dynamic> testSignUp = {
    'firstName': 'John',
    'lastName': 'Jayasingh',
    'email': 'johnjayasingh.s@gmail.com',
    'password': 'Admin@100',
    'confirmPassword': 'Admin@100',
  };

  // Test data for sign in
  static const Map<String, dynamic> testSignIn = {
    'email': 'johnjayasingh.s@gmail.com',
    'password': 'Admin@100',
  };

  // Test data for will onboarding
  static const Map<String, dynamic> testWillOnboarding = {'hasCapacity': true};

  // Test data for basic details
  static const Map<String, dynamic> testBasicDetails = {
    'firstName': 'John',
    'middleName': 'Michael',
    'lastName': 'Doe',
    'dob': '15/06/1985',
    'addressLine1': '123 Test Street',
    'suburb': 'Sydney',
    'postcode': '2000',
    'country': 'Australia',
  };

  // Test data for relationship status
  static const Map<String, dynamic> testRelationshipStatus = {
    'relationshipStatus': 'MARRIED',
    'hasBeenMarried': 'yes',
    'includeFormerPartners': 'yes',
  };

  // Test data for former partner
  static const Map<String, dynamic> testFormerPartner = {
    'fullName': 'Jane',
    'middleName': 'Marie',
    'lastName': 'Smith',
    'email': 'jane.smith@example.com',
    'phone': '+61412345678',
  };

  // Test data for dependent
  static const Map<String, dynamic> testDependent = {
    'fullName': 'Tommy',
    'middleName': 'James',
    'lastName': 'Doe',
    'relationship': 'SON',
    'email': 'tommy.doe@example.com',
    'phone': '+61412345679',
    'dependentType': 'minor',
    'guardianFullName': 'Sarah',
    'guardianMiddleName': 'Ann',
    'guardianLastName': 'Johnson',
    'guardianEmail': 'sarah.johnson@example.com',
    'guardianPhone': '+61412345680',
  };

  // Test data for pet
  static const Map<String, dynamic> testPet = {
    'fullName': 'Max',
    'petType': 'DOG',
    'dependentType': 'pet',
    'caretakerFullName': 'Robert',
    'caretakerMiddleName': 'Lee',
    'caretakerLastName': 'Wilson',
    'caretakerEmail': 'robert.wilson@example.com',
    'caretakerPhone': '+61412345681',
  };

  // Test data for beneficiary
  static const Map<String, dynamic> testBeneficiary = {
    'fullName': 'Michael',
    'middleName': 'David',
    'lastName': 'Brown',
    'dob': '15/03/1990',
    'relation': 'NEPHEW',
    'email': 'michael.brown@example.com',
    'phone': '+61412345682',
    'isMinor': 'no',
  };

  // Test data for asset
  static const Map<String, dynamic> testAsset = {
    'assetType': 'PROPERTY',
    'institution': 'CBA',
    'description': '123 Main Street, Sydney NSW 2000 - Investment Property',
  };

  // Test data for gifts question
  static const Map<String, dynamic> testGiftsQuestion = {'leaveGift': true};

  // Test data for gift recipient
  static const Map<String, dynamic> testGiftRecipient = {
    'fullName': 'Emily',
    'middleName': 'Rose',
    'lastName': 'Anderson',
    'dob': '20/08/1995',
    'email': 'emily.anderson@example.com',
    'phone': '412345683',
    'countryCode': '+61',
    'address': '456 Park Avenue, Melbourne VIC 3000',
    'relation': 'NIECE',
    'isMinor': 'no',
    'giftType': 'specific_item',
    'giftName': 'Vintage Watch Collection',
    'giftDescription':
        'Collection of 5 vintage watches including Rolex and Omega timepieces stored in safe deposit box',
  };

  // Alternative test data for gift recipient with money
  static const Map<String, dynamic> testGiftRecipientMoney = {
    'fullName': 'Daniel',
    'middleName': 'James',
    'lastName': 'Thompson',
    'dob': '10/12/2010',
    'email': 'daniel.thompson@example.com',
    'phone': '412345684',
    'countryCode': '+61',
    'address': '789 Beach Road, Gold Coast QLD 4217',
    'relation': 'SON',
    'isMinor': 'yes',
    'giftType': 'money',
    'currency': 'AUD',
    'amount': '50000',
  };

  // Test data for personal executor
  static const Map<String, dynamic> testPersonalExecutor = {
    'firstName': 'Richard',
    'middleName': 'Paul',
    'lastName': 'Stevens',
    'email': 'richard.stevens@example.com',
    'phone': '412345685',
    'countryCode': '+61',
    'relationship': 'OTHER',
  };

  // Test data for witness
  static const Map<String, dynamic> testWitness = {
    'firstName': 'Patricia',
    'middleName': 'Anne',
    'lastName': 'Martinez',
    'email': 'patricia.martinez@example.com',
    'relationship': 'GUARDIAN',
    'note':
        'Long-time family friend and colleague, available to witness will signing',
  };

  // Test data for personal lawyer
  static const Map<String, dynamic> testPersonalLawyer = {
    'firstName': 'Michael',
    'middleName': 'James',
    'lastName': 'Harrison',
    'email': 'michael.harrison@lawfirm.com',
    'phone': '412345686',
    'countryCode': '+61',
    'firmName': 'Harrison & Associates',
    'address': '123 Legal Street, Sydney NSW 2000',
  };
}
