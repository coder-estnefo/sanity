import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/navigation/navigation_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/notifications/presentation/bloc/notification_inbox_bloc.dart';
import 'features/notifications/presentation/pages/notifications_page.dart';
import 'features/quotes/presentation/bloc/quotes_bloc.dart';
import 'features/tracker/presentation/bloc/tracker_bloc.dart';

class SanityApp extends StatefulWidget {
  const SanityApp({super.key});

  @override
  State<SanityApp> createState() => _SanityAppState();
}

class _SanityAppState extends State<SanityApp> with WidgetsBindingObserver {
  late final TrackerBloc _tracker = sl<TrackerBloc>()..add(const LoadTrackers());
  late final QuotesBloc _quotes = sl<QuotesBloc>()..add(const LoadDailyQuotes());
  late final NotificationBloc _notifications =
      sl<NotificationBloc>()..add(const InitNotifications());
  late final NotificationInboxBloc _inbox =
      sl<NotificationInboxBloc>()..add(const LoadNotificationInbox());

  StreamSubscription<String?>? _clickSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToNotificationClicks();
  }

  void _listenToNotificationClicks() {
    _clickSub = sl<NotificationRepository>().notificationClicks.listen((payload) {
      if (payload != null && mounted) {
        // Automatically navigate to NotificationsPage on notification tap
        sl<NavigationService>().navigateTo(const NotificationsPage());
      }
    });
  }

  /// On resume: refresh day counts, today's quotes, inbox, and the reminder schedule.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tracker.add(const DayTicked());
      _quotes.add(const LoadDailyQuotes());
      _notifications.add(const InitNotifications());
      _inbox.add(const LoadNotificationInbox());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clickSub?.cancel();
    _tracker.close();
    _quotes.close();
    _notifications.close();
    _inbox.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _tracker),
        BlocProvider.value(value: _quotes),
        BlocProvider.value(value: _notifications),
        BlocProvider.value(value: _inbox),
      ],
      child: MaterialApp(
        title: 'Sanity',
        navigatorKey: sl<NavigationService>().navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        home: const HomePage(),
      ),
    );
  }
}
