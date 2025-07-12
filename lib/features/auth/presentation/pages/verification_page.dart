import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../../../core/ui/widgets/custom_button.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/auth_provider.dart';
import '../../../home/presentation/pages/home_page.dart';

class VerificationPage extends StatefulWidget {
  final String phone;
  final String email;

  const VerificationPage({super.key, required this.phone, required this.email});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> with CodeAutoFill {
  String _verificationCode = '';
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _initializeAutoOTP();
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }

  Future<void> _initializeAutoOTP() async {
    try {
      await SmsAutoFill().listenForCode;
    } catch (e) {
      debugPrint('SMS Auto-fill initialization failed: $e');
    }
  }

  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      setState(() {
        _verificationCode = code!;
      });
      _verifyAccount();
    }
  }

  Future<void> _verifyAccount() async {
    if (_verificationCode.length != 6) {
      context.showSnackBar(
        'Please enter the complete verification code',
        isError: true,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final result = await authProvider.verifyAccount(
      identifier: widget.phone,
      code: _verificationCode,
    );

    if (mounted) {
      result.fold(
        (failure) {
          context.showSnackBar(failure.message, isError: true);
          setState(() {
            _verificationCode = '';
          });
        },
        (user) {
          context.showSnackBar('Account verified successfully!');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomePage()),
            (route) => false,
          );
        },
      );
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final result = await authProvider.resendVerificationCode(
      identifier: widget.phone,
    );

    if (mounted) {
      setState(() {
        _isResending = false;
      });

      result.fold(
        (failure) {
          context.showSnackBar(failure.message, isError: true);
        },
        (success) {
          context.showSnackBar('New verification code sent');
          setState(() {
            _verificationCode = '';
          });
          SmsAutoFill().listenForCode;
        },
      );
    }
  }

  String _maskContactInfo(String contact) {
    if (contact.contains('@')) {
      // Email masking
      final parts = contact.split('@');
      if (parts[0].length <= 2) return contact;
      return '${parts[0].substring(0, 2)}${'*' * (parts[0].length - 2)}@${parts[1]}';
    } else {
      // Phone masking
      if (contact.length <= 4) return contact;
      return '${contact.substring(0, 4)}${'*' * (contact.length - 4)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Top spacer
                    const SizedBox(height: 60),

                    // Modern verification icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Verification Code',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle with masked contact
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Enter the 6-digit code sent to\n',
                          ),
                          TextSpan(
                            text: _maskContactInfo(widget.phone),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Code input
                    Container(
                      width: 280,
                      child: PinFieldAutoFill(
                        decoration: BoxLooseDecoration(
                          textStyle: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          strokeColorBuilder: FixedColorBuilder(
                            _verificationCode.length == 6
                                ? theme.primaryColor
                                : Colors.grey[300]!,
                          ),
                          bgColorBuilder: FixedColorBuilder(
                            _verificationCode.length == 6
                                ? theme.primaryColor.withOpacity(0.08)
                                : Colors.grey[50]!,
                          ),
                          strokeWidth: 2,
                          gapSpace: 8,
                          radius: const Radius.circular(12),
                        ),
                        currentCode: _verificationCode,
                        onCodeSubmitted: (code) {
                          setState(() {
                            _verificationCode = code;
                          });
                          _verifyAccount();
                        },
                        onCodeChanged: (code) {
                          setState(() {
                            _verificationCode = code ?? '';
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Verify button
                    CustomButton(
                      text: 'Verify Code',
                      onPressed:
                          authProvider.isLoading ||
                                  _verificationCode.length != 6
                              ? null
                              : _verifyAccount,
                      isLoading: authProvider.isLoading,
                    ),

                    // Flexible spacer to push bottom content down
                    Expanded(child: Container()),

                    // Resend section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Didn\'t receive the code? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        TextButton(
                          onPressed: _isResending ? null : _resendCode,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child:
                              _isResending
                                  ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.primaryColor,
                                    ),
                                  )
                                  : Text(
                                    'Resend',
                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Bottom help text
                    Text(
                      'Code expires in 10 minutes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
