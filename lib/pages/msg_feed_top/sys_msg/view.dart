import 'package:PiliPlus/common/skeleton/msg_feed_sys_msg_.dart';
import 'package:PiliPlus/common/sliver_single_child_delegate.dart';
import 'package:PiliPlus/common/widgets/dialog/dialog.dart';
import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/gesture/tap_gesture_recognizer.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/models_new/msg/msg_sys/data.dart';
import 'package:PiliPlus/pages/msg_feed_top/msg_feed_list_view.dart';
import 'package:PiliPlus/pages/msg_feed_top/msg_feed_strings.dart';
import 'package:PiliPlus/pages/msg_feed_top/msg_feed_style.dart';
import 'package:PiliPlus/pages/msg_feed_top/sys_msg/controller.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class SysMsgPage extends StatefulWidget {
  const SysMsgPage({super.key});

  @override
  State<SysMsgPage> createState() => _SysMsgPageState();
}

class _SysMsgPageState extends State<SysMsgPage> {
  final _sysMsgController = Get.put(SysMsgController());

  static final RegExp _urlRegExp = RegExp(
    r'#\{([^}]*)\}\{([^}]*)\}|https?:\/\/[^\s/\$.?#].[^\s]*|www\.[^\s/\$.?#].[^\s]*|【(.*?)】|（(\d+)）',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SimpleScaffold(
      appBar: AppBar(title: const Text(MsgStrings.sysMsg)),
      body: refreshIndicator(
        onRefresh: _sysMsgController.onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: MsgFeedStyle.sliverPadding(context).add(
                EdgeInsets.only(
                  bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
                ),
              ),
              sliver: buildMsgFeedSliver<MsgSysItem>(
                context: context,
                controller: _sysMsgController,
                emptyMessage: MsgStrings.emptySys,
                iosIndent: 16,
                loading: const SliverSafeArea(
                  top: false,
                  bottom: false,
                  sliver: SliverPrototypeExtentList(
                    prototypeItem: MsgFeedSysMsgSkeleton(),
                    delegate: SliverSingleChildDelegate(
                      count: 12,
                      child: MsgFeedSysMsgSkeleton(),
                    ),
                  ),
                ),
                itemBuilder:
                    (
                      context,
                      item,
                      index, {
                      required bool isFirst,
                      required bool isLast,
                    }) {
                      void onLongPress() => showConfirmDialog(
                        context: context,
                        title: const Text(MsgStrings.deleteNoticeTitle),
                        destructive: true,
                        onConfirm: () =>
                            _sysMsgController.onRemove(item.id, index),
                      );
                      return MsgFeedStyle.card(
                        context,
                        ListTile(
                          safeArea: true,
                          tileColor: MsgFeedStyle.tileColor(context),
                          onLongPress: onLongPress,
                          onSecondaryTap: PlatformUtils.isMobile
                              ? null
                              : onLongPress,
                          title: Text(
                            "${item.title}",
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text.rich(
                                _buildContent(theme, item.content ?? ''),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "${item.timeAt}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium!.copyWith(
                                    fontSize: 13,
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        isFirst: isFirst,
                        isLast: isLast,
                      );
                    },
              ),
            ),
          ],
        ),
      ),
    );
  }

  InlineSpan _buildContent(ThemeData theme, String content) {
    final List<InlineSpan> spanChildren = <InlineSpan>[];
    content.splitMapJoin(
      _urlRegExp,
      onMatch: (Match match) {
        final matchStr = match[0]!;
        if (matchStr.startsWith('#')) {
          try {
            final url = match[2]!.replaceAll('"', '');
            spanChildren.add(
              TextSpan(
                text: match[1],
                style: TextStyle(color: theme.colorScheme.primary),
                recognizer: NoDeadlineTapGestureRecognizer()
                  ..onTap = () {
                    try {
                      PiliScheme.routePushFromUrl(url);
                    } catch (err) {
                      SmartDialog.showToast(err.toString());
                    }
                  },
              ),
            );
          } catch (e) {
            spanChildren.add(TextSpan(text: matchStr));
          }
        } else if (matchStr.startsWith('【')) {
          try {
            final isBV = match[3]!.startsWith('BV');
            final int validAv;
            final String validBv;
            if (isBV) {
              validBv = match[3]!;
              validAv = IdUtils.bv2av(validBv);
            } else {
              validAv = int.parse(match[3]!);
              validBv = IdUtils.av2bv(validAv);
            }
            spanChildren
              ..add(const TextSpan(text: '【'))
              ..add(
                TextSpan(
                  text: match[3],
                  style: TextStyle(color: theme.colorScheme.primary),
                  recognizer: NoDeadlineTapGestureRecognizer()
                    ..onTap = () {
                      PiliScheme.videoPush(validAv, validBv);
                    },
                ),
              )
              ..add(const TextSpan(text: '】'));
          } catch (e) {
            spanChildren.add(TextSpan(text: matchStr));
          }
        } else if (matchStr.startsWith('（')) {
          try {
            final dynId = match[4]!; // check dynId
            spanChildren
              ..add(const TextSpan(text: '（'))
              ..add(
                TextSpan(
                  text: '查看动态',
                  style: TextStyle(color: theme.colorScheme.primary),
                  recognizer: NoDeadlineTapGestureRecognizer()
                    ..onTap = () {
                      PageUtils.pushDynFromId(id: dynId).catchError(
                        (err) => SmartDialog.showToast(err.toString()),
                      );
                    },
                ),
              )
              ..add(const TextSpan(text: '）'));
          } catch (e) {
            spanChildren.add(TextSpan(text: matchStr));
          }
        } else {
          spanChildren.add(
            TextSpan(
              text: '\u{1F517}网页链接',
              style: TextStyle(color: theme.colorScheme.primary),
              recognizer: NoDeadlineTapGestureRecognizer()
                ..onTap = () {
                  PiliScheme.routePushFromUrl(matchStr);
                },
            ),
          );
        }
        return '';
      },
      onNonMatch: (String nonMatchStr) {
        spanChildren.add(
          TextSpan(text: nonMatchStr),
        );
        return '';
      },
    );
    return TextSpan(children: spanChildren);
  }
}
