// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Purchases.Document;

/// <summary>
/// Scopes the context in which matched order lines are being received as part of posting their matched invoice.
/// </summary>
codeunit 5828 "Matched Order Context"
{
    EventSubscriberInstance = Manual;
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        ReceivingMatchedOrderLines: Boolean;

    /// <summary>
    /// Opens the scope in which matched order lines keep the quantity to receive driven by their match.
    /// </summary>
    internal procedure StartReceivingMatchedOrderLines()
    begin
        if BindSubscription(this) then;
        ReceivingMatchedOrderLines := true;
    end;

    /// <summary>
    /// Closes the scope opened by StartReceivingMatchedOrderLines.
    /// </summary>
    internal procedure StopReceivingMatchedOrderLines()
    begin
        ReceivingMatchedOrderLines := false;
        if UnbindSubscription(this) then;
    end;

    /// <summary>
    /// Returns whether the purchase line's quantity to receive should be reset to zero. Receipt-on-invoice order
    /// lines are received only when their matched invoice is posted, so their quantity to receive defaults to zero,
    /// except while their matched order lines are actively being received.
    /// </summary>
    /// <param name="PurchaseLine">The purchase line to evaluate.</param>
    procedure ShouldResetQtyToReceive(PurchaseLine: Record "Purchase Line"): Boolean
    var
        Receiving: Boolean;
    begin
        if not ((PurchaseLine."Document Type" = PurchaseLine."Document Type"::Order) and PurchaseLine."Receipt on Invoice") then
            exit(false);
        OnCheckReceivingMatchedOrderLines(Receiving);
        exit(not Receiving);
    end;

    /// <summary>
    /// Reports whether matched order lines are currently being received. Raised from a fresh instance; the bound
    /// instance, if any, answers with the current scope.
    /// </summary>
    [IntegrationEvent(false, false)]
    procedure OnCheckReceivingMatchedOrderLines(var Receiving: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Matched Order Context", OnCheckReceivingMatchedOrderLines, '', false, false)]
    local procedure HandleCheckReceivingMatchedOrderLines(var Receiving: Boolean)
    begin
        Receiving := ReceivingMatchedOrderLines;
    end;
}
