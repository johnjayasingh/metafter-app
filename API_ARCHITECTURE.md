# API Integration & Authentication Architecture

## Overview

This document describes the comprehensive API integration and authentication architecture implemented in the Willcloud Flutter app. The architecture follows clean architecture principles with proper separation of concerns, error handling, and secure token management.

## Architecture Layers

### 1. Core Layer (`lib/core/`)

#### Network Layer (`lib/core/network/`)

**ApiClient** (`api_client.dart`)
- Singleton Dio-based HTTP client
- Automatic token injection for authenticated requests
- Request/response interceptors with logging
- Automatic token refresh on 401 errors
- Retry mechanism for failed requests after token refresh

**ApiEndpoints** (`api_endpoints.dart`)
- Centralized API endpoint definitions
- Base URL configuration (TODO: Update with production URL)
- Auth endpoints: login, MFA confirmation, logout, token refresh
- User endpoints: profile management

**ApiExceptions** (`api_exceptions.dart`)
- Custom exception hierarchy:
  - `ApiException` - Base exception
  - `NetworkException` - Connection issues
  - `UnauthorizedException` - 401 errors
  - `NotFoundException` - 404 errors
  - `ServerException` - 5xx errors
  - `ValidationException` - 400 errors
  - `ForbiddenException` - 403 errors

#### Storage Layer (`lib/core/storage/`)

**SecureStorageService** (`secure_storage_service.dart`)
- Singleton service for secure data storage
- Uses `flutter_secure_storage` for encrypted storage
- Platform-specific encryption:
  - Android: EncryptedSharedPreferences
  - iOS: Keychain with first_unlock accessibility
- Manages:
  - Access tokens
  - Refresh tokens
  - Session data
  - User credentials
  - Login step tracking

### 2. Feature Layer - Authentication (`lib/features/auth/`)

#### Data Layer (`data/`)

**Models** (`data/models/auth_models.dart`)
- `LoginRequest` - Login credentials DTO
- `MfaConfirmRequest` - MFA verification DTO
- `LoginResponse` - API response wrapper
- `LoginData` - Login result data
- `UserInfo` - User profile data
- `LoginStep` enum - Login flow states (MFA_SETUP, MFA_CHALLENGE, COMPLETED)
- `ChallengeType` enum - MFA challenge types

**Repository Implementation** (`data/repositories/auth_repository_impl.dart`)
- Implements `AuthRepository` interface
- Handles API calls through `ApiClient`
- Manages token storage
- Implements business logic for:
  - Email/password login
  - MFA setup and verification
  - Logout
  - Session management

#### Domain Layer (`domain/`)

**AuthRepository** (`domain/repositories/auth_repository.dart`)
- Abstract repository interface
- Defines authentication contracts:
  - `login()` - Email/password authentication
  - `confirmMfa()` - MFA code verification
  - `logout()` - Clear session and tokens
  - `isLoggedIn()` - Check authentication status
  - `getCurrentUser()` - Get user info
  - `clearSession()` - Clear all stored data

#### Presentation Layer (`presentation/`)

**BLoC Pattern** (`presentation/bloc/`)

*AuthBloc* (`auth_bloc.dart`)
- State management for authentication
- Events:
  - `AuthCheckRequested` - Check initial auth status
  - `AuthLoginRequested` - Initiate login
  - `AuthMfaConfirmRequested` - Verify MFA code
  - `AuthLogoutRequested` - Logout user
  - `AuthSessionCleared` - Clear session data

*AuthState* (`auth_state.dart`)
- States:
  - `initial` - App startup
  - `loading` - Processing request
  - `authenticated` - User logged in
  - `unauthenticated` - No valid session
  - `mfaSetupRequired` - First-time MFA setup
  - `mfaChallengeRequired` - MFA verification needed
  - `error` - Error occurred

**Screens** (`presentation/pages/`)

*SignInScreen* (`sign_in_screen.dart`)
- Email/password login form
- BLoC integration for login flow
- Navigation based on login step:
  - MFA Setup → `/mfa-setup`
  - MFA Challenge → `/mfa-challenge`
  - Success → `/home`
- Error handling with SnackBar feedback

*MfaSetupScreen* (`mfa_setup_screen.dart`)
- QR code display for authenticator app setup
- 6-digit code verification input
- Step-by-step instructions
- Verification and navigation to home

*MfaChallengeScreen* (`mfa_challenge_screen.dart`)
- MFA code input for returning users
- Support for different challenge types
- Verification and navigation to home

*HomeScreen* (`home/presentation/pages/home_screen.dart`)
- Protected screen requiring authentication
- User profile menu with logout
- Logout confirmation dialog
- Navigation to will creation

## Authentication Flow

### Login Flow

```
1. User enters email/password → AuthLoginRequested event
2. AuthBloc calls authRepository.login()
3. AuthRepositoryImpl calls API via ApiClient
4. API returns LoginResponse with login_step:

   Case A: MFA_SETUP (First-time user)
   → Save session to secure storage
   → Emit mfaSetupRequired state
   → Navigate to MfaSetupScreen
   → User scans QR code
   → User enters code → AuthMfaConfirmRequested event
   → API validates and returns tokens
   → Save tokens to secure storage
   → Emit authenticated state
   → Navigate to HomeScreen

   Case B: MFA_CHALLENGE (Returning user)
   → Save session to secure storage
   → Emit mfaChallengeRequired state
   → Navigate to MfaChallengeScreen
   → User enters code → AuthMfaConfirmRequested event
   → API validates and returns tokens
   → Save tokens to secure storage
   → Emit authenticated state
   → Navigate to HomeScreen

   Case C: COMPLETED (No MFA required)
   → Save tokens to secure storage
   → Emit authenticated state
   → Navigate to HomeScreen

5. Error cases:
   - Invalid credentials → Show error message
   - User not found → Show error message
   - User not active → Show error message
   - Network error → Show error message
```

