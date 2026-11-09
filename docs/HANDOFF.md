# Handoff — PiliPlus iOS 观感改造（第三轮 / iOS 18 Menus）

日期：2026-11-04
工作目录：`/Users/matt/Documents/Code/PiliPlus`
状态：**所有改动仍未提交**

## 一句话现状

在首页、动态页、我的页、搜索页、消息页 iOS 化的基础上，本轮把全应用
`PopupMenuButton` 统一替换为 **iOS 18 Menus 风格锚定弹层**：
磨砂玻璃、13pt 圆角、44pt 行高、分组分割线、选中勾号、从按钮方向缩放展开；
Material 皮肤继续走原生 `PopupMenuButton`，外观与行为不变。

---

## 第四轮：消息 / 通知 review 修复（2026-11-04）

依据 `docs/msg-notification-review.md`（v2）落地，改动仍未提交。

### P1 已修

| 项 | 改动 |
|---|---|
| P1-1 点开即清零 | 首页铃铛不再在点击时 `clearUnreadMsg()` / 顺延 `lastCheckUnreadAt`；`await Get.toNamed('/whisper')` 返回后调用 `queryUnreadMsg()`。消息页 4 个入口同样在子页返回后 `queryMsgFeedUnread()`，不再本地置 0。回复 / @我 / 收到的赞没有公开已读接口，不做假清零；系统通知仍在子页加载成功后 `msgSysUpdateCursor`。 |
| P1-2 两套数据源 | `WhisperController.queryMsgFeedUnread()` 复用 `Pref.msgUnReadTypeV2` 过滤（含 `disableLikeMsg`），与首页铃铛同一规则。 |
| P1-3 点赞详情空指针 | `like_detail/view.dart` 改为 `response ?? const <MsgLikeDetailItem>[]`，不再强解包。 |

### P2 已修

- **P2-4 空列表误报错**：新增 `lib/common/widgets/loading_widget/empty_state.dart`；会话 / 回复 / @我 / 收到的赞 / 系统通知 / 点赞详情成功但为空时显示「暂无…」，错误分支继续用 `HttpError`。
- **P2-5 删除失败静默**：4 个通知 controller 的 `catch (_) {}` 改为 `SmartDialog.showToast(e.toString())`，成功仍有「删除成功」。
- **P2-6 收到的赞脏数据**：`users` 为空跳过该条；`counts` 默认 0；`id` 为空时不发删除 / 不跳详情。点赞详情 `user` 为空也跳过。
- **P2-7 返回到消息页不刷新**：子页 `await Get.toNamed(...)` 后刷新计数（同 P1-1）。
- **P2-8 iOS / Android 未读展示**：Android 入口补 `99+` 截断、禁用态 35% 透明、`GestureDetector` → `InkWell`。
- **P2-9 脆弱 `markNeedsBuild`**：`WhisperSessionItem` 改为 `StatefulWidget` + `setState`。
- **P2-10 标为未读仅本地**：Toast 明确提示「已标为未读（仅本机）」。

### N1 / N2 已修

- 新增 `lib/pages/msg_feed_top/msg_feed_style.dart`：4 个通知子页与点赞详情统一 iOS 分组卡片——页面底 `#F2F2F7`、白卡、16pt 左右留白、0.5pt hairline、首末项 10pt 圆角、系统通知缩进 16；Material 分支保持原样。
- 没有直接换 `PLListTile`：它的 iOS 分支会丢失 `onLongPress`（通知删除依赖长按），也会把头像套成设置页的彩色图标块。
- 所有通知删除 / 不再通知确认补 `destructive: true`；iOS 下「确认」为系统红。

### 组件层 N4–N7

- **N4**：Dynamic Type 叠加改按真实 `defaultTargetPlatform` 判断，Android 强开 iOS 风格时不再双重放大。
- **N5**：`PLPopupMenuButton` 未知 `PopupMenuEntry` 回退原生 `showMenu`；`child` 分支补 `Tooltip` / `Semantics`；补 `onTap` / `onSelected` 注释。
- **N6**：Popover `top` 对安全区 clamp，`maxHeight` 不再硬抬到 96。
- **N7**：iOS 分支按钮默认 44×44 最小点击区。
- 另：`queryMsgFeedUnread` 加并发守卫；侧滑单动作 `extentRatio` 0.28 → 0.35；未读点补 `Semantics`。

### 本轮验证

