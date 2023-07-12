import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sketch_games/adminPanel.dart';
import 'package:sketch_games/appObjects.dart';
import 'package:sketch_games/configuration.dart';
import 'package:sketch_games/loginPage.dart';
import 'package:sketch_games/main.dart';
import 'package:sketch_games/manageTeamPage.dart';
import 'package:sketch_games/nfc_manager_page.dart';

import 'game1Main.dart';

class RouteGenerator{

  static Route<dynamic> gen(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case '/': {
        return MaterialPageRoute(builder: (_) => LoginPage());
      }
      case '/gameOne': {
        if (args is TeamObject) return MyCustomRoute(builder: (context) => Game1MainScreen(team: args));
        return _errorRoute();
      }
      case '/nfc':
        if (FirebaseAuth.instance.currentUser != null) return MaterialPageRoute(builder: (_) => NfcManagerPage());
        return _errorRoute();
      case '/admin':
        if (FirebaseAuth.instance.currentUser != null) return MyCustomRoute(builder: (_) => AdminPanel());
        return _errorRoute();
      case '/manageTeams': if (FirebaseAuth.instance.currentUser != null &&
      args is List<TeamObject>) {
          return MaterialPageRoute(builder: (_) => ManageTeamsPage(teams: args));
        }
        return _errorRoute();
      default: return _errorRoute();
    }

  }

  static Route<dynamic> admin(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case '/': {
        return MaterialPageRoute(builder: (_) => AdminPanel());
      }
      case '/gameOne': {
        if (args is TeamObject) return MyCustomRoute(builder: (context) => Game1MainScreen(team: args));
        return _errorRoute();
      }
      case '/nfc':
        if (FirebaseAuth.instance.currentUser != null) return MaterialPageRoute(builder: (_) => NfcManagerPage());
        return _errorRoute();
      case '/manageTeams': if (FirebaseAuth.instance.currentUser != null &&
          args is List<TeamObject>) {
        return MaterialPageRoute(builder: (_) => ManageTeamsPage(teams: args));
      }
      return _errorRoute();
      default: return _errorRoute();
    }

  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return const Scaffold( // AppBar
        body: Center(
          child: Text('ERROR'),
        ), // Center
      ); // Scaffold
    }); // Material PageRoute
  }
}