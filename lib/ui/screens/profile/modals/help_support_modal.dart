import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_market_list/core/theme/app_colors.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';

class HelpSupportModal extends StatelessWidget {
  const HelpSupportModal({super.key});

  Future<void> _contactSupport(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'contato@kepoweb.com',
      query: 'subject=${l10n.emailSubject}',
    );

    if (!await launchUrl(emailLaunchUri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorTitle)), // Fallback
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            l10n.helpSupport,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 24),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                // Contact Support Button
                ElevatedButton.icon(
                  onPressed: () => _contactSupport(context),
                  icon: const Icon(Icons.email_outlined),
                  label: Text(l10n.contactSupport),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  l10n.faq,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),

                _buildFaqItem(
                  context, 
                  l10n.faqHowToShare, 
                  l10n.faqHowToShareAnswer
                ),
                _buildFaqItem(
                  context, 
                  l10n.faqPremiumBenefits, 
                  l10n.faqPremiumBenefitsAnswer
                ),
                _buildFaqItem(
                  context, 
                  l10n.faqRestore, 
                  l10n.faqRestoreAnswer
                ),

                const SizedBox(height: 32),
                
                // Version
                Center(
                  child: Text(
                    '${l10n.appVersion} 1.0.0',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
