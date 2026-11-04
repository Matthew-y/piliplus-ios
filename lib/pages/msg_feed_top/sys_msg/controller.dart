import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/msg.dart';
import 'package:PiliPlus/models_new/msg/msg_sys/data.dart';
import 'package:PiliPlus/pages/msg_feed_top/msg_feed_list_controller.dart';

class SysMsgController
    extends MsgFeedListController<List<MsgSysItem>?, MsgSysItem> {
  @override
  void handleListResponse(List<MsgSysItem> dataList) {
    if (cursor == null) {
      msgSysUpdateCursor(dataList.first.cursor);
    }
    cursor = dataList.last.cursor;
  }

  void msgSysUpdateCursor(int? cursor) {
    if (cursor != null) {
      MsgHttp.msgSysUpdateCursor(cursor);
    }
  }

  @override
  Future<LoadingState<List<MsgSysItem>?>> customGetData() =>
      MsgHttp.msgFeedNotify(cursor: cursor);

  @override
  Future<LoadingState<void>> deleteItem(dynamic id) => MsgHttp.delSysMsg(id);
}
