import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/billing/subscription_service.dart';
import '../paywall/paywall_screen.dart';
import 'auth_providers.dart';
import 'entitlement_providers.dart';

/// The active billing implementation. Overridden in `main()` with the RevenueCat
/// implementation once the SDK is initialised; defaults to a safe no-op so the
/// app runs without store credentials.
final subscriptionServiceProvider = Provider<SubscriptionService>(
  (ref) => const UnconfiguredSubscriptionService(),
);

/// Opens the Pro paywall, wiring the RevenueCat purchase/restore handlers.
Future<void> showPaywall(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const _PaywallHost()),
  );
}

class _PaywallHost extends ConsumerStatefulWidget {
  const _PaywallHost();

  @override
  ConsumerState<_PaywallHost> createState() => _PaywallHostState();
}

class _PaywallHostState extends ConsumerState<_PaywallHost> {
  bool _busy = false;
  String? _price;

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  Future<void> _loadPrice() async {
    final price = await ref.read(subscriptionServiceProvider).proPriceLabel();
    if (mounted) setState(() => _price = price);
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  String _messageFor(PurchaseResult r) => switch (r) {
        PurchaseResult.success => 'Welcome to Pro! 🎉',
        PurchaseResult.cancelled => 'Purchase cancelled.',
        PurchaseResult.notConfigured =>
          'Billing isn’t configured in this build yet.',
        PurchaseResult.error => 'Purchase failed. Please try again.',
      };

  Future<void> _subscribe(BuildContext _, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _busy = true);
    final result = await ref
        .read(subscriptionServiceProvider)
        .purchasePro(appUserId: user.email);
    if (result == PurchaseResult.success) {
      ref.read(proStatusProvider.notifier).grantLocally();
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(_messageFor(result));
    if (result == PurchaseResult.success) Navigator.of(context).pop();
  }

  Future<void> _restore(BuildContext _, WidgetRef ref) async {
    setState(() => _busy = true);
    final result = await ref.read(subscriptionServiceProvider).restore();
    if (result == PurchaseResult.success) {
      ref.read(proStatusProvider.notifier).grantLocally();
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(_messageFor(result));
    if (result == PurchaseResult.success) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PaywallScreen(
      busy: _busy,
      priceLabel: _price,
      onSubscribe: _subscribe,
      onRestore: _restore,
    );
  }
}
