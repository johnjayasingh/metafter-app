/// Centralized form constants for the application
/// Usage: FormConstants.countryCodes, FormConstants.relations
class FormConstants {
  // ==================== Country Codes ====================
  
  /// Standard country code list used across all phone inputs
  static const List<String> countryCodes = [
    '+61', // Australia
    '+1',  // USA/Canada
    '+44', // UK
    '+91', // India
    '+64', // New Zealand
    '+65', // Singapore
    '+86', // China
    '+81', // Japan
  ];

  /// Default country code
  static const String defaultCountryCode = '+61';

  // ==================== Relations ====================
  
  /// Relations for minor beneficiaries (children)
  static const List<String> minorRelations = [
    'SON',
    'DAUGHTER',
    'STEP_SON',
    'STEP_DAUGHTER',
    'NEPHEW',
    'NIECE',
    'OTHER',
  ];

  /// Relations for adult beneficiaries
  static const List<String> adultRelations = [
    'FATHER',
    'MOTHER',
    'HUSBAND',
    'WIFE',
    'SISTER',
    'GUARDIAN',
    'SON',
    'DAUGHTER',
    'STEP_SON',
    'STEP_DAUGHTER',
    'NEPHEW',
    'NIECE',
    'OTHER',
  ];

  /// All relations
  static List<String> get allRelations => [...minorRelations, ...adultRelations];

  /// Relations for the partner relationship dropdown
  static const List<String> partnerRelations = [
    'HUSBAND',
    'WIFE',
    'EX_HUSBAND',
    'EX_WIFE',
    'OTHER',
  ];

  /// Relations for the person relationship field (guardian, caretaker, partner, etc.)
  static const List<String> personRelations = [
    'SON',
    'DAUGHTER',
    'STEP_SON',
    'STEP_DAUGHTER',
    'NEPHEW',
    'NIECE',
    'FATHER',
    'MOTHER',
    'GUARDIAN',
    'CARETAKER',
    'OTHER',
  ];

  /// Display names for relations (for UI)
  static String getRelationDisplayName(String relation) {
    switch (relation) {
      case 'SON': return 'Son';
      case 'DAUGHTER': return 'Daughter';
      case 'STEP_SON': return 'Step Son';
      case 'STEP_DAUGHTER': return 'Step Daughter';
      case 'NEPHEW': return 'Nephew';
      case 'NIECE': return 'Niece';
      case 'FATHER': return 'Father';
      case 'MOTHER': return 'Mother';
      case 'GUARDIAN': return 'Guardian';
      case 'BACKUP_GUARDIAN': return 'Backup Guardian';
      case 'CARETAKER': return 'Caretaker';
      case 'SPOUSE': return 'Spouse';
      case 'PARTNER': return 'Partner';
      case 'SIBLING': return 'Sibling';
      case 'BROTHER': return 'Brother';
      case 'SISTER': return 'Sister';
      case 'WIFE': return 'Wife';
      case 'HUSBAND': return 'Husband';
      case 'EX_HUSBAND': return 'Ex Husband';
      case 'EX_WIFE': return 'Ex Wife';
      case 'GRANDCHILD': return 'Grandchild';
      case 'GRANDPARENT': return 'Grandparent';
      case 'FRIEND': return 'Friend';
      case 'OTHER': return 'Other';
      default: return relation;
    }
  }

  // ==================== Countries ====================
  
