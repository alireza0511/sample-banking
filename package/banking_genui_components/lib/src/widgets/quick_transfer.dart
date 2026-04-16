import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that displays a quick transfer form for moving money between accounts.
///
/// This widget is designed to be used with GenUI/A2UI for dynamic rendering
/// by AI agents in banking applications.
class QuickTransfer extends StatefulWidget {
  /// The source account name
  final String fromAccount;

  /// The destination account name or recipient
  final String toAccount;

  /// Pre-filled amount (optional)
  final double? initialAmount;

  /// Optional memo/note
  final String? memo;

  /// Callback when transfer is submitted
  final void Function(double amount, String? memo)? onSubmit;

  /// Callback when transfer is cancelled
  final VoidCallback? onCancel;

  const QuickTransfer({
    super.key,
    required this.fromAccount,
    required this.toAccount,
    this.initialAmount,
    this.memo,
    this.onSubmit,
    this.onCancel,
  });

  @override
  State<QuickTransfer> createState() => _QuickTransferState();
}

class _QuickTransferState extends State<QuickTransfer> {
  late final TextEditingController _amountController;
  late final TextEditingController _memoController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount?.toStringAsFixed(2) ?? '',
    );
    _memoController = TextEditingController(text: widget.memo ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      final memo = _memoController.text.isEmpty ? null : _memoController.text;
      widget.onSubmit?.call(amount, memo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.swap_horiz,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Quick Transfer',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // From/To accounts
              _AccountRow(
                label: 'From',
                accountName: widget.fromAccount,
                icon: Icons.arrow_upward,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              _AccountRow(
                label: 'To',
                accountName: widget.toAccount,
                icon: Icons.arrow_downward,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // Amount input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Memo input (optional)
              TextFormField(
                controller: _memoController,
                decoration: InputDecoration(
                  labelText: 'Memo (optional)',
                  hintText: 'What\'s this for?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  if (widget.onCancel != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  if (widget.onCancel != null) const SizedBox(width: 12),
                  Expanded(
                    flex: widget.onCancel != null ? 2 : 1,
                    child: FilledButton(
                      onPressed: _handleSubmit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Transfer'),
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

class _AccountRow extends StatelessWidget {
  final String label;
  final String accountName;
  final IconData icon;
  final Color color;

  const _AccountRow({
    required this.label,
    required this.accountName,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  accountName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
