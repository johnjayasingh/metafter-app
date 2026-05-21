import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/status_utils.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../will_creation/presentation/bloc/will_bloc.dart';
import '../../../will_creation/presentation/bloc/will_event.dart';
import '../../../will_creation/presentation/bloc/will_state.dart';
import '../../../will_creation/data/models/will_models.dart';
import '../widgets/will_options_bottom_sheet.dart';

class MyWillsTab extends StatefulWidget {
  const MyWillsTab({super.key});

  @override
  State<MyWillsTab> createState() => _MyWillsTabState();
}

class _MyWillsTabState extends State<MyWillsTab>
    with WidgetsBindingObserver, RouteAware, SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedRoleFilter = 'all'; // Default to all
  
  // Local cache for wills data
  List<WillSummary> _myWills = [];
  List<WillSummary> _invitedWills = [];
  bool _isLoadingMyWills = false;
  bool _isLoadingInvitedWills = false;
  String? _myWillsError;
  String? _invitedWillsError;
  bool _invitedWillsLoaded = false; // Track if we've ever loaded invited wills
  
  // Role filter options
  static const List<Map<String, String>> _roleFilterOptions = [
    {'value': 'all', 'label': 'All'},
    {'value': 'witness', 'label': 'Witness'},
    {'value': 'beneficiary', 'label': 'Beneficiary'},
    {'value': 'executor', 'label': 'Executor'},
    {'value': 'lawyer', 'label': 'Lawyer'},
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addObserver(this);
    // Load wills when tab is opened
    _loadMyWills();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {}); // Rebuild to show correct tab content
    if (_tabController.index == 0) {
      _loadMyWills();
    } else {
      _loadInvitedWills();
    }
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
    // Called when returning to this screen from another screen
    if (_tabController.index == 0) {
      _loadMyWills();
    } else {
      _loadInvitedWills();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_tabController.index == 0) {
        _loadMyWills();
      } else {
        _loadInvitedWills();
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    AppRouter.routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _loadMyWills() {
    setState(() {
      _isLoadingMyWills = true;
      _myWillsError = null;
    });
    context.read<WillBloc>().add(const GetAllWillsEvent());
  }

  void _loadInvitedWills() {
    setState(() {
      _isLoadingInvitedWills = true;
      _invitedWillsError = null;
    });
    context.read<WillBloc>().add(const GetInvitedWillsEvent());
  }

  void _refreshWills() {
    // Use RefreshWillsEvent for silent background refresh without loading state
    context.read<WillBloc>().add(const RefreshWillsEvent());
  }

  void _refreshInvitedWills() {
    context.read<WillBloc>().add(const RefreshInvitedWillsEvent());
  }

  List<WillSummary> _filterWillsByRole(List<WillSummary> wills) {
    if (_selectedRoleFilter.isEmpty || _selectedRoleFilter == 'all') {
      return wills;
    }
    return wills
        .where((will) =>
            will.invitedRole?.toLowerCase() == _selectedRoleFilter.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WillBloc, WillState>(
      listener: (context, state) {
        // Update local cache based on state changes
        // Note: We don't track WillLoading here to avoid race conditions
        // between My Wills and Invited Wills loading. Each content builder
        // shows its own loading state based on its data being empty.
        if (state is AllWillsLoaded) {
          setState(() {
            _myWills = state.wills;
            _isLoadingMyWills = false;
            _myWillsError = null;
          });
        } else if (state is InvitedWillsLoaded) {
          setState(() {
            _invitedWills = state.wills;
            _isLoadingInvitedWills = false;
            _invitedWillsError = null;
            _invitedWillsLoaded = true;
          });
        } else if (state is WillError) {
          setState(() {
            // Set error for the current tab
            if (_tabController.index == 0) {
              _isLoadingMyWills = false;
              _myWillsError = state.message;
            } else {
              _isLoadingInvitedWills = false;
              _invitedWillsError = state.message;
            }
          });
        }
      },
      child: BlocBuilder<WillBloc, WillState>(
        buildWhen: (previous, current) {
          // Only rebuild for auth state changes, not will state changes
          // We handle will state changes in the listener above
          return false;
        },
        builder: (context, willState) {
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
              children: [Text('My Wills', style: AppTextStyles.pageTitle)],
            ),
            backgroundColor: AppColors.backgroundWhite,
            elevation: 0,
            actions: [
              // Show add button only when there are existing wills and on My will tab
              if (_myWills.isNotEmpty && _tabController.index == 0)
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
                  onPressed: () async {
                    // Clear will_id for new will flow
                    await SecureStorageService().clearWillId();
                    if (context.mounted) {
                      context.read<WillBloc>().add(const ResetWillStateEvent());
                      await context.push(AppRouter.willOnboarding);
                      if (context.mounted) _refreshWills();
                    }
                  },
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
                  onPressed: () {
                    context.push(AppRouter.notifications);
                  },
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: _buildTabBar(),
            ),
          ),
          body: BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state.status == AuthStatus.unauthenticated) {
                context.go(AppRouter.splash);
              }
            },
            child: SafeArea(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // My Will tab content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    child: _buildMyWillsContent(),
                  ),
                  // Invited tab content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: _buildInvitedWillsContent(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryGreen,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.bodyMedium,
        indicatorColor: AppColors.primaryGreen,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.borderGray,
        tabs: const [
          Tab(text: 'My wills'),
          Tab(text: 'Invited'),
        ],
      ),
    );
  }

  Widget _buildMyWillsContent() {
    if (_isLoadingMyWills && _myWills.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myWillsError != null && _myWills.isEmpty) {
      return _buildErrorState(_myWillsError!, isInvited: false);
    }

    if (_myWills.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildWillsList(_myWills);
  }

  Widget _buildInvitedWillsContent() {
    // Load invited wills if not already loaded and not loading
    if (!_invitedWillsLoaded && !_isLoadingInvitedWills && _invitedWillsError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInvitedWills();
      });
    }

    if (_isLoadingInvitedWills && _invitedWills.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_invitedWillsError != null && _invitedWills.isEmpty) {
      return _buildErrorState(_invitedWillsError!, isInvited: true);
    }

    if (_invitedWills.isEmpty) {
      return _buildEmptyInvitedState();
    }
    
    return _buildInvitedWillsListWithFilter(_invitedWills);
  }

  Widget _buildInvitedWillsListWithFilter(List<WillSummary> wills) {
    final filteredWills = wills;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Role filter button
        _buildRoleFilterButton(),
        const SizedBox(height: 16),
        // Wills list
        Expanded(
          child: filteredWills.isEmpty
              ? _buildNoFilterResultsState()
              : _buildInvitedWillsList(filteredWills),
        ),
      ],
    );
  }

  Widget _buildRoleFilterButton() {
    // Get display text for current filter
    final option = _roleFilterOptions.firstWhere(
      (opt) => opt['value'] == _selectedRoleFilter,
      orElse: () => {'label': 'All'},
    );
    final displayText = _selectedRoleFilter == 'all'
        ? 'All roles'
        : 'As ${option['label']!.toLowerCase()}';

    return GestureDetector(
      onTap: _showRoleFilterBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              // Options list
              ..._roleFilterOptions.map((option) => _buildRoleOptionTile(
                    label: option['label']!,
                    value: option['value']!,
                    isSelected: _selectedRoleFilter == option['value'],
                  )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOptionTile({
    required String label,
    required String value,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRoleFilter = value;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.borderGray.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: AppColors.primaryGreen,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFilterResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_off,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No wills found for this role',
            style: AppTextStyles.questionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different filter',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, {required bool isInvited}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error loading wills', style: AppTextStyles.questionTitle),
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
            onPressed: () {
              if (isInvited) {
                context.read<WillBloc>().add(const GetInvitedWillsEvent());
              } else {
                context.read<WillBloc>().add(const GetAllWillsEvent());
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        // Empty state card
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundLightGray4,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(
                'Create your will',
                style: AppTextStyles.pageTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Protect what matters most with an easy, guided will-creation experience.',
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
                    // Layer 2: Image
                    Image.asset(
                      'assets/images/family.png',
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                    ),
                    // Layer 3: Gradient overlay
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
                              AppColors.backgroundMintPastel.withValues(
                                alpha: 0.3,
                              ),
                              AppColors.backgroundMintPastel.withValues(
                                alpha: 0.5,
                              ),
                              AppColors.backgroundMintPastel,
                            ],
                            stops: const [0.0, 0.3, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Layer 4: Button
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: AppPrimaryButton(
                        text: 'Start Will creation',
                        onPressed: () async {
                          // Clear will_id for new will flow
                          await SecureStorageService().clearWillId();
                          if (context.mounted) {
                            context.read<WillBloc>().add(const ResetWillStateEvent());
                            await context.push(AppRouter.willOnboarding);
                            if (context.mounted) _refreshWills();
                          }
                        },
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

  Widget _buildEmptyInvitedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No invited wills',
            style: AppTextStyles.questionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'You haven\'t been invited as a witness, executor, or lawyer to any wills yet.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWillsList(List<WillSummary> wills) {
    // Sort by date - latest first
    final sortedWills = List<WillSummary>.from(wills)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.separated(
      itemCount: sortedWills.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final will = sortedWills[index];
        return _buildWillCard(will);
      },
    );
  }

  Widget _buildInvitedWillsList(List<WillSummary> wills) {
    // Sort by date - latest first
    final sortedWills = List<WillSummary>.from(wills)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.separated(
      itemCount: sortedWills.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final will = sortedWills[index];
        return _buildInvitedWillCard(will);
      },
    );
  }

  Widget _buildInvitedWillCard(WillSummary will) {
    return GestureDetector(
      onTap: () async {
        // Save will_id for context
        await SecureStorageService().saveWillId(will.willId);
        if (!context.mounted) return;

        // For invited wills, navigate to the timeline/view screen
        await context.push(
          AppRouter.willTimeline,
          extra: {
            'willId': will.willId,
            'fullName': will.fullName,
            'status': will.status,
            'isInvited': true,
            'invitedRole': will.invitedRole,
          },
        );

        if (context.mounted) _refreshInvitedWills();
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
            // Header with will ID, role badge, and menu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                will.willId,
                                style: AppTextStyles.cardSecondary,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Role badge
                            if (will.invitedRole != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(will.invitedRole!).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _formatRoleName(will.invitedRole!),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: _getRoleColor(will.invitedRole!),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Will of ${will.fullName}',
                          style: AppTextStyles.questionTitle,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    color: AppColors.textPrimary,
                    onPressed: () {
                      WillOptionsBottomSheet.show(
                        context: context,
                        willId: will.willId,
                        fullName: will.fullName,
                        status: will.status,
                        isInvited: true,
                      );
                    },
                  ),
                ],
              ),
            ),

            // Will details card
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
                    'Last Will and Testament of',
                    style: AppTextStyles.itemLabel.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    will.fullName,
                    style: AppTextStyles.itemLabel.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Document ID: ${will.willId}',
                    style: AppTextStyles.inputLabelFloating,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${_formatDate(will.createdAt)}',
                    style: AppTextStyles.inputLabelFloating,
                  ),
                  if (will.invitedRole != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Your role: ${_formatRoleName(will.invitedRole!)}',
                      style: AppTextStyles.inputLabelFloating.copyWith(
                        color: _getRoleColor(will.invitedRole!),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Created and Last update dates (outside the gray card)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Created on', style: AppTextStyles.bodyMedium),
                      Text(
                        _formatDate(will.createdAt),
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
                        will.lastUpdated != null
                            ? _formatDateWithTimeBar(will.lastUpdated!)
                            : _formatDateWithTimeBar(will.createdAt),
                        style: AppTextStyles.itemLabel,
                      ),
                    ],
                  ),
                  if (will.status.isNotEmpty) ...[
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
                            color: StatusUtils.getStatusColor(will.status),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          StatusUtils.formatStatus(will.status),
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

  String _formatRoleName(String role) {
    switch (role.toLowerCase()) {
      case 'witness':
        return 'Witness';
      case 'executor':
        return 'Executor';
      case 'lawyer':
        return 'Lawyer';
      default:
        return role.substring(0, 1).toUpperCase() + role.substring(1);
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'witness':
        return const Color(0xFF2196F3); // Blue
      case 'executor':
        return const Color(0xFF9C27B0); // Purple
      case 'lawyer':
        return const Color(0xFFFF9800); // Orange
      default:
        return AppColors.primaryGreen;
    }
  }

  Widget _buildWillCard(WillSummary will) {
    return GestureDetector(
      onTap: () async {
        // Save will_id for context
        await SecureStorageService().saveWillId(will.willId);
        if (!context.mounted) return;

        final upperStatus = will.status.toUpperCase();

        // Navigate based on will status
        if (upperStatus == 'REVIEW_COMPLETED' || upperStatus == 'WILL_SIGNED') {
          // Will is signed - go to timeline screen
          await context.push(
            AppRouter.willTimeline,
            extra: {
              'willId': will.willId,
              'fullName': will.fullName,
              'status': will.status,
            },
          );
        }
        // TODO: change legal review flow when implemented
        else if (upperStatus == 'IN_LEGAL_REVIEW' ||
            upperStatus == 'LEGAL_REVIEW' ||
            upperStatus == 'UNDER_REVIEW') {
          // Will is review - go to timeline screen
          await context.push(
            AppRouter.legalReview,
            extra: {
              'willId': will.willId,
              'fullName': will.fullName,
              'status': will.status,
            },
          );
        }
        // TODO: Re-enable legal review flow when implemented
        // else if (upperStatus == 'IN_LEGAL_REVIEW' ||
        //     upperStatus == 'LEGAL_REVIEW' ||
        //     upperStatus == 'UNDER_REVIEW') {
        //   // Will is in legal review - go to legal review screen
        //   await context.push(
        //     AppRouter.legalReview,
        //     extra: {'userName': will.fullName, 'willId': will.willId},
        //   );
        // }
        else {
          // Default: navigate to basic details for editing
          await context.push(AppRouter.willOnboarding);
        }

        if (context.mounted) _refreshWills();
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
            // Header with will ID and menu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        will.willId,
                        style: AppTextStyles.cardSecondary,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Will of ${will.fullName}',
                        style: AppTextStyles.questionTitle,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    color: AppColors.textPrimary,
                    onPressed: () {
                      WillOptionsBottomSheet.show(
                        context: context,
                        willId: will.willId,
                        fullName: will.fullName,
                        status: will.status,
                      );
                    },
                  ),
                ],
              ),
            ),

            // Will details card
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
                    'Last Will and Testament of',
                    style: AppTextStyles.itemLabel.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    will.fullName,
                    style: AppTextStyles.itemLabel.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Document ID: ${will.willId}',
                    style: AppTextStyles.inputLabelFloating,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${_formatDate(will.createdAt)}',
                    style: AppTextStyles.inputLabelFloating,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Place of Signing: Brisbane QLD 4000, Australia',
                    style: AppTextStyles.inputLabelFloating,
                  ),
                ],
              ),
            ),

            // Created and Last update dates (outside the gray card)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Created on', style: AppTextStyles.bodyMedium),
                      Text(
                        _formatDate(will.createdAt),
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
                        will.lastUpdated != null
                            ? _formatDateWithTimeBar(will.lastUpdated!)
                            : _formatDateWithTimeBar(will.createdAt),
                        style: AppTextStyles.itemLabel,
                      ),
                    ],
                  ),
                  if (will.status.isNotEmpty) ...[
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
                            color: StatusUtils.getStatusColor(will.status),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          StatusUtils.formatStatus(will.status),
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

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.day} ${_getMonthName(localDate.month)} ${localDate.year}';
  }

  String _formatDateWithTime(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDate);

    // If within 24 hours, show time as well
    if (difference.inHours < 24) {
      final hour = localDate.hour;
      final minute = localDate.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${localDate.day} ${_getMonthName(localDate.month)} ${localDate.year}, $displayHour:$minute $period';
    }

    return '${localDate.day} ${_getMonthName(localDate.month)} ${localDate.year}';
  }

  String _formatDateWithTimeBar(DateTime date) {
    final localDate = date.toLocal();
    final hour = localDate.hour;
    final minute = localDate.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${localDate.day} ${_getMonthName(localDate.month)} ${localDate.year} | ${displayHour.toString().padLeft(2, '0')}:$minute$period';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
