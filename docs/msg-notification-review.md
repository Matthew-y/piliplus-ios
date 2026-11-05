# 消息 / 通知页面 审核报告

- **审核对象**：首页右上角铃铛 → 消息页 → 4 个通知子页
- **代码基线**：`main` @ `d635f20e2`（工作区未提交改动 80 个文件）
- **审核日期**：2026-11-04（v2 复核）
- **静态检查**：`flutter analyze lib/pages/whisper lib/pages/msg_feed_top lib/pages/home/view.dart lib/pages/main/controller.dart lib/utils/ios_style.dart lib/utils/theme_utils.dart lib/common/widgets/adaptive lib/common/widgets/dialog/dialog.dart lib/utils/extension/three_dot_ext.dart` → **No issues found**
- **结论**：**有条件通过**（P1 全部修复、P2 至少修复 4 / 5 / 6，并补齐 iOS 风格在子页的一致性后再合并）

---

## 修订记录

| 版本 | 日期 | 说明 |
| --- | --- | --- |
| v1 | 2026-11-04 | 首次审核，输出 P1×3、P2×7、P3×6 |
| v2 | 2026-11-04 | 代码变更后复核：新增全局 `IosStyle` 开关、`PLPopupMenuButton` / `PLConfirmDialog`、主题层 iOS 化；复核上轮 16 项结论并新增 7 项意见 |

### 本次变更摘要（与消息功能的关联）

| 变更 | 位置 | 对消息功能的影响 |
| --- | --- | --- |
| 新增「界面风格」设置（跟随系统 / 始终开启 / 始终关闭） | `lib/utils/ios_style.dart`、`lib/pages/setting/models/style_settings.dart:177-188` | 决定消息页走 iOS 还是 Material 布局，可强制在 Android / 桌面开启 |
| `ThemeData.platform` 接入 `IosStyle.targetPlatform` | `lib/utils/theme_utils.dart:63,82` | `Adaptive.isIOS(context)` 由主题平台决定，影响消息页分支 |
| 新增 iOS 锚定 Popover 并替换消息页三点菜单 | `lib/common/widgets/adaptive/pl_popover.dart`、`lib/pages/whisper/view.dart:99` | 三点菜单在 iOS 风格下变为磨砂 Popover |
| 新增 iOS 确认框，`showConfirmDialog` 自动分流 | `lib/common/widgets/adaptive/pl_dialog.dart`、`lib/common/widgets/dialog/dialog.dart:14-23` | 消息页的删除确认在 iOS 风格下变为 CupertinoAlertDialog，并新增 `destructive` 参数 |
| 列表 / 主题 iOS 化基础设施 | `pl_list_tile.dart`、`pl_list_section.dart`、`theme_utils.dart` | **仅设置页接入**，消息子页未接入 |
| 顶栏高度、滚动回弹改为按风格取值 | `lib/common/style.dart:24`、`lib/common/widgets/scroll_physics.dart:13` | 首页入口与消息页滚动行为随风格变化 |

> 说明：`lib/pages/whisper/**`、`lib/pages/msg_feed_top/**`、`lib/pages/home/view.dart` 的**业务代码与 v1 审核时一致**（文件 mtime 变化但内容未变），本次变更集中在主题 / 自适应组件层。

---

## 一、入口与调用链

| 层级 | 位置 | 说明 |
| --- | --- | --- |
| 入口 | `lib/pages/home/view.dart:437` `msgBadge()` | 铃铛图标，仅登录后显示（`isLogin`），支持点 / 数字两种角标 |
| 跳转 | `lib/pages/home/view.dart:445-449` | 先 `clearUnreadMsg()` + 记录 `lastCheckUnreadAt`，再 `Get.toNamed('/whisper')` |
| 消息页 | `lib/pages/whisper/view.dart` | 顶部 4 个入口 + 私信会话列表（`ImGrpc.sessionMain`） |
| 子页 | `/replyMe`、`/atMe`、`/likeMe`、`/sysMsg`、`/msgLikeDetail` | 见 `lib/router/app_pages.dart:132-163` |
| 未读数据 | 主界面：`MsgHttp.msgUnread()` + `MsgHttp.msgFeedUnread()`；消息页：`ImGrpc.getTotalUnread(unreadType: 2)` | 两套接口 |

