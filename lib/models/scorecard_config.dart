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
    this.defaultPrice,
  });

  final String id;
  final String label;
  final WashSection section;

  /// Out-of-the-box dollar value of one sale. `null` for items that ship as
  /// count-only (no fixed price on the card). The manager can override this —
  /// always read the live value via [PriceBook.priceFor] / [priceOf].
  final double? defaultPrice;
}

/// The canonical, ordered list of all scorecard line items.
const List<LineItem> kLineItems = [
  // Membership tally
  LineItem(
    id: 'full_service_protect',
    label: 'Full Service Protect',
    section: WashSection.membership,
    defaultPrice: 49,
  ),
  LineItem(
    id: 'protect',
    label: 'Protect',
    section: WashSection.membership,
    defaultPrice: 29,
  ),
  LineItem(
    id: 'shine',
    label: 'Shine',
    section: WashSection.membership,
    defaultPrice: 23,
  ),
  LineItem(
    id: 'basic',
    label: 'Basic',
    section: WashSection.membership,
    defaultPrice: 17,
  ),
  // Single washes
  LineItem(
    id: 'single_protect',
    label: 'Single Protect',
    section: WashSection.single,
    defaultPrice: 29,
  ),
  LineItem(
    id: 'single_shine',
    label: 'Single Shine',
    section: WashSection.single,
    defaultPrice: 23,
  ),
  LineItem(
    id: 'single_basic',
    label: 'Single Basic',
    section: WashSection.single,
    defaultPrice: 17,
  ),
  LineItem(
    id: 'economy',
    label: 'Economy',
    section: WashSection.single,
    defaultPrice: 11,
  ),
  // Shop sales (count-only by default — manager can attach a price)
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

/// Holds the manager's live price edits. Seeded from each item's
/// [LineItem.defaultPrice]; the [Store] hydrates overrides from local storage /
/// Firestore at startup and on every change. Kept here (not in the Store) so the
/// pure [Submission] model can compute revenue without importing services.
class PriceBook {
  PriceBook._();

  /// id -> price. A present key with a `null` value means "count only".
  static Map<String, double?> _overrides = {};

  static void setOverrides(Map<String, double?> overrides) {
    _overrides = Map.of(overrides);
  }

  static Map<String, double?> get overrides => Map.of(_overrides);

  /// The effective price for an item: the manager override if set, otherwise the
  /// built-in default. `null` means the item is tracked as a count only.
  static double? priceFor(String id) =>
      _overrides.containsKey(id) ? _overrides[id] : itemById(id).defaultPrice;

  static bool hasPrice(String id) => priceFor(id) != null;
}

/// Convenience accessor for a [LineItem]'s live price.
double? priceOf(LineItem item) => PriceBook.priceFor(item.id);

bool itemHasPrice(LineItem item) => PriceBook.hasPrice(item.id);
