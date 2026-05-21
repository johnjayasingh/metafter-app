import 'package:flutter/material.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/app_checkbox.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../will_creation/data/services/executor_checklist_service.dart';

/// A local-only checklist item (not tracked by the API).
class _LocalItem {
  final String id;
  final String label;

  const _LocalItem(this.id, this.label);
}

/// A section in the executor checklist.
class _ChecklistSection {
  final String title;
  final String? description;

  /// API-tracked items (persisted to server).
  final List<ExecutorChecklistItem> apiItems;

  /// Local-only items (in-memory only).
  final List<_LocalItem> localItems;

  /// Whether this section has a download button.
  final bool hasDownload;
  final String? downloadLabel;

  const _ChecklistSection({
    required this.title,
    this.description,
    this.apiItems = const [],
    this.localItems = const [],
    this.hasDownload = false,
    this.downloadLabel,
  });

  int get totalItems => apiItems.length + localItems.length;
}

class ExecutorChecklistScreen extends StatefulWidget {
  final String willId;
  final String executorName;
  final String testatorName;

  const ExecutorChecklistScreen({
    super.key,
    required this.willId,
    required this.executorName,
    required this.testatorName,
  });

  @override
  State<ExecutorChecklistScreen> createState() =>
      _ExecutorChecklistScreenState();
}

class _ExecutorChecklistScreenState extends State<ExecutorChecklistScreen> {
  final _service = ExecutorChecklistService();
  bool _isLoading = true;

  /// API-tracked item states (persisted to server).
  Map<ExecutorChecklistItem, bool> _apiChecked = {
    for (final item in ExecutorChecklistItem.values) item: false,
  };

  /// Local-only item states (in-memory only).
  final Map<String, bool> _localChecked = {};

