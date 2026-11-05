import 'dart:io' show File;

import 'package:PiliPlus/common/widgets/adaptive/adaptive.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_form.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_list_section.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_list_tile.dart';
import 'package:PiliPlus/common/widgets/adaptive/pl_switch.dart';
import 'package:PiliPlus/common/widgets/dialog/simple_dialog_option.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/view_insets_safe_area.dart';
import 'package:PiliPlus/http/fav.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/msg.dart';
import 'package:PiliPlus/utils/bili_utils.dart';
import 'package:PiliPlus/utils/extension/file_ext.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

class CreateFavPage extends StatefulWidget {
  const CreateFavPage({super.key});

  @override
  State<CreateFavPage> createState() => _CreateFavPageState();
}

class _CreateFavPageState extends State<CreateFavPage> {
  dynamic _mediaId;
  late final TextEditingController _titleController;
  late final TextEditingController _introController;
  String? _cover;
  bool _isPublic = true;
  late final _imagePicker = ImagePicker();
  String? _errMsg;
  int? _attr;
  late ThemeData theme;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _introController = TextEditingController();
    _mediaId = Get.parameters['mediaId'];
    if (_mediaId != null) {
      _getFolderInfo();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  void _getFolderInfo() {
    _errMsg = null;
    FavHttp.favFolderInfo(mediaId: _mediaId).then((res) {
      if (res case Success(:final response)) {
        _titleController.text = response.title;
        _introController.text = response.intro ?? '';
        _isPublic = BiliUtils.isPublicFav(response.attr);
        _cover = response.cover;
        _attr = response.attr;
      } else {
        _errMsg = res.toString();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      appBar: AppBar(
        title: Text(_mediaId != null ? '编辑' : '创建'),
        actions: [
          TextButton(
            onPressed: () {
              if (_titleController.text.isEmpty) {
                SmartDialog.showToast('名称不能为空');
                return;
              }
              FavHttp.addOrEditFolder(
                isAdd: _mediaId == null,
                mediaId: _mediaId,
                title: _titleController.text,
                privacy: _isPublic ? 0 : 1,
                cover: _cover ?? '',
                intro: _introController.text,
              ).then((res) {
                if (res case Success(:final response)) {
                  SmartDialog.showToast('${_mediaId != null ? '编辑' : '创建'}成功');
                  if (mounted) {
                    Get.back(result: response);
                  }
                } else {
                  res.toast();
                }
              });
            },
            child: const Text('完成'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _mediaId != null
          ? _titleController.text.isNotEmpty
                ? _buildBody()
                : _errMsg?.isNotEmpty == true
                ? scrollErrorWidget(errMsg: _errMsg, onReload: _getFolderInfo)
                : m3eLoading
          : _buildBody(),
    );
  }

  Future<void> _pickImg(BuildContext context) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
        requestFullMetadata: false,
      );
      if (pickedFile != null && mounted) {
        String imgPath = pickedFile.path;
        if (PlatformUtils.isMobile) {
          final croppedFile = await ImageCropper.platform.cropImage(
            sourcePath: imgPath,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: '裁剪',
                toolbarColor: theme.colorScheme.secondaryContainer,
                toolbarWidgetColor: theme.colorScheme.onSecondaryContainer,
                statusBarLight: theme.isLight,
                aspectRatioPresets: [CropAspectRatioPreset.ratio16x9],
                lockAspectRatio: true,
                hideBottomControls: true,
                initAspectRatio: CropAspectRatioPreset.ratio16x9,
              ),
              IOSUiSettings(
                title: '裁剪',
                // aspectRatioPresets: [CropAspectRatioPreset.ratio16x9],
                // aspectRatioLockEnabled: false,
                // resetAspectRatioEnabled: false,
                // aspectRatioPickerButtonHidden: true,
              ),
            ],
          );
          if (croppedFile != null) {
            File(imgPath).tryDel();
            imgPath = croppedFile.path;
          }
        }
        MsgHttp.uploadImage(
          path: imgPath,
          bucket: 'medialist',
          dir: 'cover',
        ).then((res) {
          if (context.mounted) {
            if (res case Success(:final response)) {
              _cover = response['location'];
              (context as Element).markNeedsBuild();
            } else {
              res.toast();
            }
          }
          if (PlatformUtils.isMobile) {
            File(imgPath).tryDel();
          }
        });
      }
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }

  final leadingStyle = const TextStyle(fontSize: 14);

  void _onEditCover(BuildContext context) {
    if (_cover?.isNotEmpty == true) {
      showDialog(
        context: context,
        builder: (_) => SimpleDialog(
          clipBehavior: Clip.hardEdge,
          contentPadding: const .symmetric(vertical: 12),
          children: [
            DialogOption(
              onPressed: () {
                Get.back();
                _pickImg(context);
              },
              child: const Text(
                '替换封面',
                style: TextStyle(fontSize: 14),
              ),
            ),
            DialogOption(
              onPressed: () {
                Get.back();
                _cover = null;
                (context as Element).markNeedsBuild();
              },
              child: const Text(
                '移除封面',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    } else {
      _pickImg(context);
    }
  }

  Widget _buildBody() {
    final rows = <Widget>[
      if (_attr == null || !BiliUtils.isDefaultFav(_attr!)) _coverRow(),
      _nameRow(),
      if (_attr == null || !BiliUtils.isDefaultFav(_attr!)) _introRow(),
    ];
    final publicRow = _publicRow();
    if (Adaptive.isIOS(context)) {
      return ViewInsetsSafeArea(
        child: ListView(
          padding: EdgeInsets.only(
            top: 8,
            bottom: MediaQuery.viewPaddingOf(context).bottom + 25,
          ),
          children: [
            PLListSection(children: rows),
            // 组与组之间要有留白：PLListSection 的 margin 只给左右 16，
            // 上下为 0，直接相邻会让「公开」卡片的圆角顶在前一张卡片底边上，
            // 形成左右两个内凹缺口。
            const SizedBox(height: 10),
            PLListSection(children: [publicRow]),
          ],
        ),
      );
    }
    return ViewInsetsSafeArea(
      child: SingleChildScrollView(
        padding: .only(
          bottom: MediaQuery.viewPaddingOf(context).bottom + 25,
        ),
        child: Column(
          spacing: 12,
          children: [...rows, publicRow],
        ),
      ),
    );
  }

  Widget _coverRow() {
    final coverTrailing = Row(
      spacing: 10,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_cover?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: NetworkImgLayer(
              src: _cover,
              height: 55,
              width: 88,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
          ),
        Icon(
          Icons.keyboard_arrow_right,
          color: theme.colorScheme.outline,
        ),
      ],
    );

    return PLListTile(
      visualDensity: .standard,
      tileColor: theme.colorScheme.onInverseSurface,
      onTap: () {
        EasyThrottle.throttle(
          'imagePicker',
          const Duration(milliseconds: 500),
          () => _onEditCover(context),
        );
      },
      // Material 下标签留在 leading 槽位（改动前的布局）；
      // iOS 的 PLListTile 会把 leading 变成彩色图标，因此标签随内容进 title。
      leading: Adaptive.isIOS(context) ? null : Text('封面', style: leadingStyle),
      title: Adaptive.isIOS(context)
          ? Row(
              spacing: 10,
              children: [
                Text('封面', style: leadingStyle),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: coverTrailing,
                  ),
                ),
              ],
            )
          : null,
      trailing: Adaptive.isIOS(context) ? null : coverTrailing,
    );
  }

  Widget _nameRow() => PLListTile(
    tileColor: theme.colorScheme.onInverseSurface,
    title: Row(
      children: [
        SizedBox(
          width: 55,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '*',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.error,
                  ),
                ),
                const TextSpan(
                  text: '名称',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TextField(
            autofocus: true,
            readOnly: _attr != null && BiliUtils.isDefaultFav(_attr!),
            controller: _titleController,
            style: TextStyle(
              fontSize: 14,
              color: _attr != null && BiliUtils.isDefaultFav(_attr!)
                  ? theme.colorScheme.outline
                  : null,
            ),
            inputFormatters: [LengthLimitingTextInputFormatter(20)],
            decoration: Adaptive.isIOS(context)
                ? plInputDecoration(context, hintText: '名称')
                : InputDecoration(
                    isDense: true,
                    hintText: '名称',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.outline,
                    ),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      gapPadding: 0,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
          ),
        ),
      ],
    ),
  );

  Widget _introRow() => PLListTile(
    tileColor: theme.colorScheme.onInverseSurface,
    title: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 55,
          child: Text(
            '简介',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            minLines: 6,
            maxLines: 6,
            controller: _introController,
            style: const TextStyle(fontSize: 14),
            inputFormatters: [LengthLimitingTextInputFormatter(200)],
            decoration: Adaptive.isIOS(context)
                ? plInputDecoration(context, hintText: '可填写简介')
                : InputDecoration(
                    isDense: true,
                    hintText: '可填写简介',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.outline,
                    ),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide.none,
                      gapPadding: 0,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
          ),
        ),
      ],
    ),
  );

  Widget _publicRow() => PLListTile(
    tileColor: theme.colorScheme.onInverseSurface,
    // Material 下「公开」留在 leading 槽位（改动前的布局）；iOS 进 title。
    leading: Adaptive.isIOS(context) ? null : Text('公开', style: leadingStyle),
    title: Adaptive.isIOS(context) ? Text('公开', style: leadingStyle) : null,
    onTap: () => setState(() => _isPublic = !_isPublic),
    trailing: PLSwitch(
      value: _isPublic,
      onChanged: (value) => setState(() => _isPublic = value),
      materialScale: 0.8,
    ),
  );
}
