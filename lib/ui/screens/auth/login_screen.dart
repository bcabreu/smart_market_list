import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';
import 'package:smart_market_list/providers/user_provider.dart';

import 'package:smart_market_list/ui/screens/auth/signup_screen.dart';
import 'package:smart_market_list/ui/screens/auth/widgets/auth_text_field.dart';
import 'package:smart_market_list/ui/screens/auth/widgets/social_login_buttons.dart';
import 'package:smart_market_list/providers/auth_provider.dart';
import 'package:smart_market_list/core/services/sharing_service.dart';
import 'package:smart_market_list/providers/sharing_provider.dart';
import 'package:smart_market_list/ui/common/modals/loading_dialog.dart';
import 'package:smart_market_list/ui/common/modals/status_feedback_modal.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
      final l10n = AppLocalizations.of(context)!;
      final emailController = TextEditingController(text: _emailController.text);
      
      return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(l10n.resetPasswordTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.resetPasswordDescription),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    hintText: l10n.emailHint,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) return;
                  
                  Navigator.pop(context); // Close dialog
                  LoadingDialog.show(context, l10n.processing);
                  
                  try {
                     await ref.read(authServiceProvider).sendPasswordResetEmail(email);
                     
                     if (context.mounted) {
                       LoadingDialog.hide(context);
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(
                           content: Text(l10n.resetLinkSentMessage),
                           backgroundColor: Colors.green,
                         ),
                       );
                     }
                  } catch (e) {
                     if (context.mounted) {
                       LoadingDialog.hide(context);
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(
                           content: Text('Erro: ${e.toString()}'),
                           backgroundColor: Colors.red,
                         ),
                       );
                     }
                  }
                },
                child: Text(l10n.sendLink),
              ),
            ],
          );
        },
      );
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
        leading: Navigator.canPop(context) 
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
                onPressed: () => Navigator.pop(context),
              )
            : null,
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
                l10n.welcomeBack,
                style: const TextStyle(
                  fontSize: 28, // Reduced from 32
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.welcomeBackSubtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32), // Reduced from 48

              // Inputs
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
                textInputAction: TextInputAction.done,
              ),
              
              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showForgotPasswordDialog(context),
                  child: Text(
                    l10n.forgotPassword,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login Button
              ElevatedButton(
                onPressed: () async {
                  final email = _emailController.text.trim();
                  final password = _passwordController.text;
                  
                  if (email.isEmpty || password.isEmpty) return;
                  
                  FocusScope.of(context).unfocus();
                  LoadingDialog.show(context, l10n.processing);
                  
                  try {
                    await ref.read(authServiceProvider).signIn(
                      email: email, 
                      password: password
                    );
                    
                    // Update global state on success
                    await ref.read(userEmailProvider.notifier).setEmail(email);
                    
                    // Fetch Name from Firebase
                    final user = ref.read(authServiceProvider).currentUser;
                    if (user?.displayName != null) {
                      await ref.read(userNameProvider.notifier).setName(user!.displayName!);
                    }
                    
                    await ref.read(isLoggedInProvider.notifier).setLoggedIn(true);


                    
                    // Check for pending Deep Link Joins (Universal Links)
                    if (SharingService.pendingListId != null && SharingService.pendingFamilyId != null) {
                       try {
                         // We need the user UID, which we just fetched
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
                            
                            if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Lista compartilhada adicionada com sucesso!')),
                               );
                            }
                         }
                       } catch (e) {
                         print('Error joining pending list: $e');
                       }
                    }
                    
                    if (context.mounted) {
                      LoadingDialog.hide(context);
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      LoadingDialog.hide(context);
                      
                      String errorMessage = e.toString();
                      if (errorMessage.contains('invalid-credential') || errorMessage.contains('user-not-found') || errorMessage.contains('wrong-password')) {
                         errorMessage = l10n.invalidCredentialsError; // "E-mail ou senha incorretos"
                      } else if (errorMessage.contains('invalid-email')) {
                         errorMessage = l10n.invalidEmailError;
                      } else {
                         errorMessage = errorMessage.replaceAll('Exception: ', '');
                      }

                      StatusFeedbackModal.show(
                        context,
                        title: l10n.errorTitle,
                        message: errorMessage,
                        type: FeedbackType.error,
                      );
                    }
                  }
                },
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
                  l10n.loginButton,
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
                    l10n.dontHaveAccount,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: Text(
                      l10n.signUpButton,
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
