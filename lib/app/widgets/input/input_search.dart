import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:radiozeit/app/style.dart';
import 'package:radiozeit/l10n/app_localizations.dart';

class InputSearch extends StatefulWidget {
  final bool isActive;
  final bool isAutoFocus;
  final Function(String)? onSearch;
  final Function(String)? onEnter;
  final Function()? onTap;
  final Function()? onCancel;
  final String hint;

  const InputSearch({super.key, this.isActive = true, this.isAutoFocus = false, this.onSearch, this.onEnter, this.hint = "",  this.onTap, this.onCancel});

  @override
  State<InputSearch> createState() => _InputSearchState();
}

class _InputSearchState extends State<InputSearch> {
  TextEditingController controller = TextEditingController();
  FocusNode focus = FocusNode();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    if(widget.isAutoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    focus.dispose();
    timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if(widget.isActive) {
      return _buildActive();
    }
    return _buildInactive();
  }

  _buildActive() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focus,
            onChanged: _onSearch,
            onSubmitted: widget.onEnter,
            textInputAction: TextInputAction.search,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14,right: 7),
                child: SvgPicture.asset("assets/icons/ic_search.svg",width: 20,color: Theme.of(context).colorScheme.onBackground,),
              ),
              prefixIconConstraints: BoxConstraints(
                maxWidth: 41,
                maxHeight: 20
              )
            ),

          ),
        ),
        TextButton(onPressed: _clear, child: Text(AppLocalizations.of(context)!.cancel))
      ],
    );
  }

  _buildInactive() {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            children: [
              SvgPicture.asset("assets/icons/ic_search.svg",width: 20,color: Theme.of(context).colorScheme.onBackground,),
              const SizedBox(width: 8,),
              Text(widget.hint,style: Theme.of(context).inputDecorationTheme.hintStyle,)
            ],
          ),
        ),
      ),
    );
  }

  _onSearch(String query) {
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch?.call(query);
    });
  }

  _clear() {
    controller.text = "";
    _onSearch("");
    widget.onCancel?.call();
  }
}