- `flutter analyze lib`：**0 error / 0 warning**，仍为 38 条既有 info。
- `flutter build ios --simulator --debug`：成功；已安装并启动。
- 已截图确认：
  - 消息页会话列表（iOS 白卡分组）；
  - 「回复我的」与「收到的赞」子页：16pt 留白、白卡、hairline、分组标题对齐；
  - 「系统通知」子页：白卡、16 缩进 hairline、长按删除；
  - 删除确认：iOS 弹窗「确认」为红色（`destructive`）；
  - 设置搜索页（`/settingsSearch`）：iOS 搜索框 + 取消、iOS 开关、结果列表可输入过滤；
  - 我的页：资料卡与收藏卡片正常。
- **未完成视觉确认**：点赞详情（`msgLikeDetail`）当次点击被模拟器上另一个仍在运行的自动化进程抢走（日志出现大量无参数路由跳转：music / fav_detail / subscription_detail / upower_rank 等），页面被带到了 `memberUpowerRank`；该页面的 null 报错来自无参数路由，与本次消息改动无关。
- 测试偏好：`iosStyle=0`、浅色外观，保持还原状态。

### 剩余 P3（第五轮，已完成）

**P3-11 控制器 / 视图去重**

- 新增 `lib/pages/msg_feed_top/msg_feed_list_controller.dart`：
  统一 `cursor` / `cursorTime`、`onRefresh` 重置、`onRemove` 删除反馈；
  子类只提供 `customGetData` 和 `deleteItem`。
- 新增 `lib/pages/msg_feed_top/msg_feed_list_view.dart`：
  `buildMsgFeedSliver<T>` 统一 Loading 骨架 / 列表 / 空态 / 错误重试 / 触底加载；
  回复、@我、系统通知的 view 只剩 AppBar 与行内容。
- 「收到的赞」保留独立实现：`Pair` 双段列表（最新 / 累计）+ 单条 notice 状态，
  套基类需要额外泛型与分支，反而更难读。

**P3-12 文案入口**

- 新增 `lib/pages/msg_feed_top/msg_feed_strings.dart`，把本模块固定文案
  （标题、空态、删除确认、Toast、无未读语义）收拢到单一入口。
- 仓库没有全局 i18n（`main.dart` 锁定 `zh_CN`，业务文案均为中文），
  因此本轮做的是「单一入口」而不是 ARB 迁移；后续接多语言只需改这一层。

**P3-13 可访问性**

- 消息页 4 个入口（iOS 卡片 / Android 图标）补 `Semantics(button: true)`，
  标签包含名称、未读数与禁用状态；未读圆点原有「未读」语义保留。

**P3-15 设置实时生效**

- `WhisperController.disableLikeMsg` 与 `MainController.disableLikeMsg`
  改为 getter，`msgFeedTopItems` 改为按当前设置生成，不再用启动快照。
- `WhisperPage` 接入 `RouteAware.didPopNext`：从通知子页 / 消息设置返回后
  重新拉未读并 `setState`，关闭「收到的赞」入口立即生效。

**N3 界面风格实时切换**

- `IosStyle.revision`（ValueNotifier）：`setMode` 写入后自增。
- `MyApp` 用 `ValueListenableBuilder` 包住 `GetMaterialApp`，风格变化时重建主题；
  `ThemeData.platform`、`Style.topBarHeight`、TabBarView 物理等同步更新。
- 设置项文案由「重启生效」改为「已切换界面风格」。
- 模拟器已验证「跟随系统 ↔ 始终关闭」双向即时切换，无崩溃、无半生效。

**顺带修复：iOS 设置下拉项全部点不动**

- `PLListTile` 的 iOS 分支是 `CupertinoListTile`，只支持 `onTap`；
  而 `PopupListTile` 只传 `onTapUp`，导致 iOS 下「界面风格」「消息未读标记」
  等所有设置下拉项点击无反应。
- 改为 `onTap` + 用行自身 `RenderBox` 计算 `showMenu` 锚点；
  Material / iOS 两种皮肤都能正常弹出。

**验证**

- `flutter analyze lib`：0 error / 0 warning（38 条既有 info）。
- `flutter build ios --simulator --debug`：成功。
- 回复页列表渲染正常；设置「界面风格」菜单可打开；实时切换双向验证通过。
- 测试偏好已还原：`iosStyle=0`（跟随系统）、浅色外观。

---

## 快速开始