  static const List<String> countries = [
    'Afghanistan',
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Antigua & Deps',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bhutan',
    'Bolivia',
    'Bosnia Herzegovina',
    'Botswana',
    'Brazil',
    'Brunei',
    'Bulgaria',
    'Burkina',
    'Burundi',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Cape Verde',
    'Central African Rep',
    'Chad',
    'Chile',
    'China',
    'Colombia',
    'Comoros',
    'Congo',
    'Congo {Democratic Rep}',
    'Costa Rica',
    'Croatia',
    'Cuba',
    'Cyprus',
    'Czech Republic',
    'Denmark',
    'Djibouti',
    'Dominica',
    'Dominican Republic',
    'East Timor',
    'Ecuador',
    'Egypt',
    'El Salvador',
    'Equatorial Guinea',
    'Eritrea',
    'Estonia',
    'Ethiopia',
    'Fiji',
    'Finland',
    'France',
    'Gabon',
    'Gambia',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Grenada',
    'Guatemala',
    'Guinea',
    'Guinea-Bissau',
    'Guyana',
    'Haiti',
    'Honduras',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland {Republic}',
    'Israel',
    'Italy',
    'Ivory Coast',
    'Jamaica',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kiribati',
    'Korea North',
    'Korea South',
    'Kosovo',
    'Kuwait',
    'Kyrgyzstan',
    'Laos',
    'Latvia',
    'Lebanon',
    'Lesotho',
    'Liberia',
    'Libya',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Macedonia',
    'Madagascar',
    'Malawi',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Marshall Islands',
    'Mauritania',
    'Mauritius',
    'Mexico',
    'Micronesia',
    'Moldova',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Morocco',
    'Mozambique',
    'Myanmar, {Burma}',
    'Namibia',
    'Nauru',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'Norway',
    'Oman',
    'Pakistan',
    'Palau',
    'Panama',
    'Papua New Guinea',
    'Paraguay',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russian Federation',
    'Rwanda',
    'St Kitts & Nevis',
    'St Lucia',
    'Saint Vincent & the Grenadines',
    'Samoa',
    'San Marino',
    'Sao Tome & Principe',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leone',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'Solomon Islands',
    'Somalia',
    'South Africa',
    'South Sudan',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Suriname',
    'Swaziland',
    'Sweden',
    'Switzerland',
    'Syria',
    'Taiwan',
    'Tajikistan',
    'Tanzania',
    'Thailand',
    'Togo',
    'Tonga',
    'Trinidad & Tobago',
    'Tunisia',
    'Turkey',
    'Turkmenistan',
    'Tuvalu',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Uruguay',
    'Uzbekistan',
    'Vanuatu',
    'Vatican City',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Zambia',
    'Zimbabwe',
  ];

  /// Default country
  static const String defaultCountry = 'Australia';

  // ==================== Australian States ====================

  /// API value → display name (matches web app option values)
  static const Map<String, String> australianStateMap = {
    'queensland': 'Queensland',
    'new_south_wales': 'New South Wales',
    'victoria': 'Victoria',
    'south_australia': 'South Australia',
    'western_australia': 'Western Australia',
    'tasmania': 'Tasmania',
    'northern_territory': 'Northern Territory',
    'act': 'Australian Capital Territory',
  };

  /// List of API state keys (for dropdown items)
  static List<String> get australianStateKeys => australianStateMap.keys.toList();

  /// Returns display name for a state API key
  static String getStateDisplayName(String state) {
    return australianStateMap[state.toLowerCase()] ?? state;
  }

  /// Converts any incoming value (display name, old abbreviation, or API key) → API key.
  /// Returns null when the input cannot be matched.
  static String? toStateApiValue(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final lower = raw.trim().toLowerCase();
    // Already an API key
    if (australianStateMap.containsKey(lower)) return lower;
    // Display name → find the key
    for (final entry in australianStateMap.entries) {
      if (entry.value.toLowerCase() == lower) return entry.key;
    }
    // Legacy abbreviation mapping
    const legacyMap = {
      'nsw': 'new_south_wales',
      'vic': 'victoria',
      'qld': 'queensland',
      'wa': 'western_australia',
      'sa': 'south_australia',
      'tas': 'tasmania',
      'nt': 'northern_territory',
    };
    return legacyMap[lower];
  }

  // ==================== Animal Types ====================
  
  /// Animal types for pets
  static const List<String> animalTypes = [
    'DOG',
    'CAT',
    'FISH',
  ];

  /// Display names for animals (for UI) - properly capitalized
  static String getAnimalDisplayName(String animal) {
    switch (animal) {
      case 'DOG': return 'Dog';
      case 'CAT': return 'Cat';
      case 'FISH': return 'Fish';
      default: 
        // Convert any animal type to init caps (e.g., 'BIRD' -> 'Bird')
        return animal.toLowerCase().split(' ').map((w) => 
          w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : ''
        ).join(' ');
    }
  }

  // ==================== Witness Relations ====================
  
  static const List<String> witnessRelations = [
    'FATHER',
    'MOTHER',
    'GUARDIAN',
    'CARETAKER',
    'SON',
    'DAUGHTER',
    'STEP_SON',
    'STEP_DAUGHTER',
    'NEPHEW',
    'NIECE',
    'OTHER',
  ];

  // ==================== Executor Relations ====================
  
  static const List<String> executorRelations = [
    'SPOUSE',
    'PARTNER',
    'SON',
    'DAUGHTER',
    'SIBLING',
    'FRIEND',
    'LAWYER',
    'ACCOUNTANT',
    'PROFESSIONAL',
    'OTHER',
  ];
}
