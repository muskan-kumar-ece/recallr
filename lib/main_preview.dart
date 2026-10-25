import 'package:flutter/material.dart';
import 'app/app_shell.dart';
import 'core/di/recallr_dependencies.dart';
import 'core/routing/app_router.dart';
import 'core/theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final deps = RecallrDependencies.mock();
  RecallrDependencies.setInstance(deps);

  runApp(RecallerPreviewApp(dependencies: deps));
}

class RecallerPreviewApp extends StatelessWidget {
  final RecallrDependencies dependencies;
  const RecallerPreviewApp({super.key, required this.dependencies});

  @override
  Widget build(BuildContext context) {
    return RecallrScope(
      dependencies: dependencies,
      child: MaterialApp(
        title: 'Recallr Preview',
        debugShowCheckedModeBanner: false,
        theme: RecallrTheme.darkTheme,
        darkTheme: RecallrTheme.darkTheme,
        themeMode: ThemeMode.dark,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: const RecallrAppShell(initialIndex: 0),
      ),
    );
  }
}