```bash
cd /Users/matt/Documents/Code/PiliPlus
export PATH="/Users/matt/development/flutter/bin:$PATH"
# CocoaPods 需要 UTF-8，否则 pod install 报 ASCII-8BIT 编码错误
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 静态检查
flutter analyze lib

# 目标模拟器（换设备只改这一行）；同名设备优先取已开机的
DEVICE_NAME="iPhone 16e"
SIM_LIST=$(xcrun simctl list devices available | grep "$DEVICE_NAME (")
UDID=$(printf '%s\n' "$SIM_LIST" | grep '(Booted)' | head -n 1 \
  | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')
[ -n "$UDID" ] || UDID=$(printf '%s\n' "$SIM_LIST" | head -n 1 \
  | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')

# 启动模拟器 + App（带热重载）
xcrun simctl bootstatus "$UDID" -b
flutter run -d "$UDID" --debug

# 可选：手动构建 / 安装 / 启动
# flutter build ios --simulator --debug
# xcrun simctl install "$UDID" build/ios/iphonesimulator/Runner.app
# xcrun simctl launch "$UDID" com.example.piliplus
```

模拟器信息：

| 项目 | 值 |
|---|---|
| 设备 | iPhone 16e |
| UDID | 运行时由 `xcrun simctl list devices` 解析，不硬编码 |
| Bundle ID | `com.example.piliplus` |

> 不要用 `booted`：同时开多个模拟器时会产生歧义，一律用 UDID。

测试偏好：

- `iosStyle = 0`：跟随系统；模拟器为 iOS，走 iOS 分支。
- `iosStyle = 2`：始终关闭；用于验证 Material 皮肤回退。
- `defaultHomePage = 0`、浅色外观为当前还原状态。
- 修改 Hive 偏好后需要重启 App 才会生效。

---

## 已完成

### 1. 自适应组件层

目录：`lib/common/widgets/adaptive/`

| 文件 | 作用 |
|---|---|
| `adaptive.dart` | 统一导出 |
| `ios_colors.dart` | iOS 语义色（`brandPink`、`separator`、`groupedBackground` 等） |
| `pl_bottom_nav.dart` | iOS 底部导航 |
| `pl_dialog.dart` | `showPLConfirmDialog` / `showPLActionSheet` |
| `pl_list_section.dart` | iOS 分组列表 |
| `pl_list_tile.dart` | iOS 列表行 |
| `pl_loading_indicator.dart` | iOS 加载指示器 |
| `pl_popover.dart` | **本轮新增：iOS 18 Menus 弹层** |
| `pl_search_bar.dart` / `pl_search_field.dart` | iOS 搜索栏 |
| `pl_segmented_tabs.dart` | iOS 分段 Tab |
| `pl_switch.dart` | iOS 开关 |

另有 `lib/utils/ios_style.dart` 统一管理 iOS 外观模式与 `TargetPlatform`。

### 2. 首页 / 动态页 / 我的页 / 搜索页

- 首页：iOS 搜索栏、分段 Tab、AppBar、底部导航。
- 动态页：列表模式白卡分组、12pt 圆角、卡片间距 12pt；
  瀑布流模式不套卡片（有意保留）。
- 我的页：资料卡分割线上下对称；收藏夹卡片化。
- 搜索页：共享 `PLSearchBar`；剩余 5 个结构不同的搜索页未适配，见「待确认」。
- 设置页 / 设置搜索页已做 iOS 列表化，但设置搜索页仍缺模拟器视觉验证。

### 3. 消息页 iOS List 与左滑操作

文件：

- `lib/pages/whisper/view.dart`
- `lib/pages/whisper/widgets/item.dart`
- `lib/common/widgets/dialog/dialog.dart`（`showConfirmDialog` 新增 `destructive`）

要点：

- 浅灰分组背景 + 逐行白卡，首/末行 10pt 圆角。
- 40×40 头像、16/w500 标题、14 次要文字、未读蓝点。
- 左滑：蓝色「标为已读/未读」+ 红色「删除」；
  右滑：橙色「免打扰」+ 深灰「置顶」；滑动与点击都有轻震。
- 删除确认使用 `showConfirmDialog(destructive: true)`，iOS 下「确认」为系统红。
- 顶部 4 个入口改为白色圆角卡片内的纯文字 Tab；Material 分支保留原圆形图标入口。
- AppBar 右侧 `IconButton` 在 iOS 下最小点击区 `44×44`。

### 4. iOS 18 Menus 弹层

核心文件：`lib/common/widgets/adaptive/pl_popover.dart`

实现方式：

