# Will API Integration Summary

## Overview

This document provides a comprehensive overview of the Will Management API integration based on the Postman collection provided. The implementation follows clean architecture principles with proper separation of concerns.

## API Base URL

```
http://13.54.59.56:8000
```

## Architecture

```
lib/features/will_creation/
├── data/
│   ├── models/
│   │   ├── will_models.dart         # Will, Asset, Allocation models
│   │   ├── family_models.dart       # Family, Former Partner, Dependent, Pet, Beneficiary models
│   │   └── gift_models.dart         # Gift and Gift Beneficiary models
│   └── repositories/
│       └── will_repository_impl.dart # Repository implementation
├── domain/
│   └── repositories/
│       └── will_repository.dart     # Repository interface
└── presentation/
    └── pages/                       # UI screens (existing)
```

## Data Models

### 1. Will Models (`will_models.dart`)

#### Requests
- **InitialWillRequest**: Create initial will with personal details
- **WillAssetRequest**: Add assets to will
- **BeneficiaryAllocationRequest**: Set beneficiary percentages

#### Responses
- **WillResponse<T>**: Generic API response wrapper
- **InitialWillData**: Initial will data
- **WillAsset**: Asset details
- **WillSummary**: Will summary for listing

### 2. Family Models (`family_models.dart`)

#### Core Models
- **PersonDetails**: Basic person information (reusable)
- **FamilyInitialRequest/Data**: Family relationship status
- **FormerPartnerRequest/Data**: Former partner details
- **DependentPersonRequest/Data**: Dependent person with optional guardian
- **DependentDetails**: Dependent person information
- **PetRequest/Data**: Pet with caretaker
- **BeneficiaryPersonRequest/Data**: Person beneficiary
- **CharityRequest/Data**: Charity information
- **BeneficiaryCharityRequest/Data**: Charity beneficiary

### 3. Gift Models (`gift_models.dart`)

- **GiftRequest/Data**: Gift preferences
- **GiftBeneficiaryRequest/Data**: Gift receiver details
- **GiftReceiverDetails**: Person receiving gift

## API Endpoints

All endpoints are defined in `lib/core/network/api_endpoints.dart`:

### Will Endpoints
```dart
POST   /will/initial                    # Create initial will
GET    /will/initial                    # Get initial will
GET    /will/asset                      # Get assets
POST   /will/asset                      # Add asset
GET    /will/gift                       # Get gift
POST   /will/gift                       # Create/update gift
POST   /will/beneficiary/allocation     # Set allocations
GET    /will/all                        # Get all wills
```

### Family Endpoints
```dart
POST   /will/family/initial                    # Create family initial
GET    /will/family/initial/{willId}           # Get family initial

POST   /will/family/former-partner             # Add former partner
GET    /will/family/former-partner?will_id=    # Get former partners
DELETE /will/family/former-partner/{willId}/{partnerId}

POST   /will/family/dependent/person           # Add dependent person
GET    /will/family/dependent/person?will_id=  # Get dependents
DELETE /will/family/dependent/person?will_id=&dependent_id=

POST   /will/family/dependent/pet              # Add pet
GET    /will/family/dependent/pet?will_id=     # Get pets
DELETE /will/family/dependent/pet?will_id=&will_pet_id=&care_taker_id=
```

### Beneficiary Endpoints
```dart
POST   /will/family/beneficiary/person         # Add person beneficiary
GET    /will/family/beneficiary/person?will_id=
DELETE /will/family/beneficiary/person?will_id=&beneficiary_id=

POST   /will/charity                           # Create charity
GET    /will/charity                           # Get all charities

POST   /will/family/beneficiary/charity        # Add charity beneficiary
GET    /will/family/beneficiary/charity?will_id=
DELETE /will/family/beneficiary/charity?will_id=&beneficiary_charity_id=
```

### Gift Endpoints
```dart
POST   /will/gift/beneficiary                  # Add gift beneficiary
GET    /will/gift/beneficiary?will_id=         # Get gift beneficiaries
```

## Repository Usage

### Initialize Repository

```dart
import 'package:digitalwill/core/network/api_client.dart';
import 'package:digitalwill/features/will_creation/data/repositories/will_repository_impl.dart';
import 'package:digitalwill/features/will_creation/domain/repositories/will_repository.dart';

final WillRepository willRepository = WillRepositoryImpl(
  apiClient: ApiClient(),
);
```

### Example Usage

#### 1. Create Initial Will

```dart
try {
  final request = InitialWillRequest(
    hasCapacity: true,
    firstName: 'John',
    middleName: 'Trevor',
    lastName: 'Doe',
    dob: '1985-06-05',
    addressLine1: 'No 12',
    suburb: 'Queen',
    postcode: '62578',
    country: 'Australia',
  );

  final response = await willRepository.createInitialWill(request);
  
  if (response.isSuccess && response.data != null) {
    final willId = response.data!.willId;
    print('Will created: $willId');
  }
} on ApiException catch (e) {
  print('Error: ${e.message}');
}
```

#### 2. Add Family Details

```dart
// Set family initial status
final familyRequest = FamilyInitialRequest(
  willId: willId,
  relationshipStatus: 'MARRIED',
  hasPreviousRelationship: true,
  canIncludeFormerPartner: true,
);

final familyResponse = await willRepository.createFamilyInitial(familyRequest);

// Add former partner
final partnerRequest = FormerPartnerRequest(
  willId: willId,
  formerPartner: PersonDetails(
    firstName: 'Jane',
    lastName: 'Smith',
    email: 'jane@example.com',
    mobile: '+61 400 000 000',
  ),
);

await willRepository.addFormerPartner(partnerRequest);
```

#### 3. Add Dependents

