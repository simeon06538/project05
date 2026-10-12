import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/courier_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import 'request_card.dart';
import 'request_detail_screen.dart';
import 'tab_header.dart';

/// K-03: list of open delivery requests from the [CourierService].
class AvailableTab extends StatefulWidget {
  const AvailableTab({
    super.key,
    required this.service,
    required this.courierId,
  });

  final CourierService service;
  final String courierId;

  @override
  State<AvailableTab> createState() => _AvailableTabState();
}

class _AvailableTabState extends State<AvailableTab> {
  late Future<List<Order>> _requests;

  @override
  void initState() {
    super.initState();
    _requests = widget.service.fetchAvailableRequests();
  }

  Future<void> _openDetails(Order order) async {
    final accepted = await Navigator.of(context).push<Order>(
      MaterialPageRoute(
        builder: (_) => RequestDetailScreen(
          order: order,
          service: widget.service,
          courierId: widget.courierId,
        ),
      ),
    );
    if (accepted == null || !mounted) return;

    // The accepted order is no longer open, so reload the list.
    setState(() {
      _requests = widget.service.fetchAvailableRequests();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Delivery accepted · ${formatCents(accepted.totalPayCents)} '
          'when you drop it off',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Order>>(
      future: _requests,
      builder: (context, snapshot) {
        final requests = snapshot.data;
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
            else if (snapshot.hasError || requests == null)
              Text(
                "Couldn't load requests.",
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else if (requests.isEmpty)
              const GlassPanel(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                child: EmptyState(
                  icon: Icons.delivery_dining,
                  title: 'No requests right now',
                  subtitle: 'New delivery requests will show up here.',
                ),
              )
            else ...[
              Text(
                '${requests.length} open '
                '${requests.length == 1 ? 'request' : 'requests'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              for (final order in requests) ...[
                RequestCard(order: order, onTap: () => _openDetails(order)),
                const SizedBox(height: 12),
              ],
            ],
          ],
        );
      },
    );
  }
}