- 没有使用 `showCupertinoModalPopup`：它自带的底部滑入动画无法满足
  “从触发按钮位置缩放展开”，因此用 `showGeneralDialog` + 自定义锚定布局。
- `PLPopupMenuButton<T>`：
  - Material 皮肤：直接透传原生 `PopupMenuButton`，参数、外观、行为不变。
  - iOS 皮肤：读取触发按钮的全局 `Rect`，在按钮附近显示自绘弹层。
- 支持 `PopupMenuItem`、`CheckedPopupMenuItem`、`CustomPopupMenuItem`、
  `PopupMenuDivider`、`CustomPopupMenuDivider`；未知 entry 类型会被跳过。
- 触发方式：
  - 传 `icon`：使用 `IconButton`。
  - 传 `child`：使用 `InkWell` 包裹，保留点击语义。

视觉规格：

| 项目 | 值 |
|---|---|
| 宽度 | 250pt（屏幕过窄时自动收窄） |
| 对齐 | 菜单右边缘对齐按钮右边缘 |
| 垂直位置 | 按钮下方 6pt；空间不足自动翻到上方 |
| 圆角 | 13pt |
| 材质 | `ClipRRect` + `BackdropFilter(blur 20)` |
| 背景 | `systemBackground`：浅色 0.75 / 深色 0.72 |
| 描边 | `separator` 0.35，0.5pt |
| 阴影 | 低透明度、28pt blur、向下 10pt |
| 行高 | 44pt |
| 图标 | 20pt |
| 文字 | 16pt，`CupertinoColors.label` |
| 图标/文字间距 | 12pt |
| 左右 padding | 12pt |
| 危险项 | `CupertinoColors.systemRed` |
| 选中项 | 左侧蓝色勾号；无图标菜单统一预留勾选列 |
| 分割线 | `CupertinoColors.separator`，有图标/勾选时缩进 44pt，纯文字菜单缩进 12pt |
| 动画 | 200ms，遮罩淡入 + `easeOutBack` 缩放，原点在按钮方向 |
| 关闭 | 点击遮罩 / 返回键平滑关闭 |

动态卡片「更多」：

- 文件：`lib/pages/dynamics/widgets/author_panel.dart`
- 「更多」按钮包一层 `Builder` 捕获按钮 context，菜单锚定到按钮。
- `_MoreAction` 新增 `groupStart`，在分享 / 屏蔽 / 作者操作 / 举报之间插入分割线。
- 长按卡片的「更多」入口仍复用同一份 actions；没有按钮 context 时退化为右上角锚点。

批量替换：

- `lib` 下 31 个文件的 `PopupMenuButton` → `PLPopupMenuButton` 并补 import；
  加上此前已接入的 `whisper/view.dart`，共 **32 个调用文件**。
- Material 皮肤全部走原生回退。

---

## 验证结果

- `flutter analyze lib`：**0 error / 0 warning**，仅剩 38 条既有 info。
- `flutter build ios --simulator --debug`：构建成功。
- 消息页：浅色/深色、左右滑动、标为已读/未读、删除确认（红色「确认」）均已截图验证。
- 弹层：
  - 消息页「…」菜单：锚定按钮下方、磨砂、44pt 行高、图标/文字对齐正常；
  - 动态卡片「更多」：锚定卡片按钮、分组分割线与危险项红色正常；
  - 收藏夹排序：选中项左侧蓝色勾号、纯文字菜单文字对齐正常；
  - 深色模式：深色半透明底 + 白色文字/图标正常；
  - 点击遮罩可关闭；
  - Material 皮肤（`iosStyle=2`）下仍为原生 `PopupMenuButton`，未受 iOS 改动影响。
- 截图（`$TMPDIR`，临时文件）：
  - `whisper_menu1.png`：消息页浅色弹层
  - `dark_menu2.png`：消息页深色弹层
  - `final_dyn_menu.png`：动态卡片分组弹层
  - `fav_sort1.png`：排序菜单选中勾号
  - `material_menu3.png`：Material 皮肤回退
  - `final_home2.png`：还原后的首页
- 测试偏好已还原：`iosStyle=0`、浅色外观。

---

## 未完成 / 待确认

