import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/widgets.dart';
import '../bloc/cards_bloc.dart';
import '../model/card.dart';

/// Cards screen showing all cards
class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  late final CardsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = CardsBloc();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider<CardsBloc>.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cards'),
        ),
        body: StreamBuilder<CardsViewModel>(
          stream: _bloc.viewModelPipe.receive,
          builder: (context, snapshot) {
            final viewModel = snapshot.data;

            if (viewModel == null || viewModel.isLoading) {
              return const ShimmerList(itemHeight: 180);
            }

            if (viewModel.hasError) {
              return ErrorView(
                message: viewModel.errorMessage,
                onRetry: () => _bloc.refreshPipe.launch(),
              );
            }

            if (viewModel.isEmpty) {
              return EmptyView.noCards();
            }

            return RefreshIndicator(
              onRefresh: () async => _bloc.refreshPipe.launch(),
              child: _CardsList(viewModel: viewModel, bloc: _bloc),
            );
          },
        ),
      ),
    );
  }
}

class _CardsList extends StatelessWidget {
  final CardsViewModel viewModel;
  final CardsBloc bloc;

  const _CardsList({required this.viewModel, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        ...viewModel.cards.map(
          (card) => _CardWidget(
            card: card,
            isSelected: viewModel.selectedCard?.id == card.id,
            revealedDetails: viewModel.selectedCard?.id == card.id
                ? viewModel.revealedDetails
                : null,
            isTogglingFreeze: viewModel.isTogglingFreeze,
            isRevealingDetails: viewModel.isRevealingDetails,
            onTap: () => bloc.selectCardPipe.send(
              viewModel.selectedCard?.id == card.id ? null : card,
            ),
            onToggleFreeze: () => bloc.toggleFreezePipe.send(card),
            onRevealDetails: () => bloc.revealDetailsPipe.send(card),
            onHideDetails: () => bloc.hideDetailsPipe.launch(),
          ),
        ),
      ],
    );
  }
}

class _CardWidget extends StatelessWidget {
  final BankCard card;
  final bool isSelected;
  final CardDetails? revealedDetails;
  final bool isTogglingFreeze;
  final bool isRevealingDetails;
  final VoidCallback onTap;
  final VoidCallback onToggleFreeze;
  final VoidCallback onRevealDetails;
  final VoidCallback onHideDetails;

  const _CardWidget({
    required this.card,
    required this.isSelected,
    this.revealedDetails,
    required this.isTogglingFreeze,
    required this.isRevealingDetails,
    required this.onTap,
    required this.onToggleFreeze,
    required this.onRevealDetails,
    required this.onHideDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          // Card visual
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getCardGradient(),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Card content
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: network & virtual badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              card.networkDisplayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (card.isVirtual)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'VIRTUAL',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),

                        // Card number
                        Text(
                          revealedDetails?.cardNumber ?? card.maskedNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            letterSpacing: 2,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Bottom row: name & expiry
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CARDHOLDER',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  card.cardholderName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'EXPIRES',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  card.expirationDate,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Frozen overlay
                  if (card.isFrozen)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.ac_unit, color: Colors.white, size: 48),
                            SizedBox(height: 8),
                            Text(
                              'FROZEN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Card actions (expanded)
          if (isSelected) ...[
            const SizedBox(height: AppSpacing.sm),
            _CardActions(
              card: card,
              revealedDetails: revealedDetails,
              isTogglingFreeze: isTogglingFreeze,
              isRevealingDetails: isRevealingDetails,
              onToggleFreeze: onToggleFreeze,
              onRevealDetails: onRevealDetails,
              onHideDetails: onHideDetails,
            ),
          ],
        ],
      ),
    );
  }

  List<Color> _getCardGradient() {
    if (card.isFrozen) {
      return [Colors.blueGrey[400]!, Colors.blueGrey[600]!];
    }
    switch (card.network) {
      case CardNetwork.visa:
        return [const Color(0xFF1A1F71), const Color(0xFF232B5D)];
      case CardNetwork.mastercard:
        return [const Color(0xFFEB001B), const Color(0xFFF79E1B)];
      case CardNetwork.amex:
        return [const Color(0xFF006FCF), const Color(0xFF0050AA)];
      case CardNetwork.discover:
        return [const Color(0xFFFF6000), const Color(0xFFD14700)];
    }
  }
}

class _CardActions extends StatelessWidget {
  final BankCard card;
  final CardDetails? revealedDetails;
  final bool isTogglingFreeze;
  final bool isRevealingDetails;
  final VoidCallback onToggleFreeze;
  final VoidCallback onRevealDetails;
  final VoidCallback onHideDetails;

  const _CardActions({
    required this.card,
    this.revealedDetails,
    required this.isTogglingFreeze,
    required this.isRevealingDetails,
    required this.onToggleFreeze,
    required this.onRevealDetails,
    required this.onHideDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Card info
            if (card.isCredit) ...[
              _InfoRow(
                label: 'Credit Limit',
                value: '\$${card.creditLimit?.toStringAsFixed(2) ?? '0.00'}',
              ),
              _InfoRow(
                label: 'Available Credit',
                value: '\$${card.availableCredit?.toStringAsFixed(2) ?? '0.00'}',
              ),
              _InfoRow(
                label: 'Current Balance',
                value: '\$${card.currentBalance?.toStringAsFixed(2) ?? '0.00'}',
              ),
            ] else ...[
              _InfoRow(
                label: 'Daily Limit',
                value: '\$${card.dailyLimit?.toStringAsFixed(2) ?? '0.00'}',
              ),
              _InfoRow(
                label: 'Monthly Limit',
                value: '\$${card.monthlyLimit?.toStringAsFixed(2) ?? '0.00'}',
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            // Revealed details
            if (revealedDetails != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Card Number'),
                        Row(
                          children: [
                            Text(
                              revealedDetails!.cardNumber,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: revealedDetails!.cardNumber),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Card number copied')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('CVV'),
                        Text(
                          revealedDetails!.cvv,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Expires'),
                        Text(revealedDetails!.expirationDate),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Details hidden in ${revealedDetails!.expiresInSeconds} seconds',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isTogglingFreeze ? null : onToggleFreeze,
                    icon: isTogglingFreeze
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(card.isFrozen ? Icons.lock_open : Icons.ac_unit),
                    label: Text(card.isFrozen ? 'Unfreeze' : 'Freeze'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: revealedDetails != null
                      ? OutlinedButton.icon(
                          onPressed: onHideDetails,
                          icon: const Icon(Icons.visibility_off),
                          label: const Text('Hide'),
                        )
                      : ElevatedButton.icon(
                          onPressed: isRevealingDetails ? null : onRevealDetails,
                          icon: isRevealingDetails
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.visibility),
                          label: const Text('Reveal'),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
