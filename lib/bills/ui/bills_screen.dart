import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/haptic_feedback_helper.dart';
import '../../core/widgets/widgets.dart';
import '../bloc/bills_bloc.dart';
import '../model/bill.dart';

/// Bills screen for paying bills
class BillsScreen extends StatefulWidget {
  final String? initialBillerId;
  final String? initialAmount;

  const BillsScreen({
    super.key,
    this.initialBillerId,
    this.initialAmount,
  });

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  late final BillsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = BillsBloc(
      initialBillerId: widget.initialBillerId,
      initialAmount: widget.initialAmount != null
          ? double.tryParse(widget.initialAmount!)
          : null,
    );
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider<BillsBloc>.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pay Bills'),
        ),
        body: StreamBuilder<BillsViewModel>(
          stream: _bloc.viewModelPipe.receive,
          builder: (context, snapshot) {
            final viewModel = snapshot.data;

            if (viewModel == null || viewModel.isLoading) {
              return const ShimmerList();
            }

            if (viewModel.hasError) {
              return ErrorView(
                message: viewModel.errorMessage,
                onRetry: () => _bloc.resetPipe.launch(),
              );
            }

            if (viewModel.isEmpty) {
              return EmptyView.noBills();
            }

            if (viewModel.paymentSuccess) {
              return _SuccessView(
                biller: viewModel.selectedBiller!,
                amount: viewModel.paymentAmount!,
                onDone: () => context.go(Routes.hub),
                onPayAnother: () => _bloc.resetPipe.launch(),
              );
            }

            if (viewModel.selectedBiller != null) {
              return _PaymentForm(viewModel: viewModel, bloc: _bloc);
            }

            return RefreshIndicator(
              onRefresh: () async => _bloc.resetPipe.launch(),
              child: _BillerList(viewModel: viewModel, bloc: _bloc),
            );
          },
        ),
      ),
    );
  }
}

class _BillerList extends StatelessWidget {
  final BillsViewModel viewModel;
  final BillsBloc bloc;

  const _BillerList({required this.viewModel, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Due',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  Text(
                    '\$${viewModel.totalDue.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              if (viewModel.dueSoon.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '${viewModel.dueSoon.length} due soon',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Billers list
        Text(
          'Your Billers',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...viewModel.billers.map(
          (biller) => _BillerTile(
            biller: biller,
            onTap: () => bloc.selectBillerPipe.send(biller),
          ),
        ),
      ],
    );
  }
}

class _BillerTile extends StatelessWidget {
  final Biller biller;
  final VoidCallback onTap;

  const _BillerTile({required this.biller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _getCategoryColor(biller.category).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            _getCategoryIcon(biller.category),
            color: _getCategoryColor(biller.category),
          ),
        ),
        title: Text(biller.name),
        subtitle: Row(
          children: [
            Text('Due ${biller.formattedDueDate}'),
            if (biller.autopay) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.autorenew, size: 14, color: AppColors.success),
              const SizedBox(width: 2),
              Text(
                'Autopay',
                style: TextStyle(color: AppColors.success, fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${biller.amountDue.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (biller.isDueSoon)
              Text(
                'Due soon',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'utilities':
        return Icons.bolt;
      case 'credit':
        return Icons.credit_card;
      case 'insurance':
        return Icons.security;
      default:
        return Icons.receipt;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'utilities':
        return Colors.blue;
      case 'credit':
        return Colors.purple;
      case 'insurance':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _PaymentForm extends StatefulWidget {
  final BillsViewModel viewModel;
  final BillsBloc bloc;

  const _PaymentForm({required this.viewModel, required this.bloc});

  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.viewModel.paymentAmount?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final biller = widget.viewModel.selectedBiller!;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              // Biller info
              Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text(biller.name),
                  subtitle: Text('Account ${biller.accountNumber}'),
                  trailing: TextButton(
                    onPressed: () => widget.bloc.selectBillerPipe.send(null),
                    child: const Text('Change'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Amount
              Text(
                'Payment Amount',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: Theme.of(context).textTheme.headlineMedium,
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: Theme.of(context).textTheme.headlineMedium,
                  border: const OutlineInputBorder(),
                  helperText: 'Amount due: \$${biller.amountDue.toStringAsFixed(2)}',
                ),
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  if (amount != null) {
                    widget.bloc.setAmountPipe.send(amount);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Quick amount buttons
              Row(
                children: [
                  _QuickAmountButton(
                    label: 'Minimum',
                    amount: biller.amountDue * 0.1,
                    onTap: (a) {
                      _amountController.text = a.toStringAsFixed(2);
                      widget.bloc.setAmountPipe.send(a);
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _QuickAmountButton(
                    label: 'Full Amount',
                    amount: biller.amountDue,
                    onTap: (a) {
                      _amountController.text = a.toStringAsFixed(2);
                      widget.bloc.setAmountPipe.send(a);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Submit button
        Container(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.viewModel.isSubmitting ||
                        widget.viewModel.paymentAmount == null
                    ? null
                    : () {
                        HapticFeedbackHelper.mediumImpact();
                        widget.bloc.submitPipe.launch();
                      },
                child: widget.viewModel.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Pay Now'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAmountButton extends StatelessWidget {
  final String label;
  final double amount;
  final ValueChanged<double> onTap;

  const _QuickAmountButton({
    required this.label,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => onTap(amount),
        child: Text('$label\n\$${amount.toStringAsFixed(2)}'),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final Biller biller;
  final double amount;
  final VoidCallback onDone;
  final VoidCallback onPayAnother;

  const _SuccessView({
    required this.biller,
    required this.amount,
    required this.onDone,
    required this.onPayAnother,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 48, color: AppColors.success),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Payment Scheduled!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '\$${amount.toStringAsFixed(2)} to ${biller.name}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onDone, child: const Text('Done')),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onPayAnother,
              child: const Text('Pay Another Bill'),
            ),
          ),
        ],
      ),
    );
  }
}
