import 'package:flutter/foundation.dart';

/// Notifies listeners when a new print is logged (main grid + transactions).
class PrintHistoryRefreshNotifier extends ChangeNotifier {
  void notifyPrintLogged() => notifyListeners();
}
