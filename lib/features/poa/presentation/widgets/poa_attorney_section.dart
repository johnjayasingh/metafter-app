import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../will_creation/presentation/widgets/select_recipient_bottom_sheet.dart';
import '../../data/models/poa_models.dart';
import '../../data/services/poa_service.dart';
import '../screens/poa_attorneys_screen.dart';

/// Self-contained attorney management section for POA screens.
///
/// Handles loading, adding, editing, and deleting attorneys of a given
/// [AttorneyType] via [PoaService]. The parent is notified of list changes
/// through [onChanged] so it can include the data when navigating.
///
/// Usage:
/// ```dart
/// PoaAttorneySection(
///   type: AttorneyType.PRIMARY,
///   title: 'Attorney(s)',
///   addButtonText: '+ Add Attorney',
///   onChanged: (list) => _attorneys = list,
/// )
/// ```
class PoaAttorneySection extends StatefulWidget {
  final AttorneyType type;
  final String title;
  final bool isOptional;
  final String addButtonText;
  final ValueChanged<List<PoaPersonData>> onChanged;

  /// When set, hides add/select buttons once the list reaches this count.
  final int? maxPersons;

  const PoaAttorneySection({
    super.key,
    required this.type,
    required this.title,
    this.isOptional = false,
    required this.addButtonText,
    required this.onChanged,
    this.maxPersons,
  });

  @override
  State<PoaAttorneySection> createState() => _PoaAttorneySectionState();
}

