import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/adaptive/ios_colors.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/font_utils.dart';
import 'package:PiliPlus/utils/ios_style.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoPageTransitionsBuilder, CupertinoThemeData;
import 'package:flutter/foundation.dart' show PlatformDispatcher;
import 'package:material_ui/material_ui.dart';

abstract final class ThemeUtils {
  static late ThemeData lightTheme;

  static late ThemeData darkTheme;

  static late ThemeMode themeMode;

  static ThemeData get theme {
    if (themeMode == .dark ||
        (themeMode == .system &&
            PlatformDispatcher.instance.platformBrightness == .dark)) {
      return darkTheme;
    }
    return lightTheme;
  }

  static bool get isDarkMode => theme.isDark;

  static String themeUrl(bool isDark) =>
      'native.theme=${isDark ? 2 : 1}&night=${isDark ? 1 : 0}';

  static ThemeData getThemeData({
    required ColorScheme colorScheme,
    required bool isDynamic,
    bool isDark = false,
  }) {
    final fontWeight = Pref.appFontWeight;
    final fontFamily = FontUtils.fontFamily;

    TextTheme? textTheme;
    if (fontWeight != .normal) {
      final textStyle = TextStyle(fontWeight: fontWeight);
      textTheme = TextTheme(
        displayLarge: textStyle,
        displayMedium: textStyle,
        displaySmall: textStyle,
        headlineLarge: textStyle,
        headlineMedium: textStyle,
        headlineSmall: textStyle,
        titleLarge: textStyle,
        titleMedium: textStyle,
        titleSmall: textStyle,
        bodyLarge: textStyle,
        bodyMedium: textStyle,
        bodySmall: textStyle,
        labelLarge: textStyle,
        labelMedium: textStyle,
        labelSmall: textStyle,
      );
    }

    final isIOS = IosStyle.isIOSStyleEnabled;
    // iOS 语义色：需求要求页面底色用 systemGroupedBackground，
    // 内容卡片用 systemBackground（纯白），两者不能被 Material 的粉色 surface 顶替。
    final groupedBg = isIOS
        ? IosColors.groupedBackground(isDark ? .dark : .light)
        : colorScheme.surface;
    final cardBg = isIOS
        ? IosColors.secondaryGroupedBackground(isDark ? .dark : .light)
        : colorScheme.surface;

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      textTheme: textTheme,
      // 「iOS 风格」开关的核心接入点。
      // 设为 TargetPlatform.iOS 后，Flutter 内建的平台自适应行为会自动切换：
      // AppBar 标题居中规则、Scrollbar 形态、PageTransitionsTheme 的转场、
      // 以及各类 Cupertino 文本选择工具条。
      platform: IosStyle.targetPlatform,
      // 页面底色：iOS 风格用 systemGroupedBackground（浅灰），
      // 非 iOS 风格保持原来的 surface。
      scaffoldBackgroundColor: groupedBg,
      appBarTheme: AppBarTheme(
        elevation: 0,
        // iOS 导航栏标题始终居中（真 iOS 行为），与 actions 数量无关。
        // 不能留 centerTitle: null —— AppBar 的 platformCenter() 在 iOS 上
        // 是「actions < 2 才居中」，≥2 个 action 的页面会退回左对齐，
        // 叠加 titleSpacing: 0 后标题贴死屏幕左缘、首字被裁。
        // titleSpacing 保留 16，居中标题在 actions 过宽时不会被挤到贴边。
        titleSpacing: isIOS ? 16 : 0,
        centerTitle: isIOS ? true : false,
        scrolledUnderElevation: 0,
        backgroundColor: groupedBg,
        // iOS 导航栏底部有一条 hairline 分割线。
        // 放在 theme 层，98 个 AppBar 调用点无需任何改动即可生效。
        shape: isIOS
            ? Border(
                bottom: BorderSide(
                  color: IosColors.separator(isDark ? .dark : .light),
                  width: 0.5,
                ),
              )
            : null,
        titleTextStyle: TextStyle(
          fontSize: isIOS ? 17 : 16,
          fontWeight: isIOS ? FontWeight.w600 : fontWeight,
          fontFamily: fontFamily,
          color: colorScheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        surfaceTintColor: isDark ? colorScheme.surfaceContainerHighest : null,
      ),
      snackBarTheme: SnackBarThemeData(
        elevation: 20,
        actionTextColor: colorScheme.primary,
        closeIconColor: colorScheme.secondary,
        backgroundColor: colorScheme.secondaryContainer,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontWeight: fontWeight,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        surfaceTintColor: isDark ? colorScheme.surfaceContainerHighest : null,
      ),
      cardTheme: CardThemeData(
        elevation: isIOS ? 0 : 1,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        // iOS 的内容卡片是纯白（systemBackground），与浅灰页面底色形成层级。
        color: cardBg,
        surfaceTintColor: isDark ? colorScheme.onSurfaceVariant : null,
      ),
      dividerTheme: DividerThemeData(
        color: IosColors.separator(isDark ? .dark : .light),
        thickness: 0.5,
        space: 0.5,
      ),
      progressIndicatorTheme: isDark
          ? ProgressIndicatorThemeData(
              // ignore: deprecated_member_use
              year2023: false,
              refreshBackgroundColor: colorScheme.onInverseSurface,
            )
          // ignore: deprecated_member_use
          : const ProgressIndicatorThemeData(year2023: false),
      dialogTheme: DialogThemeData(
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: fontWeight,
          fontFamily: fontFamily,
          color: colorScheme.onSurface,
        ),
        backgroundColor: colorScheme.surface,
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 420),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        // iOS 的 sheet 浮在内容之上，用二级分组背景（比页面底色略深一层）。
        backgroundColor: isIOS
            ? IosColors.secondaryGroupedBackground(isDark ? .dark : .light)
            : colorScheme.surface,
        // iOS 18 的 sheet 顶部圆角是 12，且带一条拖拽把手。
        shape: isIOS
            ? const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              )
            : const RoundedRectangleBorder(
                borderRadius: Style.bottomSheetRadius,
              ),
        showDragHandle: isIOS,
        elevation: isIOS ? 0 : null,
        surfaceTintColor: isIOS ? Colors.transparent : null,
      ),
      // ignore: deprecated_member_use
      sliderTheme: const SliderThemeData(year2023: false),
      tooltipTheme: TooltipThemeData(
        textStyle: TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontFamily: fontFamily,
          fontWeight: fontWeight,
        ),
        decoration: const BoxDecoration(
          color: Color(0xE6616161), // Colors.grey[700]!.withValues(alpha: 0.9)
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        selectionHandleColor: colorScheme.primary,
      ),
      switchTheme: const SwitchThemeData(
        padding: .zero,
        materialTapTargetSize: .shrinkWrap,
        thumbIcon: WidgetStateProperty<Icon?>.fromMap(
          <WidgetStatesConstraint, Icon?>{
            WidgetState.selected: Icon(Icons.done),
            WidgetState.any: null,
          },
        ),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        shape: Border(),
        collapsedShape: Border(),
      ),
      listTileTheme: const ListTileThemeData(controlAffinity: .leading),
      filledButtonTheme: const FilledButtonThemeData(
        style: ButtonStyle(
          shadowColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      // 页面转场：iOS 风格下用 Cupertino 的横向滑动，
      // 其余平台维持原有的 Android 缩放转场。
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
    if (isDark && Pref.isPureBlackTheme) {
      return darkenTheme(theme);
    }
    return theme;
  }

  static ThemeData darkenTheme(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final color = colorScheme.surfaceContainerHighest.darken(0.7);
    return theme.copyWith(
      canvasColor: Colors.black,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: Colors.black,
      ),
      cardTheme: theme.cardTheme.copyWith(
        color: colorScheme.surfaceContainer.darken(0.75),
      ),
      dialogTheme: theme.dialogTheme.copyWith(backgroundColor: color),
      bottomSheetTheme: theme.bottomSheetTheme.copyWith(
        backgroundColor: color,
      ),
      bottomNavigationBarTheme: theme.bottomNavigationBarTheme.copyWith(
        backgroundColor: color,
      ),
      navigationBarTheme: theme.navigationBarTheme.copyWith(
        backgroundColor: color,
      ),
      navigationRailTheme: theme.navigationRailTheme.copyWith(
        backgroundColor: Colors.black,
      ),
      popupMenuTheme: theme.popupMenuTheme.copyWith(color: color),
      colorScheme: colorScheme.copyWith(
        primary: colorScheme.primary.darken(0.1),
        onPrimary: colorScheme.onPrimary.darken(0.1),
        primaryContainer: colorScheme.primaryContainer.darken(0.1),
        onPrimaryContainer: colorScheme.onPrimaryContainer.darken(0.1),
        inversePrimary: colorScheme.inversePrimary.darken(0.1),
        secondary: colorScheme.secondary.darken(0.05),
        onSecondary: colorScheme.onSecondary.darken(0.05),
        secondaryContainer: colorScheme.secondaryContainer.darken(0.05),
        onSecondaryContainer: colorScheme.onSecondaryContainer.darken(0.05),
        error: colorScheme.error.darken(0.05),
        surface: Colors.black,
        onSurface: colorScheme.onSurface.darken(0.15),
        surfaceTint: colorScheme.surfaceTint.darken(),
        inverseSurface: colorScheme.inverseSurface.darken(),
        onInverseSurface: colorScheme.onInverseSurface.darken(),
        surfaceContainer: colorScheme.surfaceContainer.darken(),
        surfaceContainerHigh: colorScheme.surfaceContainerHigh.darken(),
        surfaceContainerHighest: colorScheme.surfaceContainerHighest.darken(
          0.4,
        ),
      ),
    );
  }
}
