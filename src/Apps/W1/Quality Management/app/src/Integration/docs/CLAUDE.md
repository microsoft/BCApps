# Integration

Hooks Quality Management into BC's core business processes via event subscribers and page extensions. This is the largest module (67 files) because it touches every domain where inspections can originate -- purchasing, production, assembly, warehouse, sales, transfers, and item tracking.

## How it works

Each BC domain has a dedicated integration codeunit that subscribes to posting events. When a purchase receipt is posted, `QltyReceivingIntegration` fires. When production output is posted, `QltyManufacturIntegration` fires. These subscribers call `QltyInspectionCreate` to generate inspections based on matching generation rules.

The module also extends 27+ BC pages with page extensions that add inspection-related columns, actions (create inspection, view inspections), and factboxes. This makes quality data visible directly in the BC pages users already work with -- purchase orders, production orders, item cards, warehouse receipts, etc.

Item tracking integration (15 files in `Inventory/Tracking/`) is the most complex sub-area. It enforces result-based blocking on transactions -- checking whether the lot/serial/package has a quality result that allows the specific transaction type (sales, transfer, consumption, pick, put-away, movement, output).

## Things to know

- **Event subscribers are domain-specific** -- each domain has its own codeunit rather than a single dispatcher. This keeps the subscription logic local to the domain it understands.
- **Page extensions outnumber everything else** -- 27 page extensions vs 13 codeunits. Most of the integration work is UI: showing inspection status and actions on existing BC pages.
- **Item tracking blocking is checked at transaction time** -- not just at inspection finish. The `QltyItemTrackingIntegration` codeunit subscribes to posting events across all domains to enforce blocking.
- **Transfer integration is split** -- `Inventory/Transfer/` covers transfer order integration, while `Inventory/Transfer/Document/` and `Inventory/Transfer/History/` handle document-level and posted transfer integration separately.
- **Navigate integration** -- `Foundation/Navigate/` hooks into BC's Navigate feature so users can find inspections from posted documents.
- **Attachment integration** -- `Foundation/Attachment/` connects inspection pictures/documents to BC's standard Document Attachment system.
