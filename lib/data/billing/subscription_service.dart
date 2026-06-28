/// Outcome of a purchase/restore attempt.
enum PurchaseResult { success, cancelled, notConfigured, error }

/// Abstraction over the billing provider (RevenueCat). Kept behind an interface
/// so the app compiles and runs without store credentials; the RevenueCat
/// implementation is plugged in via [subscriptionServiceProvider].
abstract class SubscriptionService {
  /// Localised price for the Pro offering, or null if unavailable.
  Future<String?> proPriceLabel();

  /// Launches the purchase flow for Pro (with its free trial).
  Future<PurchaseResult> purchasePro({required String appUserId});

  /// Restores previously purchased entitlements.
  Future<PurchaseResult> restore();

  /// Whether the active entitlements include Pro (client-side check).
  Future<bool> isProActive();
}

/// Default no-op used until RevenueCat is configured with real keys/products.
/// Purchases report [PurchaseResult.notConfigured] so the UI can explain.
class UnconfiguredSubscriptionService implements SubscriptionService {
  const UnconfiguredSubscriptionService();

  @override
  Future<String?> proPriceLabel() async => null;

  @override
  Future<PurchaseResult> purchasePro({required String appUserId}) async =>
      PurchaseResult.notConfigured;

  @override
  Future<PurchaseResult> restore() async => PurchaseResult.notConfigured;

  @override
  Future<bool> isProActive() async => false;
}
