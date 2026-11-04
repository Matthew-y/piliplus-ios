import 'dart:convert';

import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/dialog/dialog.dart';
import 'package:PiliPlus/common/widgets/dialog/simple_dialog_option.dart';
import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/common/widgets/pendant_avatar.dart';
import 'package:PiliPlus/grpc/bilibili/app/im/v1.pb.dart'
    show Session, SessionId, SessionPageType, Unread, UnreadStyle;
import 'package:PiliPlus/grpc/im.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/msg.dart';
import 'package:PiliPlus/pages/whisper_secondary/view.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoColors;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class WhisperSessionItem extends StatefulWidget {
  const WhisperSessionItem({
    super.key,
    required this.item,
    required this.onSetTop,
    required this.onSetMute,
    required this.onRemove,
    this.isFirst = false,
    this.isLast = false,
  });

  final Session item;
  final Function(bool isTop, SessionId id) onSetTop;
  final Function(bool isMuted, Int64 talkerUid) onSetMute;
  final ValueChanged<int> onRemove;

  /// iOS 分组卡片中的首项 / 末项，用于给卡片外沿加圆角。
  final bool isFirst;
  final bool isLast;

  @override
  State<WhisperSessionItem> createState() => _WhisperSessionItemState();
}

class _WhisperSessionItemState extends State<WhisperSessionItem> {
  Session get item => widget.item;
  Function(bool isTop, SessionId id) get onSetTop => widget.onSetTop;
  Function(bool isMuted, Int64 talkerUid) get onSetMute => widget.onSetMute;
  ValueChanged<int> get onRemove => widget.onRemove;
  bool get isFirst => widget.isFirst;
  bool get isLast => widget.isLast;

  Future<void> _updateAck(BuildContext context) async {
    final talkerUid = item.id.privateId.talkerUid;
    final res = await ImGrpc.sessionDetail(talkerId: talkerUid, sessionType: 1);
    if (res case Success(:final response)) {
      final res = await MsgHttp.ackSessionMsg(
        talkerId: talkerUid.toInt(),
        ackSeqno: response.ackSeqno.toInt(),
      );
      if (res.isSuccess) {
        SmartDialog.showToast('已标为已读');
        item.clearUnread();
        if (context.mounted) {
          setState(() {});
        }
      } else {
        res.toast();
      }
    } else {
      res.toast();
    }
  }

  /// 左滑「标为已读 / 标为未读」。
  ///
  /// 私信会话走服务端 ack；系统 / 折叠会话没有 ack 接口，只做本地状态切换。
  Future<void> _toggleRead(BuildContext context, bool hasUnread) async {
    if (hasUnread) {
      if (item.id.privateId.hasTalkerUid()) {
        await _updateAck(context);
      } else {
        item.clearUnread();
        if (context.mounted) {
          setState(() {});
        }
        SmartDialog.showToast('已标为已读');
      }
    } else {
      item.unread = Unread(
        style: UnreadStyle.UNREAD_STYLE_NUMBER,
        number: Int64.ONE,
      );
      if (context.mounted) {
        setState(() {});
      }
      // 私信没有「标为未读」的服务端接口，这里只改本机会话状态，
      // 下拉刷新后会恢复，Toast 中明确告知用户。
      SmartDialog.showToast('已标为未读（仅本机）');
    }
  }

  /// 左滑「删除」。
  void _confirmRemove(BuildContext context) {
    if (!item.id.privateId.hasTalkerUid()) {
      SmartDialog.showToast('该会话暂不支持删除');
      return;
    }
    showConfirmDialog(
      context: context,
      title: const Text('确定删除该对话？'),
      destructive: true,
      onConfirm: () => onRemove(item.id.privateId.talkerUid.toInt()),
    );
  }

