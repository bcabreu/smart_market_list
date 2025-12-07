import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_market_list/providers/auth_provider.dart';
import 'package:smart_market_list/providers/user_provider.dart';
import 'package:smart_market_list/ui/common/modals/loading_dialog.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';

class SocialLoginButtons extends ConsumerWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    Future<void> handleLogin(Future<void> Function() loginMethod, {String? defaultName}) async {
      LoadingDialog.show(context, l10n.processing);
      try {
        await loginMethod();
        
        final user = ref.read(authServiceProvider).currentUser;
        if (user != null) {
          if (user.displayName != null) {
            await ref.read(userNameProvider.notifier).setName(user.displayName!);
          } else if (defaultName != null) {
             await ref.read(userNameProvider.notifier).setName(defaultName);
          }
          
          if (user.email != null) {
            await ref.read(userEmailProvider.notifier).setEmail(user.email!);
          }

          await ref.read(isLoggedInProvider.notifier).setLoggedIn(true);
          
          if (context.mounted) {
            LoadingDialog.hide(context);
            // Pop until we find the root or a safe place
            Navigator.of(context).popUntil((route) => route.isFirst); 
          }
        }
      } catch (e) {
        if (context.mounted) {
          LoadingDialog.hide(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login falhou: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton(
              context, 
              FontAwesomeIcons.google, 
              isDark, 
              () => handleLogin(() => ref.read(authServiceProvider).signInWithGoogle())
            ),
            const SizedBox(width: 16),
            _buildButton(
              context, 
              FontAwesomeIcons.apple, 
              isDark, 
              () => handleLogin(() => ref.read(authServiceProvider).signInWithApple())
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => handleLogin(
             () => ref.read(authServiceProvider).signInAnonymously(),
             defaultName: 'Anônimo'
          ),
          icon: Icon(Icons.person_off_outlined, size: 18, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          label: Text(
            'Entrar como Anônimo',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(BuildContext context, IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark 
                ? Colors.white.withOpacity(0.1) 
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Center(
          child: FaIcon(
            icon,
            size: 24,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
