import '../../models/order.dart';

/// How the Available list is ordered.
enum RequestSort {
  oldest('Oldest first'),
  highestPay('Highest pay'),
  closest('Closest');

  const RequestSort(this.label);

  final String label;
}

/// K-10: returns [requests] sorted by [sort], keeping only ones with a tip
/// when [tipsOnly] is set. Ties keep the oldest request first, so the
/// order never jumps around between refreshes.
List<Order> applyRequestFilters(
  List<Order> requests, {
  RequestSort sort = RequestSort.oldest,
  bool tipsOnly = false,
}) {
  final result = [
    for (final o in requests)
      if (!tipsOnly || o.tipCents > 0) o,
  ];
  int byAge(Order a, Order b) => a.createdAt.compareTo(b.createdAt);
  result.sort(switch (sort) {
    RequestSort.oldest => byAge,
    RequestSort.highestPay => (a, b) {
      final byPay = b.totalPayCents.compareTo(a.totalPayCents);
      return byPay != 0 ? byPay : byAge(a, b);
    },
    RequestSort.closest => (a, b) {
      final byDistance = a.distanceMiles.compareTo(b.distanceMiles);
      return byDistance != 0 ? byDistance : byAge(a, b);
    },
  });
  return result;
}
