# Agent Instructions for Digital Will Flutter Project

This document provides guidelines for AI agents and developers working on the Digital Will Flutter application. Follow these instructions to maintain code consistency and use centralized components.

## Table of Contents

- [Centralized UI Components](#centralized-ui-components)
- [Theme System](#theme-system)
- [Form Widgets](#form-widgets)
- [Button Components](#button-components)
- [State Management](#state-management)
- [Best Practices](#best-practices)

---

## Centralized UI Components

### Import Statement

For all form-related widgets, use a single import:

```dart
import '../../../../core/widgets/form/form_widgets.dart';
```

This barrel export provides access to all centralized form widgets:
- `AppTextField`
- `AppDropdownFormField`
- `AppPhoneInputField`
- `AppDatePickerField`
- `AppPrimaryButton`
- `AppSecondaryButton`
- `AppCancelButton`
- `AppTextButton`
- `AppBottomActionBar`
- `AppRadioOption`

---

## Theme System

### Colors

Always use `AppColors` for consistent theming:

```dart
import '../../../../core/theme/app_colors.dart';

// Usage examples:
Container(color: AppColors.primaryGreen)
Text('Hello', style: TextStyle(color: AppColors.textPrimary))
Border.all(color: AppColors.borderGray)
```

### Text Styles

Always use `AppTextStyles` for typography:

```dart
import '../../../../core/theme/app_text_styles.dart';

// Available styles:
AppTextStyles.pageTitle       // Page headers
AppTextStyles.sectionTitle    // Section headers
AppTextStyles.questionTitle   // Question/card titles
AppTextStyles.cardTitle       // Card headers
AppTextStyles.subtitle        // Subtitles
AppTextStyles.bodyMedium      // Body text
AppTextStyles.bodySmall       // Small body text
AppTextStyles.itemLabel       // List item labels
AppTextStyles.labelSmall      // Small labels/tags
AppTextStyles.buttonPrimary   // Primary button text
AppTextStyles.buttonSecondary // Secondary button text
```

### Decorations

Use `AppDecorations` for consistent input field styling:

```dart
import '../../../../core/theme/app_decorations.dart';

// For input fields:
AppDecorations.inputDecoration(labelText: 'Email')
AppDecorations.inputDecorationAlt(labelText: 'Phone')

// For buttons:
AppDecorations.primaryButtonStyle
AppDecorations.secondaryButtonStyle
AppDecorations.cancelButtonStyle
```

---

## Form Widgets

### AppTextField

Use instead of raw `TextFormField`:

```dart
AppTextField(
  controller: _nameController,
  labelText: 'Full Name',
  hintText: 'Enter your full name',
  validator: (value) => value?.isEmpty == true ? 'Required' : null,
  keyboardType: TextInputType.text,
  textCapitalization: TextCapitalization.words,
)
```

**NEVER use** raw `TextFormField` in new code.

### AppDropdownFormField

Use instead of raw `DropdownButtonFormField`:

```dart
AppDropdownFormField<String>(
  value: _selectedState,
  labelText: 'State',
  hintText: 'Select state',
  items: FormConstants.australianStates.map((state) => 
    DropdownMenuItem(value: state, child: Text(state))
  ).toList(),
  onChanged: (value) => setState(() => _selectedState = value),
  validator: (value) => value == null ? 'Required' : null,
)
```

### AppPhoneInputField

Use for phone number inputs:

```dart
AppPhoneInputField(
  controller: _phoneController,
  selectedCountryCode: _selectedCountryCode,
  onCountryCodeChanged: (code) => setState(() => _selectedCountryCode = code),
  labelText: 'Phone Number',
)
```

### AppDatePickerField

Use for date inputs:

```dart
AppDatePickerField(
  controller: _dobController,
  selectedDate: _selectedDate,
  labelText: 'Date of Birth',
  onDateSelected: (date) => setState(() {
    _selectedDate = date;
    _dobController.text = DateFormat('dd/MM/yyyy').format(date);
  }),
  firstDate: DateTime(1900),
  lastDate: DateTime.now(),
)
```

### AppRadioOption

Use for radio button selections:

```dart
AppRadioOption<String>(
  value: 'yes',
  groupValue: _selectedValue,
  label: 'Yes',
  onChanged: (value) => setState(() => _selectedValue = value),
)
```

---

## Button Components

### AppPrimaryButton

Primary action button (green filled):

```dart
AppPrimaryButton(
  text: 'Continue',
  onPressed: _onContinue,
  isLoading: _isLoading,
  leadingIcon: Icons.arrow_forward,  // Optional
  fullWidth: true,                    // Default: true
)
```

### AppSecondaryButton

Secondary action button (outlined):

```dart
AppSecondaryButton(
  text: 'Previous',
  onPressed: _onPrevious,
  leadingIcon: Icons.arrow_back,
  trailingIcon: Icons.arrow_forward,  // Optional
)
```

### AppCancelButton

Cancel/destructive button (red outlined):

```dart
AppCancelButton(
  text: 'Cancel',
  onPressed: _onCancel,
)
```

### AppTextButton

Text-only button:

```dart
AppTextButton(
  text: 'Skip',
  onPressed: _onSkip,
)
```

### AppBottomActionBar

Bottom navigation with Previous/Next buttons:

```dart
AppBottomActionBar(
  child: Row(
    children: [
      Expanded(
        child: AppSecondaryButton(
          text: 'Previous',
          leadingIcon: Icons.arrow_back,
          onPressed: _onPrevious,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: AppPrimaryButton(
          text: 'Next',
          trailingIcon: Icons.arrow_forward,
          onPressed: _onNext,
          isLoading: _isLoading,
        ),
      ),
    ],
  ),
)
```

**Important**: Both buttons should have equal width (use `Expanded` without `flex`).

---

## State Management

### BLoC Pattern

Use flutter_bloc for state management:

```dart
// Events
context.read<WillBloc>().add(const GetAllWillsEvent());

// Listen to state changes
BlocBuilder<WillBloc, WillState>(
  builder: (context, state) {
    if (state is WillLoading) return CircularProgressIndicator();
    if (state is AllWillsLoaded) return _buildContent(state.wills);
    if (state is WillError) return _buildError(state.message);
    return SizedBox.shrink();
  },
)
```

### Will Events Available

```dart
// My Wills
GetAllWillsEvent()              // Load user's own wills
RefreshWillsEvent()             // Silent refresh (no loading state)
GetInvitedWillsEvent()          // Load wills where user is invited
RefreshInvitedWillsEvent()      // Silent refresh for invited wills
```

---

## Best Practices

### 1. Never Use Inline Styles

❌ **Don't do this:**
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Name',
    border: OutlineInputBorder(),
    // ... inline styles
  ),
)
```

✅ **Do this:**
```dart
AppTextField(
  labelText: 'Name',
  controller: _nameController,
)
```

### 2. Use FormConstants for Common Data

```dart
import '../../../../core/constants/form_constants.dart';

// Available constants:
FormConstants.countryCodes        // List of country codes with flags
FormConstants.australianStates    // Australian state/territory list
FormConstants.relationships       // Family relationship options
```

### 3. Consistent Button Sizing

For Previous/Next button pairs, ensure equal sizing:

```dart
Row(
  children: [
    Expanded(  // NO flex parameter
      child: AppSecondaryButton(text: 'Previous', ...),
    ),
    const SizedBox(width: 16),
    Expanded(  // NO flex parameter
      child: AppPrimaryButton(text: 'Next', ...),
    ),
  ],
)
```

### 4. Error Handling

Use consistent error state widgets:

```dart
if (state is WillError) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Error loading data', style: AppTextStyles.questionTitle),
        const SizedBox(height: 8),
        Text(state.message, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 16),
        AppPrimaryButton(
          text: 'Retry',
          fullWidth: false,
          onPressed: () => context.read<WillBloc>().add(const GetAllWillsEvent()),
        ),
      ],
    ),
  );
}
```

### 5. Loading States

Use the built-in `isLoading` property on buttons:

```dart
AppPrimaryButton(
  text: 'Submit',
  isLoading: _isSubmitting,
  onPressed: _isSubmitting ? null : _onSubmit,
)
```

### 6. Navigation

Use go_router for navigation:

```dart
import '../../../../core/routes/app_router.dart';

