import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:monekin/core/services/income_privacy_service.dart';

/// Blurs [child] while income is hidden; tapping it reveals income everywhere
/// until the app goes to the background. Use [enabled] to apply the mask only
/// when [child] actually shows income.
class IncomeMask extends StatelessWidget {
  const IncomeMask({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return StreamBuilder<bool>(
      stream: IncomePrivacyService.instance.hiddenStream,
      initialData: IncomePrivacyService.instance.isHidden,
      builder: (context, snapshot) {
        if (!(snapshot.data ?? true)) return child;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: IncomePrivacyService.instance.reveal,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 7.5, sigmaY: 7.5),
            child: IgnorePointer(child: child),
          ),
        );
      },
    );
  }
}
