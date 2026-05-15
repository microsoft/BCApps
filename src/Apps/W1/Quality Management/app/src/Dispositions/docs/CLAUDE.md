# Dispositions

Handles post-inspection actions for non-conforming items. Each disposition type creates or modifies BC documents/entries to physically handle items that failed quality checks. The module uses an interface pattern (`QltyDispositionInterface`) for extensibility.

## How it works

After an inspection finishes with a failing result, the user (or a workflow response) triggers a disposition action. Seven disposition types are available, each implemented as a separate codeunit:

- **Change item tracking** -- reclassify lot/serial/package numbers via item reclassification journal
- **Negative adjustment** -- scrap or destroy items via item journal negative adjustment lines
- **Move inventory (item reclass)** -- transfer to quarantine bin via item reclassification journal
- **Move inventory (warehouse reclass)** -- same but via warehouse reclassification journal (for directed put-away locations)
- **Purchase return** -- create a purchase return order to send back to the vendor
- **Warehouse put-away** -- create internal put-away to move items to a rework/quarantine bin
- **Transfer order** -- create a transfer order to move items to another location (external lab, rework center)

Each disposition codeunit generates the appropriate BC document/journal lines, populating them from the inspection's source fields (item, lot, quantity, location).

## Things to know

- **Interface-based** -- `QltyDispositionInterface` (the single interface in this app) defines the contract. Each disposition codeunit implements it.
- **Reports as entry points** -- disposition actions are triggered via processing-only reports (`QltyChangeItemTracking`, `QltyCreateNegativeAdjmt`, `QltyMoveInventory`, `QltyCreatePurchaseReturn`, `QltyCreateInternalPutaway`, `QltyCreateTransferOrder`). These reports handle the request page (quantity, destination, etc.) and call the codeunit.
- **Workflow-triggerable** -- workflow responses can automatically trigger dispositions when an inspection finishes, enabling fully automated quality pipelines.
- **Quantity-aware** -- dispositions respect the inspection's fail quantity, not the full source quantity. Only the non-conforming portion is disposed.
