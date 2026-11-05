import 'dart:async';

import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_list_section.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_list_tile.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:hive_ce/hive.dart';
import 'package:material_ui/material_ui.dart';

class SetDisplayMode extends StatefulWidget {
  const SetDisplayMode({super.key});

  @override
  State<SetDisplayMode> createState() => _SetDisplayModeState();
}

class _SetDisplayModeState extends State<SetDisplayMode> {
  List<DisplayMode> modes = <DisplayMode>[];
  DisplayMode? active;
  DisplayMode? preferred;

  Box setting = GStorage.setting;

  @override
  void initState() {
    super.initState();
    init();
  }

  // 获取所有的mode
  Future<void> fetchAll() async {
    preferred = await FlutterDisplayMode.preferred;
    active = await FlutterDisplayMode.active;
    setting.put(SettingBoxKey.displayMode, preferred.toString());
    if (mounted) {
      setState(() {});
    }
  }

  // 初始化mode/手动设置
  Future<void> init() async {
    try {
      modes = await FlutterDisplayMode.supported;
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint(e.toString());
    }

    final value = setting.get(SettingBoxKey.displayMode);
    if (value != null) {
      preferred = modes.firstWhereOrNull((e) => e.toString() == value);
    }

    preferred ??= DisplayMode.auto;

    FlutterDisplayMode.setPreferredMode(preferred!).whenComplete(() {
      Timer(const Duration(milliseconds: 100), fetchAll);
    });
  }

  void _select(DisplayMode mode) {
    FlutterDisplayMode.setPreferredMode(
      mode,
    ).whenComplete(() => Timer(const Duration(milliseconds: 100), fetchAll));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SimpleScaffold(
      appBar: AppBar(title: const Text('屏幕帧率设置')),
      body: Adaptive.isIOS(context)
          ? _buildIos(theme)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      MediaQuery.viewPaddingOf(
                        context,
                      ).copyWith(top: 0, bottom: 0) +
                      const EdgeInsets.only(left: 25, top: 10, bottom: 5),
                  child: Text(
                    '没有生效？重启app试试',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                ),
                Expanded(
                  child: RadioGroup(
                    onChanged: (newMode) => _select(newMode!),
                    groupValue: preferred,
                    child: ListView.builder(
                      itemCount: modes.length,
                      padding: .only(
                        bottom: MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      itemBuilder: (context, index) {
                        final DisplayMode mode = modes[index];
                        return RadioListTile<DisplayMode>(
                          value: mode,
                          title: mode == DisplayMode.auto
                              ? const Text('自动')
                              : Text(
                                  '$mode${mode == active ? '  [系统]' : ''}',
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildIos(ThemeData theme) {
    final padding = MediaQuery.viewPaddingOf(context);
    return ListView(
      padding: EdgeInsets.only(top: 8, bottom: padding.bottom + 40),
      children: [
        PLListSection(
          header: const Text('屏幕刷新率'),
          footer: const Text('没有生效时，重启 App 再试一次。'),
          children: [
            for (final mode in modes)
              PLListTile(
                title: Text(
                  mode == DisplayMode.auto
                      ? '自动'
                      : '$mode${mode == active ? '  [系统]' : ''}',
                ),
                trailing: mode == preferred
                    ? Icon(
                        Icons.check,
                        size: 20,
                        color: theme.colorScheme.primary,
                      )
                    : null,
                onTap: () => _select(mode),
              ),
          ],
        ),
      ],
    );
  }
}
