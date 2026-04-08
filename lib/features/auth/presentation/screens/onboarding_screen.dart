import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/features/settings/data/models/user_prefs_models.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_profile_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Main screen ────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  final Future<void> Function() onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  // Step 1 — Profile
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _step1Key = GlobalKey<FormState>();

  // Step 2 — Metal types
  static const _allMetals = [
    (key: 'gold', label: 'Gold'),
    (key: 'silver', label: 'Silver'),
    (key: 'platinum', label: 'Platinum'),
  ];
  final Set<String> _selectedMetals = {};

  // Step 3 — Retailers
  List<Map<String, dynamic>> _allRetailers = [];
  final Set<String> _selectedRetailerIds = {};
  bool _loadingRetailers = true;

  // Step 4 — Global spot provider
  List<Map<String, dynamic>> _providers = [];
  String? _selectedProviderKey;
  final _apiKeyController = TextEditingController();
  bool _loadingProviders = true;

  // Saving state
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadRetailers();
    _loadProviders();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadRetailers() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('retailers')
          .select('id, name')
          .order('name');
      if (mounted) {
        setState(() {
          _allRetailers = (response as List).cast<Map<String, dynamic>>();
          _loadingRetailers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingRetailers = false);
    }
  }

  Future<void> _loadProviders() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('global_spot_providers')
          .select()
          .eq('is_active', true)
          .order('name');
      if (mounted) {
        setState(() {
          _providers = (response as List).cast<Map<String, dynamic>>();
          _loadingProviders = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingProviders = false);
    }
  }

  void _goNext() {
    if (_currentPage == 0 && !_step1Key.currentState!.validate()) return;
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _complete() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // 1. Save profile
      await ref.read(userProfileNotifierProvider.notifier).upsert(
            username: _usernameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          );

      // 2. Save metal type prefs
      await ref
          .read(userMetalTypesNotifierProvider.notifier)
          .set(_selectedMetals.toList());

      // 3. Save retailer prefs
      await ref
          .read(userRetailersNotifierProvider.notifier)
          .set(_selectedRetailerIds.toList());

      // 4. Save global spot pref (optional)
      if (_selectedProviderKey != null && _apiKeyController.text.trim().isNotEmpty) {
        await ref.read(userGlobalSpotPrefNotifierProvider.notifier).upsert(
              UserGlobalSpotPref(
                userId: userId,
                providerKey: _selectedProviderKey!,
                apiKey: _apiKeyController.text.trim(),
              ),
            );
      }

      await widget.onComplete();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = 'Could not save your preferences. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _Step1Profile(
                    formKey: _step1Key,
                    usernameController: _usernameController,
                    phoneController: _phoneController,
                  ),
                  _Step2Metals(
                    allMetals: _allMetals.toList(),
                    selected: _selectedMetals,
                    onToggle: (key) => setState(() {
                      if (_selectedMetals.contains(key)) {
                        _selectedMetals.remove(key);
                      } else {
                        _selectedMetals.add(key);
                      }
                    }),
                  ),
                  _Step3Retailers(
                    allRetailers: _allRetailers,
                    selected: _selectedRetailerIds,
                    loading: _loadingRetailers,
                    onToggle: (id) => setState(() {
                      if (_selectedRetailerIds.contains(id)) {
                        _selectedRetailerIds.remove(id);
                      } else {
                        _selectedRetailerIds.add(id);
                      }
                    }),
                    onSelectAll: () => setState(() => _selectedRetailerIds
                        .addAll(_allRetailers.map((r) => r['id'] as String))),
                    onClearAll: () =>
                        setState(() => _selectedRetailerIds.clear()),
                  ),
                  _Step4GlobalSpot(
                    providers: _providers,
                    loading: _loadingProviders,
                    selectedProviderKey: _selectedProviderKey,
                    apiKeyController: _apiKeyController,
                    onProviderChanged: (key) =>
                        setState(() => _selectedProviderKey = key),
                  ),
                  _Step5Done(
                    username: _usernameController.text.trim(),
                    metalCount: _selectedMetals.length,
                    retailerCount: _selectedRetailerIds.length,
                    hasProvider: _selectedProviderKey != null &&
                        _apiKeyController.text.trim().isNotEmpty,
                    saving: _saving,
                    error: _saveError,
                    onComplete: _complete,
                  ),
                ],
              ),
            ),
            _buildNavButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    const titles = [
      'Your Profile',
      'Metal Preferences',
      'Retailer Preferences',
      'Global Spot Provider',
      'All Set!',
    ];
    const subtitles = [
      'Tell us a bit about yourself',
      'Which metals do you track?',
      'Which retailers do you use?',
      'Connect a spot price API (optional)',
      'Review your preferences',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${_currentPage + 1} of $_totalPages',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titles[_currentPage],
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitles[_currentPage],
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (_currentPage + 1) / _totalPages,
          backgroundColor: AppColors.backgroundCard,
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
          minHeight: 4,
        ),
      ),
    );
  }

  Widget _buildNavButtons() {
    final isLast = _currentPage == _totalPages - 1;
    final isFirst = _currentPage == 0;
    final canSkip = _currentPage >= 1 && _currentPage <= 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          if (!isFirst)
            TextButton(
              onPressed: _goBack,
              child: const Text(
                'Back',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          const Spacer(),
          if (canSkip)
            TextButton(
              onPressed: _goNext,
              child: const Text(
                'Skip',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          if (!isLast) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _goNext,
              child: const Text('Next'),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Step 1 — Profile ───────────────────────────────────────────────────────────

class _Step1Profile extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController phoneController;

  const _Step1Profile({
    required this.formKey,
    required this.usernameController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            TextFormField(
              controller: usernameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'User name *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter a user name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number (optional)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 2 — Metal types ──────────────────────────────────────────────────────

class _Step2Metals extends StatelessWidget {
  final List<({String key, String label})> allMetals;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _Step2Metals({
    required this.allMetals,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Which metals do you track?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This personalises which prices are shown throughout the app.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ...allMetals.map((m) => CheckboxListTile(
                value: selected.contains(m.key),
                onChanged: (_) => onToggle(m.key),
                title: Text(m.label,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 15)),
                activeColor: AppColors.primaryGold,
                checkColor: AppColors.textDark,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              )),
        ],
      ),
    );
  }
}

// ── Step 3 — Retailers ────────────────────────────────────────────────────────

class _Step3Retailers extends StatelessWidget {
  final List<Map<String, dynamic>> allRetailers;
  final Set<String> selected;
  final bool loading;
  final ValueChanged<String> onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;

  const _Step3Retailers({
    required this.allRetailers,
    required this.selected,
    required this.loading,
    required this.onToggle,
    required this.onSelectAll,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Which retailers do you use?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select all retailers you want to track prices from.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: onSelectAll,
                child: const Text('Select All',
                    style: TextStyle(
                        color: AppColors.primaryGold, fontSize: 13)),
              ),
              TextButton(
                onPressed: onClearAll,
                child: const Text('Clear All',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ),
            ],
          ),
          if (loading)
            const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGold))
          else
            Expanded(
              child: ListView(
                children: allRetailers.map((r) {
                  final id = r['id'] as String;
                  final name = r['name'] as String;
                  return CheckboxListTile(
                    value: selected.contains(id),
                    onChanged: (_) => onToggle(id),
                    title: Text(name,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14)),
                    activeColor: AppColors.primaryGold,
                    checkColor: AppColors.textDark,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Step 4 — Global spot provider ─────────────────────────────────────────────

class _Step4GlobalSpot extends StatelessWidget {
  final List<Map<String, dynamic>> providers;
  final bool loading;
  final String? selectedProviderKey;
  final TextEditingController apiKeyController;
  final ValueChanged<String?> onProviderChanged;

  const _Step4GlobalSpot({
    required this.providers,
    required this.loading,
    required this.selectedProviderKey,
    required this.apiKeyController,
    required this.onProviderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: const Text(
              'To generate Global Spot Prices you will need an account '
              'with one of the providers below and an API Key.\n\n'
              'The Global Spot Prices you capture will be shared across '
              'the Metal Tracker platform and visible to other users.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold),
            )
          else ...[
            DropdownButtonFormField<String>(
              value: selectedProviderKey,
              decoration: const InputDecoration(
                labelText: 'Provider',
                prefixIcon: Icon(Icons.cloud_outlined),
              ),
              dropdownColor: AppColors.backgroundCard,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'Skip for now',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ...providers.map(
                  (p) => DropdownMenuItem<String>(
                    value: p['provider_key'] as String,
                    child: Text(p['name'] as String),
                  ),
                ),
              ],
              onChanged: onProviderChanged,
            ),
            if (selectedProviderKey != null) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
              ),
              const SizedBox(height: 12),
              if (selectedProviderKey != null) ...[
                _ProviderLink(
                  providerKey: selectedProviderKey!,
                  providers: providers,
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _ProviderLink extends StatelessWidget {
  final String providerKey;
  final List<Map<String, dynamic>> providers;

  const _ProviderLink({
    required this.providerKey,
    required this.providers,
  });

  @override
  Widget build(BuildContext context) {
    final provider = providers.firstWhere(
      (p) => p['provider_key'] == providerKey,
      orElse: () => {},
    );
    final url = provider['base_url'] as String?;
    if (url == null) return const SizedBox.shrink();
    return Text(
      'Sign up at $url',
      style: const TextStyle(
        color: AppColors.primaryGold,
        fontSize: 12,
      ),
    );
  }
}

// ── Step 5 — Done ─────────────────────────────────────────────────────────────

class _Step5Done extends StatelessWidget {
  final String username;
  final int metalCount;
  final int retailerCount;
  final bool hasProvider;
  final bool saving;
  final String? error;
  final VoidCallback onComplete;

  const _Step5Done({
    required this.username,
    required this.metalCount,
    required this.retailerCount,
    required this.hasProvider,
    required this.saving,
    required this.error,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.primaryGold,
            size: 56,
          ),
          const SizedBox(height: 16),
          if (username.isNotEmpty) ...[
            Text(
              'Welcome, $username!',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
          _SummaryRow(
            icon: Icons.toll_outlined,
            label: 'Metals',
            value: metalCount == 0 ? 'None selected' : '$metalCount selected',
          ),
          _SummaryRow(
            icon: Icons.store_outlined,
            label: 'Retailers',
            value: retailerCount == 0 ? 'None selected' : '$retailerCount selected',
          ),
          _SummaryRow(
            icon: Icons.cloud_outlined,
            label: 'Global spot provider',
            value: hasProvider ? 'Configured' : 'Not configured',
          ),
          const SizedBox(height: 8),
          const Text(
            'You can update any of these in Settings at any time.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          if (error != null) ...[
            Text(
              error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: saving ? null : onComplete,
              child: saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textDark,
                      ),
                    )
                  : const Text('Get Started'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryGold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
