import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/features/location/location_cubit.dart';
import 'package:radiozeit/features/location/location_request_page.dart';
import 'package:radiozeit/features/player/player_cubit.dart';
import 'package:radiozeit/features/radio_list/cubit/radio_list_cubit.dart';
import 'package:radiozeit/features/transcript/bloc/transcript_cubit.dart';
import 'package:radiozeit/utils/extensions.dart';
import 'package:radiozeit/utils/settings.dart';

class GlobalCubitConnection extends StatelessWidget {
  final Widget child;
  const GlobalCubitConnection({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return _locationCubit(
        _radioListEvents(child: child)
    );
  }

  _locationCubit(Widget child) {
    return BlocPresentationListener<LocationCubit,LocationEvents>(
        listener: (context, event) {

          if(event is LocationShowEvent) {
            LocationRequestPage.showAsDialog(context);
          }
        },
      child: child,
    );
  }



  _radioListEvents({
    required Widget child
  }) {
    return BlocPresentationListener<RadioListCubit,RadioListEvent>(
      child: child,
      listener: (context, event) {
        if(event is RadioListLoadedEvent) {
          // if(event.radioList.isNotEmpty) {
          //   PlayerCubit playerCubit = context.read<PlayerCubit>();
          //   if(playerCubit.state.selectedRadio == null) {
          //     String lastRadioId = AppSettings.getInstance().getLastRadioId();
          //     AppRadio? autoPlayRadio;
          //     if(lastRadioId.isNotEmpty) {
          //       autoPlayRadio = event.radioList.firstOrNullWhere((item) => item.id == lastRadioId,);
          //     }
          //     autoPlayRadio ??= event.radioList.firstOrNull;
          //     if(autoPlayRadio != null) {
          //       playerCubit.selectRadio(autoPlayRadio);
          //     }
          //   }
          // }

        }
      },);
  }
}
