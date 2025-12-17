import 'package:flutter/material.dart';
import 'package:radiozeit/l10n/app_localizations.dart';
import 'package:radiozeit/utils/error_mapper.dart';

class ErrorLoad extends StatelessWidget {
  final String error;
  final Function() load;

  const ErrorLoad({super.key, required this.error, required this.load});


  @override
  Widget build(BuildContext context) {
    final localizedError = ErrorMapper.getLocalizedError(context, error);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text(localizedError,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily:"inter",fontSize: 14,color: Colors.red)),
          const SizedBox(height: 10,),
          SizedBox(
            width: 120,
            child: FilledButton(
                child: Text(AppLocalizations.of(context)?.reload ?? "Reload"),
                onPressed: load),
          )
        ],
      ),
    );
  }
}
