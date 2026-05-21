import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../tabs/my_wills_tab.dart';
import '../tabs/digital_vault_tab.dart';
import '../tabs/funeral_tab.dart';
import '../tabs/probate_tab.dart';
import '../tabs/poa_tab.dart';
import '../tabs/ahd_tab.dart';
import '../tabs/profile_tab.dart';
import '../../../profile/data/models/profile_models.dart';
import '../../../profile/data/services/profile_service.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Screens wider than this threshold show the left sidebar instead of the
// bottom navigation bar.
const double _kSidebarBreakpoint = 800;

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  bool _sidebarCollapsed = false;
  final ProfileService _profileService = ProfileService();
  UserProfile? _userProfile;
  int _poaTabVersion = 0;
  int _ahdTabVersion = 0;

  final List<Widget> _screens = [
    const MyWillsTab(),
    const DigitalVaultTab(),
    const FuneralTab(),
    const ProbateTab(),
    const ProfileTab(),
  ];

  // Nav item definitions: label, image asset path, icon fallback
  static const List<_NavItem> _navItems = [
    _NavItem(label: 'My Wills', imagePath: 'assets/images/wills.png'),
    _NavItem(label: 'Digital Vault', imagePath: 'assets/images/digital-vault.png'),
    _NavItem(label: 'Funeral', imagePath: 'assets/images/funeral.png'),
    _NavItem(label: 'Probate', imagePath: 'assets/images/probate.png'),
    _NavItem(label: 'POA', imagePath: 'assets/images/poa.png'),
    _NavItem(label: 'AHD', imagePath: 'assets/images/poa.png'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadProfile();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
        if (widget.initialIndex == 4) {
          _poaTabVersion++;
        } else if (widget.initialIndex == 5) {
          _ahdTabVersion++;
        }
      });
    } else if (widget.initialIndex == 4) {
      // Same tab index (e.g. navigating back via context.go with extra: 4)
      // — still force a refresh so the card shows updated data.
      setState(() => _poaTabVersion++);
    } else if (widget.initialIndex == 5) {
      setState(() => _ahdTabVersion++);
    }
  }

  Future<void> _loadProfile() async {
    final response = await _profileService.getProfile();
    if (response.isSuccess && response.data != null) {
      setState(() => _userProfile = response.data);
    }
  }

  String _getInitials() {
    if (_userProfile == null) return '';
    final first = _userProfile!.firstName;
    final last = _userProfile!.lastName;
    String initials = first.isNotEmpty ? first[0].toUpperCase() : '';
    if (last != null && last.isNotEmpty) initials += last[0].toUpperCase();
    return initials;
  }

  String _getFullName() {
    if (_userProfile == null) return '';
    final first = _userProfile!.firstName;
    final last = _userProfile!.lastName ?? '';
    return '$first $last'.trim();
  }

  void _selectTab(int index) {
    setState(() {
      if (index == 4 && _currentIndex != 4) {
        _poaTabVersion++;
      } else if (index == 5 && _currentIndex != 5) {
        _ahdTabVersion++;
      }
      _currentIndex = index;
    });
  }

  /// Returns the screen widget for the current tab index.
  /// PoaTab (index 4) and AhdTab (index 5) are built with versioned keys
  /// so they rebuild and refetch live data whenever the user navigates to them.
  Widget _buildCurrentScreen() {
    if (_currentIndex == 4) {
      return PoaTab(key: ValueKey(_poaTabVersion));
    }
    if (_currentIndex == 5) {
      return AhdTab(key: ValueKey(_ahdTabVersion));
    }
    // Adjust index since PoaTab and AhdTab are removed from the static _screens list
    final screenIdx = _currentIndex > 5
        ? _currentIndex - 2
        : _currentIndex > 4
            ? _currentIndex - 1
            : _currentIndex;
    return _screens[screenIdx];
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _kSidebarBreakpoint;
        if (isWide) {
          return _buildSidebarLayout();
        }
        return _buildBottomNavLayout();
      },
    );
  }

  // -------------------------------------------------------------------------
  // Sidebar layout (wide screens)
  // -------------------------------------------------------------------------

  Widget _buildSidebarLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: ClipRect(
              child: _buildCurrentScreen(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final double width = _sidebarCollapsed ? 72 : 260;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: width,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo ──────────────────────────────────────────────────────────
          _buildSidebarHeader(),
          // ── Section label + collapse toggle ──────────────────────────────
          _buildSidebarSectionRow(),
          const SizedBox(height: 4),
          // ── Nav items ────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                for (int i = 0; i < _navItems.length; i++)
                  _buildSidebarItem(
                    index: i,
                    item: _navItems[i],
                  ),
                // Profile item at the end of the list
                _buildSidebarProfileItem(6),
              ],
            ),
          ),
          // ── User card ────────────────────────────────────────────────────
          _buildSidebarUserCard(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/logo_icon.svg',
            width: 32,
            height: 32,
          ),
          if (!_sidebarCollapsed) ...[
            const SizedBox(width: 10),
            SvgPicture.asset(
              'assets/images/logo.svg',
              height: 18,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarSectionRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!_sidebarCollapsed)
            Text(
              'Navigation',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _sidebarCollapsed
                  ? Icons.keyboard_double_arrow_right_rounded
                  : Icons.keyboard_double_arrow_left_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
            tooltip: _sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
            onPressed: () =>
                setState(() => _sidebarCollapsed = !_sidebarCollapsed),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required _NavItem item,
  }) {
    final isActive = _currentIndex == index;

    return Tooltip(
      message: _sidebarCollapsed ? item.label : '',
      preferBelow: false,
      child: InkWell(
        onTap: () => _selectTab(index),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: _sidebarCollapsed ? 12 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.backgroundLightGreen
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  isActive ? AppColors.primaryGreen : AppColors.textGray,
                  BlendMode.srcIn,
                ),
                child: Image.asset(item.imagePath, width: 20, height: 20),
              ),
              if (!_sidebarCollapsed) ...[
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isActive
                        ? AppColors.primaryGreen
                        : AppColors.textPrimary,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarProfileItem(int index) {
    final isActive = _currentIndex == index;
    final initials = _getInitials();

    return Tooltip(
      message: _sidebarCollapsed ? 'Profile' : '',
      preferBelow: false,
      child: InkWell(
        onTap: () => _selectTab(index),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.backgroundLightGreen
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryGreen
                      : AppColors.textGray,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (!_sidebarCollapsed) ...[
                const SizedBox(width: 12),
                Text(
                  'Profile',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isActive
                        ? AppColors.primaryGreen
                        : AppColors.textPrimary,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarUserCard() {
    if (_sidebarCollapsed) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _getInitials(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getFullName(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Testator',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Bottom nav layout (narrow screens — unchanged)
  // -------------------------------------------------------------------------

  Widget _buildBottomNavLayout() {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: _buildCurrentScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: _buildImageNavItem(0, 'assets/images/wills.png', 'My Wills')),
                Expanded(child: _buildImageNavItem(1, 'assets/images/digital-vault.png', 'Digital Vault')),
                Expanded(child: _buildImageNavItem(2, 'assets/images/funeral.png', 'Funeral')),
                Expanded(child: _buildImageNavItem(3, 'assets/images/probate.png', 'Probate')),
                Expanded(child: _buildImageNavItem(4, 'assets/images/poa.png', 'POA')),
                Expanded(child: _buildImageNavItem(5, 'assets/images/poa.png', 'AHD')),
                Expanded(child: _buildProfileNavItem(6, 'Profile')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageNavItem(int index, String imagePath, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _selectTab(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 32,
              decoration: isActive
                  ? BoxDecoration(
                      color: AppColors.backgroundLightGreen,
                      borderRadius: BorderRadius.circular(16),
                    )
                  : null,
              child: Center(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    isActive ? AppColors.primaryGreen : AppColors.textGray,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(imagePath, width: 24, height: 24),
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                softWrap: false,
                style: isActive
                    ? AppTextStyles.tabLabelActive
                    : AppTextStyles.tabLabelInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNavItem(int index, String label) {
    final isActive = _currentIndex == index;
    final initials = _getInitials();

    return GestureDetector(
      onTap: () => _selectTab(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 32,
              decoration: isActive
                  ? BoxDecoration(
                      color: AppColors.backgroundLightGreen,
                      borderRadius: BorderRadius.circular(16),
                    )
                  : null,
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryGreen : AppColors.textGray,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                softWrap: false,
                style: isActive
                    ? AppTextStyles.tabLabelActive
                    : AppTextStyles.tabLabelInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper data class for nav items
class _NavItem {
  final String label;
  final String imagePath;
  const _NavItem({required this.label, required this.imagePath});
}
