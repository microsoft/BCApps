# Customer contracts extensibility

The customer contracts area is the richest extensibility surface in the
Subscription Billing app. The `CustomerSubscriptionContract` table alone
publishes roughly 50 IntegrationEvents, and `CustSubContractLine` adds 6 more.
The `ExtendContract` page publishes 3 events.

## Customizing contract creation and initialization

These events let you intercept contract setup, number series selection, and
initial field population.

- `OnBeforeInitInsert` -- override the number series or auto-number logic
- `OnValidateSellToCustomerNoAfterInit` -- adjust fields after a new
  sell-to customer reinitializes the contract
- `OnAfterGetSubscriptionContractSetup` -- modify the setup record before
  it is used (e.g. override number series per context)
- `OnInitFromContactOnAfterInitNoSeries` -- hook contact-based creation
- `OnBeforeAssistEdit` -- replace the standard assist-edit / no-series lookup

## Customizing customer and contact validation

Events for controlling how sell-to, bill-to, and contact relationships resolve.

- `OnBeforeValidateSellToCustomerName`, `OnBeforeValidateBillToCustomerName`
  -- intercept name-to-number resolution
- `OnBeforeConfirmSellToContactNoChange`, `OnBeforeConfirmBillToContactNoChange`
  -- suppress or customize the change-confirmation dialog
- `OnBeforeUpdateSellToCust`, `OnBeforeUpdateBillToCust` -- skip or
  replace the contact-to-customer resolution logic
- `OnUpdateSellToCustOnBeforeContactIsNotRelatedToAnyCustomerErr`,
  `OnUpdateBillToCustOnBeforeContactIsNotRelatedToAnyCustomerErr` --
  handle unrelated contacts without erroring
- `OnUpdateSellToCustOnBeforeFindContactBusinessRelation`,
  `OnUpdateBillToCustOnBeforeFindContactBusinessRelation` -- replace the
  business-relation lookup
- `OnAfterUpdateSellToCont`, `OnAfterUpdateBillToCont` -- post-process
  contact updates
- `OnAfterUpdateSellToCust`, `OnAfterUpdateBillToCust` -- post-process
  customer-from-contact updates
- `OnValidateBillToCustomerNoOnAfterConfirmed` -- runs after user confirms
  bill-to customer change

## Customizing address handling

Events for controlling address copy and sync behavior across sell-to, bill-to,
and ship-to.

- `OnAfterCopySellToCustomerAddressFieldsFromCustomer` -- modify fields
  after sell-to address is copied from the Customer card
- `OnAfterSetFieldsBilltoCustomer` -- post-process bill-to fields from
  Customer
- `OnAfterCopySellToAddressToBillToAddress`,
  `OnAfterCopySellToAddressToShipToAddress` -- hook address cascading
- `OnBeforeCopyShipToCustomerAddressFieldsFromCustomer`,
  `OnBeforeCopyShipToCustomerAddressFieldsFromShipToAddr` -- skip or
  replace ship-to copy logic
- `OnAfterCopyShipToCustomerAddressFieldsFromCustomer`,
  `OnAfterCopyShipToCustomerAddressFieldsFromShipToAddr` -- post-process
  ship-to
- `OnAfterIsShipToAddressEqualToSellToAddress`,
  `OnAfterIsShipToAddressEqualToSubscriptionHeaderShipToAddress` --
  override the address-equality check
- Post code lookups: `OnBeforeLookupBillToPostCode`,
  `OnBeforeLookupSellToPostCode`, `OnBeforeLookupShipToPostCode`,
  `OnBeforeValidateBillToPostCode`, `OnBeforeValidateSellToPostCode`,
  `OnBeforeValidateShipToPostCode`

## Customizing dimensions

- `OnBeforeCreateDim`, `OnAfterCreateDimDimSource` -- control which
  dimension sources feed into the default dimension set
- `OnCreateDimOnBeforeModify` -- inspect the new dim set before the
  contract header is modified
- `OnBeforeValidateShortcutDimCode`, `OnAfterValidateShortcutDimCode` --
  hook shortcut dimension changes
- `OnBeforeUpdateAllLineDim`, `OnBeforeConfirmUpdateAllLineDim` -- skip
  or customize the "update all lines?" confirmation and logic
- `OnAfterUpdateHarmonizedBillingFields` -- react after harmonized
  billing fields are recalculated from dimension/billing changes

## Customizing contract line management

Events on `CustSubContractLine` (table 8062).

- `OnAfterInitFromSubscriptionLine` -- modify the contract line after it
  is initialized from a Subscription Line
- `OnAfterCheckAndDisconnectContractLine` -- post-process after a line is
  disconnected from its Subscription Line (on delete or type change)
- `OnAfterCheckSelectedContractLinesOnMergeContractLines` -- add custom
  merge validations
- `OnAfterUpdateSubscriptionDescription`,
  `OnAfterUpdateSubscriptionLineDescription` -- react to description edits
  flowing to the Subscription Header / Line
- `OnAfterLoadAmountsForContractLine` -- adjust amounts after loading from
  the underlying Subscription Line

## Customizing contract line creation from subscriptions

Events on the contract header governing how Subscription Lines become
contract lines.

- `OnBeforeCreateCustomerContractLineFromSubscriptionLine` -- skip or
  replace the standard line-creation logic
- `OnAfterCreateCustomerContractLineFromSubscriptionLine` -- post-process
  the new contract line
- `OnBeforeModifySubscriptionLineOnCreateCustomerContractLineFromSubscriptionLine`
  -- adjust the Subscription Line before it is linked
- `OnBeforeCreateCustomerContractLineFromTempSubscriptionLine` -- intercept
  batch assignment from temporary Subscription Lines
- `OnBeforeUpdateServicesDates` -- hook before subscription date refresh

## Customizing contract extension

Events on the **Extend Contract** page (page 8002).

- `OnBeforeExtendContract` -- validate or block the extension before it runs
- `OnAfterGetAdditionalServiceCommitments` -- modify the selectable
  subscription packages
- `OnAfterValidateItemNo` -- react to item selection on the extension page

## Customizing the extend contract codeunit

`ExtendSubContractMgt` (codeunit 8075) publishes one event:

- `OnAfterAssignSubscriptionLineToContractOnBeforeModify` -- adjust the
  Subscription Line before it is saved with its new contract assignment
