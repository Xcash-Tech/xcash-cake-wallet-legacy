import 'dart:async';

import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class AppSplashOverlay extends StatefulWidget {
  const AppSplashOverlay({
    Key key,
    @required this.child,
    this.minimumVisible = const Duration(milliseconds: 600),
    this.fadeDuration = const Duration(milliseconds: 220),
  }) : super(key: key);

  final Widget child;
  final Duration minimumVisible;
  final Duration fadeDuration;

  @override
  State<AppSplashOverlay> createState() => _AppSplashOverlayState();
}

class _AppSplashOverlayState extends State<AppSplashOverlay>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Timer _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
      value: 1.0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer(widget.minimumVisible, () {
        if (!mounted) return;
        _controller.reverse();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          ignoring: false,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              if (_controller.value <= 0.0) {
                return const SizedBox.shrink();
              }

              final opacity = _controller.value;
              final scale = 0.98 + (0.02 * opacity);

              return Opacity(
                opacity: opacity,
                child: ColoredBox(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Center(
                    child: Transform.scale(
                      scale: scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/app_logo.png',
                            width: 120,
                            height: 120,
                          ),
                          const SizedBox(height: 14),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                              children: const [
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
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

