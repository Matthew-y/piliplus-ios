import 'dart:math';

import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_dialog.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_list_section.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_list_tile.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_switch.dart';
import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/pages/setting/widgets/switch_item.dart';
import 'package:PiliPlus/utils/extension/context_ext.dart';
import 'package:PiliPlus/utils/filtering_text.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class PlaySpeedPage extends StatefulWidget {
  const PlaySpeedPage({super.key});

  @override
  State<PlaySpeedPage> createState() => _PlaySpeedPageState();
}

class _PlaySpeedPageState extends State<PlaySpeedPage> {
  late double playSpeedDefault = Pref.playSpeedDefault;
  late double longPressSpeedDefault = Pref.longPressSpeedDefault;
  late List<double> speedList = Pref.speedList;
  late bool enableAutoLongPressSpeed = Pref.enableAutoLongPressSpeed;
  List<({int id, String title, Icon icon})> sheetMenu = [
    (
      id: 1,
      title: '设置为默认倍速',
      icon: const Icon(
        Icons.speed,
        size: 21,
      ),
    ),
    (
      id: 2,
      title: '设置为默认长按倍速',
      icon: const Icon(
        Icons.speed_sharp,
        size: 21,
      ),
    ),
    (
      id: -1,
      title: '删除该项',
      icon: const Icon(
        Icons.delete_outline,
        size: 21,
      ),
    ),
  ];

  Box video = GStorage.video;

