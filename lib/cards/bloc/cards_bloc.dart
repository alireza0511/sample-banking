import 'package:clean_framework/clean_framework.dart';

import '../../core/locator.dart';
import '../../core/network/api_client.dart';
import '../model/card.dart';

/// Entity for cards screen
class CardsEntity extends Entity {
  final List<BankCard> cards;
  final BankCard? selectedCard;
  final CardDetails? revealedDetails;
  final bool isLoading;
  final bool isTogglingFreeze;
  final bool isRevealingDetails;
  final String? errorMessage;

  CardsEntity({
    List<EntityFailure> errors = const [],
    this.cards = const [],
    this.selectedCard,
    this.revealedDetails,
    this.isLoading = false,
    this.isTogglingFreeze = false,
    this.isRevealingDetails = false,
    this.errorMessage,
  }) : super(errors: errors);

  @override
  CardsEntity merge({
    List<EntityFailure>? errors,
    List<BankCard>? cards,
    BankCard? selectedCard,
    CardDetails? revealedDetails,
    bool? isLoading,
    bool? isTogglingFreeze,
    bool? isRevealingDetails,
    String? errorMessage,
    bool clearSelection = false,
    bool clearRevealedDetails = false,
  }) {
    return CardsEntity(
      errors: errors ?? this.errors,
      cards: cards ?? this.cards,
      selectedCard: clearSelection ? null : (selectedCard ?? this.selectedCard),
      revealedDetails:
          clearRevealedDetails ? null : (revealedDetails ?? this.revealedDetails),
      isLoading: isLoading ?? this.isLoading,
      isTogglingFreeze: isTogglingFreeze ?? this.isTogglingFreeze,
      isRevealingDetails: isRevealingDetails ?? this.isRevealingDetails,
      errorMessage: errorMessage,
    );
  }

  List<BankCard> get activeCards => cards.where((c) => c.isActive).toList();
  List<BankCard> get frozenCards => cards.where((c) => c.isFrozen).toList();

  @override
  List<Object?> get props => [
        errors,
        cards,
        selectedCard,
        revealedDetails,
        isLoading,
        isTogglingFreeze,
        isRevealingDetails,
        errorMessage,
      ];
}

/// Use case for cards
class CardsUseCase extends UseCase {
  final ViewModelCallback<CardsViewModel> _viewModelCallback;
  final ApiClient _apiClient;

  CardsEntity _entity = CardsEntity();

  CardsUseCase(
    this._viewModelCallback, {
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? AppLocator.apiClient;

  Future<void> loadCards() async {
    _entity = _entity.merge(isLoading: true, errorMessage: null);
    _notifyListeners();

    try {
      final response =
          await _apiClient.get<Map<String, dynamic>>('api/v1/cards');

      response.fold(
        onSuccess: (data) {
          final cardList = (data['data']['cards'] as List)
              .map((e) => BankCard.fromJson(e as Map<String, dynamic>))
              .toList();

          _entity = _entity.merge(
            cards: cardList,
            isLoading: false,
          );
          _notifyListeners();
        },
        onError: (error, type) {
          _entity = _entity.merge(isLoading: false, errorMessage: error);
          _notifyListeners();
        },
      );
    } catch (e) {
      _entity = _entity.merge(
        isLoading: false,
        errorMessage: 'Failed to load cards: $e',
      );
      _notifyListeners();
    }
  }

  void selectCard(BankCard? card) {
    if (card != null) {
      _entity = _entity.merge(selectedCard: card, clearRevealedDetails: true);
    } else {
      _entity = _entity.merge(clearSelection: true, clearRevealedDetails: true);
    }
    _notifyListeners();
  }

  Future<void> toggleFreeze(BankCard card) async {
    _entity = _entity.merge(isTogglingFreeze: true, errorMessage: null);
    _notifyListeners();

    try {
      final action = card.isFrozen ? 'unfreeze' : 'freeze';
      final response = await _apiClient.post<Map<String, dynamic>>(
        'api/v1/cards/${card.id}/toggle-freeze',
        body: {'action': action},
      );

      response.fold(
        onSuccess: (data) {
          // Update the card in the list
          final updatedCards = _entity.cards.map((c) {
            if (c.id == card.id) {
              return BankCard(
                id: c.id,
                type: c.type,
                network: c.network,
                lastFour: c.lastFour,
                cardholderName: c.cardholderName,
                expirationDate: c.expirationDate,
                status: card.isFrozen ? CardStatus.active : CardStatus.frozen,
                linkedAccountId: c.linkedAccountId,
                isVirtual: c.isVirtual,
                dailyLimit: c.dailyLimit,
                monthlyLimit: c.monthlyLimit,
                creditLimit: c.creditLimit,
                availableCredit: c.availableCredit,
                currentBalance: c.currentBalance,
              );
            }
            return c;
          }).toList();

          _entity = _entity.merge(
            cards: updatedCards,
            isTogglingFreeze: false,
          );
          _notifyListeners();
        },
        onError: (error, type) {
          _entity =
              _entity.merge(isTogglingFreeze: false, errorMessage: error);
          _notifyListeners();
        },
      );
    } catch (e) {
      _entity = _entity.merge(
        isTogglingFreeze: false,
        errorMessage: 'Failed to update card: $e',
      );
      _notifyListeners();
    }
  }

  Future<void> revealCardDetails(BankCard card) async {
    _entity = _entity.merge(isRevealingDetails: true, errorMessage: null);
    _notifyListeners();

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'api/v1/cards/${card.id}/reveal',
      );

      response.fold(
        onSuccess: (data) {
          final details =
              CardDetails.fromJson(data['data'] as Map<String, dynamic>);
          _entity = _entity.merge(
            revealedDetails: details,
            isRevealingDetails: false,
          );
          _notifyListeners();
        },
        onError: (error, type) {
          _entity =
              _entity.merge(isRevealingDetails: false, errorMessage: error);
          _notifyListeners();
        },
      );
    } catch (e) {
      _entity = _entity.merge(
        isRevealingDetails: false,
        errorMessage: 'Failed to reveal card details: $e',
      );
      _notifyListeners();
    }
  }

