import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/courier_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_views.dart';
import 'active_delivery_banner.dart';
import 'request_card.dart';
import 'request_detail_screen.dart';
import 'request_filters.dart';
import 'request_sort_bar.dart';
import 'tab_header.dart';

/// K-03: list of open delivery requests from the [CourierService].
/// K-06: while the courier has an active delivery, shows a banner and
/// locks accepting on the detail screen.
/// K-10: sort by oldest, highest pay or closest, and filter to tipped ones.
/// K-11: pull to refresh, a refresh button, and auto-refresh while shown.
class AvailableTab extends StatefulWidget {
  const AvailableTab({
    super.key,
    required this.service,
    required this.courierId,
    this.onViewActiveDelivery,
    this.isVisible = true,
    this.refreshEvery = const Duration(seconds: 15),
    this.isOnline = true,
    this.onGoOnline,
    this.onCountChanged,
  });

  final CourierService service;
  final String courierId;

  /// Switches to the My Deliveries tab.
  final VoidCallback? onViewActiveDelivery;

  /// Reloads each time the tab is shown again, so the list and banner
  /// reflect anything that changed on the other tabs.
  final bool isVisible;

  /// How often to quietly reload while the tab is visible; null turns
  /// auto-refresh off.
  final Duration? refreshEvery;

  /// K-18: while offline no requests are shown or fetched.
  final bool isOnline;
  final VoidCallback? onGoOnline;

  /// K-29: called with the number of open requests after each load.
  final ValueChanged<int>? onCountChanged;

  @override
  State<AvailableTab> createState() => _AvailableTabState();
}

typedef _TabData = ({List<Order> requests, Order? active});

class _AvailableTabState extends State<AvailableTab> {
  late Future<_TabData> _data;
  RequestSort _sort = RequestSort.oldest;
  bool _tipsOnly = false;
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    _data = _load();
    _syncAutoRefresh();
  }

  @override
  void didUpdateWidget(AvailableTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cameBack =
        (widget.isVisible && !oldWidget.isVisible) ||
        (widget.isOnline && !oldWidget.isOnline);
    if (cameBack) _data = _load();
    _syncAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  /// Runs the auto-refresh timer only while this tab is on screen.
  void _syncAutoRefresh() {
    final every = widget.refreshEvery;
    final shouldRun = widget.isVisible && widget.isOnline && every != null;
    if (shouldRun && _autoRefresh == null) {
      _autoRefresh = Timer.periodic(every, (_) => _refresh());
    } else if (!shouldRun) {
      _autoRefresh?.cancel();
      _autoRefresh = null;
    }
  }

  /// Reloads without hiding the current list, for pull-to-refresh, the
  /// refresh button and the timer.
  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _data = next;
    });
    try {
      await next;
    } catch (_) {
      // The FutureBuilder shows the error; nothing else to do here.
    }
  }

  Future<_TabData> _load() async {
    final (requests, active) = await (
      widget.service.fetchAvailableRequests(),
      widget.service.fetchActiveDelivery(widget.courierId),
    ).wait;
    if (mounted) widget.onCountChanged?.call(requests.length);
    return (requests: requests, active: active);
  }

  void _reload() {
    setState(() {
      _data = _load();
    });
  }

  Future<void> _openDetails(Order order, {required bool locked}) async {
    final accepted = await Navigator.of(context).push<Order>(
      MaterialPageRoute(
        builder: (_) => RequestDetailScreen(
          order: order,
          service: widget.service,
          courierId: widget.courierId,
          hasActiveDelivery: locked,
        ),
      ),
    );
    if (!mounted) return;

    // Reload either way: the order may be gone, or our active delivery
    // may have changed while we were on the detail screen.
    _reload();
    if (accepted == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Delivery accepted · ${formatCents(accepted.totalPayCents)} '
          'when you drop it off',
        ),
      ),
    );
    // K-19: go straight to the new delivery.
    widget.onViewActiveDelivery?.call();
  }

  List<Widget> _buildList(_TabData data) {
    final total = data.requests.length;
    final shown = applyRequestFilters(
      data.requests,
      sort: _sort,
      tipsOnly: _tipsOnly,
    );
    final noun = total == 1 ? 'request' : 'requests';
    return [
      RequestSortBar(
        sort: _sort,
        tipsOnly: _tipsOnly,
        onSortChanged: (sort) => setState(() => _sort = sort),
        onTipsOnlyChanged: (on) => setState(() => _tipsOnly = on),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: Text(
              shown.length == total
                  ? '$total open $noun'
                  : '${shown.length} of $total open $noun',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          IconButton(
            onPressed: _refresh,
            tooltip: 'Refresh',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.refresh, color: AppColors.accentSoft),
          ),
        ],
      ),
      const SizedBox(height: 4),
      if (shown.isEmpty)
        GlassPanel(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'No requests with a tip right now.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _tipsOnly = false),
                child: const Text(
                  'Show all',
                  style: TextStyle(color: AppColors.accentSoft),
                ),
              ),
            ],
          ),
        ),
      for (final order in shown) ...[
        RequestCard(
          order: order,
          onTap: () => _openDetails(order, locked: data.active != null),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _buildOffline() {
    return ListView(
      children: [
        const TabHeader(
          title: 'Available requests',
          pill: 'Pickup, drop-off and pay shown before you accept',
        ),
        const SizedBox(height: 20),
        const GlassPanel(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 28),
          child: EmptyState(
            icon: Icons.power_settings_new_rounded,
            title: "You're offline",
            subtitle: 'Go online to see and accept delivery requests.',
          ),
        ),
        if (widget.onGoOnline != null) ...[
          const SizedBox(height: 16),
          PrimaryButton(label: 'Go online', onPressed: widget.onGoOnline),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOnline) return _buildOffline();
    return FutureBuilder<_TabData>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final loading = snapshot.connectionState != ConnectionState.done;
        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.accent,
          child: ListView(
            // Always scrollable so pull-to-refresh works on a short list.
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const TabHeader(
                title: 'Available requests',
                pill: 'Pickup, drop-off and pay shown before you accept',
              ),
              const SizedBox(height: 20),
              // A refresh keeps the old list on screen until the new one
              // arrives; the spinner is only for the very first load.
              if (loading && data == null)
                const LoadingState(label: 'Loading requests…')
              else if ((snapshot.hasError && !loading) || data == null)
                ErrorState(title: "Couldn't load requests", onRetry: _refresh)
              else ...[
                if (data.active case final active?) ...[
                  ActiveDeliveryBanner(
                    order: active,
                    onView: widget.onViewActiveDelivery,
                  ),
                  const SizedBox(height: 16),
                ],
                if (data.requests.isEmpty)
                  const GlassPanel(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                    child: EmptyState(
                      icon: Icons.delivery_dining,
                      title: 'No requests right now',
                      subtitle: 'New delivery requests will show up here.',
                    ),
                  )
                else
                  ..._buildList(data),
              ],
            ],
          ),
        );
      },
    );
  }
}
