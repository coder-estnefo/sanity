import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/navigation_service.dart';
import '../storage/key_value_store.dart';
import '../../features/notifications/data/datasources/notification_service.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/usecases/notification_history_usecases.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../../features/notifications/presentation/bloc/notification_inbox_bloc.dart';
import '../../features/quotes/data/datasources/quote_local_ds.dart';
import '../../features/quotes/data/datasources/quote_remote_ds.dart';
import '../../features/quotes/data/repositories/quote_repository_impl.dart';
import '../../features/quotes/domain/repositories/quote_repository.dart';
import '../../features/quotes/domain/usecases/get_daily_quotes.dart';
import '../../features/quotes/presentation/bloc/quotes_bloc.dart';
import '../../features/tracker/data/repositories/tracker_repository_impl.dart';
import '../../features/tracker/domain/repositories/tracker_repository.dart';
import '../../features/tracker/domain/usecases/tracker_usecases.dart';
import '../../features/tracker/presentation/bloc/tracker_bloc.dart';
import '../../features/widgets/data/repositories/home_widget_repository_impl.dart';
import '../../features/widgets/domain/repositories/home_widget_repository.dart';
import '../../features/widgets/domain/usecases/sync_home_widgets.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<KeyValueStore>(PrefsKeyValueStore(prefs));

  sl.registerLazySingleton<NavigationService>(() => NavigationService());

  final notificationService = LocalNotificationService();
  await notificationService.init();
  sl.registerSingleton<NotificationService>(notificationService);

  sl.registerLazySingleton(() => Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      )));

  // Repositories
  sl.registerLazySingleton<TrackerRepository>(() => TrackerRepositoryImpl(sl()));
  sl.registerLazySingleton<QuoteRepository>(() => QuoteRepositoryImpl(
        QuoteRemoteDataSourceImpl(sl()),
        QuoteLocalDataSourceImpl(sl()),
      ));
  sl.registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<HomeWidgetRepository>(
      () => HomeWidgetRepositoryImpl(PluginHomeWidgetGateway()));

  // Use cases
  sl.registerLazySingleton(() => GetAddictions(sl()));
  sl.registerLazySingleton(() => SaveAddiction(sl()));
  sl.registerLazySingleton(() => DeleteAddiction(sl()));
  sl.registerLazySingleton(() => ResetAddiction(sl()));
  sl.registerLazySingleton(() => GetDailyQuotes(sl()));
  sl.registerLazySingleton(() => SyncHomeWidgets(sl()));
  sl.registerLazySingleton(() => GetNotificationHistory(sl()));
  sl.registerLazySingleton(() => DeleteNotificationEntry(sl()));
  sl.registerLazySingleton(() => ClearNotificationHistory(sl()));
  sl.registerLazySingleton(() => RecordNotificationEntry(sl()));
  sl.registerLazySingleton(() => TriggerTestNotificationUseCase(sl()));

  // BLoCs
  sl.registerFactory(() => TrackerBloc(
        getAddictions: sl(),
        saveAddiction: sl(),
        deleteAddiction: sl(),
        resetAddiction: sl(),
        syncHomeWidgets: sl(),
      ));
  sl.registerFactory(() => QuotesBloc(sl()));
  sl.registerFactory(() => NotificationBloc(sl(), getAddictions: sl()));
  sl.registerFactory(() => NotificationInboxBloc(
        getHistory: sl(),
        triggerTest: sl(),
      ));
}