### Token Management

**Access Token Flow:**
```
1. All authenticated API requests include: Authorization: Bearer <access_token>
2. On 401 Unauthorized:
   → ApiClient interceptor catches error
   → Attempts token refresh with refresh_token
   → If refresh succeeds:
     → Save new tokens
     → Retry original request
   → If refresh fails:
     → Clear session
     → Navigate to sign-in
```

### Logout Flow

```
1. User clicks logout → Show confirmation dialog
2. User confirms → AuthLogoutRequested event
3. AuthBloc calls authRepository.logout()
4. AuthRepositoryImpl:
   → Calls logout API endpoint
   → Clears all secure storage (even if API fails)
5. Emit unauthenticated state
6. Navigate to sign-in screen
```

## Security Features

1. **Secure Token Storage**
   - iOS: Keychain with first_unlock accessibility
   - Android: EncryptedSharedPreferences
   - Tokens never stored in plain text

2. **Automatic Token Refresh**
   - Transparent to the user
   - Handles expired access tokens
   - Retries failed requests after refresh

3. **Session Management**
   - Session data encrypted in secure storage
   - Automatic session clearing on logout
   - Auth state checked on app startup

4. **MFA Support**
   - TOTP-based authenticator apps
   - QR code generation for easy setup
   - Support for SMS-based MFA (ready to implement)

## Configuration

### API Base URL

Update the base URL in `lib/core/network/api_endpoints.dart`:

```dart
static const String baseUrl = 'https://your-api-domain.com';
```

### MFA Challenge Endpoint

If your API uses a different endpoint for MFA confirmation, update in `lib/core/network/api_endpoints.dart`:

```dart
static const String loginMfaConfirm = '/user/login/mfa/confirm';
```

## Error Handling

### API Error Responses

All API errors are caught and converted to appropriate exceptions:

```dart
try {
  final response = await apiClient.post(...);
} on UnauthorizedException catch (e) {
  // Handle 401
} on NotFoundException catch (e) {
  // Handle 404
} on NetworkException catch (e) {
  // Handle network issues
} on ApiException catch (e) {
  // Handle other API errors
}
```

### User-Facing Error Messages

Errors are displayed to users via SnackBars with appropriate messages:
- "Invalid credentials" → 401
- "User not found" → 404
- "User not active" → 403
- "Network error. Please check your connection" → Connection issues

## Testing

### Mock Login Credentials

For testing the complete flow, you can use these test credentials (if available on your backend):

```dart
Email: test@example.com
Password: Test@123
```

### Testing MFA Flow

1. Login with test credentials
2. If first-time user → Scan QR code with authenticator app
3. Enter 6-digit code from app
4. Should navigate to home screen

### Testing Token Refresh

The token refresh mechanism is automatically tested when access tokens expire. The ApiClient will:
1. Detect 401 response
2. Attempt refresh
3. Retry original request
4. Continue seamlessly (or logout if refresh fails)

## Dependencies

```yaml
dependencies:
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Networking
  dio: ^5.4.0
  
  # Storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.2
  
  # Navigation
  go_router: ^14.0.2
  
  # UI
  qr_flutter: ^4.1.0
  google_fonts: ^6.1.0
```

## Project Structure

```
lib/
├── core/
│   ├── network/
│   │   ├── api_client.dart          # Dio HTTP client
│   │   ├── api_endpoints.dart       # API endpoints
│   │   └── api_exceptions.dart      # Custom exceptions
│   ├── storage/
│   │   └── secure_storage_service.dart  # Secure storage
│   └── routes/
│       └── app_router.dart          # App navigation
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── auth_models.dart     # DTOs & models
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart # Repository interface
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       └── pages/
│   │           ├── sign_in_screen.dart
│   │           ├── mfa_setup_screen.dart
│   │           └── mfa_challenge_screen.dart
│   └── home/
│       └── presentation/
│           └── pages/
│               └── home_screen.dart     # Protected home screen
└── main.dart                            # App entry point
```

## Future Enhancements

1. **Biometric Authentication**
   - Add fingerprint/face recognition
   - Quick login without password

2. **Remember Me**
   - Optional persistent session
   - Configurable token expiry

3. **Social Login Integration**
   - Complete Google Sign-In implementation
   - Add Apple, Facebook, Twitter authentication

4. **Profile Management**
   - View/edit user profile
   - Change password
   - Manage MFA settings

5. **Session Timeout**
   - Automatic logout after inactivity
   - Configurable timeout duration

6. **Offline Support**
   - Cache user data
   - Queue API requests
   - Sync when online

## Troubleshooting

### Issue: "Invalid session" error
**Solution:** Clear app data and login again. Session tokens may have expired.

### Issue: QR code not scanning
**Solution:** Ensure authenticator app has camera permissions. Try manual code entry option.

### Issue: Token refresh fails repeatedly
**Solution:** Check if refresh token is expired. User needs to login again.

### Issue: API calls failing with network error
**Solution:** 
1. Check internet connection
2. Verify API base URL in `api_endpoints.dart`
3. Check if backend server is running

## Support

For API-related issues, contact the backend team with:
- User email
- Timestamp of the error
- Error message/response
- Auth flow step where error occurred
