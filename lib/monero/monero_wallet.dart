import 'dart:async';
import 'package:cake_wallet/entities/transaction_priority.dart';
import 'package:cake_wallet/monero/monero_amount_format.dart';
import 'package:cake_wallet/monero/monero_transaction_creation_exception.dart';
import 'package:cake_wallet/monero/monero_transaction_info.dart';
import 'package:cake_wallet/monero/monero_wallet_addresses.dart';
import 'package:cake_wallet/monero/monero_wallet_utils.dart';
import 'package:cw_monero/structs/pending_transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_monero/transaction_history.dart'
    as monero_transaction_history;
import 'package:cw_monero/wallet.dart';
import 'package:cw_monero/wallet.dart' as monero_wallet;
import 'package:cw_monero/transaction_history.dart' as transaction_history;
import 'package:cw_monero/monero_output.dart';
import 'package:cake_wallet/monero/monero_transaction_creation_credentials.dart';
import 'package:cake_wallet/monero/pending_monero_transaction.dart';
import 'package:cake_wallet/monero/monero_wallet_keys.dart';
import 'package:cake_wallet/monero/monero_balance.dart';
import 'package:cake_wallet/monero/monero_transaction_history.dart';
import 'package:cake_wallet/monero/account.dart';
import 'package:cake_wallet/core/pending_transaction.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/sync_status.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/entities/node.dart';
import 'package:cake_wallet/entities/monero_transaction_priority.dart';

part 'monero_wallet.g.dart';

const moneroBlockSize = 1000;

class MoneroWallet = MoneroWalletBase with _$MoneroWallet;