## 二、已实现功能

- **角标**：三种模式（隐藏 / 小红点 / 数字），数字 > 99 显示 `99+`；按设置项 `msgUnReadTypes` 过滤统计（`lib/pages/main/controller.dart:121-195`）。
- **消息页**：4 个入口（回复我的 / @我 / 收到的赞 / 系统通知）带未读数；iOS 为分组卡片纯文字 Tab，Android 为图标 + Badge。
- **会话列表**：置顶 / 免打扰 / 删除 / 标为已读 / 标为未读（iOS 侧滑 + 长按菜单），iOS 卡片式分组；三点菜单在 iOS 风格下为锚定 Popover。
- **通知子页**：分页加载、下拉刷新、长按（桌面右键）删除、点击跳转目标内容、系统通知富文本解析（BV / 动态 / 链接）。
- **设置联动**：`disableLikeMsg` 关闭"收到的赞"入口；`/whisperSettings` 支持各通知类型细化设置；全局「界面风格」开关可改变消息页外观。

---

## 三、上轮问题复核结果

> **未修复**：本轮代码未触及该逻辑，问题仍然成立，描述与定位保持不变。

### 🔴 P1 必须修复

#### 1. 未读状态"点开即清零"，与服务端不同步 —— ❌ 未修复

`lib/pages/home/view.dart:445-449` 与 `lib/pages/whisper/view.dart:249`、`:378` 都只是本地置 0 / 置 null：

- 主角标立即消失，但**没有调用任何服务端已读接口**。全仓库只有系统通知有 `msgSysUpdateCursor`（`lib/http/api.dart:482`），回复 / @我 / 收到的赞没有已读回写。
- **后果 A**：用户点开又立刻返回（或页面请求失败），角标照样消失，误以为已读。
- **后果 B**：`lastCheckUnreadAt` 被重置，且轮询周期 `_period = 5 分钟`（`lib/pages/main/controller.dart:69`），期间**新到达的消息不会提醒**，最长延迟 5 分钟。
- **后果 C**：若服务端未清未读，重新进入消息页（新 controller 重新 `queryMsgFeedUnread`）计数会"复活"，与主角标状态矛盾。

> **建议**：进入子页时按 B 站网页逻辑调用对应已读接口（若无公开接口，至少在文档 / 注释中说明取舍）；"清零"改为**页面成功加载后**再执行，而非点击瞬间；`lastCheckUnreadAt` 不应因清零而顺延。

#### 2. 两套未读数据源 + 两套过滤规则，数值可能对不上 —— ❌ 未修复

- 主角标：REST `msgFeedUnread`，且**按 `msgUnReadTypes` 设置过滤**（`lib/pages/main/controller.dart:136-164`）。
- 消息页四宫格：gRPC `getTotalUnread`，**完全忽略 `msgUnReadTypes`**，始终展示 4 项（`lib/pages/whisper/controller.dart:67-83`）。

即：用户在设置里关掉"系统通知"角标后，首页不计数，但消息页仍显示系统通知未读数。

> **建议**：统一为单一数据源（同一接口），并在消息页复用同一套过滤规则。

#### 3. `LikeDetailPage` 存在空指针崩溃路径 —— ❌ 未修复

`lib/pages/msg_feed_top/like_detail/view.dart:87` 直接 `response!.length`，而 `LikeDetailController.getDataList` 返回可空的 `items`（`lib/models_new/msg/msg_like_detail/data.dart:8`）。当接口只返回 `card` 不返回 `items` 时，`CommonListController` 会写入 `Success(null)`（`lib/pages/common/common_list_controller.dart:30-34`），随后强解包抛 `Null check operator used on a null value`。

```dart
case Success(:final response):
  final items = response ?? const <MsgLikeDetailItem>[];
```

### 🟠 P2 建议修复

#### 4. 空列表被当成"加载失败" —— ❌ 未修复

