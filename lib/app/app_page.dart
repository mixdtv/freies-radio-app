import 'package:flutter/material.dart';
import 'package:radiozeit/app/bottom_navigation/app_menu_bottom.dart';
import 'package:radiozeit/app/drawer/app_drawer.dart';

class AppPage extends StatefulWidget {
  final Widget child;

  const AppPage({super.key, required this.child});

  @override
  _AppPageState createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(),
      bottomNavigationBar: const AppMenuBottom(),
      body: widget.child,
    );
  }

}
