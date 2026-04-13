import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../balance/model/account.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/haptic_feedback_helper.dart';
import '../../core/widgets/widgets.dart';
import '../bloc/transfer_bloc.dart';
import '../model/payee.dart';

/// Transfer screen with multi-step flow
class TransferScreen extends StatefulWidget {
  final String? initialRecipient;
  final String? initialAmount;

  const TransferScreen({
    super.key,
    this.initialRecipient,
    this.initialAmount,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  late final TransferBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = TransferBloc(
      initialRecipient: widget.initialRecipient,
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
    return Provider<TransferBloc>.value(
      value: _bloc,
      child: StreamBuilder<TransferViewModel>(
        stream: _bloc.viewModelPipe.receive,
        builder: (context, snapshot) {
          final viewModel = snapshot.data;

          return Scaffold(
            appBar: AppBar(
              title: Text(viewModel?.stepTitle ?? 'Transfer'),
              leading: viewModel?.step == TransferStep.success
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.pop(),
                    ),
            ),
            body: _buildBody(viewModel),
          );
        },
      ),
    );
  }

  Widget _buildBody(TransferViewModel? viewModel) {
    if (viewModel == null || viewModel.isLoading) {
      return const LoadingView(message: 'Loading...');
    }

    if (viewModel.hasError && viewModel.step != TransferStep.success) {
      return ErrorView(
        message: viewModel.errorMessage,
        onRetry: () => _bloc.resetPipe.launch(),
      );
    }

    switch (viewModel.step) {
      case TransferStep.selectPayee:
        return _PayeeSelectionStep(viewModel: viewModel, bloc: _bloc);
      case TransferStep.enterAmount:
        return _AmountEntryStep(viewModel: viewModel, bloc: _bloc);
      case TransferStep.confirm:
        return _ConfirmationStep(viewModel: viewModel, bloc: _bloc);
      case TransferStep.success:
        return _SuccessStep(viewModel: viewModel, bloc: _bloc);
    }
  }
}

/// Step 1: Select payee
class _PayeeSelectionStep extends StatelessWidget {
  final TransferViewModel viewModel;
  final TransferBloc bloc;

  const _PayeeSelectionStep({required this.viewModel, required this.bloc});

  @override
  Widget build(BuildContext context) {
    if (viewModel.payees.isEmpty) {
      return EmptyView.noPayees();
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Favorites section
        if (viewModel.favoritePayees.isNotEmpty) ...[
          Text(
            'Favorites',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...viewModel.favoritePayees.map(
            (payee) => _PayeeTile(
              payee: payee,
              onTap: () => bloc.selectPayeePipe.send(payee),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // All payees
        Text(
          'All Contacts',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...viewModel.payees.map(
          (payee) => _PayeeTile(
            payee: payee,
            onTap: () => bloc.selectPayeePipe.send(payee),
          ),
        ),
      ],
    );
  }
}

class _PayeeTile extends StatelessWidget {
  final Payee payee;
  final VoidCallback onTap;

  const _PayeeTile({required this.payee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Text(
            payee.name[0].toUpperCase(),
            style: TextStyle(color: AppColors.primaryBlue),
          ),
        ),
        title: Text(payee.name),
        subtitle: Text('${payee.typeDisplayName} • ${payee.maskedIdentifier}'),
        trailing: payee.isFavorite
            ? Icon(Icons.star, color: Colors.amber, size: 20)
            : null,
        onTap: onTap,
      ),
    );
  }
}

/// Step 2: Enter amount
class _AmountEntryStep extends StatefulWidget {
  final TransferViewModel viewModel;
  final TransferBloc bloc;

  const _AmountEntryStep({required this.viewModel, required this.bloc});

  @override
  State<_AmountEntryStep> createState() => _AmountEntryStepState();
}

class _AmountEntryStepState extends State<_AmountEntryStep> {
  late final TextEditingController _amountController;
  late final TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.viewModel.amount?.toStringAsFixed(2) ?? '',
    );
    _memoController = TextEditingController(text: widget.viewModel.memo ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              // Recipient info
              _RecipientCard(payee: widget.viewModel.selectedPayee!),
              const SizedBox(height: AppSpacing.lg),

              // Amount input
              Text(
                'Amount',
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
                  hintText: '0.00',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  if (amount != null) {
                    widget.bloc.setAmountPipe.send(amount);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Source account selector
              Text(
                'From Account',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              _AccountSelector(
                accounts: widget.viewModel.accounts,
                selectedAccount: widget.viewModel.selectedAccount,
                onSelect: (account) => widget.bloc.selectAccountPipe.send(account),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Memo
              Text(
                'Memo (optional)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _memoController,
                decoration: const InputDecoration(
                  hintText: 'What\'s it for?',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => widget.bloc.setMemoPipe.send(value),
              ),
            ],
          ),
        ),

        // Bottom buttons
        _BottomButtons(
          onBack: () => widget.bloc.previousStepPipe.launch(),
          onNext: widget.viewModel.canProceed
              ? () => widget.bloc.nextStepPipe.launch()
              : null,
          nextLabel: 'Continue',
        ),
      ],
    );
  }
}

class _RecipientCard extends StatelessWidget {
  final Payee payee;

