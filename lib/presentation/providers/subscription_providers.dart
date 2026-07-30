import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

/// Opens the Pro paywall.
///
/// Goes through `go_router` like everything else. It used to be pushed with a
/// raw `MaterialPageRoute`, which meant the paywall sat outside the router
/// entirely: not deep-linkable, not subject to the redirect gates, and
/// invisible to anything reasoning about the current location.
Future<void> showPaywall(BuildContext context) async {
  await context.push<void>('/paywall');
}

/// Hosts [PaywallScreen] and wires the billing handlers. Public so the router
/// can build it.
class PaywallHost extends ConsumerStatefulWidget {
  const PaywallHost({super.key});

  @override
  ConsumerState<PaywallHost> createState() => _PaywallHostState();
}

class _PaywallHostState extends ConsumerState<PaywallHost> {
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
    if (result == PurchaseResult.success) context.pop();
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
    if (result == PurchaseResult.success) context.pop();
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
