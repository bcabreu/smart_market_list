import 'package:flutter/material.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';
import 'package:smart_market_list/ui/screens/auth/login_screen.dart';
import 'package:smart_market_list/ui/screens/auth/widgets/auth_text_field.dart';
import 'package:smart_market_list/ui/screens/auth/widgets/social_login_buttons.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/providers/user_provider.dart';
import 'package:smart_market_list/providers/user_profile_provider.dart';
import 'package:smart_market_list/providers/auth_provider.dart';
import 'package:smart_market_list/core/services/sharing_service.dart';
import 'package:smart_market_list/providers/sharing_provider.dart';
import 'package:smart_market_list/ui/common/modals/loading_dialog.dart';
import 'package:smart_market_list/ui/common/modals/status_feedback_modal.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final l10n = AppLocalizations.of(context)!;

    if (name.isEmpty || email.isEmpty || password.isEmpty) return;

    if (password != confirm) {
        StatusFeedbackModal.show(
          context,
          title: l10n.errorTitle,
          message: l10n.passwordsDoNotMatch,
          type: FeedbackType.error,
        );
        return;
    }

    FocusScope.of(context).unfocus();
    LoadingDialog.show(context, l10n.processing);

    try {
      await ref.read(authServiceProvider).signUp(email: email, password: password);
      await ref.read(authServiceProvider).updateDisplayName(name); // Persist name to Firebase
      
      // Update global state
      await ref.read(userNameProvider.notifier).setName(name);
      await ref.read(userEmailProvider.notifier).setEmail(email);
      await ref.read(isLoggedInProvider.notifier).setLoggedIn(true);
      
      // Check for pending Deep Link Joins (Universal Links)
      if (SharingService.pendingListId != null && SharingService.pendingFamilyId != null) {
         try {
           final currentUser = ref.read(authServiceProvider).currentUser;
           if (currentUser != null) {
              await ref.read(sharingServiceProvider).joinList(
                SharingService.pendingListId!, 
                SharingService.pendingFamilyId!, 
                currentUser.uid
              );
              
              // Clear pending
              SharingService.pendingListId = null;
              SharingService.pendingFamilyId = null;
              
              if (mounted) {
                 StatusFeedbackModal.show(
                   context,
                   title: l10n.successTitle,
                   message: l10n.accountCreatedAndListAdded,
                   type: FeedbackType.success,
                 );
              }
           }
         } catch (e) {
           print('Error joining pending list: $e');
         }
      } else if (SharingService.pendingFamilyId != null) {
         // Pending Family Join (without list)
         try {
           final currentUser = ref.read(authServiceProvider).currentUser;
           if (currentUser != null) {
              await ref.read(sharingServiceProvider).joinFamily(
                SharingService.pendingFamilyId!, 
                currentUser.uid
              );
              
              // Clear pending
              SharingService.pendingFamilyId = null;
              SharingService.pendingListId = null; // Just in case
              
              if (mounted) {
                 StatusFeedbackModal.show(
                   context,
                   title: l10n.welcomeToFamilyTitle,
                   message: l10n.welcomeToFamilyMessage,
                   type: FeedbackType.success,
                 );
                 // Refresh profile
                 ref.refresh(userProfileProvider);
              }
           }
         } catch (e) {
           print('Error joining pending family: $e');
           if (mounted) {
             StatusFeedbackModal.show(
               context,
               title: l10n.errorTitle,
               message: l10n.joinFamilyError(e.toString()),
               type: FeedbackType.error,
             );
           }
         }
      }

      if (mounted) {
        LoadingDialog.hide(context);
        Navigator.pop(context); // Go back to profile (or main)
      }
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
        
        String errorMessage = e.toString();
        if (errorMessage.contains('email-already-in-use')) {
           errorMessage = l10n.emailAlreadyInUse;
        } else if (errorMessage.contains('invalid-email')) {
           errorMessage = l10n.invalidEmailError;
        } else if (errorMessage.contains('weak-password')) {
           errorMessage = 'A senha é muito fraca.'; // TODO: Add to arb if needed, or rely on generic
        }

        StatusFeedbackModal.show(
          context,
          title: l10n.errorTitle,
          message: errorMessage.replaceAll('Exception: ', ''),
          type: FeedbackType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Header
              Text(
                l10n.createAccountTitle,
                style: const TextStyle(
                  fontSize: 28, // Reduced from 32
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.createAccountSubtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32), // Reduced from 48

              // Inputs
              AuthTextField(
                controller: _nameController,
                label: l10n.name,
                hint: l10n.nameHint,
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 12), // Reduced from 20
              AuthTextField(
                controller: _emailController,
                label: l10n.email,
                hint: l10n.emailHint,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12), // Reduced from 20
              AuthTextField(
                controller: _passwordController,
                label: l10n.password,
                hint: l10n.passwordHint,
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 12), // Reduced from 20
              AuthTextField(
                controller: _confirmPasswordController,
                label: l10n.confirmPassword,
                hint: l10n.passwordHint,
                icon: Icons.lock_outline,
                isPassword: true,
                textInputAction: TextInputAction.done,
              ),
              
              const SizedBox(height: 24), // Reduced from 32

              // Sign Up Button
              ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
                child: Text(
                  l10n.signUpButton,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 24), // Reduced from 40

              // Social Login
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.orContinueWith,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                ],
              ),
              const SizedBox(height: 16), // Reduced from 24
              const SocialLoginButtons(),

              const SizedBox(height: 24), // Reduced from 40

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.alreadyHaveAccount,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: Text(
                      l10n.loginButton,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
