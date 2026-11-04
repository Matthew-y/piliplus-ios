/// 消息 / 通知模块的固定文案。
///
/// 仓库目前没有全局 i18n 体系（`main.dart` 直接锁定 `zh_CN`，业务文案均为中文），
/// 这里先把消息模块的固定文案收拢到单一入口：后续接入多语言时只需改这一层，
/// 不必在 view / controller 里逐个查找散落的字面量。
abstract final class MsgStrings {
  static const messages = '消息';

  static const replyMe = '回复我的';
  static const atMe = '@我的';
  static const receiveLike = '收到的赞';
  static const sysMsg = '系统通知';
  static const likeDetail = '点赞详情';

  static const disabled = '已禁用';
  static const deleteNoticeTitle = '确定删除该通知?';
  static const deleteSuccess = '删除成功';
  static const setNoticeSuccess = '设置成功';
  static const markedUnreadLocal = '已标为未读（仅本机）';

  static const emptySession = '暂无会话';
  static const emptyReply = '暂无回复';
  static const emptyAt = '暂无 @ 我的消息';
  static const emptyLike = '暂无点赞消息';
  static const emptyLikeDetail = '暂无点赞用户';
  static const emptySys = '暂无系统通知';

  /// 无未读时不追加任何说明，避免 TalkBack / VoiceOver 把“0 条未读”读出来。
  static String unreadSemantics(int count) => count > 0 ? '，$count 条未读' : '';
}
