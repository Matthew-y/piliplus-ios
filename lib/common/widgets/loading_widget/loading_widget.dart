import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_loading_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:material_ui/material_ui.dart';

const Widget m3eLoading = Center(child: PLLoadingIndicator());

const Widget linearLoading = SliverToBoxAdapter(child: _LinearLoading());

const Widget scrollableError = CustomScrollView(slivers: [HttpError()]);

Widget scrollErrorWidget({
  String? errMsg,
  VoidCallback? onReload,
  ScrollController? controller,
}) => CustomScrollView(
  controller: controller,
  slivers: [
    HttpError(
      errMsg: errMsg,
      onReload: onReload,
    ),
  ],
);

/// 列表底部的「加载中」。
///
/// iOS 用居中菊花；其余风格保留原来的细进度条。
class _LinearLoading extends StatelessWidget {
  const _LinearLoading();

  @override
  Widget build(BuildContext context) {
    if (!Adaptive.isIOS(context)) {
      return const LinearProgressIndicator();
    }
    return const SizedBox(
      height: 60,
      child: Center(child: PLLoadingIndicator(size: 24)),
    );
  }
}
