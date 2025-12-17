import 'package:bloc/bloc.dart';
import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:radiozeit/features/location/location_service.dart';
import 'package:radiozeit/features/location/model/location.dart';
import 'package:radiozeit/features/location/model/city.dart';
import 'package:radiozeit/utils/settings.dart';

class LocationEvents {

}

class LocationEnabledEvent extends LocationEvents {
  LocationEnabledEvent();
}
class LocationLaterEvent extends LocationEvents {
  LocationLaterEvent();
}
class LocationShowEvent extends LocationEvents {
  LocationShowEvent();
}

class LocationErrorEvent extends LocationEvents {
  LocationPermissionStatus status;
  LocationErrorEvent(this.status);
}

class LocationCubit extends Cubit<LocationState> with BlocPresentationMixin<LocationState,LocationEvents> {
  AppSettings settings = AppSettings.getInstance();
  final int MAX_APP_RESTART = 5;
  LocationCubit() : super(LocationState());

  void askLocationLater() {
    settings.isAskLocationLater = true;
    settings.isUserEnableLocation = false;
    settings.restartAppCountBeforeAskLocation = 0;
    emitPresentation(LocationLaterEvent());
  }

  onStartApp() {
    print("onStartApp ${settings.isAskLocationLater && !settings.isUserEnableLocation}");
    if(settings.isAskLocationLater && !settings.isUserEnableLocation) {
      int countRestart = settings.restartAppCountBeforeAskLocation;
      print("onStartApp countRestart $countRestart");
      if(countRestart >= MAX_APP_RESTART) {
        emitPresentation(LocationShowEvent());
      } else {
        settings.restartAppCountBeforeAskLocation = countRestart + 1;
      }
    }
  }

  enableLocation() async {
    emit(LocationState(isLoading: true));

    bool isLocationEnabled = await LocationService.isLocationServiceEnabled();
    if(!isLocationEnabled) {
      emitPresentation(LocationErrorEvent(LocationPermissionStatus.DISABLED));
      emit(LocationState(isLoading: false));
      return;
    }

    bool isForbiddenForever = await LocationService.isForbiddenForever();
    if(isForbiddenForever) {
      emitPresentation(LocationErrorEvent(LocationPermissionStatus.FORBIDDEN_FOREVER));
      emit(LocationState(isLoading: false));
      return;
    }

    settings.isAskLocationLater = false;

    LocationPermissionStatus status = await LocationService.requestLocationPermission();
    emit(LocationState(isLoading: false));
    if(status == LocationPermissionStatus.ALLOW) {
      settings.isUserEnableLocation = true;
      emitPresentation(LocationEnabledEvent());
    } else {
      settings.isUserEnableLocation = false;
      emitPresentation(LocationErrorEvent(status));
    }
  }






}

class LocationState {

  bool isLoading;


  LocationState({
    this.isLoading = false,
  });



}
