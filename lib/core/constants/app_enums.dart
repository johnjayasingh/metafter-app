/// Centralized enums for the application.
/// Replaces hardcoded strings with type-safe values.

// ==================== Beneficiary Type ====================

/// Type discriminator used in allocation items and backup beneficiaries.
/// Maps to the API field `beneficiary_type`.
enum BeneficiaryType {
  beneficiary('BENEFICIARY'),
  charity('CHARITY');

  final String value;
  const BeneficiaryType(this.value);

  /// Parse from API string, defaulting to [beneficiary].
  static BeneficiaryType fromString(String? value) {
    return BeneficiaryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BeneficiaryType.beneficiary,
    );
  }
}

// ==================== Allocation Notify For ====================

/// Determines who should be notified / receive the allocation when the
/// primary beneficiary cannot.
/// Maps to `allocation_notify_for` in the API.
enum AllocationNotifyFor {
  myChildren('MY_CHILDREN'),
  divideEqually('DIVIDE_EQUALLY'),
  specificBeneficiaries('SPECIFIC_BENEFICIARIES'),
  toCharities('SPECIFIC_CHARITIES');

  final String value;
  const AllocationNotifyFor(this.value);

  static AllocationNotifyFor fromString(String? value) {
    return AllocationNotifyFor.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AllocationNotifyFor.specificBeneficiaries,
    );
  }
}

// ==================== Gift Type ====================

/// The kind of gift being left: a physical / specific item or money.
/// Maps to `gift_type` in the API.
enum GiftType {
  specificItem('specific_item'),
  money('money');

  final String value;
  const GiftType(this.value);

  static GiftType? fromString(String? value) {
    if (value == null) return null;
    return GiftType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GiftType.specificItem,
    );
  }
}

// ==================== Dependent Type ====================

/// The type of dependent being added.
enum DependentType {
  major('major'),
  minor('minor'),
  pet('pet');

  final String value;
  const DependentType(this.value);

  static DependentType? fromString(String? value) {
    if (value == null) return null;
    return DependentType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DependentType.minor,
    );
  }
}

// ==================== Will User Role ====================

/// Roles assigned to users associated with a will.
/// Used when fetching notification recipients, etc.
enum WillUserRole {
  executor('EXECUTOR'),
  beneficiary('BENEFICIARY');

  final String value;
  const WillUserRole(this.value);

  String get displayName {
    switch (this) {
      case WillUserRole.executor:
        return 'Executor';
      case WillUserRole.beneficiary:
        return 'Beneficiary';
    }
  }

  static WillUserRole fromString(String? value) {
    return WillUserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WillUserRole.beneficiary,
    );
  }
}

// ==================== Executor Checklist Items ====================

/// Items in the executor checklist.
/// Maps to the `ExecutorChecklistItems` enum in the API.
enum ExecutorChecklistItem {
  locateDeceasedRecentWill('LOCATE_DECEASED_RECENT_WILL'),
  verifyWillValidity('VERIFY_WILL_VALIDITY'),
  understandInstructionAndWishes('UNDERSTAND_INSTRUCTION_AND_WISHES'),
  determineProbateRequired('DETERMINE_PROBATE_REQUIRED'),
  prepareLodgeProbateApplication('PREPARE_LODGE_PROBATE_APPLICATION'),
  obtainProbateGrant('OBTAIN_PROBATE_GRANT'),
  realEstateProperty('REAL_ESTATE_PROPERTY'),
  bankAccounts('BANK_ACCOUNTS'),
  investments('INVESTMENTS'),
  personalBelongings('PERSONAL_BELONGINGS'),
  superannuationAndInsurancePolicies('SUPERANNUATION_AND_INSURANCE_POLICIES');

  final String value;
  const ExecutorChecklistItem(this.value);

  /// Human-readable label for UI display.
  String get label {
    switch (this) {
      case ExecutorChecklistItem.locateDeceasedRecentWill:
        return "Locate the deceased's most recent will";
      case ExecutorChecklistItem.verifyWillValidity:
        return "Verify the will's validity";
      case ExecutorChecklistItem.understandInstructionAndWishes:
        return 'Understand the instructions and wishes outlined in the will';
      case ExecutorChecklistItem.determineProbateRequired:
        return 'Determine if probate is required';
      case ExecutorChecklistItem.prepareLodgeProbateApplication:
        return 'Prepare and lodge a probate application with the Supreme Court';
      case ExecutorChecklistItem.obtainProbateGrant:
        return 'Obtain the grant of probate';
      case ExecutorChecklistItem.realEstateProperty:
        return 'Real estate property';
      case ExecutorChecklistItem.bankAccounts:
        return 'Bank accounts';
      case ExecutorChecklistItem.investments:
        return 'Investments';
      case ExecutorChecklistItem.personalBelongings:
        return 'Personal belongings';
      case ExecutorChecklistItem.superannuationAndInsurancePolicies:
        return 'Superannuation and insurance policies';
    }
  }

  static ExecutorChecklistItem? fromString(String? value) {
    if (value == null) return null;
    return ExecutorChecklistItem.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ExecutorChecklistItem.locateDeceasedRecentWill,
    );
  }
}
