import 'package:cake_wallet/di.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/core/wallet_service.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/wallet_type.dart';

Future<void> loadCurrentWallet() async {
  final stopwatch = Stopwatch()..start();
  print('[LOAD_WALLET] Starting loadCurrentWallet...');
  
  final appStore = getIt.get<AppStore>();
  final name = getIt
      .get<SharedPreferences>()
      .getString(PreferencesKey.currentWalletName);
  final typeRaw =
      getIt.get<SharedPreferences>().getInt(PreferencesKey.currentWalletType) ??
          0;
  final type = deserializeFromInt(typeRaw);
  print('[LOAD_WALLET] Got wallet name: $name, type: $type (${stopwatch.elapsedMilliseconds}ms)');
  
  final password =
      await getIt.get<KeyService>().getWalletPassword(walletName: name);
  print('[LOAD_WALLET] Got password (${stopwatch.elapsedMilliseconds}ms)');
  
  final _service = getIt.get<WalletService>(param1: type);
  print('[LOAD_WALLET] Got wallet service, calling openWallet... (${stopwatch.elapsedMilliseconds}ms)');
  
  final wallet = await _service.openWallet(name, password);
  print('[LOAD_WALLET] openWallet completed (${stopwatch.elapsedMilliseconds}ms)');
  
  appStore.changeCurrentWallet(wallet);
  print('[LOAD_WALLET] DONE! Total time: ${stopwatch.elapsedMilliseconds}ms');
}
