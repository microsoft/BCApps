# Inventory extensibility

## Stock calculation interfaces

There are three interfaces involved in stock calculation, and an event for
post-calculation adjustment.

### Shpfy Stock Calculation

The base interface (`Interface/ShpfyStockCalculation.Interface.al`):

```
procedure GetStock(var Item: Record Item): Decimal;
```

Receives an Item record with `Date Filter`, `Location Filter`, and
optionally `Variant Filter` already applied. Return the computed stock
quantity. Two built-in implementations exist: `Shpfy Balance Today` (uses
`ItemAvailabilityFormsMgt.CalcAvailQuantities` for projected available
balance) and `Shpfy Free Inventory` (returns `Inventory - Reserved Qty.`).

### Shpfy Extended Stock Calculation

Extends the base interface
(`Interface/ShpfyExtendedStockCalculation.Interface.al`):

```
procedure GetStock(var Item: Record Item; var ShopLocation: Record "Shpfy Shop Location"): Decimal;
```

Same as above but also receives the Shop Location record. This gives your
implementation access to the location's `Shop Code`, `Location Filter`,
and other configuration. The `InventoryAPI` checks at runtime whether your
implementation supports this extended interface via an `is` type check
and downcasts when it does. If your implementation only needs the Item
record, implement the base interface instead.

### Shpfy IStock Available

Controls whether an item type participates in stock sync at all
(`Interface/ShpfyIStockAvailable.Interface.al`):

```
procedure CanHaveStock(): Boolean;
```

The `Shpfy Stock Calculation` enum implements both `Shpfy Stock Calculation`
and `Shpfy IStock Available` simultaneously. The `Disabled` value maps to
`Shpfy Can Not Have Stock` (returns false); the active values map to
`Shpfy Can Have Stock` (returns true). When you add a custom enum value,
you must provide implementations for both interfaces.

## Adding a custom stock calculation

The `Shpfy Stock Calculation` enum is `Extensible = true`. To add a
custom strategy:

- Create an enum extension adding your value to `Shpfy Stock Calculation`.
- Provide an `Implementation` clause mapping both
  `Shpfy Stock Calculation` and `Shpfy IStock Available` to your
  codeunits.
- Your `IStock Available` implementation should return true (otherwise
  stock sync is skipped for that location).
- Your `Stock Calculation` implementation receives the Item with filters
  already set. Optionally implement `Shpfy Extended Stock Calculation` if
  you need the Shop Location record.

## OnAfterCalculationStock event

Fired by `Shpfy Inventory Events`
(`Codeunits/ShpfyInventoryEvents.Codeunit.al`) after the stock
calculation completes but before the value is exported. Parameters:

- `Item: Record Item` -- the item record with filters applied
- `ShopifyShop: Record "Shpfy Shop"` -- the shop configuration
- `LocationFilter: Text` -- the location filter string from the Shop Location
- `var StockResult: Decimal` -- the calculated stock, modifiable

Use this event when you need to adjust the final stock number regardless
of which calculation strategy is active. For example, reserving safety
stock or applying a multiplier. If you need to replace the calculation
entirely, implement a custom stock calculation enum value instead.
