import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/msg.dart';
import 'package:PiliPlus/models_new/msg/msg_reply/data.dart';
import 'package:PiliPlus/models_new/msg/msg_reply/item.dart';
import 'package:PiliPlus/pages/msg_feed_top/msg_feed_list_controller.dart';

class ReplyMeController
    extends MsgFeedListController<MsgReplyData, MsgReplyItem> {
  @override
  List<MsgReplyItem>? getDataList(MsgReplyData response) {
    if (response.cursor?.isEnd == true) {
      isEnd = true;
    }
    cursor = response.cursor?.id;
    cursorTime = response.cursor?.time;
    return response.items;
  }

  @override
  Future<LoadingState<MsgReplyData>> customGetData() =>
      MsgHttp.msgFeedReplyMe(cursor: cursor, cursorTime: cursorTime);

  @override
  Future<LoadingState<void>> deleteItem(dynamic id) =>
      MsgHttp.delMsgfeed(1, id);
}
