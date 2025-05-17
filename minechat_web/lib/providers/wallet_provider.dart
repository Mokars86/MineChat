import 'dart:async';
import 'package:flutter/material.dart';
import '../models/mining_models.dart';
import '../models/wallet_address.dart';
import '../services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();

  List<WalletTransaction> _transactions = [];
  List<WalletAddress> _walletAddresses = [];
  List<ExternalTransaction> _externalTransactions = [];
  double _balance = 0.0;
  bool _isLoading = false;
  String? _error;

  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _walletAddressesSubscription;
  StreamSubscription? _externalTransactionsSubscription;
  StreamSubscription? _balanceSubscription;

  List<WalletTransaction> get transactions => _transactions;
  List<WalletAddress> get walletAddresses => _walletAddresses;
  List<ExternalTransaction> get externalTransactions => _externalTransactions;
  double get balance => _balance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  WalletAddress? get defaultWalletAddress => _walletService.getDefaultWalletAddress();

  WalletProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _walletService.init();

      // Listen for transactions updates
      _transactionsSubscription = _walletService.transactionsStream.listen((transactions) {
        _transactions = transactions;
        notifyListeners();
      });

      // Listen for wallet addresses updates
      _walletAddressesSubscription = _walletService.walletAddressesStream.listen((addresses) {
        _walletAddresses = addresses;
        notifyListeners();
      });

      // Listen for external transactions updates
      _externalTransactionsSubscription = _walletService.externalTransactionsStream.listen((transactions) {
        _externalTransactions = transactions;
        notifyListeners();
      });

      // Listen for balance updates
      _balanceSubscription = _walletService.balanceStream.listen((balance) {
        _balance = balance;
        notifyListeners();
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction({
    required double amount,
    required String description,
    String? miningSessionId,
    required bool isDeposit,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _walletService.addTransaction(
        amount: amount,
        description: description,
        miningSessionId: miningSessionId,
        isDeposit: isDeposit,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createWalletAddress({
    required String label,
    bool isDefault = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _walletService.createWalletAddress(
        label: label,
        isDefault: isDefault,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendToExternalAddress({
    required String externalAddress,
    required double amount,
    String? note,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _walletService.sendToExternalAddress(
        externalAddress: externalAddress,
        amount: amount,
        note: note,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> receiveFromExternalAddress({
    required String externalAddress,
    required double amount,
    String? note,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _walletService.receiveFromExternalAddress(
        externalAddress: externalAddress,
        amount: amount,
        note: note,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> simulateReceiveFromExternal() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _walletService.simulateReceiveFromExternal();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    _walletAddressesSubscription?.cancel();
    _externalTransactionsSubscription?.cancel();
    _balanceSubscription?.cancel();
    super.dispose();
  }
}
