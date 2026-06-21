namespace Microsoft.SubscriptionBilling;

using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

/// <summary>
/// Manual-binding helper used by "Create Billing Documents" to skip the redundant unit price / unit cost
/// engine work that the platform runs while validating the created Sales and Purchase lines. The billing
/// flow already assigns the known Unit Price and Unit Cost explicitly (the values come from the Billing
/// Line), so the price-list and cost lookups inside those Validate calls are wasted work on every line.
/// Only the price/cost calculation is skipped - all other validation side effects (dimensions, VAT,
/// posting groups, item defaults) still run. Bind this instance only around the line field initialization
/// via BindSubscription / UnbindSubscription.
/// </summary>
codeunit 8036 "Billing Price Calc. Skip"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", OnBeforeUpdateUnitPrice, '', false, false)]
    local procedure SkipSalesUpdateUnitPrice(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer; var Handled: Boolean)
    begin
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", OnBeforeGetUnitCost, '', false, false)]
    local procedure SkipSalesGetUnitCost(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    // Suppresses UoM quantity conversion while the billing line is being initialised. At the point this
    // subscriber fires, the Sales Line quantity is still 0 (the billing amount is assigned afterwards),
    // so the platform's UoM conversion logic produces no meaningful result and only adds overhead. All
    // UoM-driven quantity validation runs normally once BillingPriceCalcSkip is unbound.
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", OnBeforeUpdateQuantityFromUOMCode, '', false, false)]
    local procedure SkipSalesUpdateQuantityFromUOMCode(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeUpdateUnitCost, '', false, false)]
    local procedure SkipPurchaseUpdateUnitCost(var PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;
}
