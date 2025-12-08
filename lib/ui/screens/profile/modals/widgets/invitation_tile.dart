import 'package:flutter/material.dart';
import 'package:smart_market_list/l10n/generated/app_localizations.dart';

class InvitationTile extends StatefulWidget {
  final String email;
  final VoidCallback onCancel;
  final bool isDark;

  const InvitationTile({
    super.key,
    required this.email,
    required this.onCancel,
    required this.isDark,
  });

  @override
  State<InvitationTile> createState() => _InvitationTileState();
}

class _InvitationTileState extends State<InvitationTile> {
  bool _isDeleting = false;

  Future<void> _handleCancel() async {
    setState(() => _isDeleting = true);
    await Future.delayed(const Duration(milliseconds: 300));
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      child: SizedBox(
        height: _isDeleting ? 0 : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isDeleting ? 0.0 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.orangeAccent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.access_time_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.inviteSentTitle,
                        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.orange),
                      ),
                      Text(
                        widget.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDark ? Colors.grey[400] : Colors.grey[600]
                        ),
                      ),
                    ],
                  ),
                ),
                 IconButton(
                   onPressed: _handleCancel, 
                   icon: const Icon(Icons.close, size: 18),
                   color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                   padding: EdgeInsets.zero,
                   constraints: const BoxConstraints(),
                 ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