class _PoaAttorneySectionState extends State<PoaAttorneySection> {
  final PoaService _poaService = PoaService();
  List<PoaPersonData> _persons = [];
  List<RecipientInfo> _previousPeople = [];
  bool _isOperationInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadPersons();
    _loadPreviousPeople();
  }

  Future<void> _loadPersons() async {
    final persons = await _poaService.getAttorneysByType(widget.type);
    if (!mounted) return;
    setState(() => _persons = persons);
    widget.onChanged(_persons);
  }

  Future<void> _loadPreviousPeople() async {
    // Load from both will-people AND existing POA attorneys so that the
    // "Select previously added" sheet is never empty when attorneys exist.
    final results = await Future.wait([
      _poaService.getWillPeople(),
      _poaService.getAttorneysForPoa(),
    ]);
    if (!mounted) return;

    final willPersons = results[0] as List<Map<String, dynamic>>;
    final poaAttorneys = results[1] as List<PoaPersonData>;

    final List<RecipientInfo> combined = [];
    final Set<String> seen = {};

    // Will people first
    for (final p in willPersons) {
      if (p['first_name'] == null && p['full_name'] == null) continue;
      final firstName = p['first_name'] as String? ?? '';
      final lastName = p['last_name'] as String? ?? '';
      final key = '${firstName.toLowerCase()}_${lastName.toLowerCase()}';
      if (seen.contains(key)) continue;
      seen.add(key);
      combined.add(RecipientInfo(
        id: p['id']?.toString() ?? '',
        firstName: firstName,
        middleName: p['middle_name'] as String?,
        lastName: lastName,
        email: p['email'] as String?,
        mobile: p['phone'] as String?,
        address: p['address'] as String?,
      ));
    }

    // POA attorneys (from any type)
    for (final a in poaAttorneys) {
      final key =
          '${a.firstName.toLowerCase()}_${a.lastName.toLowerCase()}';
      if (seen.contains(key)) continue;
      seen.add(key);
      combined.add(RecipientInfo(
        id: a.id,
        firstName: a.firstName,
        middleName: a.middleName,
        lastName: a.lastName,
        email: a.email,
        mobile: a.phone,
        address: a.address,
      ));
    }

    setState(() => _previousPeople = combined);
  }

  Future<void> _showSelectPreviousSheet() async {
    final selected = await showModalBottomSheet<RecipientInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectRecipientBottomSheet(
        recipients: _previousPeople,
        title: 'Select previously added',
        subtitle: 'Select from previously added persons',
        emptyMessage:
            'No previously added persons found.\nTap "${widget.addButtonText}" to add one.',
      ),
    );
    if (selected != null && mounted) {
      final person = PoaPersonData(
        id: selected.id,
        firstName: selected.firstName,
        middleName: selected.middleName,
        lastName: selected.lastName,
        role: widget.type.displayLabel,
        email: selected.email,
        phone: selected.mobile,
        relation: selected.relation,
        address: selected.address,
      );
      setState(() => _isOperationInProgress = true);
      final response = await _poaService.createAttorneyForPoa(
        person,
        type: widget.type,
      );
      if (!mounted) return;
      if (response.isSuccess) {
        await _loadPersons();
      } else {
        SnackBarUtils.showError(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Failed to add ${widget.type.displayLabel.toLowerCase()}',
        );
      }
      setState(() => _isOperationInProgress = false);
    }
  }

  Future<void> _addPerson() async {
    final result = await context.push<PoaPersonData>(
      AppRouter.poaAddAttorney,
      extra: widget.type == AttorneyType.PRIMARY
          ? null
          : PoaPersonData(
              id: '',
              firstName: '',
              lastName: '',
              role: widget.type.displayLabel,
            ),
    );
    if (result != null && mounted) {
      setState(() => _isOperationInProgress = true);
      final response = await _poaService.createAttorneyForPoa(
        result,
        type: widget.type,
      );
      if (!mounted) return;
      if (response.isSuccess) {
        await _loadPersons();
      } else {
        SnackBarUtils.showError(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Failed to add ${widget.type.displayLabel.toLowerCase()}',
        );
      }
      setState(() => _isOperationInProgress = false);
    }
  }

  Future<void> _editPerson(int index) async {
    final updated = await context.push<PoaPersonData>(
      AppRouter.poaAddAttorney,
      extra: _persons[index],
    );
    if (updated != null && mounted) {
      setState(() => _isOperationInProgress = true);
      final response = updated.attorneyId != null
          ? await _poaService.updateAttorneyForPoa(updated, type: widget.type)
          : await _poaService.createAttorneyForPoa(updated, type: widget.type);
      if (!mounted) return;
      if (response.isSuccess) {
        await _loadPersons();
      } else {
        SnackBarUtils.showError(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Failed to update ${widget.type.displayLabel.toLowerCase()}',
        );
      }
      setState(() => _isOperationInProgress = false);
    }
  }

  Future<void> _removePerson(int index) async {
    final person = _persons[index];
    if (person.attorneyPoaId == null) {
      setState(() => _persons.removeAt(index));
      widget.onChanged(_persons);
      return;
    }
    setState(() => _isOperationInProgress = true);
    final response =
        await _poaService.deleteAttorneyForPoa(person.attorneyPoaId!);
    if (!mounted) return;
    if (response.isSuccess) {
      await _loadPersons();
    } else {
      SnackBarUtils.showError(
        context,
        'Failed to remove ${widget.type.displayLabel.toLowerCase()}',
      );
    }
    setState(() => _isOperationInProgress = false);
  }

  bool get _isAtLimit =>
      widget.maxPersons != null && _persons.length >= widget.maxPersons!;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        if (widget.isOptional)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${widget.title} ',
                style: AppTextStyles.pageTitle,
              ),
              Text(
                '(optional)',
                style: AppTextStyles.pageTitle.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          )
        else
          Text(widget.title, style: AppTextStyles.pageTitle),
        const SizedBox(height: 24),

        // Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLightGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your selection will show up here',
                style: AppTextStyles.instructionSmall,
              ),
              const SizedBox(height: 12),

              // Select previously added row (hidden at limit)
              if (!_isAtLimit)
                InkWell(
                  onTap: _isOperationInProgress ? null : _showSelectPreviousSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderGray),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select previously added',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

              // Person cards
              if (_persons.isNotEmpty) ...[
                const SizedBox(height: 12),
                ..._persons.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PoaPersonCard(
                          person: entry.value,
                          onEdit: _isOperationInProgress
                              ? () {}
                              : () => _editPerson(entry.key),
                          onDelete: _isOperationInProgress
                              ? () {}
                              : () => _removePerson(entry.key),
                          showDelete: widget.maxPersons == null,
                        ),
                      ),
                    ),
              ],

              // Add button (hidden at limit)
              if (!_isAtLimit) ...[
                const SizedBox(height: 12),
                AppPrimaryButton(
                  text: widget.addButtonText,
                  onPressed: _isOperationInProgress ? null : _addPerson,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