1. **长按上下文菜单未改**：以下位置仍直接使用 `showMenu`，保持系统原生菜单，
   不在本轮 `PopupMenuButton` 替换范围内：
   - `lib/common/widgets/image_viewer/gallery_viewer.dart`
   - `lib/common/widgets/image_grid/image_grid_view.dart`
   - `lib/pages/live_room/superchat/superchat_card.dart`
   - `lib/pages/live_room/widgets/chat_panel.dart`
   - `lib/pages/download/download_action_mixin.dart`
   - `lib/pages/whisper_detail/view.dart`
   - `lib/pages/whisper/widgets/item.dart`
   - `lib/pages/setting/widgets/popup_item.dart`（设置项下拉）
2. **搜索页剩余 5 个结构不同的页面**：
   - `lib/pages/member_search/view.dart`
   - `lib/pages/live_search/view.dart`
   - `lib/pages/video/reply_search_item/view.dart`
   - `lib/pages/search_result/view.dart`
   - `lib/pages/search_trending/view.dart`
3. 设置搜索页（`/settingsSearch`）已在第四轮补做浅色 iOS 分支验证（搜索框、取消、开关、结果过滤）；深色与 Material 分支仍未验证。
4. 动态页瀑布流模式未套卡片，保持原样。
5. 真机下拉刷新 / 分页菊花未做手势验证。
6. `showPLActionSheet` 目前没有调用点，保留作为自适应层工具；如确认不再使用可删除。

---

## 风险与注意事项

1. **`material_ui` 必须保持 `1.9.0`**。
   升级到 `1.10.0` 会破坏 `lib/common/widgets/flutter/dyn_tab_bar.dart`
   （`TabBarState` / `IndicatorPainter` 等类型消失）。
2. 重新解析依赖时使用：
   ```bash
   PUB_HOSTED_URL=https://pub.dev flutter pub get --offline
   ```
   直接 `flutter pub get` 可能升级 `material_ui`。
3. `pubspec.lock` 实际新增依赖只有 `cupertino_icons` 与 `flutter_slidable`。
4. **模拟器截图用 `--route` 深链，不要用 CGEvent 坐标点击。**
   坐标点击（Mac 屏幕坐标 + `screenX = 771 + shotX * 0.267` 映射）曾让两个 agent
   卡死 30 分钟以上，且窗口位置一变就失效。改用 Flutter 自带的初始路由：
   ```bash
   export PATH="/Users/matt/development/flutter/bin:$PATH"
   export LANG=en_US.UTF-8
   export LC_ALL=en_US.UTF-8
   DEV=$(xcrun simctl list devices available | grep "iPhone 16e (" \
     | grep '(Booted)' | head -n 1 \
     | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')
   BID=com.example.piliplus

   xcrun simctl terminate "$DEV" "$BID" 2>/dev/null
   flutter run -d "$DEV" --route=/history --no-resident
   sleep 6
   xcrun simctl io "$DEV" screenshot out.png
   ```
   任意 GetX 路由都可直达（`/fav` `/later` `/follow` `/createFav` `/editProfile`
   `/logs` `/settingsSearch` …），不需要点任何东西。
   深色截图必须**同时**把 `Pref.themeMode` 改成「跟随系统」——
   只切 `xcrun simctl ui "$DEV" appearance dark` 时 App 仍是浅色（本机 themeMode 存的是 0）。
5. 改动已按「适配层 / 表单页 / 列表页 / 主题修复 / 文档」拆分提交；
   后续继续按同一粒度拆分，不要合成一个 commit。

---

## 主要改动文件

### 本轮弹层

- `lib/common/widgets/adaptive/pl_popover.dart`（新增）
- `lib/pages/dynamics/widgets/author_panel.dart`
- `lib/utils/desktop/window_controller.dart`（删除冗余 `default`，恢复 0 warning）

`PopupMenuButton` → `PLPopupMenuButton`（共 32 个调用文件）：

```text
lib/common/widgets/video_popup_menu.dart
lib/models_new/download/bili_download_entry_info.dart
lib/pages/article/view.dart
lib/pages/audio/view.dart
lib/pages/common/page_order/page_order_btn_mixin.dart
lib/pages/dynamics_create/view.dart
lib/pages/dynamics_create_reserve/view.dart
lib/pages/dynamics_create_vote/view.dart
lib/pages/dynamics_topic/view.dart
lib/pages/fav_detail/view.dart
lib/pages/fav_search/view.dart
lib/pages/follow/view.dart
lib/pages/history/view.dart
lib/pages/history/widgets/item.dart
lib/pages/later/view.dart
lib/pages/live_room/view.dart
lib/pages/live_room/widgets/bottom_control.dart
lib/pages/live_room/widgets/header_control.dart
lib/pages/login/view.dart
lib/pages/member/view.dart
lib/pages/member_search/child/widgets/search_archive_grpc.dart
lib/pages/member_video_web/base/view.dart
lib/pages/setting/pages/logs.dart
lib/pages/sponsor_block/view.dart
lib/pages/video/download_panel/view.dart
lib/pages/video/post_panel/popup_menu_text.dart
lib/pages/video/view.dart
lib/pages/video/widgets/header_control.dart
lib/pages/webview/view.dart
lib/pages/whisper/view.dart
lib/pages/whisper_secondary/view.dart
lib/plugin/pl_player/view/view.dart
```