  // 添加自定义倍速
  void onAddSpeed() {
    String initialValue = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加倍速'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            TextFormField(
              autofocus: true,
              initialValue: initialValue,
              keyboardType: const .numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '自定义倍速',
                border: OutlineInputBorder(borderRadius: .all(.circular(6))),
              ),
              onChanged: (value) => initialValue = value,
              inputFormatters: FilteringText.decimal,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              '取消',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          TextButton(
            onPressed: () {
              try {
                final val = double.parse(initialValue);
                if (speedList.contains(val)) {
                  SmartDialog.showToast('该倍速已存在');
                } else {
                  Get.back();
                  speedList
                    ..add(val)
                    ..sort();
                  video.put(VideoBoxKey.speedsList, speedList);
                  setState(() {});
                }
              } catch (e) {
                SmartDialog.showToast(e.toString());
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  // 设定倍速弹窗
  void showBottomSheet(ThemeData theme, int index) {
    if (Adaptive.isIOS(context)) {
      showPLActionSheet(
        context: context,
        title: '${speedList[index]}x',
        items: [
          for (final item in sheetMenu)
            if (!(enableAutoLongPressSpeed && item.id == 2))
              PLActionSheetItem(
                title: item.title,
                isDestructive: item.id == -1,
                onTap: () => menuAction(index, item.id),
              ),
        ],
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      clipBehavior: Clip.hardEdge,
      constraints: BoxConstraints(
        maxWidth: min(640, context.mediaQueryShortestSide),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            ...sheetMenu.map(
              (item) => ListTile(
                enabled: enableAutoLongPressSpeed && item.id == 2
                    ? false
                    : true,
                onTap: () {
                  Get.back();
                  menuAction(index, item.id);
                },
                minLeadingWidth: 0,
                iconColor: theme.colorScheme.onSurface,
                leading: item.icon,
                title: Text(
                  item.title,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            SizedBox(height: 25 + MediaQuery.viewPaddingOf(context).bottom),
          ],
        );
      },
    );
  }

  //
  void menuAction(int index, int id) {
    double speed = speedList[index];
    // 设置
    if (id == 1) {
      // 设置默认倍速
      playSpeedDefault = speed;
      video.put(VideoBoxKey.playSpeedDefault, playSpeedDefault);
    } else if (id == 2) {
      // 设置默认长按倍速
      longPressSpeedDefault = speed;
      video.put(VideoBoxKey.longPressSpeedDefault, longPressSpeedDefault);
    } else if (id == -1) {
      if ([
        1.0,
        playSpeedDefault,
        longPressSpeedDefault,
      ].contains(speed)) {
        SmartDialog.showToast('不支持删除默认倍速');
        return;
      }
      speedList.removeAt(index);
      video.put(VideoBoxKey.speedsList, speedList);
    }
    setState(() {});
  }

  /// iOS：分组卡片 + CupertinoSwitch + 胶囊倍速项。
  Widget _buildIos(ThemeData theme) {
    final padding = MediaQuery.viewPaddingOf(context);
    return ListView(
      padding: EdgeInsets.only(bottom: padding.bottom + 100),
      children: [
        PLListSection(
          header: const Text('默认'),
          footer: const Text('点击下方倍速胶囊可设置默认 / 长按倍速'),
          children: [
            PLListTile(
              title: const Text('默认倍速'),
              trailing: Text('${playSpeedDefault}x'),
            ),
            PLListTile(
              title: const Text('动态长按倍速'),
              subtitle: const Text('根据默认倍速长按时自动双倍'),
              trailing: PLSwitch(
                value: enableAutoLongPressSpeed,
                onChanged: (val) =>
                    setState(() => enableAutoLongPressSpeed = val),
              ),
              onTap: () => setState(
                () => enableAutoLongPressSpeed = !enableAutoLongPressSpeed,
              ),
            ),
            if (!enableAutoLongPressSpeed)
              PLListTile(
                title: const Text('默认长按倍速'),
                trailing: Text('${longPressSpeedDefault}x'),
              ),
          ],
        ),
        PLListSection(
          header: const Text('倍速列表'),
          children: [
            PLListTile(
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < speedList.length; i++)
                      _speedChip(theme, i),
                  ],
                ),
              ),
            ),
            PLListTile(
              title: const Text('添加倍速'),
              trailing: const Icon(Icons.add, size: 20),
              onTap: onAddSpeed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _speedChip(ThemeData theme, int index) {
    final speed = speedList[index];
    final selected = speed == playSpeedDefault;
    return GestureDetector(
      onTap: () => showBottomSheet(theme, index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : IosColors.gray5(theme.brightness),
          borderRadius: const BorderRadius.all(Radius.circular(999)),
        ),
        child: Text(
          '${speed}x',
          style: TextStyle(
            fontSize: 15,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? theme.colorScheme.primary : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SimpleScaffold(
      appBar: AppBar(
        title: const Text('倍速设置'),
        actions: [
          TextButton(
            onPressed: () async {
              await video.delete(VideoBoxKey.speedsList);
              speedList = Pref.speedList;
              setState(() {});
            },
            child: const Text('重置'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ViewSafeArea(
        child: Adaptive.isIOS(context)
            ? _buildIos(theme)
            : ListView(
                padding: .only(
                  bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 14,
                      right: 14,
                      top: 6,
                      bottom: 0,
                    ),
                    child: Text(
                      '点击下方按钮设置默认（长按）倍速',
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                  ),
                  ListTile(
                    title: const Text('默认倍速'),
                    subtitle: Text(playSpeedDefault.toString()),
                  ),
                  SetSwitchItem(
                    title: '动态长按倍速',
                    subtitle: '根据默认倍速长按时自动双倍',
                    setKey: SettingBoxKey.enableAutoLongPressSpeed,
                    defaultVal: enableAutoLongPressSpeed,
                    onChanged: (val) =>
                        setState(() => enableAutoLongPressSpeed = val),
                  ),
                  if (!enableAutoLongPressSpeed)
                    ListTile(
                      title: const Text('默认长按倍速'),
                      subtitle: Text(longPressSpeedDefault.toString()),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 14,
                      right: 14,
                      bottom: 10,
                      top: 20,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '倍速列表',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: onAddSpeed,
                          child: const Text('添加'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 18,
                      right: 18,
                      bottom: 30,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 8,
                      runSpacing: 2,
                      children: List.generate(
                        speedList.length,
                        (index) => FilledButton.tonal(
                          style: FilledButton.styleFrom(tapTargetSize: .padded),
                          onPressed: () => showBottomSheet(theme, index),
                          child: Text(speedList[index].toString()),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