```dart
// Add minor dependent with guardian
final dependentRequest = DependentPersonRequest(
  willId: willId,
  dependent: DependentDetails(
    firstName: 'Emily',
    lastName: 'Doe',
    mobile: '+61 400 111 111',
    email: 'emily@example.com',
    relation: 'DAUGHTER',
    isMinor: true,
  ),
  guardian: PersonDetails(
    firstName: 'Sarah',
    lastName: 'Johnson',
    email: 'sarah@example.com',
    mobile: '+61 400 222 222',
  ),
);

await willRepository.addDependentPerson(dependentRequest);

// Add pet
final petRequest = PetRequest(
  willId: willId,
  animalName: 'Max',
  animalCategory: 'DOG',
  caretaker: PersonDetails(
    firstName: 'Bob',
    lastName: 'Wilson',
    email: 'bob@example.com',
    mobile: '+61 400 333 333',
  ),
);

await willRepository.addPet(petRequest);
```

#### 4. Add Beneficiaries

```dart
// Add person beneficiary
final beneficiaryRequest = BeneficiaryPersonRequest(
  willId: willId,
  beneficiary: PersonDetails(
    firstName: 'Alice',
    lastName: 'Brown',
    email: 'alice@example.com',
    mobile: '+61 400 444 444',
  ),
);

await willRepository.addBeneficiaryPerson(beneficiaryRequest);

// Create and add charity beneficiary
final charityRequest = CharityRequest(
  name: 'Red Cross',
  address: '123 Charity St, Sydney',
);

final charityResponse = await willRepository.createCharity(charityRequest);

if (charityResponse.isSuccess && charityResponse.data != null) {
  final charityId = charityResponse.data!.id;
  
  await willRepository.addBeneficiaryCharity(
    BeneficiaryCharityRequest(
      willId: willId,
      charityId: charityId,
    ),
  );
}
```

#### 5. Set Beneficiary Allocations

```dart
final allocationRequest = BeneficiaryAllocationRequest(
  willId: willId,
  beneficiaryAllocation: [
    AllocationItem(id: '1', percentage: '50'),
    AllocationItem(id: '2', percentage: '30'),
  ],
  charityAllocation: [
    AllocationItem(id: '1', percentage: '20'),
  ],
);

await willRepository.setBeneficiaryAllocation(allocationRequest);
```

#### 6. Get Data

```dart
// Get initial will
final willResponse = await willRepository.getInitialWill();

// Get all former partners
final partnersResponse = await willRepository.getFormerPartners(willId);

// Get all dependents
final dependentsResponse = await willRepository.getDependentPersons(willId);

// Get all pets
final petsResponse = await willRepository.getPets(willId);

// Get all beneficiaries
final beneficiariesResponse = await willRepository.getBeneficiaryPersons(willId);

// Get all charity beneficiaries
final charitiesResponse = await willRepository.getBeneficiaryCharities(willId);

// Get all wills
final allWillsResponse = await willRepository.getAllWills();
```

#### 7. Delete Operations

```dart
// Delete former partner
await willRepository.deleteFormerPartner(
  willId: willId,
  partnerId: '3',
);

// Delete dependent
await willRepository.deleteDependentPerson(
  willId: willId,
  dependentId: '14',
);

// Delete pet
await willRepository.deletePet(
  willId: willId,
  petId: '2',
  caretakerId: '24',
);

// Delete beneficiary
await willRepository.deleteBeneficiaryPerson(
  willId: willId,
  beneficiaryId: '33',
);

// Delete charity beneficiary
await willRepository.deleteBeneficiaryCharity(
  willId: willId,
  beneficiaryCharityId: '1',
);
```

## Response Handling

All API responses follow the same structure:

```dart
{
  "status": "success" | "failure",
  "message": "Optional message",
  "data": { ... } // or null
}
```

The `WillResponse<T>` class provides:
- `isSuccess`: Boolean indicating success
- `isFailure`: Boolean indicating failure
- `data`: Typed data (nullable)
- `message`: Optional message

## Error Handling

All API calls can throw the following exceptions:

- **NetworkException**: Connection issues
- **UnauthorizedException**: 401 - Need to login
- **NotFoundException**: 404 - Resource not found
- **ValidationException**: 400 - Invalid data
- **ForbiddenException**: 403 - Access denied
- **ServerException**: 500+ - Server errors
- **ApiException**: Generic API error

Example:

```dart
try {
  final response = await willRepository.createInitialWill(request);
  // Handle success
} on UnauthorizedException {
  // Redirect to login
} on ValidationException catch (e) {
  // Show validation errors
} on NetworkException {
  // Show network error
} on ApiException catch (e) {
  // Show generic error
  print('Error: ${e.message}');
}
```

## Authentication

All API requests automatically include the Bearer token from secure storage via the `ApiClient` interceptor. No manual token handling needed.

## Next Steps

1. **Create BLoC/Cubit** for state management of will creation flow
2. **Integrate with UI** - Connect existing screens to repository
3. **Add form validation** - Validate data before API calls
4. **Implement caching** - Store will data locally for offline access
5. **Add progress tracking** - Track completion of will creation steps
6. **Test API integration** - Write integration tests

## API Documentation Notes

Based on the Postman collection:

- **will_id**: UUID string (e.g., "36897618-e0c7-4a11-91de-0ffac47f148d")
- **Dates**: Format as "YYYY-MM-DD" (e.g., "1985-06-05")
- **Phone numbers**: Include country code (e.g., "+61 978979879")
- **Relationship Status**: String values (check backend for valid options)
- **Relations**: SON, DAUGHTER, GRANDCHILD, etc.
- **Animal Categories**: DOG, CAT, BIRD, FISH, etc.

## Support

For API issues or questions:
1. Check backend API documentation
2. Verify authentication token is valid
3. Check network connectivity
4. Review error messages from API responses