abstract class MoneroWalletBase extends WalletBase<MoneroBalance,
    MoneroTransactionHistory, MoneroTransactionInfo> with Store {
  MoneroWalletBase({WalletInfo walletInfo}) : super(walletInfo) {
    transactionHistory = MoneroTransactionHistory();
    balance = MoneroBalance(
        fullBalance: monero_wallet.getFullBalance(accountIndex: 0),
        unlockedBalance: monero_wallet.getFullBalance(accountIndex: 0));
    _isTransactionUpdating = false;
    _hasSyncAfterStartup = false;
    _lastTxHistoryUpdate = DateTime.now();
    walletAddresses = MoneroWalletAddresses(walletInfo);
    _onAccountChangeReaction =
        reaction((_) => walletAddresses.account, (Account account) {
      balance = MoneroBalance(
          fullBalance: monero_wallet.getFullBalance(accountIndex: account.id),
          unlockedBalance:
              monero_wallet.getUnlockedBalance(accountIndex: account.id));
      walletAddresses.updateSubaddressList(accountIndex: account.id);
    });
  }

  static const int _autoSaveInterval = 30;

  @override
  MoneroWalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  MoneroBalance balance;

  @override
  String get seed => monero_wallet.getSeed();

  @override
  MoneroWalletKeys get keys => MoneroWalletKeys(
      privateSpendKey: monero_wallet.getSecretSpendKey(),
      privateViewKey: monero_wallet.getSecretViewKey(),
      publicSpendKey: monero_wallet.getPublicSpendKey(),
      publicViewKey: monero_wallet.getPublicViewKey());

  SyncListener _listener;
  ReactionDisposer _onAccountChangeReaction;
  bool _isTransactionUpdating;
  bool _hasSyncAfterStartup;
  Timer _autoSaveTimer;
  bool _refreshPaused = false;
  DateTime _lastTxHistoryUpdate;

  Future<void> init() async {
    final stopwatch = Stopwatch()..start();
    print('[WALLET_INIT] Starting init()...');
    
    await walletAddresses.init();
    print('[WALLET_INIT] walletAddresses.init() done (${stopwatch.elapsedMilliseconds}ms)');
    
    balance = MoneroBalance(
        fullBalance: monero_wallet.getFullBalance(
            accountIndex: walletAddresses.account.id),
        unlockedBalance: monero_wallet.getUnlockedBalance(
            accountIndex: walletAddresses.account.id));
    print('[WALLET_INIT] balance set (${stopwatch.elapsedMilliseconds}ms)');
    
    _setListeners();
    print('[WALLET_INIT] listeners set (${stopwatch.elapsedMilliseconds}ms)');
    
    // Load transactions in background with delay to let UI render first
    print('[WALLET_INIT] Scheduling updateTransactions() in background...');
    Future.delayed(Duration(milliseconds: 500), () => updateTransactions());
    print('[WALLET_INIT] updateTransactions scheduled (${stopwatch.elapsedMilliseconds}ms)');

    if (walletInfo.isRecovery) {
      monero_wallet.setRecoveringFromSeed(isRecovery: walletInfo.isRecovery);

      if (monero_wallet.getCurrentHeight() <= 1) {
        monero_wallet.setRefreshFromBlockHeight(
            height: walletInfo.restoreHeight);
      }
    }
    print('[WALLET_INIT] recovery check done (${stopwatch.elapsedMilliseconds}ms)');

    _autoSaveTimer = Timer.periodic(
        Duration(seconds: _autoSaveInterval), (_) async => await save());
    print('[WALLET_INIT] DONE! Total: ${stopwatch.elapsedMilliseconds}ms');
  }

  @override
  void close() {
    _listener?.stop();
    _onAccountChangeReaction?.reaction?.dispose();
    _autoSaveTimer?.cancel();
    // Note: Don't call closeCurrentWallet() here - when switching wallets,
    // the new wallet is opened before close() is called on the old one,
    // so closeCurrentWallet() would close the NEW wallet instead.
    // The native wallet is properly closed by openWallet() before opening a new one.
  }

  void pauseRefresh() {
    if (_refreshPaused) {
      return;
    }

    _refreshPaused = true;
    _listener?.stop();
    monero_wallet.pauseRefresh();
  }

  void resumeRefresh() {
    if (!_refreshPaused) {
      return;
    }

    _refreshPaused = false;
    monero_wallet.resumeRefresh();
    _listener?.start();
  }

  @override
  Future<void> connectToNode({@required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();
      await monero_wallet.setupNode(
          address: node.uri.toString(),
          login: node.login,
          password: node.password,
          useSSL: node.isSSL,
          isLightWallet: false); // FIXME: hardcoded value
      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
      print(e);
    }
  }

  @override
  Future<void> startSync() async {
    try {
      _setInitialHeight();
    } catch (_) {}

    try {
      syncStatus = StartingSyncStatus();
      monero_wallet.startRefresh();
      _setListeners();
      _listener?.start();
    } catch (e) {
      syncStatus = FailedSyncStatus();
      print(e);
      rethrow;
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final _credentials = credentials as MoneroTransactionCreationCredentials;
    final outputs = _credentials.outputs;
    final hasMultiDestination = outputs.length > 1;
    final unlockedBalance = monero_wallet.getUnlockedBalance(
        accountIndex: walletAddresses.account.id);

    PendingTransactionDescription pendingTransactionDescription;

    if (!(syncStatus is SyncedSyncStatus)) {
      throw MoneroTransactionCreationException('The wallet is not synced.');
    }
/*
    if (hasMultiDestination) {
      if (outputs.any((item) => item.sendAll
          || item.formattedCryptoAmount <= 0)) {
        throw MoneroTransactionCreationException('Wrong balance. Not enough XMR on your balance.');
      }

      final int totalAmount = outputs.fold(0, (acc, value) =>
          // acc + value.formattedCryptoAmount);

      if (unlockedBalance < totalAmount) {
        throw MoneroTransactionCreationException('Wrong balance. Not enough XMR on your balance.');
      }

      final moneroOutputs = outputs.map((output) =>
          MoneroOutput(
              address: output.address,
              amount: output.cryptoAmount.replaceAll(',', '.')))
          // .toList();

      pendingTransactionDescription =
      await transaction_history.createTransactionMultDest(
          outputs: moneroOutputs,
          priorityRaw: _credentials.priority.serialize(),
          accountIndex: walletAddresses.account.id);
    } else {
*/
    final output = outputs.first;
    final address = output.address;
    final amount =
        output.sendAll ? null : output.cryptoAmount.replaceAll(',', '.');
    final formattedAmount =
        output.sendAll ? null : output.formattedCryptoAmount;

    if ((formattedAmount != null && unlockedBalance < formattedAmount) ||
        (formattedAmount == null && unlockedBalance <= 0)) {
      final formattedBalance = moneroAmountToString(amount: unlockedBalance);

      throw MoneroTransactionCreationException(
          'Incorrect unlocked balance. Unlocked: $formattedBalance. Transaction amount: ${output.cryptoAmount}.');
    }

    pendingTransactionDescription = await transaction_history.createTransaction(
        address: address,
        amount: amount,
        priorityRaw: _credentials.priority.serialize(),
        accountIndex: walletAddresses.account.id);
    //}

    return PendingMoneroTransaction(pendingTransactionDescription);
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int amount) {
    // FIXME: hardcoded value;

    if (priority is MoneroTransactionPriority) {
      switch (priority) {
        case MoneroTransactionPriority.slow:
          return 24590000;
        case MoneroTransactionPriority.regular:
          return 123050000;
        case MoneroTransactionPriority.medium:
          return 245029999;
        case MoneroTransactionPriority.fast:
          return 614530000;
        case MoneroTransactionPriority.fastest:
          return 26021600000;
      }
    }

    return 0;
  }

  @override
  Future<void> save() async {
    await walletAddresses.updateAddressesInBox();
    await backupWalletFiles(name);
    await monero_wallet.store();
  }

  Future<int> getNodeHeight() async => monero_wallet.getNodeHeight();

  Future<bool> isConnected() async => monero_wallet.isConnected();

  Future<void> setAsRecovered() async {
    walletInfo.isRecovery = false;
    await walletInfo.save();
  }

  @override
  Future<void> rescan({int height}) async {
    print('MoneroWallet.rescan: height=$height');
    walletInfo.restoreHeight = height;
    walletInfo.isRecovery = true;
    monero_wallet.setRefreshFromBlockHeight(height: height);
    monero_wallet.rescanBlockchainAsync();
    await startSync();
    _askForUpdateBalance();
    walletAddresses.accountList.update();
    await _askForUpdateTransactionHistory();
    await save();
    await walletInfo.save();
  }

  String getTransactionAddress(int accountIndex, int addressIndex) =>
      monero_wallet.getAddress(
          accountIndex: accountIndex, addressIndex: addressIndex);

  // Track how many transactions we've loaded (for incremental loading)
  int _loadedTransactionsCount = 0;
  int _totalTransactionsCount = 0;
  bool _isLoadingMore = false;
  
  /// Initial batch size for first load (most recent transactions)
  static const int _initialBatchSize = 500;
  /// Batch size for loading more when scrolling  
  static const int _loadMoreBatchSize = 500;

  /// Check if there are more old transactions to load
  bool get hasMoreTransactions => _loadedTransactionsCount < _totalTransactionsCount;
  
  /// How many transactions are not yet loaded
  int get remainingTransactionsCount => _totalTransactionsCount - _loadedTransactionsCount;

  @override
  Future<Map<String, MoneroTransactionInfo>> fetchTransactions() async {
    // Initial load - only fetch the most recent transactions
    final stopwatch = Stopwatch()..start();
    print('[FETCH_TX] Starting initial load (last $_initialBatchSize)...');
    
    monero_transaction_history.refreshTransactions();
    _totalTransactionsCount = monero_transaction_history.countOfTransactions();
    print('[FETCH_TX] Total available: $_totalTransactionsCount');
    
    if (_totalTransactionsCount == 0) {
      _loadedTransactionsCount = 0;
      return {};
    }
    
    // Load only the most recent transactions (from the end)
    final count = _totalTransactionsCount > _initialBatchSize 
        ? _initialBatchSize 
        : _totalTransactionsCount;
    final start = _totalTransactionsCount - count;
    
    print('[FETCH_TX] Loading batch $start-${start + count} (newest)...');
    final rows = monero_transaction_history.getTransactionsRange(start, count);
    
    final result = <String, MoneroTransactionInfo>{};
    for (final row in rows) {
      final tx = MoneroTransactionInfo.fromRow(row);
      result[tx.id] = tx;
    }
    
    transactionHistory.addMany(result);
    _loadedTransactionsCount = count;
    
    print('[FETCH_TX] Initial load done: ${result.length} tx (${stopwatch.elapsedMilliseconds}ms)');
    print('[FETCH_TX] Remaining to load on scroll: ${_totalTransactionsCount - _loadedTransactionsCount}');
    
    return result;
  }

  /// Load more older transactions (called when user scrolls down)
  Future<void> loadMoreTransactions() async {
    if (_isLoadingMore || !hasMoreTransactions) {
      return;
    }
    
    _isLoadingMore = true;
    final stopwatch = Stopwatch()..start();
    
    try {
      // Calculate range for older transactions
      final alreadyLoaded = _loadedTransactionsCount;
      final oldestLoadedIndex = _totalTransactionsCount - alreadyLoaded;
      
      final count = oldestLoadedIndex > _loadMoreBatchSize 
          ? _loadMoreBatchSize 
          : oldestLoadedIndex;
      final start = oldestLoadedIndex - count;
      
      print('[LOAD_MORE] Loading $count more tx (index $start-${start + count})...');
      final rows = monero_transaction_history.getTransactionsRange(start, count);
      
      final moreTxs = <String, MoneroTransactionInfo>{};
      for (final row in rows) {
        final tx = MoneroTransactionInfo.fromRow(row);
        moreTxs[tx.id] = tx;
      }
      
      transactionHistory.addMany(moreTxs);
      _loadedTransactionsCount += count;
      
      print('[LOAD_MORE] Done: +$count tx, total loaded: $_loadedTransactionsCount/${_totalTransactionsCount} (${stopwatch.elapsedMilliseconds}ms)');
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Fetch only new transactions (for incremental updates after new block)
  Future<void> fetchNewTransactions() async {
    final stopwatch = Stopwatch()..start();
    
    monero_transaction_history.refreshTransactions();
    final newTotalCount = monero_transaction_history.countOfTransactions();
    final newCount = newTotalCount - _totalTransactionsCount;
    
    if (newCount <= 0) {
      print('[FETCH_NEW_TX] No new transactions');
      return;
    }
    
    print('[FETCH_NEW_TX] Loading $newCount new transactions...');
    
    // New transactions are at the end
    final rows = monero_transaction_history.getTransactionsRange(_totalTransactionsCount, newCount);
    
    final newTxs = <String, MoneroTransactionInfo>{};
    for (final row in rows) {
      final tx = MoneroTransactionInfo.fromRow(row);
      newTxs[tx.id] = tx;
    }
    
    transactionHistory.addMany(newTxs);
    _totalTransactionsCount = newTotalCount;
    _loadedTransactionsCount += newCount;
    
    print('[FETCH_NEW_TX] Added $newCount transactions (${stopwatch.elapsedMilliseconds}ms)');
  }

  Future<void> updateTransactions() async {
    try {
      if (_isTransactionUpdating) {
        print('[UPDATE_TX] Already updating, skipping...');
        return;
      }

      final stopwatch = Stopwatch()..start();
      print('[UPDATE_TX] Starting updateTransactions...');
      
      _isTransactionUpdating = true;
      _lastTxHistoryUpdate = DateTime.now();
      
      final transactions = await fetchTransactions();
      print('[UPDATE_TX] fetchTransactions returned ${transactions.length} transactions (${stopwatch.elapsedMilliseconds}ms)');
      
      await transactionHistory.save();
      print('[UPDATE_TX] save done (${stopwatch.elapsedMilliseconds}ms)');
      
      _isTransactionUpdating = false;
      _lastTxHistoryUpdate = DateTime.now();
      print('[UPDATE_TX] DONE! Total: ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      print('[UPDATE_TX] ERROR: $e');
      _isTransactionUpdating = false;
    }
  }

  List<MoneroTransactionInfo> _getAllTransactions(dynamic _) =>
      monero_transaction_history
          .getAllTransations()
          .map((row) => MoneroTransactionInfo.fromRow(row))
          .toList();

  void _setListeners() {
    _listener?.stop();
    _listener = monero_wallet.setListeners(_onNewBlock, _onNewTransaction);
  }

  void _setInitialHeight() {
    if (walletInfo.isRecovery) {
      return;
    }

    final currentHeight = getCurrentHeight();

    if (currentHeight <= 1) {
      final height = _getHeightByDate(walletInfo.date);
      monero_wallet.setRecoveringFromSeed(isRecovery: true);
      monero_wallet.setRefreshFromBlockHeight(height: height);
    }
  }

  int _getHeightDistance(DateTime date) {
    final distance =
        DateTime.now().millisecondsSinceEpoch - date.millisecondsSinceEpoch;
    final daysTmp = (distance / 86400).round();
    final days = daysTmp < 1 ? 1 : daysTmp;

    return days * 1000;
  }

  int _getHeightByDate(DateTime date) {
    final nodeHeight = monero_wallet.getNodeHeightSync();
    final heightDistance = _getHeightDistance(date);

    if (nodeHeight <= 0) {
      return 0;
    }

    return nodeHeight - heightDistance;
  }

  void _askForUpdateBalance() {
    final unlockedBalance = _getUnlockedBalance();
    final fullBalance = _getFullBalance();

    if (balance.fullBalance != fullBalance ||
        balance.unlockedBalance != unlockedBalance) {
      balance = MoneroBalance(
          fullBalance: fullBalance, unlockedBalance: unlockedBalance);
    }
  }

  Future<void> _askForUpdateTransactionHistory() async =>
      await updateTransactions();

  int _getFullBalance() =>
      monero_wallet.getFullBalance(accountIndex: walletAddresses.account.id);

  int _getUnlockedBalance() => monero_wallet.getUnlockedBalance(
      accountIndex: walletAddresses.account.id);

  // Throttled transaction history update - max once every 5 minutes for large wallets
  // For wallets with many transactions, frequent updates freeze the UI
  static const int _txThrottleSeconds = 300; // 5 minutes
  
  Future<void> _throttledTxHistoryUpdate() async {
    // Skip if already updating
    if (_isTransactionUpdating) {
      print('[THROTTLE_TX] Already updating, skipping...');
      return;
    }
    
    // Skip if wallet has many transactions (> 1000) - only update on explicit refresh
    final txCount = transactionHistory.transactions.length;
    if (txCount > 1000) {
      print('[THROTTLE_TX] Large wallet ($txCount tx), skipping auto-update to avoid UI freeze');
      return;
    }
    
    final now = DateTime.now();
    final elapsed = now.difference(_lastTxHistoryUpdate).inSeconds;
    if (elapsed >= _txThrottleSeconds) {
      print('[THROTTLE_TX] ${elapsed}s since last update, updating now...');
      _lastTxHistoryUpdate = now;
      await _askForUpdateTransactionHistory();
    } else {
      print('[THROTTLE_TX] Only ${elapsed}s since last update, skipping (need ${_txThrottleSeconds}s)');
    }
  }

  void _onNewBlock(int height, int blocksLeft, double ptc) async {
    try {
      if (walletInfo.isRecovery) {
        // Throttle tx history updates during recovery to avoid UI freeze
        await _throttledTxHistoryUpdate();
        _askForUpdateBalance();
        walletAddresses.accountList.update();
      }

      if (blocksLeft < 100) {
        // Near sync completion - only update balance, skip tx history (will be done once at sync complete)
        _askForUpdateBalance();
        walletAddresses.accountList.update();
        syncStatus = SyncedSyncStatus();

        if (!_hasSyncAfterStartup) {
          _hasSyncAfterStartup = true;
          // Skip tx history update here - it was already loaded in init() background task
          // await _askForUpdateTransactionHistory();
          await save();
        }

        if (walletInfo.isRecovery) {
          await setAsRecovered();
        }
      } else {
        syncStatus = SyncingSyncStatus(blocksLeft, ptc);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void _onNewTransaction() async {
    try {
      // Fast incremental update - only fetch new transactions
      print('[ON_NEW_TX] New transaction detected, fetching new ones...');
      await fetchNewTransactions();
      _askForUpdateBalance();
    } catch (e) {
      print('[ON_NEW_TX] ERROR: $e');
    }
  }
}
