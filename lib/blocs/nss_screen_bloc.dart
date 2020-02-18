import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:gigya_native_screensets_engine/services/nss_api_service.dart';
import 'package:gigya_native_screensets_engine/models/api.dart';
import 'package:gigya_native_screensets_engine/utils/debug.dart';
import 'package:gigya_native_screensets_engine/nss_registry.dart';
import 'package:gigya_native_screensets_engine/utils/logging.dart';

enum NssScreenState { idle, progress, error }

class NssScreenViewModel with ChangeNotifier {
  final String id;

  final ApiService apiBloc = ApiService();

  NssScreenState _state = NssScreenState.idle;

  String _errorText;

  String get error => _errorText;

  final StreamController _screenEvents = StreamController<ScreenEvent>();

  Sink get streamEventSink => _screenEvents.sink;

  NssScreenViewModel(this.id) {
    _registerScreenActionsStream();
  }

  //region State management

  isIdle() => _state == NssScreenState.idle;

  isProgress() => _state == NssScreenState.progress;

  isError() => _state == NssScreenState.error;

  setIdle() {
    nssLogger.d('Screen with id: $id setIdle');
    _state = NssScreenState.idle;
    _errorText = null;
    notifyListeners();
  }

  setProgress() {
    nssLogger.d('Screen with id: $id setProgress');
    _state = NssScreenState.progress;
    _errorText = null;
    notifyListeners();
  }

  /// State management
  setError(String error) {
    nssLogger.d('Screen with id: $id setError with $error');
    _state = NssScreenState.error;
    _errorText = error;
    notifyListeners();
  }

  //endregion

  /// Start listening for [ScreenEvent] action [ScreenAction] events.
  /// Events are propagated bottom up and are available for all child components.
  _registerScreenActionsStream() {
    _screenEvents.stream.listen((event) {
      nssLogger.d('Event received with data: ${event.data.toString()}');

      sendApi(event.data['api'], event.data['params']);
    });
  }

  /// Send requested API request given a String [method] and base [parameters] map.
  /// [parameter] map is not signed.
  sendApi(String method, Map<String, dynamic> parameters) {
    setProgress();

    apiBloc.send(method, parameters).then((result) {
      if (result.isSuccess()) {
        setIdle();

        nssLogger.d('Api request success: ${result.data.toString()}');
      } else {
        setError(result.errorMessage);

        nssLogger.d('Api request error: ${result.errorMessage}');
      }
    }).catchError((error) {
      setError(error.errorMessage);
    });
  }

  @override
  void dispose() {
    // Close screen event stream to avoid leaks.
    _screenEvents.close();
    super.dispose();
  }
}

enum ScreenAction { submit, refresh }

class ScreenEvent {
  final ScreenAction action;
  final Map<String, dynamic> data;

  ScreenEvent(this.action, this.data);
}