// Navigate
context.push(AppRouter.basicDetails);

// Go back
context.pop();

// Replace
context.go(AppRouter.home);
```

---

## File Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── form_constants.dart      # Common dropdown options
│   ├── theme/
│   │   ├── app_colors.dart          # Color palette
│   │   ├── app_text_styles.dart     # Typography
│   │   └── app_decorations.dart     # Input/button decorations
│   ├── widgets/
│   │   └── form/
│   │       ├── form_widgets.dart    # Barrel export
│   │       ├── app_text_field.dart
│   │       ├── app_dropdown.dart
│   │       ├── app_phone_input.dart
│   │       ├── app_date_picker_field.dart
│   │       ├── app_button.dart
│   │       └── app_radio_option.dart
│   └── routes/
│       └── app_router.dart          # Route definitions
├── features/
│   └── [feature_name]/
│       ├── data/
│       ├── domain/
│       └── presentation/
│           ├── bloc/
│           ├── pages/
│           └── widgets/
```

---

## Quick Reference

| Old Pattern | New Pattern |
|------------|-------------|
| `TextFormField(...)` | `AppTextField(...)` |
| `DropdownButtonFormField(...)` | `AppDropdownFormField(...)` |
| `ElevatedButton(...)` | `AppPrimaryButton(...)` |
| `OutlinedButton(...)` | `AppSecondaryButton(...)` |
| `TextButton(...)` | `AppTextButton(...)` |
| `Color(0xFF...)` | `AppColors.primaryGreen` |
| `TextStyle(...)` | `AppTextStyles.bodyMedium` |
| `InputDecoration(...)` | `AppDecorations.inputDecoration(...)` |

---

## Checklist Before Submitting Code

- [ ] Used centralized form widgets (no raw TextFormField/DropdownButtonFormField)
- [ ] Used AppColors for all colors
- [ ] Used AppTextStyles for all text styling
- [ ] Used AppPrimaryButton/AppSecondaryButton for buttons
- [ ] Button pairs have equal sizing (no flex parameter)
- [ ] Used FormConstants for dropdown options
- [ ] Added proper error handling with retry buttons
- [ ] Used isLoading property for async operations
- [ ] Imported from barrel export files where available
