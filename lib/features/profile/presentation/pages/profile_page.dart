// lib/features/profile/presentation/pages/profile_page.dart
import 'package:daladala_smart_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:daladala_smart_app/features/auth/domain/entities/user.dart';
import 'package:daladala_smart_app/features/splash/presentation/pages/login_page.dart';
import 'package:daladala_smart_app/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:daladala_smart_app/features/wallet/presentation/pages/wallet_page.dart';
import 'package:daladala_smart_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  User? user;
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;
  File? _selectedImage;
  String? errorMessage;
  String? successMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    setState(() => isLoading = true);

    try {
      // First, ensure we have current user data
      if (authProvider.currentUser == null) {
        await authProvider.refreshCurrentUser();
      }

      if (authProvider.currentUser != null) {
        setState(() {
          user = authProvider.currentUser;
        });

        // 🔥 FIX: Always populate fields from current user
        _populateFields();

        // Load additional profile data from API
        await profileProvider.getProfile();

        // Load wallet data
        await walletProvider.getWalletBalance();
      } else {
        // No user found, redirect to login
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
          return;
        }
      }
    } catch (e) {
      print('Profile initialization error: $e');
      setState(() {
        errorMessage = 'Failed to load profile. Please try again.';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🔥 FIX: Improved field population
  void _populateFields() {
    if (user != null) {
      _firstNameController.text = user!.firstName;
      _lastNameController.text = user!.lastName;
      _emailController.text = user!.email ?? '';

      // Debug: Print values to check
      print('Populating fields:');
      print('FirstName: "${user!.firstName}"');
      print('LastName: "${user!.lastName}"');
      print('Email: "${user!.email}"');
    }
  }

  // 🔥 FIX: Improved profile update
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSaving = true;
      errorMessage = null;
      successMessage = null;
    });

    try {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Create update data map
      final updateData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
      };

      print('Updating profile with: $updateData');

      // Update profile
      final success = await profileProvider.updateProfile(updateData);

      if (success) {
        // 🔥 FIX: Force refresh user data from backend
        await authProvider.refreshCurrentUser();

        // Update local user state
        if (authProvider.currentUser != null) {
          setState(() {
            user = authProvider.currentUser;
            isEditing = false;
            successMessage = 'Profile updated successfully!';
          });

          // Re-populate fields with fresh data
          _populateFields();

          // Clear success message after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() => successMessage = null);
            }
          });
        }
      } else {
        setState(() {
          errorMessage =
              profileProvider.errorMessage ?? 'Failed to update profile';
        });
      }
    } catch (e) {
      print('Profile update error: $e');
      setState(() {
        errorMessage = 'Failed to update profile. Please try again.';
      });
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Logout',
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.logout();

      if (mounted) {
        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: Colors.red,
              ),
            );
          },
          (_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  void _cancelEdit() {
    setState(() {
      isEditing = false;
      _selectedImage = null;
      errorMessage = null;
      _populateFields();
    });
  }

  void _navigateToWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WalletPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch multiple providers
    return Consumer3<AuthProvider, ProfileProvider, WalletProvider>(
      builder: (context, authProvider, profileProvider, walletProvider, child) {
        final currentUser = authProvider.currentUser;

        if (currentUser == null && !isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Please log in to view your profile'),
                ],
              ),
            ),
          );
        }

        // Sync with AuthProvider if user is null
        if (user == null && currentUser != null) {
          user = currentUser;
          _populateFields();
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child:
                    isLoading
                        ? _buildLoadingState()
                        : _buildContent(walletProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildProfilePicture(),
                const SizedBox(height: 16),
                _buildUserInfo(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (!isEditing && !isLoading)
          IconButton(
            onPressed: () => setState(() => isEditing = true),
            icon: const Icon(Icons.edit, color: Colors.white),
          ),
      ],
    );
  }

  Widget _buildProfilePicture() {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(child: _buildProfileImage()),
        ),
        if (isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileImage() {
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    } else if (user?.profilePicture != null &&
        user!.profilePicture!.isNotEmpty) {
      return Image.network(
        user!.profilePicture!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar();
        },
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey[300],
      child:
          user != null &&
                  (user!.firstName.isNotEmpty) &&
                  (user!.lastName.isNotEmpty)
              ? Center(
                child: Text(
                  '${user!.firstName[0]}${user!.lastName[0]}'.toUpperCase(),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              )
              : Icon(Icons.person, size: 60, color: Colors.grey[600]),
    );
  }

  Widget _buildUserInfo() {
    final firstName = user?.firstName ?? '';
    final lastName = user?.lastName ?? '';
    final fullName = '$firstName $lastName'.trim();

    return Column(
      children: [
        Text(
          fullName.isEmpty ? 'Complete Your Profile' : fullName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user?.phone ?? '',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                (user?.role ?? 'PASSENGER').toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading profile...'),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(WalletProvider walletProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (errorMessage != null) _buildErrorMessage(),
          if (successMessage != null) _buildSuccessMessage(),
          const SizedBox(height: 16),

          // Wallet Section
          _buildWalletSection(walletProvider),
          const SizedBox(height: 16),

          // Profile Form
          _buildProfileForm(),
          const SizedBox(height: 24),

          if (!isEditing) _buildLogoutSection(),
        ],
      ),
    );
  }

  Widget _buildWalletSection(WalletProvider walletProvider) {
    final wallet = walletProvider.wallet;
    final isWalletLoading = walletProvider.isLoading;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Wallet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _navigateToWallet,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (isWalletLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (wallet != null) ...[
              // Balance Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      wallet.formattedBalance,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Wallet Status
              Row(
                children: [
                  Icon(
                    wallet.isActive ? Icons.check_circle : Icons.error,
                    color: wallet.isActive ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status: ${wallet.status.toUpperCase()}',
                    style: TextStyle(
                      color: wallet.isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Limits
              if (wallet.dailyLimit != null)
                _buildWalletInfoRow(
                  'Daily Limit',
                  '${wallet.dailyLimit!.toStringAsFixed(0)} ${wallet.currency}',
                ),
              if (wallet.monthlyLimit != null)
                _buildWalletInfoRow(
                  'Monthly Limit',
                  '${wallet.monthlyLimit!.toStringAsFixed(0)} ${wallet.currency}',
                ),
              if (wallet.lastActivity != null)
                _buildWalletInfoRow(
                  'Last Activity',
                  _formatDate(wallet.lastActivity.toString()),
                ),
            ] else ...[
              // No wallet found
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.orange.shade600,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Wallet Not Available',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contact support to activate your wallet',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            if (walletProvider.error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Error loading wallet: ${walletProvider.error}',
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ),
                    TextButton(
                      onPressed: () => walletProvider.getWalletBalance(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWalletInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              successMessage!,
              style: TextStyle(color: Colors.green.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isEditing)
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (!isEditing) const Spacer(),
                  if (isEditing)
                    Row(
                      children: [
                        TextButton(
                          onPressed: _cancelEdit,
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSaving ? null : _updateProfile,
                          child:
                              isSaving
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('Save'),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _firstNameController,
                enabled: isEditing,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (isEditing && (value == null || value.trim().isEmpty)) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                enabled: isEditing,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (isEditing && (value == null || value.trim().isEmpty)) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                enabled: isEditing,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (isEditing && (value == null || value.trim().isEmpty)) {
                    return 'Email is required';
                  }
                  if (isEditing &&
                      !RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value!)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: user?.phone ?? '',
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  helperText: 'Contact support to change phone number',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
