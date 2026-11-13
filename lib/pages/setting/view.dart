import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_list_section.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_search_field.dart';
import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/http/login.dart';
import 'package:PiliPlus/models/common/setting_type.dart';
import 'package:PiliPlus/pages/about/view.dart';
import 'package:PiliPlus/pages/login/controller.dart';
import 'package:PiliPlus/pages/setting/common_setting.dart';
import 'package:PiliPlus/pages/setting/widgets/multi_select_dialog.dart';
import 'package:PiliPlus/pages/webdav/view.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:PiliPlus/utils/utils.dart';

import 'dart:async';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class _SettingsModel {
  final SettingType type;
  final String? subtitle;
  final Icon icon;

  const _SettingsModel({
    required this.type,
    this.subtitle,
    required this.icon,
  });
}

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late SettingType _type = .privacySetting;
  final RxBool _noAccount = Accounts.account.isEmpty.obs;
  late bool _isPortrait;
  late ThemeData theme;
  // 监听账号变化以重建列表（iOS 分支不能用 Obx 包 CupertinoListSection，
  // 见 _iosGroupedList）。Material 分支仍用自身的 Obx。
  StreamSubscription? _noAccountSub;

  static const List<_SettingsModel> _items = [
    _SettingsModel(
      type: .privacySetting,
      subtitle: '账号、黑名单',
      icon: Icon(Icons.privacy_tip_outlined),
    ),
    _SettingsModel(
      type: .recommendSetting,
      subtitle: '推荐来源（web/app）、刷新保留内容、过滤器',
      icon: Icon(Icons.explore_outlined),
    ),
    _SettingsModel(
      type: .videoSetting,
      subtitle: '画质、音质、解码、缓冲、音频输出等',
      icon: Icon(Icons.video_settings_outlined),
    ),
    _SettingsModel(
      type: .playSetting,
      subtitle: '双击/长按、全屏、后台播放、弹幕、字幕、底部进度条等',
      icon: Icon(Icons.touch_app_outlined),
    ),
    _SettingsModel(
      type: .dmSetting,
      subtitle: '点击弹幕、弹幕行高、彩色弹幕、合并弹幕',
      icon: Icon(CustomIcons.dm_settings),
    ),
    _SettingsModel(
      type: .replySetting,
      subtitle: '过滤、屏蔽、记录、默认展示等',
      icon: Icon(Icons.comment_outlined),
    ),
    _SettingsModel(
      type: .dynSetting,
      subtitle: '过滤、屏蔽、默认展示等',
      icon: Icon(CustomIcons.motion_photos_on_outlined),
    ),
    _SettingsModel(
      type: .styleSetting,
      subtitle: '横屏适配（平板）、侧栏、列宽、首页、动态红点、主题、字号、图片、帧率等',
      icon: Icon(Icons.style_outlined),
    ),
    _SettingsModel(
      type: .extraSetting,
      subtitle: '震动、搜索、收藏、ai、评论、动态、代理、更新检查等',
      icon: Icon(Icons.extension_outlined),
    ),
    _SettingsModel(
      type: .webdavSetting,
      icon: Icon(MdiIcons.databaseCogOutline),
    ),
    _SettingsModel(
      type: .about,
      icon: Icon(Icons.info_outline),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 账号列表变化时重建列表，让「退出登录」在登出后自动消失
    // （iOS 分支 _iosGroupedList 直接读 _noAccount.value，靠这里触发 rebuild）。
    _noAccountSub = _noAccount.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    _isPortrait = MediaQuery.isPortraitOf(context);
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      appBar: AppBar(
        title: _isPortrait ? const Text('设置') : Text(_type.title),
      ),
      body: ViewSafeArea(
        child: _isPortrait
            ? _buildList(theme)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildList(theme),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    flex: 6,
                    child: switch (_type) {
                      .webdavSetting => const WebDavSettingPage(
                        showAppBar: false,
                      ),
                      .about => const AboutPage(showAppBar: false),
                      _ => CommonSetting(settingType: _type, showAppBar: false),
                    },
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _noAccountSub?.cancel();
    _noAccount.close();
    super.dispose();
  }

  void _toPage(SettingType type) {
    if (_isPortrait) {
      Get.to(
        () => switch (type) {
          .webdavSetting => const WebDavSettingPage(),
          .about => const AboutPage(),
          _ => CommonSetting(settingType: type),
        },
      );
    } else {
      _type = type;
      setState(() {});
    }
  }

  Color? _getTileColor(ThemeData theme, SettingType type) {
    if (_isPortrait) {
      return null;
    } else {
      return type == _type ? theme.colorScheme.onInverseSurface : null;
    }
  }

  Widget _buildList(ThemeData theme) {
    final padding = MediaQuery.viewPaddingOf(context);
    TextStyle titleStyle = theme.textTheme.titleMedium!;
    TextStyle subTitleStyle = theme.textTheme.labelMedium!.copyWith(
      color: theme.colorScheme.outline,
    );

    final entries = <Widget>[
      _buildSearchItem(theme),
      ..._items
          .take(_items.length - 1)
          .map(
            (item) => ListTile(
              tileColor: _getTileColor(theme, item.type),
              onTap: () => _toPage(item.type),
              leading: item.icon,
              title: Text(item.type.title, style: titleStyle),
              subtitle: item.subtitle == null
                  ? null
                  : Text(item.subtitle!, style: subTitleStyle),
            ),
          ),
      ListTile(
        onTap: () => LoginPageController.switchAccountDialog(context),
        leading: const Icon(Icons.switch_account_outlined),
        title: Text('切换账号', style: titleStyle),
      ),
      Obx(
        () => _noAccount.value
            ? const SizedBox.shrink()
            : ListTile(
                leading: const Icon(Icons.logout_outlined),
                onTap: () => _logoutDialog(context),
                title: Text('退出登录', style: titleStyle),
              ),
      ),
      ListTile(
        tileColor: _getTileColor(theme, _items.last.type),
        onTap: () => _toPage(_items.last.type),
        leading: _items.last.icon,
        title: Text(_items.last.type.title, style: titleStyle),
      ),
    ];

    return ListView(
      padding: EdgeInsets.only(
        top: Adaptive.isIOS(context) ? 8 : 0,
        bottom: padding.bottom + 100,
      ),
      children: Adaptive.isIOS(context) ? [_iosGroupedList(entries)] : entries,
    );
  }

  /// iOS 风格：把设置项整理成圆角分组卡片（inset grouped）。
  Widget _iosGroupedList(List<Widget> entries) {
    // 普通条目都是 ListTile，直接转成 PLListSectionTile。
    // 注意「退出登录」被 Obx(() => ... ListTile) 包了一层，本身不是 ListTile，
    // 不能靠类型判断，要单独按 _noAccount 条件追加，否则登录态下会整条丢失。
    //
    // 这里不能用 Obx 包住 PLListSection：CupertinoListSection 在语义收集阶段
    // 被 Obx 重建会触发 Flutter 的 `node.parent?._dirty` 断言。
    // 改用 _noAccount 的 listen + setState（见 initState），由 build 直接读值。
    final plainTiles = [
      for (final e in entries.whereType<ListTile>())
        PLListSectionTile(
          title: e.title,
          subtitle: e.subtitle,
          leading: e.leading,
          onTap: e.onTap,
        ),
    ];
    return Column(
      crossAxisAlignment: .start,
      children: [
        // 搜索框独立在分组卡片之外，顶部留出与导航栏的间距。
        PLSearchField(
          placeholder: '搜索',
          onTap: () => Get.toNamed('/settingsSearch'),
          bottomPadding: 16,
        ),
        PLListSection(
          children: [
            for (final t in plainTiles) t,
            if (!_noAccount.value)
              PLListSectionTile(
                title: const Text('退出登录'),
                leading: const Icon(Icons.logout_outlined),
                onTap: () => _logoutDialog(context),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _removeAccounts(Set<LoginAccount> accounts) async {
    await Accounts.deleteAll(accounts);
    if (mounted) _noAccount.value = Accounts.account.isEmpty;
  }

  static Future<LoginAccount?> _logoutWrapper(LoginAccount account) async {
    try {
      final res = await LoginHttp.logout(account);
      return res.isSuccess ? account : null;
    } catch (e, s) {
      Utils.reportError(e, s);
      return null;
    }
  }

  Future<void> _logoutDialog(BuildContext context) async {
    final result = await showDialog<Set<LoginAccount>>(
      context: context,
      builder: (context) => MultiSelectDialog<LoginAccount>(
        title: '选择要登出的账号uid',
        initValues: const Iterable.empty(),
        values: {
          for (final i in Accounts.account.values) i: i.mid.toString(),
        },
      ),
    );
    if (!context.mounted || result == null || result.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('提示'),
          content: Text(
            "确认要退出以下账号登录吗\n\n${result.map((i) => i.mid).join('\n')}",
          ),
          actions: [
            TextButton(
              onPressed: Get.back,
              child: Text(
                '点错了',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                _removeAccounts(result);
              },
              child: Text(
                '仅登出',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            TextButton(
              onPressed: () async {
                SmartDialog.showLoading();
                final res = await Future.wait(result.map(_logoutWrapper));
                SmartDialog.dismiss();
                final logoutAccounts = res.nonNulls.toSet();
                if (logoutAccounts.isEmpty) {
                  SmartDialog.showToast('所选账号均退出登录失败');
                } else {
                  Get.back();
                  _removeAccounts(logoutAccounts);
                  if (logoutAccounts.length != result.length) {
                    result.removeWhere(logoutAccounts.contains);
                    SmartDialog.showToast(
                      '账号 ${result.map((i) => i.mid).join(",")} 退出登录失败',
                    );
                  }
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchItem(ThemeData theme) => Padding(
    padding: const EdgeInsets.only(
      left: 16,
      right: 16,
      bottom: 8,
    ),
    child: Material(
      color: theme.colorScheme.onInverseSurface,
      borderRadius: const BorderRadius.all(Radius.circular(50)),
      child: InkWell(
        onTap: () => Get.toNamed('/settingsSearch'),
        borderRadius: const BorderRadius.all(Radius.circular(50)),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  size: 18,
                  applyTextScaling: true,
                  Icons.search,
                ),
                Text(
                  ' 搜索',
                  style: TextStyle(height: 1),
                  strutStyle: StrutStyle(height: 1, leading: 0),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
