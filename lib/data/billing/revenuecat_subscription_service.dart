import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import 'subscription_service.dart';

/// RevenueCat-backed [SubscriptionService].
///
/// Configure once at startup with the public SDK key (sandbox or production):
/// `--dart-define=REVENUECAT_API_KEY=...`. The [proEntitlementId] must match the
/// entitlement configured in RevenueCat (and the backend's `PRO_ENTITLEMENT_ID`).
class RevenueCatSubscriptionService implements SubscriptionService {
  RevenueCatSubscriptionService({this.proEntitlementId = 'pro'});

  final String proEntitlementId;

  /// Initialises the SDK. Returns false if no key was supplied.
  static Future<RevenueCatSubscriptionService?> configure({
    required String apiKey,
    String proEntitlementId = 'pro',
  }) async {
    if (apiKey.isEmpty) return null;
    await rc.Purchases.configure(rc.PurchasesConfiguration(apiKey));
    return RevenueCatSubscriptionService(proEntitlementId: proEntitlementId);
  }

  @override
  Future<String?> proPriceLabel() async {
    try {
      final offerings = await rc.Purchases.getOfferings();
      final pkg = _proPackage(offerings);
      return pkg?.storeProduct.priceString;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PurchaseResult> purchasePro({required String appUserId}) async {
    try {
      // Tie purchases to the backend account so the webhook can grant Pro.
      await rc.Purchases.logIn(appUserId);
      final offerings = await rc.Purchases.getOfferings();
      final pkg = _proPackage(offerings);
      if (pkg == null) return PurchaseResult.notConfigured;
      final result = await rc.Purchases.purchase(rc.PurchaseParams.package(pkg));
      return _isActive(result.customerInfo)
          ? PurchaseResult.success
          : PurchaseResult.error;
    } on PlatformException catch (e) {
      final code = rc.PurchasesErrorHelper.getErrorCode(e);
      if (code == rc.PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult.cancelled;
      }
      return PurchaseResult.error;
    } catch (_) {
      return PurchaseResult.error;
    }
  }

  @override
  Future<PurchaseResult> restore() async {
    try {
      final info = await rc.Purchases.restorePurchases();
      return _isActive(info) ? PurchaseResult.success : PurchaseResult.error;
    } catch (_) {
      return PurchaseResult.error;
    }
  }

  @override
  Future<bool> isProActive() async {
    try {
      return _isActive(await rc.Purchases.getCustomerInfo());
    } catch (_) {
      return false;
    }
  }

  bool _isActive(rc.CustomerInfo info) =>
      info.entitlements.active.containsKey(proEntitlementId);

  rc.Package? _proPackage(rc.Offerings offerings) {
    final current = offerings.current;
    if (current == null) return null;
    return current.monthly ??
        current.annual ??
        (current.availablePackages.isEmpty
            ? null
            : current.availablePackages.first);
  }
}
