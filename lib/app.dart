import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/services/platform_service.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/pages/onboarding_screen.dart';

class UnscrollApp extends StatelessWidget {
  final bool showOnboarding; // 👈 Added field

  const UnscrollApp({
    super.key,
    required this.showOnboarding, // 👈 Added required parameter
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => HomeBloc(
            platformService: PlatformService.instance,
          )..add(LoadHomeData()),
        ),
      ],
      child: MaterialApp(
        title: 'Unscroll',
        debugShowCheckedModeBanner: false,
        
        // Performance: Disable debug grid overlay
        debugShowMaterialGrid: false,
        
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        
        // Optimized scrolling behavior
        scrollBehavior: const _OptimizedScrollBehavior(),
        
        // Performance: Disable text scaling for consistent UI
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        
        // 👈 Logic to decide start screen
        home: showOnboarding ? const OnboardingPage() : const HomePage(),
      ),
    );
  }
}

// Custom ScrollBehavior to remove Android glow effect (improves performance)
class _OptimizedScrollBehavior extends ScrollBehavior {
  const _OptimizedScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      decelerationRate: ScrollDecelerationRate.fast,
    );
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}