  const _RecipientCard({required this.payee});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              payee.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sending to',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Text(
                payee.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountSelector extends StatelessWidget {
  final List<Account> accounts;
  final Account? selectedAccount;
  final ValueChanged<Account> onSelect;

  const _AccountSelector({
    required this.accounts,
    required this.selectedAccount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Account>(
      initialValue: selectedAccount,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ),
      items: accounts.map((account) {
        return DropdownMenuItem(
          value: account,
          child: Text('${account.name} (\$${account.availableBalance.toStringAsFixed(2)})'),
        );
      }).toList(),
      onChanged: (account) {
        if (account != null) onSelect(account);
      },
    );
  }
}

/// Step 3: Confirmation
class _ConfirmationStep extends StatelessWidget {
  final TransferViewModel viewModel;
  final TransferBloc bloc;

  const _ConfirmationStep({required this.viewModel, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              // Amount display
              Center(
                child: Column(
                  children: [
                    Text(
                      'You\'re sending',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '\$${viewModel.amount?.toStringAsFixed(2) ?? '0.00'}',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Details card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'To',
                        value: viewModel.selectedPayee?.name ?? '',
                      ),
                      const Divider(),
                      _DetailRow(
                        label: 'From',
                        value: viewModel.selectedAccount?.name ?? '',
                      ),
                      if (viewModel.memo?.isNotEmpty == true) ...[
                        const Divider(),
                        _DetailRow(
                          label: 'Memo',
                          value: viewModel.memo!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom buttons
        _BottomButtons(
          onBack: () => bloc.previousStepPipe.launch(),
          onNext: viewModel.isSubmitting ? null : () {
            HapticFeedbackHelper.mediumImpact();
            bloc.submitPipe.launch();
          },
          nextLabel: viewModel.isSubmitting ? 'Sending...' : 'Send Money',
          isLoading: viewModel.isSubmitting,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

/// Step 4: Success
class _SuccessStep extends StatelessWidget {
  final TransferViewModel viewModel;
  final TransferBloc bloc;

  const _SuccessStep({required this.viewModel, required this.bloc});

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
            child: Icon(
              Icons.check,
              size: 48,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Transfer Sent!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '\$${viewModel.amount?.toStringAsFixed(2)} to ${viewModel.selectedPayee?.name}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go(Routes.hub),
              child: const Text('Done'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                bloc.resetPipe.launch();
              },
              child: const Text('Send Another'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom navigation buttons
class _BottomButtons extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool isLoading;

  const _BottomButtons({
    this.onBack,
    this.onNext,
    required this.nextLabel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (onBack != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Back'),
                ),
              ),
            if (onBack != null) const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: onNext,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(nextLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
