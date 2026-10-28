import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notifications/data/datasources/notification_service.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';
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
import '../storage/key_value_store.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<KeyValueStore>(PrefsKeyValueStore(prefs));

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

  // Use cases
  sl.registerLazySingleton(() => GetAddictions(sl()));
  sl.registerLazySingleton(() => SaveAddiction(sl()));
  sl.registerLazySingleton(() => DeleteAddiction(sl()));
  sl.registerLazySingleton(() => ResetAddiction(sl()));
  sl.registerLazySingleton(() => GetDailyQuotes(sl()));

  // BLoCs
  sl.registerFactory(() => TrackerBloc(
        getAddictions: sl(),
        saveAddiction: sl(),
        deleteAddiction: sl(),
        resetAddiction: sl(),
      ));
  sl.registerFactory(() => QuotesBloc(sl()));
  sl.registerFactory(() => NotificationBloc(sl()));
}

