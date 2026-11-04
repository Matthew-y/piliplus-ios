import 'package:PiliPlus/grpc/bilibili/app/im/v1.pb.dart'
    show Offset, Session, SessionMainReply, SessionPageType, ThreeDotItem;
import 'package:PiliPlus/grpc/im.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/msg/msg_unread_type.dart';
import 'package:PiliPlus/models_new/msg/msgfeed_unread.dart';
import 'package:PiliPlus/pages/common/common_whisper_controller.dart';
import 'package:PiliPlus/pages/msg_feed_top/msg_feed_strings.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:protobuf/protobuf.dart' show PbMap;

typedef MsgFeedTopItem = ({
  bool enabled,
  IconData icon,
  String name,
  String route,
});

class WhisperController extends CommonWhisperController<SessionMainReply> {
  @override
  SessionPageType sessionPageType = SessionPageType.SESSION_PAGE_TYPE_HOME;

  // 说明：回复 / @我 / 收到的赞没有公开的服务端「已读」接口，所以进入子页时
  // 不会在本地把计数清零——那只会让角标假消失、返回后又被服务端计数「复活」。
  // 改为从子页返回后重新拉取；系统通知则在子页成功加载后调用
  // `msgSysUpdateCursor`，由服务端完成已读。
  //
  // 这两个 getter 都实时读设置：用户从设置页改完 `disableLikeMsg` 返回后，
  // 只要页面重建就能立即生效，不再依赖启动时的 `late final` 快照。
  List<MsgFeedTopItem> get msgFeedTopItems => [
    const (
      name: MsgStrings.replyMe,
      icon: Icons.message_outlined,
      route: "/replyMe",
      enabled: true,
    ),
    const (
      name: MsgStrings.atMe,
      icon: Icons.alternate_email_outlined,
      route: "/atMe",
      enabled: true,
    ),
    (
      name: MsgStrings.receiveLike,
      icon: Icons.favorite_border_outlined,
      route: "/likeMe",
      enabled: !disableLikeMsg,
    ),
    const (
      name: MsgStrings.sysMsg,
      icon: Icons.notifications_none_outlined,
      route: "/sysMsg",
      enabled: true,
    ),
  ];

  bool get disableLikeMsg => Pref.disableLikeMsg;

  late final RxList<int> unreadCounts;

  /// 防止快速进入 / 下拉刷新时并发多次 gRPC 请求。
  bool _isQueryingUnread = false;

  PbMap<int, Offset>? offset;

  Rx<List<ThreeDotItem>?> threeDotItems = Rx<List<ThreeDotItem>?>(null);
  Rx<List<ThreeDotItem>?> outsideItem = Rx<List<ThreeDotItem>?>(null);

  @override
  void onInit() {
    super.onInit();
    unreadCounts = List.filled(msgFeedTopItems.length, 0).obs;
    queryMsgFeedUnread();
    queryData();
  }

  Future<void> queryMsgFeedUnread() async {
    if (_isQueryingUnread) return;
    _isQueryingUnread = true;
    try {
      final res = await ImGrpc.getTotalUnread(unreadType: 2);
      if (res case Success(:final response)) {
        final data = MsgFeedUnread.fromJson(response.msgFeedUnread.unread);
        // 与首页铃铛复用同一套「未读类型」过滤规则：用户在设置里关掉的类型
        // 不应在这里继续计数，否则首页不显示、消息页却显示，两处数字对不上。
        final types = Pref.msgUnReadTypeV2;
        final unreadCounts = [
          types.contains(MsgUnReadType.reply) ? data.reply : 0,
          types.contains(MsgUnReadType.at) ? data.at : 0,
          types.contains(MsgUnReadType.like) && !disableLikeMsg ? data.like : 0,
          types.contains(MsgUnReadType.sysMsg) ? data.sysMsg : 0,
        ];
        if (!listEquals(this.unreadCounts, unreadCounts)) {
          this.unreadCounts.value = unreadCounts;
        }
      } else {
        res.toast();
      }
    } finally {
      _isQueryingUnread = false;
    }
  }

  @override
  List<Session>? getDataList(SessionMainReply response) {
    offset = response.paginationParams.offsets;
    isEnd = !response.paginationParams.hasMore;
    return response.sessions;
  }

  @override
  bool customHandleResponse(
    bool isRefresh,
    Success<SessionMainReply> response,
  ) {
    if (isRefresh) {
      threeDotItems.value = response.response.threeDotItems;
      outsideItem.value = response.response.outsideItem;
    }
    return false;
  }

  @override
  Future<LoadingState<SessionMainReply>> customGetData() =>
      ImGrpc.sessionMain(offset: offset);

  @override
  Future<void> onRefresh() {
    offset = null;
    queryMsgFeedUnread();
    return super.onRefresh();
  }
}