  void _onTap(BuildContext context, String avatar) {
    if (item.hasUnread()) {
      item.clearUnread();
      if (context.mounted) {
        setState(() {});
      }
    }
    if (item.id.privateId.hasTalkerUid()) {
      Get.toNamed(
        '/whisperDetail',
        arguments: {
          'talkerId': item.id.privateId.talkerUid.toInt(),
          'name': item.sessionInfo.sessionName,
          'face': avatar,
          if (item.sessionInfo.avatar.hasMid())
            'mid': item.sessionInfo.avatar.mid.toInt(),
          'isLive': item.sessionInfo.isLive,
        },
      );
      return;
    }

    if (item.id.foldId.hasType()) {
      SessionPageType? sessionPageType = switch (item.id.foldId.type) {
        .SESSION_TYPE_UNKNOWN => .SESSION_PAGE_TYPE_UNKNOWN,
        .SESSION_TYPE_GROUP => .SESSION_PAGE_TYPE_GROUP,
        .SESSION_TYPE_GROUP_FOLD => .SESSION_PAGE_TYPE_GROUP,
        .SESSION_TYPE_UNFOLLOWED => .SESSION_PAGE_TYPE_UNFOLLOWED,
        .SESSION_TYPE_STRANGER => .SESSION_PAGE_TYPE_STRANGER,
        .SESSION_TYPE_DUSTBIN => .SESSION_PAGE_TYPE_DUSTBIN,
        .SESSION_TYPE_CUSTOMER_FOLD => .SESSION_PAGE_TYPE_CUSTOMER,
        .SESSION_TYPE_AI_FOLD => .SESSION_PAGE_TYPE_AI,
        .SESSION_TYPE_CUSTOMER_ACCOUNT => .SESSION_PAGE_TYPE_CUSTOMER,
        _ => null,
      };
      if (sessionPageType != null) {
        Get.to(
          WhisperSecPage(
            name: item.sessionInfo.sessionName,
            sessionPageType: sessionPageType,
          ),
        );
      } else {
        SmartDialog.showToast(item.id.foldId.type.name);
      }
      return;
    }

    if (item.id.hasSystemId()) {
      switch (item.id.systemId.type) {
        case .SESSION_TYPE_SYSTEM:
          Get.toNamed('/sysMsg');
        case .SESSION_TYPE_AI_FOLD:
        case .SESSION_TYPE_CUSTOMER_ACCOUNT:
        case .SESSION_TYPE_CUSTOMER_FOLD:
        case .SESSION_TYPE_DUSTBIN:
        case .SESSION_TYPE_GROUP:
        case .SESSION_TYPE_GROUP_FOLD:
        case .SESSION_TYPE_PRIVATE:
        case .SESSION_TYPE_STRANGER:
        case .SESSION_TYPE_UNFOLLOWED:
        case .SESSION_TYPE_UNKNOWN:
          SmartDialog.showToast(item.id.systemId.type.name);
      }
    }
  }

