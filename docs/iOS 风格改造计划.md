# PiliPlus iOS 风格改造计划 (UI Refactor Plan)

基于最新的页面走查统计报告，当前项目共有 71 个页面。其中已适配 13 个，部分适配 16 个，未适配 42 个。
为了统一视觉规范，提升 iOS 用户的交互体验，本计划将未适配及部分适配的页面按 UI 特征进行归类，并制定针对性的 Flutter 组件替换方案。

> **统一改造基准**：
> 1. **全局背景**：页面底板统一使用 `CupertinoColors.systemGroupedBackground`（浅灰），内容区块使用纯白卡片。
> 2. **顶部导航**：统一使用 `CupertinoNavigationBar`，右侧操作图标需符合 iOS 习惯，右侧栏不要堆砌过多图标。
> 3. **底部弹窗/菜单**：禁用 Material 风格，统一使用 `showCupertinoModalPopup` (iOS Action Sheet / 原生 Popover)。
> 4. **空状态页**：移除默认的插画，改为纯文本 + 线框图标，或对齐 iOS 系统占位风格。

---

## 一、 批量改造项（适用于所有未适配/部分适配页面）

以下全局性组件需要全局搜索并替换，不需要逐页修改：

1. **Tab 切换栏（大量存在于列表页）**：
   - 将 Material 的 `TabBar`（带蓝色底部粗横线）批量替换为 `CupertinoSlidingSegmentedControl`，或使用无底部线条的纯文字 `CupertinoTabBar`。
   - **涉及页面**：`/history`, `/later`, `/followed`, `/memberGuard`, `/searchResult` 等。
2. **顶部/底部搜索框**：
   - 移除带有独立搜索图标和取消按钮的顶栏，替换为 iOS App Store 风格的搜索栏（左侧放大镜，右侧取消文字，无边框灰底）。
   - **涉及页面**：`/laterSearch`, `/followSearch`, `/historySearch`, `/webview` 等。
3. **表单与输入框（Settings 类）**：
   - 将 Material 的 `TextField`（下划线样式）替换为带圆角灰底的 `CupertinoTextField`。
   - 将 `Switch`（带勾号或 Android 绿/蓝样式）替换为原生的 `CupertinoSwitch`（纯圆点无勾号）。
   - 下拉选择框替换为右侧带有 `Chevron` 的 iOS 列表项或弹出 `CupertinoActionSheet`。
4. **悬浮按钮（FAB）**：
   - 移除 Material 的大圆形彩色悬浮按钮（如截图中的加号、刷新按钮）。
   - 将操作移至导航栏右上角，或改为无背景色的右下角小图标，或长条形操作条。
5. **错误/空状态页**：
   - 移除默认的三人插画和蓝色的“点击重试”胶囊按钮。
   - 改为居中的 `CupertinoIcons.exclamationmark_circle` 灰色图标 + 次要文本提示。

---

## 二、 按页面分类改造指引

### 类别 1：表单与设置类页面（Settings & Forms）
**页面特征**：由多个列表项组成，带有开关、输入框或选择项。
**涉及页面**：`/editProfile`, `/createFav`, `/createVote`, `/spaceSetting`, `/playSpeedSet`, `/sponsorBlock`, `/logs`, `/fontSetting`, `/displayModeSetting`。

**改造要点**：
1. 包裹 `CupertinoListSection.insetGrouped`，将表单项放入带圆角的白色卡片中。
2. 开关统一使用 `CupertinoSwitch`（见截图 `/spaceSetting`、`/sponsorBlock`）。
3. 创建投票页面 (`/createVote`)：顶部的“文字投票/图片投票”不要用方框，改为分段控件（Segmented Control）。
4. 字号/倍速设置（截图 `/fontSetting`, `/playSpeedSet`）：滑块使用 `CupertinoSlider`；如果是预设数值（如 0.5, 1.0），改为带边框的小胶囊按钮（Capsule）。
5. 日志页 (`/logs`)：卡片内文本排版需左对齐，增加行间距，复制按钮替换为 `CupertinoIcons.doc_on_doc`。

