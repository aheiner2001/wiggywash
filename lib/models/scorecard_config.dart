/// Static definition of the Wiggy Wash scorecard line items, mirroring the
/// physical tally card. Editing this list updates every screen + the totals.
library;

enum WashSection { membership, single, shop }

extension WashSectionLabel on WashSection {
  String get title => switch (this) {
        WashSection.membership => 'Membership Tally',
        WashSection.single => 'Single Washes',
        WashSection.shop => 'Shop Sales',
      };
}

class LineItem {
  const LineItem({
    required this.id,
    required this.label,
    required this.section,
    this.price,
  });

  final String id;
  final String label;
  final WashSection section;

  /// Dollar value of one sale. `null` for shop-sale items that are tracked as a
  /// count only (no fixed price on the card).
  final double? price;

  bool get hasPrice => price != null;
}

/// The canonical, ordered list of all scorecard line items.
const List<LineItem> kLineItems = [
  // Membership tally
  LineItem(
    id: 'full_service_protect',
    label: 'Full Service Protect',
    section: WashSection.membership,
    price: 49,
  ),
  LineItem(
    id: 'protect',
    label: 'Protect',
    section: WashSection.membership,
    price: 29,
  ),
  LineItem(
    id: 'shine',
    label: 'Shine',
    section: WashSection.membership,
    price: 23,
  ),
  LineItem(
    id: 'basic',
    label: 'Basic',
    section: WashSection.membership,
    price: 17,
  ),
  // Single washes
  LineItem(
    id: 'single_protect',
    label: 'Single Protect',
    section: WashSection.single,
    price: 29,
  ),
  LineItem(
    id: 'single_shine',
    label: 'Single Shine',
    section: WashSection.single,
    price: 23,
  ),
  LineItem(
    id: 'single_basic',
    label: 'Single Basic',
    section: WashSection.single,
    price: 17,
  ),
  LineItem(
    id: 'economy',
    label: 'Economy',
    section: WashSection.single,
    price: 11,
  ),
  // Shop sales (count-only)
  LineItem(
    id: 'full_service',
    label: 'Full Service',
    section: WashSection.shop,
  ),
  LineItem(
    id: 'wax_upsell',
    label: 'Wax Upsell',
    section: WashSection.shop,
  ),
];

List<LineItem> itemsFor(WashSection section) =>
    kLineItems.where((i) => i.section == section).toList();

LineItem itemById(String id) => kLineItems.firstWhere((i) => i.id == id);