`lib/pages/whisper/view.dart:196`、`lib/pages/msg_feed_top/reply_me/view.dart:205`、`lib/pages/msg_feed_top/at_me/view.dart`、`lib/pages/msg_feed_top/like_me/view.dart:133`、`lib/pages/msg_feed_top/sys_msg/view.dart:136` 在 `response` 为空时统一返回 `HttpError`，其默认文案是"没有数据 / 点击重试"并配错误插画（`lib/common/widgets/loading_widget/http_error.dart:31-52`）。

> **建议**：引入统一 `Empty` 状态（如"暂无新消息"），仅 `Error` 分支使用 `HttpError`。

#### 5. 删除失败被静默吞掉 —— ❌ 未修复

`lib/pages/msg_feed_top/reply_me/controller.dart:51`、`at_me/controller.dart:51`、`like_me/controller.dart:83`、`sys_msg/controller.dart:48` 均为 `catch (_) {}`。网络异常 / 接口变更时用户点删除**没有任何反馈**。

> **建议**：`catch (e) { SmartDialog.showToast(e.toString()); }`。

#### 6. "收到的赞"页多处非空断言，脏数据即崩溃 —— ❌ 未修复

`lib/pages/msg_feed_top/like_me/view.dart:167` `item.users!.first`（`users` 可能是空数组 → `StateError`）、`:252` `item.counts!`、`:256` `item.id!`。

> **建议**：空列表直接跳过该条或兜底渲染。

#### 7. 回到消息页不刷新子页计数 —— ❌ 未修复

`WhisperController` 只在 `onInit` / 下拉刷新时 `queryMsgFeedUnread`（`:63`、`:111`）。从"回复我的"读完后返回，其他三项计数与列表不会更新。

> **建议**：用 `RouteAware` / `didPopNext` 或 `Get.toNamed(...).then((_) => ...)` 刷新。

#### 8. iOS 与 Android 的未读展示规则不一致 —— ❌ 未修复

- iOS 四宫格数字做了 `99+` 截断（`lib/pages/whisper/view.dart:297`），Android 的 `Badge` 直接 `Text(" $count ")`（`:347`）。
- 禁用入口在 iOS 有 35% 透明度反馈（`:275`），Android 无视觉区分，只在点击时 Toast。
- Android 入口用 `GestureDetector`，无水波纹；iOS 用 `InkWell`。

> **建议**：抽公共组件，保证两端仅样式皮肤不同、行为与文案一致。

#### 9. `(context as Element).markNeedsBuild()` 是脆弱写法 —— ❌ 未修复

`lib/pages/whisper/widgets/item.dart:63、83、93、115-118` 在 `StatelessWidget` 里强转 context 触发重建，依赖 Element 实现细节。

> **建议**：改为 `StatefulWidget` + `setState`，或让上层持有 `RxList<Session>`。

#### 10. "标为未读"只改本地 —— ❌ 未修复

`lib/pages/whisper/widgets/item.dart:87-96` 对私信会话也只是本地设置 `unread = 1`，没有任何接口调用，下拉刷新即恢复。

> **建议**：要么去掉该入口，要么标注"仅本机"。

### 🟡 P3 优化建议 —— 全部未修复

| # | 问题 | 位置 / 说明 |
| --- | --- | --- |
| 11 | **四套 controller / view 高度重复** | reply / at / like / sys 的分页游标、删除、骨架、空态、分隔线几乎逐行复制，仅 `getDataList` 与接口不同。建议抽 `MsgFeedListController<T>` + 通用列表视图，可消掉约 300 行重复 |
| 12 | **硬编码中文** | `'消息'`、`'已禁用'`、`'删除成功'` 等散落在 view / controller，无 i18n 入口 |
| 13 | **可访问性** | iOS 未读小圆点（`whisper/view.dart:498-505`）和 Android Badge 均无 `Semantics` 标签；入口缺少 `button` 语义 |
| 14 | **`queryMsgFeedUnread` 无并发保护** | 快速下拉 / 进入页面可能并发多次 gRPC 请求，建议加 `isLoading` 守卫 |
| 15 | **`disableLikeMsg` 为启动时快照** | `whisper/controller.dart:25`、`main/controller.dart:54` 的 `late final`，设置页修改后需重启页面 / 应用才生效 |
| 16 | **`extentRatio: 0.28` 偏窄** | `whisper/widgets/item.dart:584` 单动作侧滑区偏窄，长文案"取消置顶"存在溢出风险 |

