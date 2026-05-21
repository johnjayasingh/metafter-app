import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../probate/data/services/probate_service.dart';

class ProbateTab extends StatefulWidget {
  const ProbateTab({super.key});

  @override
  State<ProbateTab> createState() => _ProbateTabState();
}

class _ProbateTabState extends State<ProbateTab>
    with WidgetsBindingObserver, RouteAware {
  final ProbateService _probateService = ProbateService();

  List<ProbateSummary> _probates = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProbates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      AppRouter.routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _loadProbates();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadProbates();
    }
  }

  @override
  void dispose() {
    AppRouter.routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadProbates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final results = await _probateService.getProbateRequests();

    if (!mounted) return;
    setState(() {
      _probates = results;
      _isLoading = false;
    });
  }

  void _navigateToCreateProbate() async {
    await context.push(AppRouter.probateRequest);
    if (mounted) _loadProbates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: SvgPicture.asset(
            'assets/images/logo_icon.svg',
            width: 33,
            height: 25,
          ),
        ),
        title: Row(
          children: [Text('Probate', style: AppTextStyles.pageTitle)],
        ),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        actions: [
          // Show add button only when there are existing probates
          if (_probates.isNotEmpty)
            IconButton(
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, size: 20, color: Colors.white),
              ),
              onPressed: _navigateToCreateProbate,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderGray, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              onPressed: () => context.push(AppRouter.notifications),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _probates.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _probates.isEmpty) {
      return _buildErrorState(_error!);
    }

    if (_probates.isEmpty) {
      return _buildEmptyState();
    }

    return _buildProbatesList(_probates);
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error loading probate requests',
              style: AppTextStyles.questionTitle),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            text: 'Retry',
            fullWidth: false,
            onPressed: _loadProbates,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundLightGray4,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(
                'Request probate',
                style: AppTextStyles.pageTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Probate confirms the will in court and allows you to act as the executor.',
                  style: AppTextStyles.subtitle,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // Image section
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/probate_banner.png',
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.contain,
                    ),
                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.backgroundLightGray4.withValues(
                                alpha: 0.3,
                              ),
                              AppColors.backgroundLightGray4.withValues(
                                alpha: 0.5,
                              ),
                              AppColors.backgroundLightGray4,
                            ],
                            stops: const [0.0, 0.3, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Button
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: AppPrimaryButton(
                        text: 'Start probate request',
                        onPressed: _navigateToCreateProbate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProbatesList(List<ProbateSummary> probates) {
    final sorted = List<ProbateSummary>.from(probates)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final probate = sorted[index];
        return _buildProbateCard(probate);
      },
    );
  }

  Widget _buildProbateCard(ProbateSummary probate) {
    return GestureDetector(
      onTap: () async {
        await context.push(AppRouter.probateRequest);
        if (mounted) _loadProbates();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with probate ID and name
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRB-${probate.id.length >= 6 ? probate.id.substring(0, 6).toUpperCase() : probate.id.toUpperCase()}',
                          style: AppTextStyles.cardSecondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Probate for ${probate.fullName.isNotEmpty ? probate.fullName : 'Unknown'}',
                          style: AppTextStyles.questionTitle,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 20, color: AppColors.textSecondary),
                ],
              ),
            ),

            // Probate details card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Probate Request',
                    style: AppTextStyles.itemLabel.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (probate.fullName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      probate.fullName,
                      style: AppTextStyles.itemLabel.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Request ID: PRB-${probate.id.length >= 7 ? probate.id.substring(0, 7) : probate.id}',
                    style: AppTextStyles.inputLabelFloating,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${_formatDate(probate.createdAt)}',
                    style: AppTextStyles.inputLabelFloating,
                  ),
                  if (probate.documentName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.attach_file,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            probate.documentName!,
                            style: AppTextStyles.inputLabelFloating,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Created and Last update dates
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Created on', style: AppTextStyles.bodyMedium),
                      Text(
                        _formatDate(probate.createdAt),
                        style: AppTextStyles.itemLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Last update', style: AppTextStyles.bodyMedium),
                      Text(
                        probate.updatedAt != null
                            ? _formatDateWithTimeBar(probate.updatedAt!)
                            : _formatDateWithTimeBar(probate.createdAt),
                        style: AppTextStyles.itemLabel,
                      ),
                    ],
                  ),
                  if (probate.status.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(height: 1, color: AppColors.borderGray),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getProbateStatusColor(probate.status),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatProbateStatus(probate.status),
                          style: AppTextStyles.itemLabel,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Color _getProbateStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'GRANTED':
      case 'COMPLETED':
        return AppColors.primaryGreen;
      case 'PENDING':
      case 'SUBMITTED':
        return Colors.amber;
      case 'IN_REVIEW':
      case 'UNDER_REVIEW':
        return Colors.blue;
      case 'REJECTED':
      case 'DENIED':
        return Colors.red;
      default:
        return AppColors.warningOrange;
    }
  }

  String _formatProbateStatus(String status) {
    const labels = {
      'PENDING': 'Pending',
      'SUBMITTED': 'Submitted',
      'IN_REVIEW': 'In Review',
      'UNDER_REVIEW': 'Under Review',
      'APPROVED': 'Approved',
      'GRANTED': 'Granted',
      'COMPLETED': 'Completed',
      'REJECTED': 'Rejected',
      'DENIED': 'Denied',
    };
    final upper = status.toUpperCase();
    if (labels.containsKey(upper)) return labels[upper]!;
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    return '${d.day} ${_getMonthName(d.month)} ${d.year}';
  }

  String _formatDateWithTimeBar(DateTime date) {
    final d = date.toLocal();
    final hour = d.hour;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${d.day} ${_getMonthName(d.month)} ${d.year} | ${displayHour.toString().padLeft(2, '0')}:$minute$period';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}
