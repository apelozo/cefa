import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_layout.dart';

class AppGradientBackground extends StatelessWidget {
  const AppGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.screenBackground),
      child: child,
    );
  }
}

class AppScreenChrome {
  static PreferredSizeWidget appBar(
    BuildContext context, {
    required String title,
    List<Widget>? actions,
    bool centerTitle = false,
  }) {
    return AppBar(
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      actions: actions,
      centerTitle: centerTitle,
    );
  }

  static BoxDecoration whiteTopSheet({double radius = AppLayout.whiteTopSheetRadius}) {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 12,
          offset: Offset(0, -2),
        ),
      ],
    );
  }
}

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.useGradient = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    final content = useGradient ? AppGradientBackground(child: body) : body;

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: content,
    );
  }
}
