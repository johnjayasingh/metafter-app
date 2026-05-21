# Form Widget Migration Guide

This guide explains how to migrate from inline form field definitions to the centralized form widgets.

## Quick Start

Import the form widgets library:

```dart
import 'package:digitalwill/core/widgets/form/form_widgets.dart';
import 'package:digitalwill/core/constants/form_constants.dart';
```

## Migration Examples

### 1. Text Fields

**Before (inline):**
```dart
Widget _buildTextField({
  required TextEditingController controller,
  required String hintText,
  TextInputType? keyboardType,
  IconData? suffixIcon,
  List<TextInputFormatter>? inputFormatters,
  String? Function(String?)? validator,
  bool isRequired = false,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: [
      NoLeadingSpaceFormatter(),
      ...?inputFormatters,
    ],
    validator: validator ?? (isRequired ? (value) {
      if (value == null || value.trim().isEmpty) {
        return 'This field is required';
      }
      return null;
    } : null),
    style: AppTextStyles.inputText,
    decoration: InputDecoration(
      labelText: isRequired ? '$hintText *' : hintText,
      labelStyle: AppTextStyles.inputLabel,
      floatingLabelStyle: AppTextStyles.inputLabelFloating,
      // ... 20+ more lines of decoration
    ),
  );
}

// Usage:
_buildTextField(
  controller: _lastNameController,
  hintText: 'Last name',
  isRequired: true,
)
```

**After (centralized):**
```dart
AppTextField(
  controller: _lastNameController,
  label: 'Last name',
  isRequired: true,
)
```

### 2. Email Fields

**Before:**
```dart
_buildTextField(
  controller: _emailController,
  hintText: 'Email address',
  keyboardType: TextInputType.emailAddress,
  isRequired: true,
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter email address';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  },
)
```

**After:**
```dart
AppEmailField(
  controller: _emailController,
  isRequired: true,
)
```

### 3. Phone Input with Country Code

**Before:**
```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Container(
      width: 90,
      height: 48,
      decoration: AppDecorations.card,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountryCode,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          items: ['+61', '+96', '+1', '+44', '+91'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: AppTextStyles.inputText),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => _selectedCountryCode = newValue);
            }
          },
        ),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: _buildTextField(
        controller: _phoneController,
        hintText: 'Phone number',
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        isRequired: true,
      ),
    ),
  ],
)
```

**After:**
```dart
AppPhoneInput(
  controller: _phoneController,
  countryCode: _selectedCountryCode,
  onCountryCodeChanged: (code) => setState(() => _selectedCountryCode = code),
  isRequired: true,
)
```

### 4. Date Picker Field

**Before:**
```dart
Future<void> _selectDate() async {
  final now = DateTime.now();
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime(now.year - 30, now.month, now.day),
    firstDate: DateTime(1900),
    lastDate: now,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryGreen,
            onPrimary: AppColors.backgroundWhite,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      );
    },
  );
  if (picked != null) {
    setState(() {
      _dobController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    });
  }
}

// Usage:
GestureDetector(
  onTap: _selectDate,
  child: AbsorbPointer(
    child: _buildTextField(
      controller: _dobController,
      hintText: 'DOB',
      suffixIcon: Icons.calendar_today,
      isRequired: true,
    ),
  ),
)
```

**After:**
```dart
// For DOB with age constraints (minor/adult)
AppDobField(
  controller: _dobController,
  isRequired: true,
  isMinor: _isMinor == 'yes',
  onDateSelected: (date) {
    // Optional: handle date selection
  },
)

// For general date picker
AppDatePickerField(
  controller: _dateController,
  label: 'Select date',
  isRequired: true,
)
```

### 5. Dropdown

**Before:**
```dart
Widget _buildDropdown({
  required String? value,
  required String hint,
  required List<String> items,
  required ValueChanged<String?> onChanged,
  String Function(String)? displayName,
}) {
  return Container(
    height: 48,
    decoration: AppDecorations.card,
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        hint: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(hint, style: AppTextStyles.inputHint),
        ),
        // ... more configuration
      ),
    ),
  );
}

_buildDropdown(
  value: _selectedRelation,
  hint: 'Relation',
  items: _relations,
  displayName: _getRelationDisplayName,
  onChanged: (value) => setState(() => _selectedRelation = value),
)
```

