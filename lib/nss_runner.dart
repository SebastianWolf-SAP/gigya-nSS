import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gigya_native_screensets_engine/components/nss_errors.dart';
import 'package:gigya_native_screensets_engine/components/nss_screen.dart';
import 'package:gigya_native_screensets_engine/models/screen.dart';
import 'package:gigya_native_screensets_engine/models/widget.dart';
import 'package:gigya_native_screensets_engine/nss_factory.dart';

import './utils/extensions.dart';

enum NssAlignment { vertical, horizontal }

class NssScreenBuilder {
  final String _screenId;

  NssScreenBuilder(this._screenId);

  /// Main rendering action providing screen map & requested screen id.
  Widget build(Map<String, Screen> screenMap) {
    // Modeled markup must contain the screen unique id.
    if (screenMap.unavailable(_screenId)) {
      return NssRenderingErrorWidget.routeMissMatch();
    }

    // Modeled screen must contain the children tag.
    if (screenMap[_screenId].children.isNullOrEmpty()) {
      return NssRenderingErrorWidget.screenWithNotChildren();
    }

    return _buildScreen(
      screenMap[_screenId], // Screen instance.
      _buildWidgets(screenMap[_screenId].children), // List<Widget> children.
    );
  }

  /// Layout the screen widget.
  /// Create the root [NssScreenWidget] screen instance.
  Widget _buildScreen(Screen screen, List<Widget> list) {
    return NssScreenWidget(
      screen: screen,
      layoutScreen: () => _groupBy(screen.align, list), // Form layout must begin with a view group.
    );
  }

  /// Dynamically create component widget or components view group according to children parameter
  /// of the [NssWidgetData] provided.
  List<Widget> _buildWidgets(List<NssWidgetData> children) {
    if (children.isEmpty) {
      return [];
    }

    List<Widget> widgets = [];
    children.forEach((widget) {
      if (widget.hasChildren()) {
        // View group required.
        widgets.add(
          _groupBy(widget.stack, _buildWidgets(widget.children)),
        );
      } else {
        widgets.add(
          NssWidgetFactory().create(widget.type, widget),
        );
      }
    });
    return widgets;
  }

  /// Group given widget [list] according to required view group [NssAlignment] alignment property.
  /// Currently supports [Column] for vertical alignment and [Row] for horizontal alignment.
  //TODO: Row & Column widgets are highly customizable. Don't forget.
  Widget _groupBy(NssAlignment alignment, List<Widget> list) {
    switch (alignment) {
      case NssAlignment.vertical:
        return Column(children: list);
      case NssAlignment.horizontal:
        return Row(children: list);
      default:
        return Column(children: list);
    }
  }
}
