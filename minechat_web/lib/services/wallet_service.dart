import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mining_models.dart';
import '../models/wallet_address.dart';
import 'auth_service.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  final List<WalletTransaction> _transactions = [];
  final List<WalletAddress> _walletAddresses = [];
  final List<ExternalTransaction> _externalTransactions = [];
  double _balance = 0.0;

  final _transactionsController = StreamController<List<WalletTransaction>>.broadcast();
  final _walletAddressesController = StreamController<List<WalletAddress>>.broadcast();
  final _externalTransactionsController = StreamController<List<ExternalTransaction>>.broadcast();
  final _balanceController = StreamController<double>.broadcast();

  Stream<List<WalletTransaction>> get transactionsStream => _transactionsController.stream;
  Stream<List<WalletAddress>> get walletAddressesStream => _walletAddressesController.stream;
  Stream<List<ExternalTransaction>> get externalTransactionsStream => _externalTransactionsController.stream;
  Stream<double> get balanceStream => _balanceController.stream;

  List<WalletTransaction> get transactions => _transactions;
  List<WalletAddress> get walletAddresses => _walletAddresses;
  List<ExternalTransaction> get externalTransactions => _externalTransactions;
  double get balance => _balance;

  // Initialize the wallet service
  Future<void> init() async {
    await _loadData();
    _calculateBalance();
    _notifyTransactionsListeners();
    _notifyWalletAddressesListeners();
    _notifyExternalTransactionsListeners();
    _notifyBalanceListeners();
  }

  // Load data from shared preferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load transactions
    final transactionsJson = prefs.getString('walletTransactions');
    if (transactionsJson != null) {
      final List<dynamic> transactionsData = jsonDecode(transactionsJson);
      _transactions.clear();
      _transactions.addAll(
        transactionsData.map((data) => WalletTransaction.fromJson(data)).toList()
      );

      // Sort transactions by timestamp (newest first)
      _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    // Load wallet addresses
    final walletAddressesJson = prefs.getString('walletAddresses');
    if (walletAddressesJson != null) {
      final List<dynamic> walletAddressesData = jsonDecode(walletAddressesJson);
      _walletAddresses.clear();
      _walletAddresses.addAll(
        walletAddressesData.map((data) => WalletAddress.fromJson(data)).toList()
      );
    }

    // Load external transactions
    final externalTransactionsJson = prefs.getString('externalTransactions');
    if (externalTransactionsJson != null) {
      final List<dynamic> externalTransactionsData = jsonDecode(externalTransactionsJson);
      _externalTransactions.clear();
      _externalTransactions.addAll(
        externalTransactionsData.map((data) => ExternalTransaction.fromJson(data)).toList()
      );

      // Sort external transactions by timestamp (newest first)
      _externalTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    // Create a default wallet address for the current user if none exists
    final authService = AuthService();
    final currentUser = authService.currentUser;
    if (currentUser != null) {
      final hasWalletAddress = _walletAddresses.any((addr) => addr.userId == currentUser.id);
      if (!hasWalletAddress) {
        _walletAddresses.add(WalletAddress(
          userId: currentUser.id,
          label: 'My MineChat Wallet',
          isDefault: true,
        ));
      }
    }
  }

  // Save data to shared preferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save transactions
    final transactionsJson = jsonEncode(_transactions.map((t) => t.toJson()).toList());
    await prefs.setString('walletTransactions', transactionsJson);

    // Save wallet addresses
    final walletAddressesJson = jsonEncode(_walletAddresses.map((a) => a.toJson()).toList());
    await prefs.setString('walletAddresses', walletAddressesJson);

    // Save external transactions
    final externalTransactionsJson = jsonEncode(_externalTransactions.map((t) => t.toJson()).toList());
    await prefs.setString('externalTransactions', externalTransactionsJson);
  }

  // Calculate the wallet balance
  void _calculateBalance() {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      _balance = 0.0;
      return;
    }

    // Calculate balance from transactions
    _balance = _transactions
        .where((t) => t.userId == currentUser.id)
        .fold(0.0, (sum, transaction) =>
            sum + (transaction.isDeposit ? transaction.amount : -transaction.amount));
  }

  // Add a new transaction
  Future<WalletTransaction> addTransaction({
    required double amount,
    required String description,
    String? miningSessionId,
    required bool isDeposit,
  }) async {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Create a new transaction
    final transaction = WalletTransaction(
      timestamp: DateTime.now(),
      amount: amount,
      description: description,
      userId: currentUser.id,
      miningSessionId: miningSessionId,
      isDeposit: isDeposit,
    );

    _transactions.insert(0, transaction);

    await _saveData();
    _calculateBalance();
    _notifyTransactionsListeners();
    _notifyBalanceListeners();

    return transaction;
  }

  // Add a transaction for a specific user (used for sending crypto to others)
  Future<WalletTransaction> addTransactionForUser({
    required String userId,
    required double amount,
    required String description,
    String? miningSessionId,
    required bool isDeposit,
  }) async {
    // Create a new transaction
    final transaction = WalletTransaction(
      timestamp: DateTime.now(),
      amount: amount,
      description: description,
      userId: userId,
      miningSessionId: miningSessionId,
      isDeposit: isDeposit,
    );

    _transactions.insert(0, transaction);

    await _saveData();
    _calculateBalance();
    _notifyTransactionsListeners();
    _notifyBalanceListeners();

    return transaction;
  }

  // Get transactions for a specific user
  List<WalletTransaction> getTransactionsForUser(String userId) {
    return _transactions.where((transaction) => transaction.userId == userId).toList();
  }

  // Get the default wallet address for the current user
  WalletAddress? getDefaultWalletAddress() {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) return null;

    try {
      return _walletAddresses.firstWhere(
        (addr) => addr.userId == currentUser.id && addr.isDefault,
      );
    } catch (e) {
      return null;
    }
  }

  // Create a new wallet address
  Future<WalletAddress> createWalletAddress({
    required String label,
    bool isDefault = false,
  }) async {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // If this is the default address, update other addresses
    if (isDefault) {
      for (int i = 0; i < _walletAddresses.length; i++) {
        if (_walletAddresses[i].userId == currentUser.id && _walletAddresses[i].isDefault) {
          _walletAddresses[i] = _walletAddresses[i].copyWith(isDefault: false);
        }
      }
    }

    // Create a new wallet address
    final walletAddress = WalletAddress(
      userId: currentUser.id,
      label: label,
      isDefault: isDefault,
    );

    _walletAddresses.add(walletAddress);

    await _saveData();
    _notifyWalletAddressesListeners();

    return walletAddress;
  }

  // Send crypto to an external address
  Future<ExternalTransaction> sendToExternalAddress({
    required String externalAddress,
    required double amount,
    String? note,
  }) async {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Check if user has enough balance
    if (amount > _balance) {
      throw Exception('Insufficient balance');
    }

    // Get the default wallet address
    final walletAddress = getDefaultWalletAddress();
    if (walletAddress == null) {
      throw Exception('No wallet address found');
    }

    // Create a new external transaction
    final transaction = ExternalTransaction(
      walletAddress: walletAddress.address,
      externalAddress: externalAddress,
      amount: amount,
      isOutgoing: true,
      status: TransactionStatus.pending,
      userId: currentUser.id,
      note: note,
    );

    _externalTransactions.add(transaction);

    // Create a wallet transaction for the outgoing amount
    final walletTransaction = WalletTransaction(
      timestamp: transaction.timestamp,
      amount: amount,
      description: 'Sent to external wallet',
      userId: currentUser.id,
      isDeposit: false,
    );

    _transactions.add(walletTransaction);

    // Simulate transaction processing
    await Future.delayed(const Duration(seconds: 2));

    // Update transaction status to completed
    final transactionIndex = _externalTransactions.indexWhere((t) => t.id == transaction.id);
    if (transactionIndex != -1) {
      _externalTransactions[transactionIndex] = _externalTransactions[transactionIndex].copyWith(
        status: TransactionStatus.completed,
      );
    }

    await _saveData();
    _calculateBalance();
    _notifyTransactionsListeners();
    _notifyExternalTransactionsListeners();
    _notifyBalanceListeners();

    return transaction;
  }

  // Receive crypto from an external address
  Future<ExternalTransaction> receiveFromExternalAddress({
    required String externalAddress,
    required double amount,
    String? note,
  }) async {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Get the default wallet address
    final walletAddress = getDefaultWalletAddress();
    if (walletAddress == null) {
      throw Exception('No wallet address found');
    }

    // Create a new external transaction
    final transaction = ExternalTransaction(
      walletAddress: walletAddress.address,
      externalAddress: externalAddress,
      amount: amount,
      isOutgoing: false,
      status: TransactionStatus.pending,
      userId: currentUser.id,
      note: note,
    );

    _externalTransactions.add(transaction);

    // Simulate transaction processing
    await Future.delayed(const Duration(seconds: 2));

    // Update transaction status to completed
    final transactionIndex = _externalTransactions.indexWhere((t) => t.id == transaction.id);
    if (transactionIndex != -1) {
      _externalTransactions[transactionIndex] = _externalTransactions[transactionIndex].copyWith(
        status: TransactionStatus.completed,
      );
    }

    // Create a wallet transaction for the incoming amount
    final walletTransaction = WalletTransaction(
      timestamp: transaction.timestamp,
      amount: amount,
      description: 'Received from external wallet',
      userId: currentUser.id,
      isDeposit: true,
    );

    _transactions.add(walletTransaction);

    await _saveData();
    _calculateBalance();
    _notifyTransactionsListeners();
    _notifyExternalTransactionsListeners();
    _notifyBalanceListeners();

    return transaction;
  }

  // Simulate receiving crypto from an external address (for demo purposes)
  Future<ExternalTransaction> simulateReceiveFromExternal() async {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Generate a random amount between 0.1 and 5.0
    final random = Random();
    final amount = 0.1 + random.nextDouble() * 4.9;

    // Generate a random external address
    final externalAddress = 'MC${random.nextInt(100000000).toString().padLeft(8, '0')}';

    return receiveFromExternalAddress(
      externalAddress: externalAddress,
      amount: amount,
      note: 'Simulated external transaction',
    );
  }

  void _notifyTransactionsListeners() {
    _transactionsController.add(_transactions);
  }

  void _notifyWalletAddressesListeners() {
    _walletAddressesController.add(_walletAddresses);
  }

  void _notifyExternalTransactionsListeners() {
    _externalTransactionsController.add(_externalTransactions);
  }

  void _notifyBalanceListeners() {
    _balanceController.add(_balance);
  }

  void dispose() {
    _transactionsController.close();
    _walletAddressesController.close();
    _externalTransactionsController.close();
    _balanceController.close();
  }
}
