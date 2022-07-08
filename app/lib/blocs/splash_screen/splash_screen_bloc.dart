// ignore_for_file: override_on_non_overriding_member

import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'splash_screen_event.dart';
part 'splash_screen_state.dart';

class SplashScreenBloc extends Bloc<SplashScreenEvent, SplashScreenState> {
  SplashScreenBloc() : super(Initial()) {
    on<NavigateToHomeScreenEvent>(_delayScreen);
  }
  void _delayScreen(
    NavigateToHomeScreenEvent event,
    Emitter<SplashScreenState> emit,
  ) async {
    stdout.writeln('splash loading');
    emit(Loading());
    stdout.writeln('splash delayed');
    await Future.delayed(
      const Duration(seconds: 4),
    );
    stdout.writeln('splash loaded');
    emit(Loaded());
  }
}
