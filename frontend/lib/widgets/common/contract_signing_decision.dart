import 'package:flutter/material.dart';

import '../../services/owner/contract_service.dart';

Future<bool> closeContractSigning(
  BuildContext context, {
  required String contractId,
  required bool reject,
}) async {
  final label = reject ? 'Từ chối ký' : 'Thu hồi yêu cầu ký';
  var reason = '';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      scrollable: true,
      title: Text(label),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yêu cầu ký sẽ kết thúc và hợp đồng vẫn nằm trong lịch sử.',
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => reason = value,
            maxLength: 500,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Lý do (không bắt buộc)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Quay lại'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(label),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final error = await ContractService.closeSigning(
    contractId: contractId,
    reject: reject,
    reason: reason.trim(),
  );
  if (!context.mounted) return false;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(error ?? (reject ? 'Đã từ chối ký hợp đồng.' : 'Đã thu hồi yêu cầu ký.')),
  ));
  return error == null;
}

class ContractSigningDecisionDetails extends StatelessWidget {
  const ContractSigningDecisionDetails({
    super.key,
    required this.closedAt,
    required this.reason,
  });

  final String? closedAt;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.tryParse(closedAt ?? '')?.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final time = parsed == null
        ? null
        : '${localizations.formatCompactDate(parsed)} '
          '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(parsed))}';
    final hasReason = reason?.isNotEmpty == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (time != null) Text('Thời điểm xử lý: $time'),
        if (hasReason) Text('Lý do: $reason'),
      ],
    );
  }
}