---

## 四、本轮新增意见

> 全部来自本次新增的 iOS 风格接入层，属于"变更引入"的问题。

### 🟠 N1（P2）消息子页未接入 iOS 列表样式，同一流程内风格混搭

`PLListTile` / `PLListSection` 目前只在设置页使用（`lib/pages/setting/widgets/*`、`lib/pages/setting/view.dart`）。消息的 4 个通知子页仍是 Material `ListTile` + 6px 灰色分隔线：

- `lib/pages/msg_feed_top/reply_me/view.dart:109`
- `lib/pages/msg_feed_top/at_me/view.dart:106`
- `lib/pages/msg_feed_top/like_me/view.dart:246`
- `lib/pages/msg_feed_top/sys_msg/view.dart:95`
- `lib/pages/msg_feed_top/like_detail/view.dart:108,120`

而本次变更后，同一条链路里：

- 消息页会话列表 = iOS 卡片 + 侧滑；
- 子页列表 = Material 平铺 + 灰色粗分隔线；
- 删除确认 = CupertinoAlertDialog（`dialog.dart:14`）。

在 Android / 桌面强开「界面风格 = 始终开启」时最明显：**列表 Material、弹窗 iOS**，观感割裂。建议把 4 个子页统一切到 `PLListTile`（或至少统一分隔线与背景），并把删除确认的 `destructive` 一起接入。

### 🟡 N2（P3）新增的 `destructive` 参数没有被消息页删除确认使用

`showConfirmDialog` 新增了 `destructive`（`lib/common/widgets/dialog/dialog.dart:10`），iOS 下会渲染红色确认按钮，Material 下确认文字变红。但消息页的删除确认都没传：

- `reply_me/view.dart:103`、`at_me/view.dart:101`、`sys_msg/view.dart:90`
- `like_me/view.dart:213`（删除）、`:226`（不再通知）

只有会话删除传了（`whisper/widgets/item.dart:105-108`）。这导致删除通知这类危险操作在 iOS 下仍是普通蓝色确认，与组件新能力不匹配。

### 🟡 N3（P3）「重启生效」与运行时读取混用，存在半生效状态

设置项写入后提示"重启生效"（`lib/pages/setting/models/style_settings.dart:186`），但代码里是运行时读取的：

- `Style.topBarHeight`（`lib/common/style.dart:24`）
- `tabBarView` 的物理（`lib/common/widgets/scroll_physics.dart:13`）
- `ThemeUtils`（`lib/utils/theme_utils.dart:63`）
- `main.dart` 的 `textScaler` / `platformBrightness`（`lib/main.dart:330,337`）

一旦后续有人在设置页加 `Get.changeTheme`（或某些页面自行重建主题），就会出现"顶栏高度已变、AppBar 主题没变"这类半生效状态。建议二选一：明确只允许重启生效（并屏蔽热切换入口），或把 `platform` 等收敛到主题刷新统一触发。

### 🟡 N4（P3）iOS 风格下系统字号叠加，Android 强制开启时可能双重放大

`lib/main.dart:326-331`：

```dart
final textScaler = TextScaler.linear(
  Pref.defaultTextScale *
      (IosStyle.isIOSStyleEnabled ? mediaQuery.textScaler.scale(1) : 1),
);
```

在真实 iOS 上叠加 Dynamic Type 是合理的；但 `alwaysOn` 可以在 Android 开启，此时会再乘一次系统字体缩放，与 App 内倍率叠加，容易过大。建议用 `defaultTargetPlatform == TargetPlatform.iOS`（而非风格开关）来控制是否叠加系统字号。

### 🟡 N5（P3）`PLPopupMenuButton` 与原生 PopupMenu 行为不完全等价

`lib/common/widgets/adaptive/pl_popover.dart:166-236`：

