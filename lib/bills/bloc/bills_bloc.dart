import 'package:clean_framework/clean_framework.dart';

import '../../core/locator.dart';
import '../../core/network/api_client.dart';
import '../model/bill.dart';

/// Entity for bills screen
class BillsEntity extends Entity {
  final List<Biller> billers;
  final Biller? selectedBiller;
  final double? paymentAmount;
  final DateTime? scheduledDate;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final bool paymentSuccess;

  BillsEntity({
    List<EntityFailure> errors = const [],
    this.billers = const [],
    this.selectedBiller,
    this.paymentAmount,
    this.scheduledDate,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.paymentSuccess = false,
  }) : super(errors: errors);

  @override
  BillsEntity merge({
    List<EntityFailure>? errors,
    List<Biller>? billers,
    Biller? selectedBiller,
    double? paymentAmount,
    DateTime? scheduledDate,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool? paymentSuccess,
  }) {
    return BillsEntity(
      errors: errors ?? this.errors,
      billers: billers ?? this.billers,
      selectedBiller: selectedBiller ?? this.selectedBiller,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      paymentSuccess: paymentSuccess ?? this.paymentSuccess,
    );
  }

  List<Biller> get dueSoon => billers.where((b) => b.isDueSoon).toList();
  List<Biller> get autopayEnabled => billers.where((b) => b.autopay).toList();
  double get totalDue => billers.fold(0, (sum, b) => sum + b.amountDue);

  @override
  List<Object?> get props => [
        errors,
        billers,
        selectedBiller,
        paymentAmount,
        scheduledDate,
        isLoading,
        isSubmitting,
        errorMessage,
        paymentSuccess,
      ];
}

/// Use case for bills
class BillsUseCase extends UseCase {
  final ViewModelCallback<BillsViewModel> _viewModelCallback;
  final ApiClient _apiClient;

  BillsEntity _entity = BillsEntity();

  BillsUseCase(
    this._viewModelCallback, {
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? AppLocator.apiClient;

  Future<void> loadBillers(
      {String? preSelectedBillerId, double? preSelectedAmount}) async {
    _entity = _entity.merge(isLoading: true, errorMessage: null);
    _notifyListeners();

    try {
      final response =
          await _apiClient.get<Map<String, dynamic>>('api/v1/bills');

      response.fold(
        onSuccess: (data) {
          final billerList = (data['data']['billers'] as List)
              .map((e) => Biller.fromJson(e as Map<String, dynamic>))
              .toList();

          Biller? preSelected;
          double? amount;
          if (preSelectedBillerId != null) {
            preSelected = billerList.firstWhere(
              (b) => b.id == preSelectedBillerId,
              orElse: () => billerList.first,
            );
            amount = preSelectedAmount ?? preSelected.amountDue;
          }

          _entity = _entity.merge(
            billers: billerList,
            selectedBiller: preSelected,
            paymentAmount: amount,
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
        errorMessage: 'Failed to load bills: $e',
      );
      _notifyListeners();
    }
  }

  void selectBiller(Biller? biller) {
    if (biller != null) {
      _entity = _entity.merge(
        selectedBiller: biller,
        paymentAmount: biller.amountDue,
      );
    } else {
      _entity = BillsEntity(billers: _entity.billers);
    }
    _notifyListeners();
  }

  void setAmount(double amount) {
    _entity = _entity.merge(paymentAmount: amount);
    _notifyListeners();
  }

  void setScheduledDate(DateTime date) {
    _entity = _entity.merge(scheduledDate: date);
    _notifyListeners();
  }

  Future<void> submitPayment() async {
    if (_entity.selectedBiller == null || _entity.paymentAmount == null) return;

    _entity = _entity.merge(isSubmitting: true, errorMessage: null);
    _notifyListeners();

    try {
      final request = BillPaymentRequest(
        billerId: _entity.selectedBiller!.id,
        amount: _entity.paymentAmount!,
        scheduledDate: _entity.scheduledDate ?? DateTime.now(),
      );

      final response = await _apiClient.post<Map<String, dynamic>>(
        'api/v1/bills/pay',
        body: request.toJson(),
      );

      response.fold(
        onSuccess: (data) {
          _entity = _entity.merge(
            isSubmitting: false,
            paymentSuccess: true,
          );
          _notifyListeners();
        },
        onError: (error, type) {
          _entity = _entity.merge(isSubmitting: false, errorMessage: error);
          _notifyListeners();
        },
      );
    } catch (e) {
      _entity = _entity.merge(
        isSubmitting: false,
        errorMessage: 'Payment failed: $e',
      );
      _notifyListeners();
    }
  }

  void reset() {
    _entity = BillsEntity();
    _notifyListeners();
    loadBillers();
  }

  void _notifyListeners() {
    _viewModelCallback(BillsViewModel.fromEntity(_entity));
  }
}

/// View model for bills
class BillsViewModel extends ViewModel {
  final List<Biller> billers;
  final List<Biller> dueSoon;
  final double totalDue;
  final Biller? selectedBiller;
  final double? paymentAmount;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final bool paymentSuccess;

  BillsViewModel({
    required this.billers,
    required this.dueSoon,
    required this.totalDue,
    this.selectedBiller,
    this.paymentAmount,
    required this.isLoading,
    required this.isSubmitting,
    this.errorMessage,
    required this.paymentSuccess,
  });

  factory BillsViewModel.fromEntity(BillsEntity entity) {
    return BillsViewModel(
      billers: entity.billers,
      dueSoon: entity.dueSoon,
      totalDue: entity.totalDue,
      selectedBiller: entity.selectedBiller,
      paymentAmount: entity.paymentAmount,
      isLoading: entity.isLoading,
      isSubmitting: entity.isSubmitting,
      errorMessage: entity.errorMessage,
      paymentSuccess: entity.paymentSuccess,
    );
  }

  factory BillsViewModel.initial() {
    return BillsViewModel(
      billers: const [],
      dueSoon: const [],
      totalDue: 0,
      isLoading: true,
      isSubmitting: false,
      paymentSuccess: false,
    );
  }

  bool get hasError => errorMessage != null;
  bool get isEmpty => !isLoading && billers.isEmpty;

  @override
  List<Object?> get props => [
        billers,
        dueSoon,
        totalDue,
        selectedBiller,
        paymentAmount,
        isLoading,
        isSubmitting,
        errorMessage,
        paymentSuccess,
      ];
}

/// Bloc for bills
class BillsBloc extends Bloc {
  final String? initialBillerId;
  final double? initialAmount;

  late final BillsUseCase _useCase;

  final viewModelPipe = Pipe<BillsViewModel>();
  final selectBillerPipe = Pipe<Biller?>();
  final setAmountPipe = Pipe<double>();
  final submitPipe = EventPipe();
  final resetPipe = EventPipe();

  @override
  void dispose() {
    viewModelPipe.dispose();
    selectBillerPipe.dispose();
    setAmountPipe.dispose();
    submitPipe.dispose();
    resetPipe.dispose();
  }

  BillsBloc({this.initialBillerId, this.initialAmount}) {
    _useCase = BillsUseCase(viewModelPipe.send);

    viewModelPipe.whenListenedDo(() {
      _useCase.loadBillers(
        preSelectedBillerId: initialBillerId,
        preSelectedAmount: initialAmount,
      );
    });

    selectBillerPipe.receive.listen((biller) => _useCase.selectBiller(biller));
    setAmountPipe.receive.listen((amount) => _useCase.setAmount(amount));
    submitPipe.listen(_useCase.submitPayment);
    resetPipe.listen(_useCase.reset);
  }
}
