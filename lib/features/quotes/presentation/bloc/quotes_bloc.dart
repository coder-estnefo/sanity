import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/quote.dart';
import '../../domain/usecases/get_daily_quotes.dart';

sealed class QuotesEvent {
  const QuotesEvent();
}

class LoadDailyQuotes extends QuotesEvent {
  const LoadDailyQuotes();
}

class QuotesState extends Equatable {
  const QuotesState({this.quotes = const [], this.loading = true, this.failed = false});
  final List<Quote> quotes;
  final bool loading;
  final bool failed;

  @override
  List<Object?> get props => [quotes, loading, failed];
}

class QuotesBloc extends Bloc<QuotesEvent, QuotesState> {
  QuotesBloc(this._getDailyQuotes) : super(const QuotesState()) {
    on<LoadDailyQuotes>((event, emit) async {
      emit(const QuotesState());
      try {
        emit(QuotesState(quotes: await _getDailyQuotes(), loading: false));
      } catch (_) {
        emit(const QuotesState(loading: false, failed: true));
      }
    });
  }
  final GetDailyQuotes _getDailyQuotes;
}