- `PopupMenuItem` 的 `onTap` 会执行，但 `onSelected` 仅在 `value != null` 时调用；而原生 PopupMenu 对 `onTap` 项不会回调 `onSelected`——两者语义不同，容易误用。
- 只识别 `PopupMenuItem` / `CheckedPopupMenuItem` / `CustomPopupMenuItem` / Divider，其它自定义 `PopupMenuEntry<T>` 被**静默丢弃**；若 `items` 全被丢弃则 `_showEntries` 直接 return，用户点击后"没反应"。
- `child != null` 分支用 `InkWell` 包裹，未提供 `tooltip` / `Semantics` 标签。

消息页当前用法（只传 `onTap`、无 `value`）可正常工作，但作为通用组件建议：未知 entry 回退到原生 `PopupMenuButton`，并补文档说明 `onTap` / `onSelected` 的差异。

### 🟡 N6（P3）Popover 在极端锚点位置可能溢出安全区

`lib/common/widgets/adaptive/pl_popover.dart:295-329`：

- `belowAvailable` / `aboveAvailable` 可能为负；`maxHeight` 被 `math.max(96.0, …)` 抬到 96，`top` 也未对 `viewPadding.top + margin` 做 clamp。
- 横屏 / 小窗 / 锚点贴近状态栏时，Popover 可能压到状态栏或超出底部。

建议：

```dart
top = top.clamp(viewPadding.top + margin, bottomLimit - maxHeight);
```

### 🟡 N7（P3）iOS 顶栏与入口点击区尺寸不统一

`PLPopupMenuButton` 在 iOS 分支用 `IconButton` 渲染（`pl_popover.dart:150-161`），`padding` 默认 8、`constraints` 为 null；而消息页 AppBar 里其它按钮显式设了 `minWidth/minHeight: 44`（`whisper/view.dart:61-63,81-83`）。同一 AppBar 内的点击区大小不一致，建议给 `PLPopupMenuButton` 也传 `constraints`。

---

## 五、建议修复顺序

1. **P1-3（崩溃）→ P1-1（已读语义）→ P1-2（数据源统一）**
2. **P2-4（空态）→ P2-5（异常提示）→ P2-6（空值兜底）**
3. **N1（子页 iOS 化，顺带解 N2）→ P2-7~10 → P3-11（抽公共组件）**
4. N3 / N4 / N5 / N6 / N7 作为组件层收尾

## 六、回归测试清单

| 场景 | 期望 |
| --- | --- |
| 未登录点首页右上角 | 无铃铛 / 不崩溃 |
| 三种角标模式 × 四类未读设置开关 | 数字与设置一致，重启后保持 |
| 四类通知各有一条未读 → 逐项进入 | 主角标、消息页计数、返回后的计数三者一致 |
| 通知列表为空 / 接口 500 | 分别为"暂无消息"和"加载失败可重试"，不得混淆 |
| 点赞数 > 1 进入点赞详情 | 正常打开，不崩溃 |
| 点赞用户列表为空 / counts 缺失 | 不崩溃，条目降级或隐藏 |
| 深色模式 / iOS 与 Android / 平板侧边栏 | 顶部卡片、分隔线、角标颜色正常 |
| 通知项删除、系统通知富文本链接跳转 | 有成功 / 失败反馈，跳转正确 |
| **界面风格 = 始终开启（Android / 桌面）** | 消息页会话列表、三点菜单、删除确认、通知子页三者风格一致 |
| **界面风格 = 始终关闭（iOS）** | 回退 Material 布局，无 Cupertino 残留 |
| **切换「界面风格」后重启** | 全局生效，无半生效残留 |
| **三点菜单在屏幕顶部 / 底部 / 横屏** | Popover 不溢出安全区，可滚动 |

## 七、结论

**有条件通过（维持 v1 结论）。**

本次代码变更引入的是**全局 iOS 风格开关与自适应组件层**，没有修复 v1 指出的任何一项问题；消息功能的 3 个 P1、7 个 P2、6 个 P3 全部仍然成立。

新增的 7 项意见中，**N1（子页未接入 iOS 列表样式）** 最值得在合并前处理——它会让"消息"这条链路在开启 iOS 风格时出现列表与弹窗风格割裂；其余 6 项属于组件层健壮性与一致性优化。

建议：**P1 全部修复 + P2 至少修复 4 / 5 / 6 + N1/N2 一并处理**，再进入合并评审。