### 类别 2：长列表/视频流/数据流页面（Lists & Feeds）
**页面特征**：包含视频、动态、文章、用户的垂直列表。
**涉及页面**：`/articleList`, `/blackListPage`, `/fan`, `/fav`, `/followed`, `/sameFollowing`, `/history`, `/later`, `/popularSeries`, `/subscription` 等。

**改造要点**：
1. **列表行（Row）**：左侧使用圆角（8pt）的封面图，右侧标题使用 `.headline` 加粗，辅助信息使用 `.secondary` 字体并调小。不要用过多的分割线，推荐使用背景色区隔。
2. **操作按钮**：长列表中的“已关注/回关”按钮，如果是选中的状态，应改为浅灰色背景，文字变为黑色，不可用高饱和度的蓝色背景。
3. **分页/加载更多**：使用 iOS 原生的下拉刷新 `CupertinoSliverRefreshControl`，并在底部使用转圈加载指示器。
4. **浮动按钮**：如 `/followed`、`/later` 右下角的悬浮操作，移至导航栏右上角（如“播放全部”）。

### 类别 3：搜索结果与详情类页面（Search & Details）
**页面特征**：有复杂的顶部过滤条件，或者复合内容（如视频卡片 + 评论）。
**涉及页面**：`/searchResult`, `/searchTrending`, `/matchInfo`, `/videoV`, `/articlePage`, `/memberDynamics`。

**改造要点**：
1. **搜索顶栏**：移除下拉筛选框（如综合排序、播放多等）的实体边框，改为 iOS 纯文字胶囊滚动条，选中状态使用浅灰色背景或加粗文字。
2. **综合搜索布局**：搜索结果不要做成生硬的块状，使用 `CupertinoListTile` 承载用户/视频条目，确保视觉与原生 App 一致。
3. **热搜榜单 (`/searchTrending`)**：顶部的渐变蓝色大 Banner 移除，替换为纯色标题栏；榜单列表右侧的“新”、“热”标签改为极小的圆角胶囊，降低饱和度。

### 类别 4：全屏弹窗与覆盖层（Overlays）
**页面特征**：作为模态弹出、或者包含 WebView 的页面。
**涉及页面**：`/loginPage`, `/colorSetting`, `/webview`, `/bubble`。

**改造要点**：
1. **登录页 (`/loginPage`)**：完全照搬 App Store 登录页。输入框无边框，使用灰色背景；登录按钮使用 `CupertinoButton.filled`（蓝色大圆角）。
2. **WebView**：顶部需添加 iOS 导航栏样式（毛玻璃），左上角返回按钮需能关闭 WebView，右侧增加刷新/分享图标。
3. **色彩选择器 (`/colorSetting`)**：色块使用圆形并带有一个选中对勾，类似于 iOS 壁纸/时钟的颜色设置界面。

### 类别 5：特定复杂交互页面（Missing Params）
这部分页面因缺少参数在截图中显示为错误页，但代码中尚未适配。请在开发时参考同类已适配页面。
**涉及页面**：`/audio`, `/dynamicDetail`, `/liveRoom`, `/videoWeb`, `/whisperDetail`, `/mainReply`。

**改造要点**：
- 播放器类页面 (`/audio`, `/liveRoom`)：需去除 Material 的悬浮操作栏，改为类 Bilibili iOS 端原生播放器布局。
- 评论详情 (`/mainReply`、`/dynamicDetail`)：评论区需使用 iOS 的 `CupertinoContextMenu`，长按评论弹出原生操作菜单。

---

## 三、 编码与重构建议 (给 Flutter 开发 Agent)

1. **消除蓝色/绿色高亮块**：搜索 `Colors.blue` 或 `Colors.green`，凡是用于背景块或选中状态的，全部替换为 `CupertinoColors.systemGrey5` 或主品牌色。
2. **统一卡片圆角**：创建一个通用的 `iOSCardContainer` Widget，统一设置 `borderRadius: BorderRadius.circular(12)`，外围 `margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8)`。
3. **清理默认边框**：凡是带有 `BoxDecoration(border: ...)` 的地方，如果只是做分割用，一律删除，改用灰色背景层进行区隔。
4. **移除多余的 `SafeArea` 叠加**：确保 `CupertinoPageScaffold` 使用时，内容区域正确对齐。