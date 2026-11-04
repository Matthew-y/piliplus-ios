import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/pages/msg_feed_top/msg_feed_strings.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

/// 回复 / @我 / 系统通知共用的游标分页 + 删除逻辑。
///
/// 这三页除了接口与行内容外，分页游标、刷新重置、删除反馈完全一致；
/// 具体接口由子类通过 [customGetData] 与 [deleteItem] 提供。
abstract class MsgFeedListController<R, T> extends CommonListController<R, T> {
  int? cursor;
  int? cursorTime;

  /// 删除单条通知。不同子页走不同接口。
  Future<LoadingState<void>> deleteItem(dynamic id);

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  Future<void> onRefresh() {
    cursor = null;
    cursorTime = null;
    return super.onRefresh();
  }

  Future<void> onRemove(dynamic id, int index) async {
    try {
      final res = await deleteItem(id);
      if (res.isSuccess) {
        loadingState
          ..value.data!.removeAt(index)
          ..refresh();
        SmartDialog.showToast(MsgStrings.deleteSuccess);
      } else {
        res.toast();
      }
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }
}
