import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/wallet_new_vm.dart';
import 'package:flutter/material.dart';

class AutoNewWalletPage extends BasePage {
  AutoNewWalletPage({@required this.type});

  final WalletType type;

  @override
  String get title => S.current.new_wallet;

  @override
  Widget body(BuildContext context) => _AutoNewWalletBody(type: type);
}

class _AutoNewWalletBody extends StatefulWidget {
  _AutoNewWalletBody({@required this.type});

  final WalletType type;

  @override
  State<_AutoNewWalletBody> createState() => _AutoNewWalletBodyState();
}

class _AutoNewWalletBodyState extends State<_AutoNewWalletBody> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_started) {
      return;
    }

    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _createWallet());
  }

  Future<void> _createWallet() async {
    final walletNewVM = getIt.get<WalletNewVM>(param1: widget.type);
    walletNewVM.type = widget.type;

    await walletNewVM.create(options: 'English');
    final state = walletNewVM.state;

    if (!mounted) {
      return;
    }

    if (state is ExecutedSuccessfullyState) {
      Navigator.of(context).pushReplacementNamed(Routes.preSeed,
          arguments: widget.type);
      return;
    }

    if (state is FailureState) {
      await showPopUp<void>(
          context: context,
          builder: (_) => AlertWithOneAction(
              alertTitle: S.current.new_wallet,
              alertContent: state.error,
              buttonText: S.of(context).ok,
              buttonAction: () => Navigator.of(context).pop()));
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            S.of(context).creating_new_wallet,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryTextTheme.title.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

