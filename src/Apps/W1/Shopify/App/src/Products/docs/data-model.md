# Data model

## Overview

The Products data model mirrors Shopify's own hierarchy -- Product contains Variants, Variants contain Inventory Items -- but adds a parallel linking layer to BC's Item/Item Variant/Item Unit of Measure structure. The core challenge this model solves is that a single BC Item can map to one Shopify Product, but the explosion of variants depends on whether "UoM as Variant" is enabled and how many BC Item Variants exist.

## Product-to-Item linking

The `Shpfy Product` table (`ShpfyProduct.Table.al`) is keyed by the Shopify BigInteger ID and carries `Item SystemId` (a Guid) that points to the BC Item's SystemId. The `Item No.` is a FlowField calculated from this Guid, not stored directly. This means the link survives item renumbering. The `Shop Code` field scopes the product to a specific Shopify shop, and the secondary key on `(Shop Code, Item SystemId)` enables efficient lookup of "which products does this item have across shops."

Products own their description HTML as a Blob field, with a companion `Description Html Hash` integer for change detection. Tags are stored externally in the polymorphic `Shpfy Tag` table (in Base) rather than on the Product itself, with a `Tags Hash` field for the same change-detection pattern.

## Variant structure and option slots

The `Shpfy Variant` table (`ShpfyVariant.Table.al`) is the workhorse of the product model. Each variant carries three pairs of option fields (`Option 1/2/3 Name` and `Option 1/2/3 Value`). How these slots are filled depends on the Shop configuration:

- **No UoM as Variant, no item attributes as options**: Option 1 is "Variant" with the BC Item Variant Code as its value. Options 2 and 3 are empty.
- **UoM as Variant, with Item Variants**: Option 1 is "Variant" (Item Variant Code), Option 2 is the UoM option name from the Shop. This creates a Cartesian product of Item Variants x Units of Measure.
- **UoM as Variant, no Item Variants**: Option 1 is the UoM option name. A product with only one UoM effectively has a single variant.
- **Item attributes as options**: Up to 3 Item Attributes marked "As Option" replace the Variant/UoM pattern entirely. Each attribute occupies one option slot in order.

The `UoM Option Id` field (integer 1, 2, or 3) records which option slot carries the unit-of-measure value. This is critical during export updates, where the code must locate the correct existing variant by scanning the right option slot.

Each variant links back to BC via `Item SystemId` and optionally `Item Variant SystemId`. When a variant represents only a UoM (no BC Item Variant), `Item Variant SystemId` is null and `Mapped By Item` is true. Pricing fields (Price, Compare at Price, Unit Cost) are stored on the variant because Shopify prices live at the variant level, not the product level.

## Inventory Items

The `Shpfy Inventory Item` table (`ShpfyInventoryItem.Table.al`) represents Shopify's InventoryItem resource. It is keyed by its own Shopify ID and linked to a Variant via `Variant Id`. This table stores origin/shipping metadata (country of origin, requires shipping, tracked status) but not stock quantities -- those are managed separately in the Inventory module. Deleting a Variant cascades to delete its Inventory Items.

## Collections and Sales Channels

`Shpfy Product Collection` and `Shpfy Shop Collection Map` handle the many-to-many relationship between products and Shopify collections. `Shpfy Sales Channel` tracks which publication channels a product is visible on. These are secondary concerns that support filtering on the Products page but do not participate in the core sync flow.
