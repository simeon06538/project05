import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/courier_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
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
class AvailableTab extends StatefulWidget {
  const AvailableTab({
    super.key,
    required this.service,
    required this.courierId,
    this.onViewActiveDelivery,
    this.isVisible = true,
  });

  final CourierService service;
  final String courierId;

  /// Switches to the My Deliveries tab.
  final VoidCallback? onViewActiveDelivery;

  /// Reloads each time the tab is shown again, so the list and banner
  /// reflect anything that changed on the other tabs.
  final bool isVisible;

  @override
  State<AvailableTab> createState() => _AvailableTabState();
}

typedef _TabData = ({List<Order> requests, Order? active});

class _AvailableTabState extends State<AvailableTab> {
  late Future<_TabData> _data;
  RequestSort _sort = RequestSort.oldest;
  bool _tipsOnly = false;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  @override
  void didUpdateWidget(AvailableTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) _data = _load();
  }

  Future<_TabData> _load() async {
    final (requests, active) = await (
      widget.service.fetchAvailableRequests(),
      widget.service.fetchActiveDelivery(widget.courierId),
    ).wait;
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
      Text(
        shown.length == total
            ? '$total open $noun'
            : '${shown.length} of $total open $noun',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 12),
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TabData>(
      future: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return ListView(
          children: [
            const TabHeader(
              title: 'Available requests',
              pill: 'Pickup, drop-off and pay shown before you accept',
            ),
            const SizedBox(height: 20),
            if (snapshot.connectionState != ConnectionState.done)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              )
            else if (snapshot.hasError || data == null)
              Text(
                "Couldn't load requests.",
                style: Theme.of(context).textTheme.bodyMedium,
              )
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
        );
      },
    );
  }
}
