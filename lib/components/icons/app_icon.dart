import 'package:flutter/material.dart';

import 'package:moneyfy/design_system/spec.dart';

enum AppIconName {
  sort,
  add,
  edit,
  visibilityOn,
  visibilityOff,
  chevronRight,
  chevronLeft,
  chevronUp,
  refresh,
  sync,
  logout,
  close,
  info,
  expandMore,
  expandLess,
  delete,
  more,
  calendar,
  person,
  settings,
  wallet,
  insights,
  lightbulb,
  error,
  inbox,
  check,
  checkCircle,
  circle,
  dragHandle,
  cloudUpload,
  pieChart,
  newspaper,
  trendingUp,
  trendingDown,
  accountBalance,
  currencyExchange,
  bitcoin,
  showChart,
}

class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, this.size, this.color})
    : iconData = null;

  const AppIcon.raw(this.iconData, {super.key, this.size, this.color})
    : name = null;

  final AppIconName? name;
  final IconData? iconData;
  final double? size;
  final Color? color;

  static IconData resolve(AppIconName name) {
    return switch (name) {
      AppIconName.sort => VisualSpec.icon.sort,
      AppIconName.add => VisualSpec.icon.add,
      AppIconName.edit => VisualSpec.icon.edit,
      AppIconName.visibilityOn => VisualSpec.icon.visibilityOn,
      AppIconName.visibilityOff => VisualSpec.icon.visibilityOff,
      AppIconName.chevronRight => VisualSpec.icon.chevronRight,
      AppIconName.chevronLeft => VisualSpec.icon.chevronLeft,
      AppIconName.chevronUp => VisualSpec.icon.chevronUp,
      AppIconName.refresh => VisualSpec.icon.refresh,
      AppIconName.sync => VisualSpec.icon.sync,
      AppIconName.logout => VisualSpec.icon.logout,
      AppIconName.close => VisualSpec.icon.close,
      AppIconName.info => VisualSpec.icon.info,
      AppIconName.expandMore => VisualSpec.icon.expandMore,
      AppIconName.expandLess => VisualSpec.icon.expandLess,
      AppIconName.delete => VisualSpec.icon.delete,
      AppIconName.more => VisualSpec.icon.more,
      AppIconName.calendar => VisualSpec.icon.calendar,
      AppIconName.person => VisualSpec.icon.person,
      AppIconName.settings => VisualSpec.icon.settings,
      AppIconName.wallet => VisualSpec.icon.wallet,
      AppIconName.insights => VisualSpec.icon.insights,
      AppIconName.lightbulb => VisualSpec.icon.lightbulb,
      AppIconName.error => VisualSpec.icon.error,
      AppIconName.inbox => VisualSpec.icon.inbox,
      AppIconName.check => VisualSpec.icon.check,
      AppIconName.checkCircle => VisualSpec.icon.checkCircle,
      AppIconName.circle => VisualSpec.icon.circle,
      AppIconName.dragHandle => VisualSpec.icon.dragHandle,
      AppIconName.cloudUpload => VisualSpec.icon.cloudUpload,
      AppIconName.pieChart => VisualSpec.icon.pieChart,
      AppIconName.newspaper => VisualSpec.icon.newspaper,
      AppIconName.trendingUp => VisualSpec.icon.trendingUp,
      AppIconName.trendingDown => VisualSpec.icon.trendingDown,
      AppIconName.accountBalance => VisualSpec.icon.accountBalance,
      AppIconName.currencyExchange => VisualSpec.icon.currencyExchange,
      AppIconName.bitcoin => VisualSpec.icon.bitcoin,
      AppIconName.showChart => VisualSpec.icon.showChart,
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolved = iconData ?? resolve(name!);
    return Icon(
      resolved,
      size: size ?? VisualSpec.icon.sizeDefault,
      color: color,
    );
  }
}
