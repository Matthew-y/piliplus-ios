import 'dart:math';

import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_popover.dart';
import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/common/widgets/dialog/report.dart';
import 'package:PiliPlus/common/widgets/pendant_avatar.dart';
import 'package:PiliPlus/common/widgets/translucent_row.dart';
import 'package:PiliPlus/http/constants.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/reply.dart';
import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/pages/dynamics/controller.dart';
import 'package:PiliPlus/pages/save_panel/view.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/bili_utils.dart';
import 'package:PiliPlus/utils/color_utils.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:PiliPlus/utils/image_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/request_utils.dart';
import 'package:PiliPlus/utils/share_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class AuthorPanel extends StatelessWidget {
  final DynamicItemModel item;
  final bool isSave;
  final bool isDetail;
  final ValueChanged<Object>? onRemove;
  final void Function(bool isTop, Object dynId)? onSetTop;
  final VoidCallback? onBlock;
  final Future<LoadingState> Function(bool isPrivate, Object dynId)?
  onSetPubSetting;
  final VoidCallback? onEdit;
  final ValueChanged<int>? onSetReplySubject;

  const AuthorPanel({
    super.key,
    required this.item,
    this.isDetail = false,
    this.onRemove,
    this.isSave = false,
    this.onSetTop,
    this.onBlock,
    this.onSetPubSetting,
    this.onEdit,
    this.onSetReplySubject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moduleAuthor = item.modules.moduleAuthor!;
    final pubTime = moduleAuthor.pubTs != null
        ? isSave
              ? DateFormatUtils.format(
                  moduleAuthor.pubTs,
                  format: DateFormatUtils.longFormatDs,
                )
              : DateFormatUtils.dateFormat(moduleAuthor.pubTs)
        : moduleAuthor.pubTime;
    Widget? pubTs;
    if (pubTime != null) {
      pubTs = Text(
        '$pubTime${moduleAuthor.pubAction != null ? ' ${moduleAuthor.pubAction}' : ''}',
        style: TextStyle(
          color: theme.colorScheme.outline,
          fontSize: theme.textTheme.labelSmall!.fontSize,
        ),
      );
      if (moduleAuthor.badgeText case final badgeText?) {
        pubTs = Row(
          mainAxisSize: .min,
          spacing: 5,
          children: [
            pubTs,
            Text(
              badgeText,
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontSize: theme.textTheme.labelSmall!.fontSize,
              ),
            ),
          ],
        );
      }
    }
    final children = [
      PendantAvatar(
        size: 40,
        moduleAuthor.face,
        pendantImage: moduleAuthor.pendant?.image,
      ),
      Flexible(
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(
              moduleAuthor.name!,
              maxLines: 1,
              overflow: .ellipsis,
              style: TextStyle(
                color:
                    moduleAuthor.vip != null &&
                        moduleAuthor.vip!.status > 0 &&
                        moduleAuthor.vip!.type == 2
                    ? theme.colorScheme.vipColor
                    : theme.colorScheme.onSurface,
                fontSize: theme.textTheme.titleSmall!.fontSize,
              ),
            ),
            ?pubTs,
          ],
        ),
      ),
    ];
    Widget header;
    if (moduleAuthor.type == 'AUTHOR_TYPE_NORMAL') {
      header = GestureDetector(
        onTap: () => {
          feedBack(),
          Get.toNamed('/member?mid=${moduleAuthor.mid}'),
        },
        child: TranslucentRow(
          spacing: 10,
          extraWidth: 50,
          children: children,
        ),
      );
    } else {
      header = Row(spacing: 10, children: children);
    }
    Widget? moreBtn = isSave
        ? null
        : SizedBox(
            width: 32,
            height: 32,
            child: Builder(
              builder: (btnContext) => IconButton(
                tooltip: '更多',
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.zero),
                ),
                onPressed: () => morePanel(context, btnContext),
                icon: const Icon(Icons.more_vert_outlined, size: 18),
              ),
            ),
          );
    final moduleTagText = !isDetail ? item.modules.moduleTag?.text : null;
    if (moduleTagText != null) {
      header = Row(
        children: [
          Expanded(child: header),
          Container(
            padding: const .symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: const .all(.circular(4)),
              border: .all(width: 1.25, color: theme.colorScheme.primary),
            ),
            child: Text(
              moduleTagText,
              style: TextStyle(
                height: 1,
                fontSize: 12,
                color: theme.colorScheme.primary,
              ),
              strutStyle: const StrutStyle(height: 1, leading: 0, fontSize: 12),
            ),
          ),
          ?moreBtn,
        ],
      );
    } else if (moduleAuthor.decorate != null) {
      const height = 32.0;
      header = Stack(
        clipBehavior: .none,
        children: [
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: CachedNetworkImage(
                height: height,
                memCacheHeight: height.cacheSize(context),
                imageUrl: ImageUtils.safeThumbnailUrl(
                  moduleAuthor.decorate!.cardUrl,
                ),
                placeholder: (_, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          if (moduleAuthor.decorate!.fan?.numStr?.isNotEmpty == true)
            Positioned(
              top: 0,
              bottom: 0,
              right: height,
              child: Center(
                child: Text(
                  moduleAuthor.decorate!.fan!.numStr!.toString(),
                  style: TextStyle(
                    height: 1,
                    fontSize: 11,
                    fontFamily: Assets.digitalNum,
                    color: ColourUtils.parseColor(
                      moduleAuthor.decorate!.fan!.color!,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const .only(right: 80),
            child: header,
          ),
        ],
      );
      if (moreBtn != null) {
        header = Row(
          children: [
            Expanded(child: header),
            moreBtn,
          ],
        );
      }
    } else if (moreBtn != null) {
      header = Row(
        children: [
          Expanded(child: header),
          moreBtn,
        ],
      );
    }
    return header;
  }

  void morePanel(BuildContext context, [BuildContext? anchorContext]) {
    String? bvid;
    try {
      String? getBvid(String? type, DynamicMajorModel? major) => switch (type) {
        'DYNAMIC_TYPE_AV' => major?.archive?.bvid,
        'DYNAMIC_TYPE_UGC_SEASON' => major?.ugcSeason?.bvid,
        _ => null,
      };
      bvid = getBvid(item.type, item.modules.moduleDynamic?.major);
      if (bvid == null && item.orig != null) {
        bvid = getBvid(
          item.orig!.type,
          item.orig!.modules.moduleDynamic?.major,
        );
      }
    } catch (_) {}
    final commentType = item.basic!.commentType;
    final theme = Theme.of(context);
    final moduleAuthor = item.modules.moduleAuthor!;

    // 菜单项只定义一次，iOS / Material 两套皮肤共用，避免逻辑漂移。
    final actions = <_MoreAction>[
      if (bvid != null)
        _MoreAction(
          icon: Icons.watch_later_outlined,
          title: '稍后再看',
          onTap: () => UserHttp.toViewLater(bvid: bvid),
        ),
      _MoreAction(
        icon: Icons.save_alt,
        title: '保存动态',
        onTap: () => SavePanel.toSavePanel(item: item),
      ),
      _MoreAction(
        icon: Icons.share_outlined,
        title: '分享动态',
        onTap: () =>
            ShareUtils.shareText('${HttpString.opusBaseUrl}/${item.idStr}'),
      ),
      if (BiliUtils.isDynOrArticle(commentType) &&
          item.modules.moduleDynamic?.major?.blocked == null)
        _MoreAction(
          icon: Icons.forward_to_inbox,
          title: '分享至消息',
          onTap: () {
            try {
              final isDyn = commentType == 17;
              final id = isDyn ? item.idStr : item.basic!.ridStr!;
              final source = switch (commentType) {
                11 => 2,
                12 => 6,
                17 => 11,
                _ => throw UnsupportedError(commentType.toString()),
              };
              final moduleDynamic = item.modules.moduleDynamic!;
              final title =
                  moduleDynamic.desc?.text ??
                  moduleDynamic.major!.opus!.summary!.text!;
              final thumb = isDyn
                  ? moduleAuthor.face
                  : moduleDynamic.major?.opus?.pics?.firstOrNull?.url;
              PageUtils.pmShare(
                context,
                content: {
                  "id": id,
                  "title": title,
                  "headline": "",
                  "source": source,
                  if (thumb?.isNotEmpty == true) "thumb": thumb,
                  "author": moduleAuthor.name,
                  "author_id": moduleAuthor.mid.toString(),
                },
              );
            } catch (e) {
              SmartDialog.showToast(e.toString());
            }
          },
        ),
      _MoreAction(
        icon: Icons.visibility_off_outlined,
        title: '临时屏蔽：${moduleAuthor.name}',
        groupStart: true,
        onTap: () {
          onBlock?.call();
          try {
            Get.find<DynamicsController>().tempBannedList.add(
              moduleAuthor.mid!,
            );
            SmartDialog.showToast(
              '已临时屏蔽${moduleAuthor.name}(${moduleAuthor.mid!})，重启恢复',
            );
          } catch (_) {}
        },
      ),
      if (kDebugMode || moduleAuthor.mid == Accounts.main.mid) ...[
        _MoreAction(
          icon: CustomIcons.shield_published,
          title: '检查动态',
          groupStart: true,
          onTap: () =>
              RequestUtils.checkCreatedDyn(id: item.idStr, isManual: true),
        ),
        if (onSetTop != null)
          _MoreAction(
            icon: Icons.vertical_align_top,
            title: '${moduleAuthor.isTop == true ? '取消' : ''}置顶',
            onTap: () => onSetTop!(moduleAuthor.isTop ?? false, item.idStr),
          ),
        if (onSetReplySubject != null)
          _MoreAction(
            icon: Icons.mark_unread_chat_alt_outlined,
            title: '互动设置',
            onTap: () async {
              final res = await ReplyHttp.replyInteraction(
                oid: item.basic!.commentIdStr!,
                type: commentType!,
              );
              if (res case Success(:final response)) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final selection = response.upReplySelection;
                      final enableSelection = selection.status == 1;

                      final reply = response.upReply;
                      final enableReply = reply.status == 1;

                      return SimpleDialog(
                        clipBehavior: .hardEdge,
                        contentPadding: const .symmetric(vertical: 12),
                        children: [
                          ListTile(
                            dense: true,
                            enabled: selection.canModify,
                            title: Text(
                              '${enableSelection ? '停止' : '开启'}评论精选',
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () {
                              Get.back();
                              onSetReplySubject!(enableSelection ? 2 : 1);
                            },
                          ),
                          ListTile(
                            dense: true,
                            enabled: reply.canModify,
                            title: Text(
                              '${enableReply ? '关闭' : '恢复'}评论',
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () {
                              Get.back();
                              onSetReplySubject!(enableReply ? 3 : 4);
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              } else {
                res.toast();
              }
            },
          ),
        if (onSetPubSetting != null)
          _MoreAction(
            icon: Icons.visibility,
            title: '可见范围',
            onTap: () {
              final isPrivate = moduleAuthor.badgeText != null;
              Future<void> onTap() async {
                Get.back();
                if ((await onSetPubSetting!(isPrivate, item.idStr)).isSuccess) {
                  if (context.mounted) {
                    (context as Element).markNeedsBuild();
                  }
                }
              }

              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  clipBehavior: Clip.hardEdge,
                  contentPadding: const .symmetric(vertical: 12),
                  children: [
                    ListTile(
                      dense: true,
                      enabled: isPrivate,
                      title: const Text(
                        '所有用户可见',
                        style: TextStyle(fontSize: 14),
                      ),
                      onTap: onTap,
                    ),
                    ListTile(
                      dense: true,
                      enabled: !isPrivate,
                      title: const Text(
                        '仅自己可见',
                        style: TextStyle(fontSize: 14),
                      ),
                      onTap: onTap,
                    ),
                  ],
                ),
              );
            },
          ),
        if (onEdit != null)
          _MoreAction(
            icon: Icons.edit_note,
            title: '编辑动态',
            onTap: () => onEdit!(),
          ),
        if (onRemove != null)
          _MoreAction(
            icon: Icons.delete_outline,
            title: '删除',
            isDestructive: true,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确定删除该动态?'),
                  actions: [
                    TextButton(
                      onPressed: Get.back,
                      child: Text(
                        '取消',
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.back();
                        onRemove!(item.idStr);
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
      if (!Accounts.main.isLogin)
        _MoreAction(
          icon: Icons.error_outline_outlined,
          title: '屏蔽',
          isDestructive: true,
          groupStart: true,
          onTap: () {
            Pref.setBlackMid(moduleAuthor.mid!);
            SmartDialog.showToast('屏蔽成功');
          },
        )
      else
        _MoreAction(
          icon: Icons.error_outline_outlined,
          title: '举报',
          isDestructive: true,
          groupStart: true,
          onTap: () {
            autoWrapReportDialog(
              context,
              mid: () => moduleAuthor.mid!,
              ReportOptions.dynamicReport,
              (reasonType, reasonDesc, banUid) {
                if (banUid) {
                  VideoHttp.relationMod(
                    mid: moduleAuthor.mid!,
                    act: 5,
                    reSrc: 11,
                  );
                }
                return UserHttp.dynamicReport(
                  mid: moduleAuthor.mid!,
                  dynId: item.idStr,
                  reasonType: reasonType,
                  reasonDesc: reasonDesc,
                );
              },
            );
          },
        ),
    ];

    // iOS：锚定到「更多」按钮的 18 风格菜单，与系统菜单一致。
    if (Adaptive.isIOS(context)) {
      final anchor =
          (anchorContext == null ? null : plPopoverAnchorOf(anchorContext)) ??
          Rect.fromLTWH(
            MediaQuery.sizeOf(context).width - 44,
            MediaQuery.viewPaddingOf(context).top + 44,
            32,
            32,
          );
      showPLPopover(
        context: context,
        anchor: anchor,
        items: [
          for (final (index, action) in actions.indexed) ...[
            if (index > 0 && action.groupStart) const PLPopoverItem.separator(),
            PLPopoverItem(
              icon: action.icon,
              title: action.title,
              isDestructive: action.isDestructive,
              onTap: action.onTap,
            ),
          ],
        ],
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: min(640, MediaQuery.shortestSideOf(context)),
      ),
      builder: (context1) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(context1).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: Get.back,
                borderRadius: Style.bottomSheetRadius,
                child: SizedBox(
                  height: 35,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline,
                        borderRadius: const .all(.circular(1.5)),
                      ),
                    ),
                  ),
                ),
              ),
              for (final action in actions)
                ListTile(
                  onTap: () {
                    Get.back();
                    action.onTap();
                  },
                  minLeadingWidth: 0,
                  leading: Icon(
                    action.icon,
                    size: 19,
                    color: action.isDestructive
                        ? theme.colorScheme.error
                        : null,
                  ),
                  title: Text(
                    action.title,
                    style: theme.textTheme.titleSmall!.copyWith(
                      color: action.isDestructive
                          ? theme.colorScheme.error
                          : null,
                    ),
                  ),
                ),
              const Divider(thickness: 0.1, height: 1),
              ListTile(
                onTap: Get.back,
                minLeadingWidth: 0,
                dense: true,
                title: Text(
                  '取消',
                  style: TextStyle(color: theme.colorScheme.outline),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 「更多」菜单的一项。iOS 与 Material 两套皮肤共享同一份定义。
class _MoreAction {
  const _MoreAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
    this.groupStart = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  /// iOS 菜单中是否在该项之前插入分组分割线。
  final bool groupStart;
}
