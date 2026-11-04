import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/msg.dart';
import 'package:PiliPlus/models_new/msg/msg_at/data.dart';
import 'package:PiliPlus/models_new/msg/msg_at/item.dart';
import 'package:PiliPlus/pages/msg_feed_top/msg_feed_list_controller.dart';

class AtMeController extends MsgFeedListController<MsgAtData, MsgAtItem> {
  @override
  List<MsgAtItem>? getDataList(MsgAtData response) {
    if (response.cursor?.isEnd == true) {
      isEnd = true;
    }
    cursor = response.cursor?.id;
    cursorTime = response.cursor?.time;
    return response.items;
  }

  @override
  Future<LoadingState<MsgAtData>> customGetData() =>
      MsgHttp.msgFeedAtMe(cursor: cursor, cursorTime: cursorTime);

  @override
  Future<LoadingState<void>> deleteItem(dynamic id) =>
      MsgHttp.delMsgfeed(2, id);
}
