import 'package:flutter/material.dart';
import 'core/di.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const InvProApp());
}
