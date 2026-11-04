import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/loading_widget/m3e_loading_indicator.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoActivityIndicator;
import 'package:material_ui/material_ui.dart';

/// 加载指示器适配组件。
///
/// iOS 外观下用系统的「菊花」[CupertinoActivityIndicator]，
/// 其余保持项目原有的 M3E 变形加载动画。
class PLLoadingIndicator extends StatelessWidget {
  const PLLoadingIndicator({super.key, this.size = 40, this.color});

  /// Material 版的边长；iOS 版按比例换算成半径（40 → 12）。
  final double size;

  /// 指示器颜色，null 用主题默认色。
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (Adaptive.isIOS(context)) {
      return CupertinoActivityIndicator(
        radius: size * 0.3,
        color: color,
      );
    }
    return M3ELoadingIndicator(
      size: Size.square(size),
      color: color,
    );
  }
}