  static const _sections = <_ChecklistSection>[
    _ChecklistSection(
      title: 'Locating and reviewing the will',
      apiItems: [
        ExecutorChecklistItem.locateDeceasedRecentWill,
        ExecutorChecklistItem.verifyWillValidity,
        ExecutorChecklistItem.understandInstructionAndWishes,
      ],
    ),
    _ChecklistSection(
      title: 'Applying for probate',
      apiItems: [
        ExecutorChecklistItem.determineProbateRequired,
        ExecutorChecklistItem.prepareLodgeProbateApplication,
        ExecutorChecklistItem.obtainProbateGrant,
      ],
      hasDownload: true,
      downloadLabel: 'Affidavit supporting probate application',
    ),
    _ChecklistSection(
      title: "Securing the estate's assets",
      apiItems: [
        ExecutorChecklistItem.realEstateProperty,
        ExecutorChecklistItem.bankAccounts,
        ExecutorChecklistItem.investments,
        ExecutorChecklistItem.personalBelongings,
        ExecutorChecklistItem.superannuationAndInsurancePolicies,
      ],
    ),
    _ChecklistSection(
      title: 'Paying debts and liabilities',
      localItems: [
        _LocalItem('mortgages-loans', 'Outstanding mortgages or loans'),
        _LocalItem('credit-card-debts', 'Credit card debts'),
        _LocalItem('utility-bills', 'Utility bills'),
        _LocalItem('funeral-expenses', 'Funeral expenses'),
        _LocalItem('tax-obligations',
            'Tax obligations (final income tax return, estate taxes)'),
        _LocalItem('notify-creditors',
            'Notify creditors and arrange necessary payments'),
        _LocalItem('selling-assets',
            'Consider selling assets where necessary to cover debts'),
      ],
    ),
    _ChecklistSection(
      title: 'Managing the estate',
      localItems: [
        _LocalItem('manage-properties',
            'Maintain and manage properties (e.g., insurance, rent, repairs)'),
        _LocalItem('ongoing-payments',
            'Ensure ongoing payments (e.g., utilities, rates) are made for the duration of the estate administration'),
      ],
    ),
    _ChecklistSection(
      title: 'Distributing the estate',
      description:
          '*not earlier than 6 months after the death of the testator',
      localItems: [
        _LocalItem('prepare-beneficiaries-list',
            'Prepare a list of beneficiaries as per the will'),
        _LocalItem('ensure-debts-paid',
            'Ensure all debts, taxes, and liabilities are paid before distribution'),
        _LocalItem('distribute-assets',
            'Distribute assets to beneficiaries according to the will'),
        _LocalItem('obtain-receipts',
            'Obtain receipts or acknowledgments from beneficiaries'),
      ],
    ),
    _ChecklistSection(
      title: 'Keeping records and reporting',
      localItems: [
        _LocalItem('maintain-records',
            'Maintain detailed records of all transactions related to the estate'),
        _LocalItem('prepare-account',
            'Prepare an account of the estate administration for beneficiaries'),
        _LocalItem('submit-accounting',
            'Where required, submit accounting to the court'),
      ],
    ),
    _ChecklistSection(
      title: 'Dealing with claims against the estate',
      localItems: [
        _LocalItem('notify-claimants',
            'Notify beneficiaries and potential claimants about the death'),
        _LocalItem('address-claims',
            'Address any claims or disputes from creditors or others (e.g., family provision claims)'),
        _LocalItem('seek-legal-advice',
            'Seek legal advice if the estate faces litigation'),
      ],
    ),
    _ChecklistSection(
      title: 'Finalising the estate',
      localItems: [
        _LocalItem('finalize-transactions',
            'Finalize all estate transactions (e.g., close bank accounts)'),
        _LocalItem('lodge-tax-returns',
            'Prepare and lodge final tax returns for the deceased and the estate'),
        _LocalItem('distribute-remaining-funds',
            'Distribute any remaining funds to beneficiaries after final expenses'),
      ],
    ),
    _ChecklistSection(
      title: 'Communicating with beneficiaries',
      localItems: [
        _LocalItem(
            'notify-entitlements', 'Notify beneficiaries of their entitlements'),
        _LocalItem('provide-updates',
            'Provide regular updates to beneficiaries on the progress of the estate administration'),
        _LocalItem('address-questions',
            'Address any questions or concerns raised by beneficiaries'),
      ],
    ),
    _ChecklistSection(
      title: 'Additional considerations',
      localItems: [
        _LocalItem('consult-professionals',
            'Consult with legal or financial professionals as needed'),
        _LocalItem('keep-documents',
            'Keep copies of all relevant documents and correspondence'),
        _LocalItem('comply-laws',
            'Ensure all actions comply with the Succession Act 1981 and other relevant laws'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    final result = await _service.getChecklist(widget.willId);
    if (mounted) {
      setState(() {
        _apiChecked = result;
        _isLoading = false;
      });
    }
  }

  int get _totalItems =>
      _sections.fold(0, (sum, s) => sum + s.totalItems);

  int get _checkedCount {
    int count = _apiChecked.values.where((v) => v).length;
    count += _localChecked.values.where((v) => v).length;
    return count;
  }

  double get _progress => _totalItems > 0 ? _checkedCount / _totalItems : 0.0;

  void _onApiItemToggled(ExecutorChecklistItem item, bool newValue) {
    setState(() => _apiChecked[item] = newValue);
    _service
        .toggleChecklistItem(
      willId: widget.willId,
      item: item,
      isSelected: newValue,
    )
        .then((success) {
      if (!success && mounted) {
        setState(() => _apiChecked[item] = !newValue);
        SnackBarUtils.showError(context, 'Failed to update checklist item');
      }
    });
  }

  void _onLocalItemToggled(String id, bool newValue) {
    setState(() => _localChecked[id] = newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Executor checklist', style: AppTextStyles.questionTitle),
        centerTitle: false,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _sections.length,
                    itemBuilder: (context, index) =>
                        _buildSection(_sections[index]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final percent = (_progress * 100).round();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryGreen.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${widget.executorName}',
              style: AppTextStyles.questionTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              "Here's your step-by-step guide to manage ${widget.testatorName}'s estate with ease.",
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGray,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '$percent%',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 8,
                      backgroundColor: AppColors.borderGray,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '100%',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(_ChecklistSection section) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: AppTextStyles.questionTitle.copyWith(fontSize: 16),
            ),
            if (section.description != null) ...[
              const SizedBox(height: 4),
              Text(
                section.description!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textGray,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            // API-tracked items
            ...section.apiItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCheckbox(
                    value: _apiChecked[item] ?? false,
                    label: item.label,
                    onChanged: (v) => _onApiItemToggled(item, v ?? false),
                  ),
                )),
            // Local-only items
            ...section.localItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCheckbox(
                    value: _localChecked[item.id] ?? false,
                    label: item.label,
                    onChanged: (v) =>
                        _onLocalItemToggled(item.id, v ?? false),
                  ),
                )),
            // Download template button
            if (section.hasDownload && section.downloadLabel != null) ...[
              const Divider(height: 24),
              Text(
                'Download template',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement download
                },
                icon: const Icon(Icons.download, size: 18),
                label: Text(
                  section.downloadLabel!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.borderGray),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
