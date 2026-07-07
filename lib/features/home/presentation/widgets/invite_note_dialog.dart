import 'package:flutter/material.dart';

import '../../../../core/domain/models.dart';
import '../../../../core/services/app_services.dart';
import '../../../../core/services/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pro_upsell.dart';

/// Invitation-note modal (DESIGN_SPEC §6.3): "Add a note to your invitation".
///
/// Returns:
///  * `null`  — the user dismissed/cancelled (do NOT send the request),
///  * `''`    — the user tapped Skip (send the request without a note),
///  * text    — the trimmed note to attach to the request.
Future<String?> showInviteNoteDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black45,
    builder: (_) => const _InviteNoteDialog(),
  );
}

/// Full connect flow shared by Discover and the nearby-person profile:
/// invite-note dialog → [ConnectionService.sendRequest] → outcome feedback
/// (SnackBar on success, Pro upsell on quota hits).
///
/// Returns `true` when the request was actually sent (BLE or relay).
Future<bool> sendConnectRequestFlow(
  BuildContext context, {
  required ProfileCard toCard,
  String? encounterId,
}) async {
  final note = await showInviteNoteDialog(context);
  if (note == null || !context.mounted) return false;

  final outcome = await AppServices.I.connection.sendRequest(
    toCard: toCard,
    note: note.isEmpty ? null : note,
    encounterId: encounterId,
  );
  if (!context.mounted) return false;

  switch (outcome) {
    case SendRequestOutcome.sentNearby:
    case SendRequestOutcome.sentRelay:
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Request sent to ${toCard.name}'),
        behavior: SnackBarBehavior.floating,
      ));
      return true;
    case SendRequestOutcome.quotaExceeded:
      await showProUpsell(
        context,
        reason: 'You have used your ${ProLimits.freeRequestsPerDay} free '
            'requests for today.',
      );
      return false;
    case SendRequestOutcome.noteQuotaExceeded:
      await showProUpsell(
        context,
        reason: 'Invitation notes are a Pro feature.',
      );
      return false;
    case SendRequestOutcome.failed:
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not send the request. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ));
      return false;
  }
}

class _InviteNoteDialog extends StatefulWidget {
  const _InviteNoteDialog();

  @override
  State<_InviteNoteDialog> createState() => _InviteNoteDialogState();
}

class _InviteNoteDialogState extends State<_InviteNoteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a note to your invitation',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Ex: We met at the expo ....',
                  hintStyle:
                      TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(''),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B6B6B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_controller.text.trim()),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Send',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