**After:**
```dart
AppDropdown<String>(
  value: _selectedRelation,
  label: 'Relation',
  items: FormConstants.adultRelations,
  displayName: FormConstants.getRelationDisplayName,
  onChanged: (value) => setState(() => _selectedRelation = value),
)
```

### 6. Buttons

**Before:**
```dart
Container(
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: AppColors.backgroundWhite,
    boxShadow: AppDecorations.shadowLight,
  ),
  child: SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _isSubmitting ? null : _submitForm,
      style: _isSubmitting ? AppDecorations.buttonDisabled : AppDecorations.buttonPrimary,
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.backgroundWhite),
              ),
            )
          : Text('Add', style: AppTextStyles.buttonPrimary),
    ),
  ),
)
```

**After:**
```dart
AppBottomActionBar(
  child: AppPrimaryButton(
    text: 'Add',
    onPressed: _submitForm,
    isLoading: _isSubmitting,
  ),
)
```

### 7. Using Form Constants

**Before:**
```dart
// Hardcoded in each file:
final List<String> _minorRelations = [
  'SON',
  'DAUGHTER',
  'STEP_SON',
  // ...
];

String _getRelationDisplayName(String relation) {
  switch (relation) {
    case 'SON': return 'Son';
    // ...
  }
}
```

**After:**
```dart
// Use centralized constants:
FormConstants.minorRelations
FormConstants.adultRelations
FormConstants.getRelationDisplayName(relation)
FormConstants.countryCodes
FormConstants.defaultCountryCode
```

## Phone Number Utilities

```dart
// Combine country code and phone number:
final fullPhone = AppPhoneInput.combinePhoneNumber(
  _selectedCountryCode,
  _phoneController.text,
);
// Result: '+61 412345678'

// Parse a combined phone number:
final (countryCode, localNumber) = AppPhoneInput.parsePhoneNumber('+61 412345678');
// countryCode: '+61', localNumber: '412345678'
```

## Date Utilities

```dart
// Format date for display (DD/MM/YYYY):
final displayDate = AppDatePickerField.formatDate(DateTime.now());

// Format date for API (YYYY-MM-DD):
final apiDate = AppDatePickerField.formatDateForApi(DateTime.now());

// Convert API date to display format:
final display = AppDatePickerField.formatApiDateForDisplay('2024-01-15');
// Result: '15/01/2024'

// Convert display date to API format:
final api = AppDatePickerField.formatDisplayDateForApi('15/01/2024');
// Result: '2024-01-15'
```

## Files to Migrate

Based on the analysis, here are the priority files to migrate:

### High Priority (Multiple Duplicated Patterns)
1. `add_personal_executor_screen.dart` - Has `_buildTextField`, phone input, date picker
2. `add_personal_lawyer_screen.dart` - Has `_buildTextField`, phone input
3. `add_gift_recipient_screen.dart` - Has `_buildFloatingLabelTextField`, phone input
4. `add_witness_screen.dart` - Has `_buildTextField`, phone input
5. `add_dependent_screen.dart` - Has phone input, date picker

### Medium Priority (Some Inline Styles)
6. `basic_details_screen.dart` - Raw TextFormField usage
7. `add_asset_screen.dart` - Dropdown patterns
8. `charity_selection_screen.dart` - Dropdown patterns

### Lower Priority (Mostly Consistent)
9. Widget files in `presentation/widgets/`
10. Other feature screens

## Benefits of Migration

1. **Consistency**: All forms look and behave the same way
2. **Maintainability**: Change styling in one place, applied everywhere
3. **Less Code**: ~50-70% reduction in form-related code
4. **Type Safety**: Built-in validators and formatters
5. **Bug Prevention**: Centralized phone/date handling eliminates format inconsistencies
