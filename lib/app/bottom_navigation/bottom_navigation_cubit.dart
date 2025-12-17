
import 'package:bloc/bloc.dart';
import 'package:radiozeit/app/bottom_navigation/menu_config.dart';


class BottomNavigationState {
  bool isActive;
  int page;
  BottomNavigationState({
    required this.page,
    required this.isActive,
});

  BottomNavigationState.init({
    int? page,
    this.isActive = false,
  }) : page = page ?? MenuConfig.getDefaultPageIndex();
}

class BottomNavigationCubit extends Cubit<BottomNavigationState> {

  BottomNavigationCubit() : super(BottomNavigationState.init());

  openMenu(bool flag) {
    emit(BottomNavigationState(page: flag ? state.page : MenuConfig.getDefaultPageIndex(),isActive: flag));
  }

  toPage(int page) {
    emit(BottomNavigationState(page: page,isActive: state.isActive));
  }
}