  /// 长按菜单（iOS / Material 共用）。
  void _showActions(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        clipBehavior: .hardEdge,
        contentPadding: const .symmetric(vertical: 12),
        children: [
          DialogOption(
            onPressed: () {
              Get.back();
              onSetTop(item.isPinned, item.id);
            },
            child: Text(item.isPinned ? '移除置顶' : '置顶'),
          ),
          if (item.id.privateId.hasTalkerUid()) ...[
            if (kDebugMode || item.hasUnread())
              DialogOption(
                onPressed: () {
                  Get.back();
                  _updateAck(context);
                },
                child: const Text('标为已读'),
              ),
            DialogOption(
              onPressed: () {
                Get.back();
                onSetMute(item.isMuted, item.id.privateId.talkerUid);
              },
              child: Text('${item.isMuted ? '关闭' : '开启'}免打扰'),
            ),
            DialogOption(
              onPressed: () {
                Get.back();
                _confirmRemove(context);
              },
              child: const Text('删除'),
            ),
          ],
        ],
      ),
    );
  }

  /// 桌面端右键菜单。
  void _showDesktopMenu(BuildContext context, TapUpDetails details) {
    final theme = Theme.of(context);
    showMenu(
      context: context,
      position: PageUtils.menuPosition(details.globalPosition),
      items: <PopupMenuEntry<Never>>[
        PopupMenuItem(
          height: 42,
          onTap: () => onSetTop(item.isPinned, item.id),
          child: Text(item.isPinned ? '移除置顶' : '置顶'),
        ),
        if (item.id.privateId.hasTalkerUid()) ...[
          if (kDebugMode || item.hasUnread())
            PopupMenuItem(
              height: 42,
              onTap: () => _updateAck(context),
              child: const Text('标为已读'),
            ),
          PopupMenuItem(
            height: 42,
            onTap: () => onSetMute(item.isMuted, item.id.privateId.talkerUid),
            child: Text('${item.isMuted ? '关闭' : '开启'}免打扰'),
          ),
          const PopupMenuDivider(height: 10),
          PopupMenuItem(
            height: 42,
            onTap: () => _confirmRemove(context),
            child: Text(
              '删除',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    String avatar,
    Map? vipInfo, {
    double size = 42,
  }) {
    final pendant = item.sessionInfo.avatar.fallbackLayers.layers
        .elementAtOrNull(1)
        ?.resource;
    final official = item
        .sessionInfo
        .avatar
        .fallbackLayers
        .layers
        .lastOrNull
        ?.resource
        .resImage
        .imageSrc;

    return GestureDetector(
      onTap: item.sessionInfo.avatar.hasMid()
          ? () => Get.toNamed('/member?mid=${item.sessionInfo.avatar.mid}')
          : null,
      child: PendantAvatar(
        avatar,
        size: size,
        badgeSize: 14,
        pendantImage: pendant?.resImage.imageSrc.remote.hasUrl() == true
            ? pendant!.resImage.imageSrc.remote.url
            : pendant?.resAnimation.webpSrc.remote.url,
        vipStatus: vipInfo?['status'],
        officialType: official?.hasLocalValue() == true
            ? switch (official!.localValue) {
                3 => 0,
                4 => 1,
                _ => null,
              }
            : null,
      ),
    );
  }

  Widget _buildTitle(
    BuildContext context,
    ThemeData theme,
    Map? vipInfo, {
    required bool isIOS,
  }) {
    return Row(
      spacing: 5,
      children: [
        Flexible(
          child: Text(
            item.sessionInfo.sessionName,
            maxLines: 1,
            overflow: .ellipsis,
            style: TextStyle(
              fontSize: isIOS ? 16 : 15,
              fontWeight: isIOS ? FontWeight.w500 : null,
              color:
                  vipInfo?['status'] != null &&
                      vipInfo!['status'] > 0 &&
                      vipInfo['type'] == 2
                  ? theme.colorScheme.vipColor
                  : isIOS
                  ? theme.colorScheme.onSurface
                  : null,
            ),
          ),
        ),
        if (item.sessionInfo.userLabel.style.borderedLabel.hasText())
          PBadge(
            isStack: false,
            type: .line_secondary,
            size: .small,
            fontSize: 10,
            isBold: false,
            text: item.sessionInfo.userLabel.style.borderedLabel.text,
          ),
        if (item.sessionInfo.isLive)
          Image.asset(
            Assets.livingRect,
            height: 15,
            cacheHeight: 15.cacheSize(context),
            filterQuality: .low,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final resource =
        item.sessionInfo.avatar.fallbackLayers.layers.first.resource;
    final avatar = resource.hasResImage()
        ? resource.resImage.imageSrc.remote.url
        : resource.hasResAnimation()
        ? resource.resAnimation.webpSrc.remote.url
        : resource.resNativeDraw.drawSrc.remote.url;
    Map? vipInfo = item.sessionInfo.hasVipInfo()
        ? jsonDecode(item.sessionInfo.vipInfo)
        : null;

    final theme = Theme.of(context);

    if (Adaptive.isIOS(context)) {
      return _buildIosTile(context, theme, avatar, vipInfo);
    }

    return ListTile(
      safeArea: true,
      tileColor: item.isPinned
          ? theme.colorScheme.onInverseSurface.withValues(
              alpha: theme.isDark ? 0.4 : 0.8,
            )
          : null,
      onLongPress: () => _showActions(context),
      onSecondaryTapUp: PlatformUtils.isDesktop
          ? (details) => _showDesktopMenu(context, details)
          : null,
      onTap: () => _onTap(context, avatar),
      leading: _buildAvatar(context, avatar, vipInfo),
      title: Row(
        spacing: 5,
        children: [
          Expanded(
            child: _buildTitle(context, theme, vipInfo, isIOS: false),
          ),
          if (item.hasTimestamp())
            Text(
              DateFormatUtils.dateFormat((item.timestamp ~/ 1000000).toInt()),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.outline,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              item.msgSummary.rawMsg,
              maxLines: 1,
              overflow: .ellipsis,
              style: theme.textTheme.labelMedium!.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          if (item.isMuted)
            Icon(
              size: 16,
              Icons.notifications_off,
              color: theme.colorScheme.outline,
            )
          else if (item.hasUnread() && item.unread.style != .UNREAD_STYLE_NONE)
            Badge(
              label: item.unread.style == .UNREAD_STYLE_NUMBER
                  ? Text(item.unread.number.toString())
                  : null,
            ),
        ],
      ),
    );
  }

  /// iOS 原生风格行：40 头像 + 16/w500 标题 + 14 次要文字，白底分组卡片。
  Widget _buildIosTile(
    BuildContext context,
    ThemeData theme,
    String avatar,
    Map? vipInfo,
  ) {
    final brightness = theme.brightness;
    final secondary = IosColors.secondaryLabel(brightness);
    final cardBg = IosColors.secondaryGroupedBackground(brightness);
    final hasUnread =
        item.hasUnread() && item.unread.style != .UNREAD_STYLE_NONE;
    final activeBlue = CupertinoColors.activeBlue.resolveFrom(context);

    final rowBg = item.isPinned
        ? Color.alphaBlend(
            theme.colorScheme.primary.withValues(alpha: 0.06),
            cardBg,
          )
        : cardBg;

    final row = InkWell(
      onTap: () => _onTap(context, avatar),
      onLongPress: () => _showActions(context),
      onSecondaryTapUp: PlatformUtils.isDesktop
          ? (details) => _showDesktopMenu(context, details)
          : null,
      splashFactory: NoSplash.splashFactory,
      highlightColor: IosColors.gray4(brightness).withValues(alpha: 0.55),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                _buildAvatar(context, avatar, vipInfo, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTitle(
                              context,
                              theme,
                              vipInfo,
                              isIOS: true,
                            ),
                          ),
                          if (item.hasTimestamp()) ...[
                            const SizedBox(width: 8),
                            Text(
                              DateFormatUtils.dateFormat(
                                (item.timestamp ~/ 1000000).toInt(),
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                color: secondary,
                              ),
                            ),
                          ],
                          if (hasUnread) ...[
                            const SizedBox(width: 5),
                            Semantics(
                              label: '未读',
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: activeBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.msgSummary.rawMsg,
                              maxLines: 1,
                              overflow: .ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: secondary,
                              ),
                            ),
                          ),
                          if (item.isMuted)
                            Icon(
                              Icons.notifications_off,
                              size: 15,
                              color: secondary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 0.5,
              thickness: 0.5,
              // 16 左内边距 + 40 头像 + 12 间距，与文字左边缘对齐。
              indent: 68,
              color: IosColors.separator(brightness),
            ),
        ],
      ),
    );

    final viewPadding = MediaQuery.viewPaddingOf(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16 + viewPadding.left,
        right: 16 + viewPadding.right,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isFirst ? 10 : 0),
          bottom: Radius.circular(isLast ? 10 : 0),
        ),
        child: Material(
          color: rowBg,
          child: Slidable(
            key: ObjectKey(item),
            groupTag: 'whisper',
            onActionPaneChanged: (pane) {
              if (pane != ActionPaneType.none) {
                feedBack();
              }
            },
            startActionPane: _buildStartPane(context),
            endActionPane: _buildEndPane(context, hasUnread: hasUnread),
            child: row,
          ),
        ),
      ),
    );
  }

  /// 右滑（左侧露出）：置顶 / 免打扰。
  ActionPane _buildStartPane(BuildContext context) {
    final hasTalker = item.id.privateId.hasTalkerUid();
    return ActionPane(
      motion: const ScrollMotion(),
      extentRatio: hasTalker ? 0.5 : 0.35,
      children: [
        if (hasTalker)
          SlidableAction(
            onPressed: (_) {
              feedBack();
              onSetMute(item.isMuted, item.id.privateId.talkerUid);
            },
            backgroundColor: CupertinoColors.systemOrange.resolveFrom(context),
            foregroundColor: Colors.white,
            borderRadius: BorderRadius.zero,
            icon: item.isMuted
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            label: item.isMuted ? '取消免打扰' : '免打扰',
            labelStyle: const TextStyle(fontSize: 12),
          ),
        SlidableAction(
          onPressed: (_) {
            feedBack();
            onSetTop(item.isPinned, item.id);
          },
          backgroundColor: CupertinoColors.systemGrey.resolveFrom(context),
          foregroundColor: Colors.white,
          borderRadius: BorderRadius.zero,
          icon: item.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          label: item.isPinned ? '取消置顶' : '置顶',
          labelStyle: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  /// 左滑（右侧露出）：标为已读 / 未读、删除。
  ActionPane _buildEndPane(BuildContext context, {required bool hasUnread}) {
    return ActionPane(
      motion: const ScrollMotion(),
      extentRatio: 0.5,
      children: [
        SlidableAction(
          onPressed: (_) {
            feedBack();
            _toggleRead(context, hasUnread);
          },
          backgroundColor: CupertinoColors.activeBlue.resolveFrom(context),
          foregroundColor: Colors.white,
          borderRadius: BorderRadius.zero,
          icon: hasUnread
              ? Icons.mark_email_read_outlined
              : Icons.mark_email_unread_outlined,
          label: hasUnread ? '标为已读' : '标为未读',
          labelStyle: const TextStyle(fontSize: 12),
        ),
        SlidableAction(
          onPressed: (_) {
            feedBack();
            _confirmRemove(context);
          },
          backgroundColor: CupertinoColors.systemRed.resolveFrom(context),
          foregroundColor: Colors.white,
          borderRadius: BorderRadius.zero,
          icon: Icons.delete_outline,
          label: '删除',
          labelStyle: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
