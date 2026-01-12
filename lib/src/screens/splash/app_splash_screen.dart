import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class AppSplashScreen extends StatelessWidget {
  const AppSplashScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
        color: PaletteExplorerDark.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/app_logo.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 14),
              const _XWalletTitle(),
            ],
          ),
        ));
  }
}

class _XWalletTitle extends StatelessWidget {
  const _XWalletTitle({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontFamily: 'Lato',
          fontSize: 26,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
        children: [
          TextSpan(
            text: 'X',
            style: TextStyle(
              color: PaletteExplorerDark.primary,
            ),
          ),
          TextSpan(
            text: '-wallet',
            style: TextStyle(
              color: PaletteExplorerDark.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
