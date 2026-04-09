import 'package:flutter/widgets.dart';

String tr(BuildContext context, {required String es, required String en}) {
  return Localizations.localeOf(context).languageCode == 'en' ? en : es;
}
