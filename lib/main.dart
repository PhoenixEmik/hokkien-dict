import 'package:flutter/material.dart';
import 'package:taigi_dict/app/app_module.dart';
import 'package:taigi_dict/core/core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerBundledFontLicenses();
  runApp(const HokkienDictionaryApp());
}
