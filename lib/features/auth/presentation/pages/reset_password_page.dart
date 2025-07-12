import 'package:daladala_smart_app/features/splash/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import '../../../../core/ui/widgets/custom_button.dart';
import '../../../../core/ui/widgets/custom_input.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/extensions.dart';

class ResetPasswordPage extends StatefulWidget {
  final String phone;

  const ResetPasswordPage({Key? key, required this.phone}) : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // TODO: Implement the reset password functionality
        // For now, we'll just simulate a successful reset
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Password reset successful! Please login with your new password.',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to login page
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          context.showSnackBar(e.toString(), isError: true);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  'Reset Your Password',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter the verification code sent to ${widget.phone} and create a new password.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Verification code field
                CustomInput(
                  label: 'Verification Code',
                  hint: 'Enter the code sent to your phone',
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  prefix: const Icon(Icons.verified_user_outlined),
                  validator:
                      (value) => Validators.validateRequired(
                        value,
                        fieldName: 'Verification code',
                      ),
                ),

                const SizedBox(height: 16),

                // New password field
                CustomInput(
                  label: 'New Password',
                  hint: 'Create a new password',
                  controller: _passwordController,
                  obscureText: true,
                  prefix: const Icon(Icons.lock_outline),
                  validator: Validators.validatePassword,
                ),

                const SizedBox(height: 16),

                // Confirm new password field
                CustomInput(
                  label: 'Confirm New Password',
                  hint: 'Confirm your new password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  prefix: const Icon(Icons.lock_outline),
                  validator:
                      (value) => Validators.validatePasswordConfirmation(
                        value,
                        _passwordController.text,
                      ),
                ),

                const SizedBox(height: 32),

                // Submit button
                CustomButton(
                  text: 'Reset Password',
                  onPressed: _resetPassword,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 16),

                // Resend code button
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      // TODO: Implement resend code functionality
                      context.showSnackBar(
                        'Verification code resent to ${widget.phone}',
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Resend Code'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
