import 'dart:async';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class SubscriptionService {
  SubscriptionService._internal();
  static final SubscriptionService instance = SubscriptionService._internal();

  final String entitlementId = 'premium';
  final StreamController<bool> _entitlementController =
      StreamController<bool>.broadcast();

  Stream<bool> get entitlementStream => _entitlementController.stream;

  Future<bool> isEntitled() async {
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey(entitlementId);
  }

  Future<void> presentPaywallIfNeeded() async {
    await RevenueCatUI.presentPaywallIfNeeded(entitlementId);
    await _emitLatest();
  }

  Future<void> restorePurchases() async {
    await Purchases.restorePurchases();
    await _emitLatest();
  }

  Future<void> logIn(String appUserId) async {
    try {
      await Purchases.logIn(appUserId);
      await _emitLatest();
    } catch (_) {
      // ignore and rely on entitlement stream remaining unchanged
    }
  }

  Future<void> logOut() async {
    try {
      await Purchases.logOut();
      await _emitLatest();
    } catch (_) {
      // ignore errors during logout
    }
  }

  Future<void> initListeners() async {
    await _emitLatest();
    Purchases.addCustomerInfoUpdateListener((_) async {
      await _emitLatest();
    });
  }

  Future<void> _emitLatest() async {
    try {
      final entitled = await isEntitled();
      _entitlementController.add(entitled);
    } catch (_) {
      _entitlementController.add(false);
    }
  }

  void dispose() {
    _entitlementController.close();
  }
}