  void hideCardDetails() {
    _entity = _entity.merge(clearRevealedDetails: true);
    _notifyListeners();
  }

  void _notifyListeners() {
    _viewModelCallback(CardsViewModel.fromEntity(_entity));
  }
}

/// View model for cards
class CardsViewModel extends ViewModel {
  final List<BankCard> cards;
  final BankCard? selectedCard;
  final CardDetails? revealedDetails;
  final bool isLoading;
  final bool isTogglingFreeze;
  final bool isRevealingDetails;
  final String? errorMessage;

  CardsViewModel({
    required this.cards,
    this.selectedCard,
    this.revealedDetails,
    required this.isLoading,
    required this.isTogglingFreeze,
    required this.isRevealingDetails,
    this.errorMessage,
  });

  factory CardsViewModel.fromEntity(CardsEntity entity) {
    return CardsViewModel(
      cards: entity.cards,
      selectedCard: entity.selectedCard,
      revealedDetails: entity.revealedDetails,
      isLoading: entity.isLoading,
      isTogglingFreeze: entity.isTogglingFreeze,
      isRevealingDetails: entity.isRevealingDetails,
      errorMessage: entity.errorMessage,
    );
  }

  factory CardsViewModel.initial() {
    return CardsViewModel(
      cards: const [],
      isLoading: true,
      isTogglingFreeze: false,
      isRevealingDetails: false,
    );
  }

  bool get hasError => errorMessage != null;
  bool get isEmpty => !isLoading && cards.isEmpty;
  bool get hasRevealedDetails => revealedDetails != null;

  @override
  List<Object?> get props => [
        cards,
        selectedCard,
        revealedDetails,
        isLoading,
        isTogglingFreeze,
        isRevealingDetails,
        errorMessage,
      ];
}

/// Bloc for cards
class CardsBloc extends Bloc {
  late final CardsUseCase _useCase;

  final viewModelPipe = Pipe<CardsViewModel>();
  final selectCardPipe = Pipe<BankCard?>();
  final toggleFreezePipe = Pipe<BankCard>();
  final revealDetailsPipe = Pipe<BankCard>();
  final hideDetailsPipe = EventPipe();
  final refreshPipe = EventPipe();

  @override
  void dispose() {
    viewModelPipe.dispose();
    selectCardPipe.dispose();
    toggleFreezePipe.dispose();
    revealDetailsPipe.dispose();
    hideDetailsPipe.dispose();
    refreshPipe.dispose();
  }

  CardsBloc() {
    _useCase = CardsUseCase(viewModelPipe.send);

    viewModelPipe.whenListenedDo(_useCase.loadCards);

    selectCardPipe.receive.listen((card) => _useCase.selectCard(card));
    toggleFreezePipe.receive.listen((card) => _useCase.toggleFreeze(card));
    revealDetailsPipe.receive.listen((card) => _useCase.revealCardDetails(card));
    hideDetailsPipe.listen(_useCase.hideCardDetails);
    refreshPipe.listen(_useCase.loadCards);
  }
}