### 其他主要区域

- 自适应层：`lib/common/widgets/adaptive/*`、`lib/utils/ios_style.dart`
- 主题：`lib/utils/theme_utils.dart`、`lib/common/style.dart`
- 首页：`lib/pages/home/view.dart`、`lib/pages/main/view.dart`
- 动态：`lib/pages/dynamics_tab/view.dart`、`lib/pages/dynamics/widgets/dynamic_panel.dart`
- 我的：`lib/pages/mine/view.dart`、`lib/pages/mine/widgets/fav_item.dart`
- 搜索：`lib/pages/common/search/common_search_page.dart`、`lib/pages/search/view.dart`
- 消息：`lib/pages/whisper/view.dart`、`lib/pages/whisper/widgets/item.dart`
- 设置：`lib/pages/setting/*`、`lib/pages/settings_search/view.dart`
- 依赖：`pubspec.yaml`、`pubspec.lock`

---

## IPA 构建与真机安装

| 项目 | 值 |
|---|---|
| IPA | `build/ios/ipa/PiliPlus.ipa`（约 25 MB） |
| Bundle ID | `com.yangchao.piliplus` |
| 版本 | `2.2.0 (1)` |
| 签名 | `Apple Development: 1685317031@qq.com (K69A73JTQ6)` |
| Team | `33RMKPKRGR` |
| 描述文件 | `iOS Team Provisioning Profile: com.yangchao.piliplus` |
| 描述文件到期 | 2026-11-08 16:11 UTC |
| 设备 | 杨超的iPhone（iPhone 12 / iOS 18.7.8） |
| UDID | `00008101-0010689A2280001E` |
| 结果 | 安装成功并已启动 |

### 签名注意

1. `com.example.piliplus` 无法在当前开发者账号注册，构建时改用已有描述文件的
   `com.yangchao.piliplus`。
2. **不要**用命令行全局覆盖 `PRODUCT_BUNDLE_IDENTIFIER`，否则 Pods 框架会被改成同一
   Bundle ID，安装报 `DuplicateIdentifier`。
   正确做法：只改 Runner target 的三处 `PRODUCT_BUNDLE_IDENTIFIER`，或使用已有 profile。
3. 构建完成后已把工程里的 Bundle ID 还原为 `com.example.piliplus`，IPA 不受影响。
4. 个人团队描述文件 2026-11-08 到期，之后需重新签名安装。

### 可复用命令

```bash
# 归档（自动签名）
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/ios/archive/Runner.xcarchive archive \
  DEVELOPMENT_TEAM=33RMKPKRGR CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates

# 导出 IPA（ExportOptions.plist: method=development, teamID=33RMKPKRGR）
xcodebuild -exportArchive \
  -archivePath build/ios/archive/Runner.xcarchive \
  -exportPath build/ios/ipa \
  -exportOptionsPlist "$TMPDIR/ExportOptions.plist" \
  -allowProvisioningUpdates

# 安装到真机
xcrun devicectl device install app --device 00008101-0010689A2280001E \
  "$TMPDIR/pili_ipa/Payload/Runner.app"

# 启动
xcrun devicectl device process launch --device 00008101-0010689A2280001E \
  com.yangchao.piliplus
```

---

## 下一步建议

1. 决定是否把长按 `showMenu` 上下文菜单也统一成 iOS 18 Menus；
   可给 `showPLPopover` 增加“坐标锚点 + 自动翻转”的重载。
2. 适配剩余 5 个结构不同的搜索页（Tab 页）。
3. 补设置搜索页的模拟器视觉验证。
4. 真机验证下拉刷新、分页、左滑操作的手势体验。
5. 提交前按模块拆分 review，并确认 `material_ui` 仍锁定 `1.9.0`。
6. 处理 IPA 描述文件即将到期的问题（升级付费团队或重新签名）。
