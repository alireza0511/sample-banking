import 'package:clean_framework/clean_framework.dart';

import '../../core/locator.dart';
import '../../core/network/api_client.dart';
import '../model/transaction.dart';

/// Entity for transactions screen
class TransactionsEntity extends Entity {
  final List<Transaction> transactions;
  final PaginationInfo? pagination;
  final String? accountId;
  final String? filter;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  TransactionsEntity({
    List<EntityFailure> errors = const [],
    this.transactions = const [],
    this.pagination,
    this.accountId,
    this.filter,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  }) : super(errors: errors);

  @override
  TransactionsEntity merge({
    List<EntityFailure>? errors,
    List<Transaction>? transactions,
    PaginationInfo? pagination,
    String? accountId,
    String? filter,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return TransactionsEntity(
      errors: errors ?? this.errors,
      transactions: transactions ?? this.transactions,
      pagination: pagination ?? this.pagination,
      accountId: accountId ?? this.accountId,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }

  bool get hasMore => pagination?.hasMore ?? false;
  bool get hasData => transactions.isNotEmpty;

  @override
  List<Object?> get props => [
        errors,
        transactions,
        pagination,
        accountId,
        filter,
        isLoading,
        isLoadingMore,
        errorMessage,
      ];
}

/// Use case for transactions
class TransactionsUseCase extends UseCase {
  final ViewModelCallback<TransactionsViewModel> _viewModelCallback;
  final ApiClient _apiClient;

  TransactionsEntity _entity = TransactionsEntity();

  TransactionsUseCase(
    this._viewModelCallback, {
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? AppLocator.apiClient;

  Future<void> loadTransactions({String? accountId, String? filter}) async {
    _entity = _entity.merge(
      isLoading: true,
      errorMessage: null,
      accountId: accountId,
      filter: filter,
    );
    _notifyListeners();

    try {
      final path = accountId != null
          ? 'api/v1/accounts/$accountId/transactions'
          : 'api/v1/accounts/acc_checking_001/transactions';

      final response = await _apiClient.get<Map<String, dynamic>>(path);

      response.fold(
        onSuccess: (data) {
          final txnList = (data['data']['transactions'] as List)
              .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
              .toList();
          final pagination = PaginationInfo.fromJson(
            data['data']['pagination'] as Map<String, dynamic>,
          );

          _entity = _entity.merge(
            transactions: txnList,
            pagination: pagination,
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
        errorMessage: 'Failed to load transactions: $e',
      );
      _notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_entity.isLoadingMore || !_entity.hasMore) return;

    _entity = _entity.merge(isLoadingMore: true);
    _notifyListeners();
    // In real app, would load next page
    // For demo, just simulate loading
    await Future.delayed(const Duration(milliseconds: 500));
    _entity = _entity.merge(isLoadingMore: false);
    _notifyListeners();
  }

  void setFilter(String? filter) {
    loadTransactions(accountId: _entity.accountId, filter: filter);
  }

  void _notifyListeners() {
    _viewModelCallback(TransactionsViewModel.fromEntity(_entity));
  }
}

/// View model for transactions
class TransactionsViewModel extends ViewModel {
  final List<Transaction> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final String? filter;

  TransactionsViewModel({
    required this.transactions,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    this.errorMessage,
    this.filter,
  });

  factory TransactionsViewModel.fromEntity(TransactionsEntity entity) {
    return TransactionsViewModel(
      transactions: entity.transactions,
      isLoading: entity.isLoading,
      isLoadingMore: entity.isLoadingMore,
      hasMore: entity.hasMore,
      errorMessage: entity.errorMessage,
      filter: entity.filter,
    );
  }

  factory TransactionsViewModel.initial() {
    return TransactionsViewModel(
      transactions: const [],
      isLoading: true,
      isLoadingMore: false,
      hasMore: false,
    );
  }

  bool get hasData => transactions.isNotEmpty;
  bool get hasError => errorMessage != null;
  bool get isEmpty => !isLoading && !hasError && transactions.isEmpty;

  /// Group transactions by date
  Map<String, List<Transaction>> get groupedByDate {
    final grouped = <String, List<Transaction>>{};
    for (final txn in transactions) {
      final key = _formatDateKey(txn.date);
      grouped.putIfAbsent(key, () => []).add(txn);
    }
    return grouped;
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txnDate = DateTime(date.year, date.month, date.day);

    if (txnDate == today) return 'Today';
    if (txnDate == yesterday) return 'Yesterday';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  List<Object?> get props => [
        transactions,
        isLoading,
        isLoadingMore,
        hasMore,
        errorMessage,
        filter,
      ];
}

/// Bloc for transactions
class TransactionsBloc extends Bloc {
  final String? initialAccountId;
  final String? initialFilter;

  late final TransactionsUseCase _useCase;

  final viewModelPipe = Pipe<TransactionsViewModel>();
  final loadMorePipe = EventPipe();
  final refreshPipe = EventPipe();
  final filterPipe = Pipe<String?>();

  @override
  void dispose() {
    viewModelPipe.dispose();
    loadMorePipe.dispose();
    refreshPipe.dispose();
    filterPipe.dispose();
  }

  TransactionsBloc({this.initialAccountId, this.initialFilter}) {
    _useCase = TransactionsUseCase(viewModelPipe.send);

    viewModelPipe.whenListenedDo(() {
      _useCase.loadTransactions(
        accountId: initialAccountId,
        filter: initialFilter,
      );
    });

    loadMorePipe.listen(_useCase.loadMore);
    refreshPipe.listen(() => _useCase.loadTransactions(
          accountId: initialAccountId,
          filter: initialFilter,
        ));
    filterPipe.receive.listen((filter) => _useCase.setFilter(filter));
  }
}
