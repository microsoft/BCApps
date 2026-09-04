// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;

codeunit 20574 "Subc. Item Tracking Ext"
{
    [EventSubscriber(ObjectType::Page, Page::"Item Tracking Lines", OnBeforeFillSourceQuantityArray, '', false, false)]
    local procedure SetSourceQuantityForSubcLastOperation_OnBeforeFillSourceQuantityArray(var SourceQuantityArray: array[5] of Decimal; TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseLine: Record "Purchase Line";
    begin
        if TrackingSpecification."Source Type" <> Database::"Prod. Order Line" then
            exit;
        ProdOrderLine.SetLoadFields("Prod. Order No.", "Line No.", "Quantity (Base)");
        if not ProdOrderLine.Get(
                Enum::"Production Order Status".FromInteger(TrackingSpecification."Source Subtype"),
                TrackingSpecification."Source ID", TrackingSpecification."Source Prod. Order Line")
        then
            exit;

        PurchaseLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        PurchaseLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        PurchaseLine.SetRange("Subc. Purchase Line Type", "Subc. Purchase Line Type"::LastOperation);
        if PurchaseLine.IsEmpty() then
            exit;

        SourceQuantityArray[1] := ProdOrderLine."Quantity (Base)";
        SourceQuantityArray[2] := TrackingSpecification."Qty. to Handle (Base)";
        SourceQuantityArray[3] := TrackingSpecification."Qty. to Invoice (Base)";
        SourceQuantityArray[4] := TrackingSpecification."Quantity Handled (Base)";
        SourceQuantityArray[5] := TrackingSpecification."Quantity Invoiced (Base)";
        IsHandled := true;
    end;
}