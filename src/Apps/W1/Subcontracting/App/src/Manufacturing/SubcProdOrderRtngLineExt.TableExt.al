// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

tableextension 99001506 "Subc. ProdOrderRtngLine Ext." extends "Prod. Order Routing Line"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(99001550; "Vendor No. Subc. Price"; Code[20])
        {
            Caption = 'Vendor No. Subcontracting Prices';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = Vendor;
        }
        field(99001551; Subcontracting; Boolean)
        {
            CalcFormula = exist("Work Center" where("No." = field("Work Center No."),
                                                    "Subcontractor No." = filter(<> '')));
            Caption = 'Subcontracting';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies whether the Work Center Group is set up with a Vendor for Subcontracting.';
        }
    }

    trigger OnBeforeDelete()
    begin
        CheckForSubcontractingPurchaseLineTypeMismatchOnDeleteLine();
    end;

    var
        PurchaseLineTypeMismatchErr: Label 'There is at least one Purchase Line (%1) which is linked to Production Order Routing Line (%2). The Purchase Line cannot be of type %3 for this Production Order Routing Line. Please delete the Purchase line first before changing the Production Order Routing Line.',
        Comment = '%1 = PurchaseLine Record Id, %2 = Production Order Routing Line Record Id, %3 = Purchase Line Type';
        PurchaseLineTypeMismatchNotLastOperationErr: Label 'There is at least one Purchase Line (%1) which is linked to Production Order Routing Line (%2). Because the Production Order Routing Line is the last operation after delete, the Purchase Line cannot be of type Not Last Operation. Please delete the Purchase line first before changing the Production Order Routing Line.',
        Comment = '%1 = PurchaseLine Record Id, %2 = Previous Production Order Routing Line Record Id';

    /// <summary>
    /// Checks if the prod. order routing line has a linked purchase order line. In case of mismatching last operation or not last operation on changing
    /// the prod. order routing line order an error will be thrown if the type does not match with purchase line
    /// </summary>
    internal procedure CheckForSubcontractingPurchaseLineTypeMismatch()
    var
        ProdOrderLine: Record "Prod. Order Line";
        PurchLine: Record "Purchase Line";
    begin
        if Status <> "Production Order Status"::Released then
            exit;

        ProdOrderLine.SetLoadFields(SystemId);
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderLine.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderLine.SetRange("Routing No.", "Routing No.");
        if ProdOrderLine.Find('-') then
            repeat
                PurchLine.SetLoadFields(SystemId);
                PurchLine.SetCurrentKey(
                  "Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
                PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                PurchLine.SetRange(Type, PurchLine.Type::Item);
                PurchLine.SetRange("Prod. Order No.", "Prod. Order No.");
                PurchLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                PurchLine.SetRange("Operation No.", "Operation No.");
                if "Next Operation No." <> '' then begin
                    PurchLine.SetRange("Subc. Purchase Line Type", "Subc. Purchase Line Type"::LastOperation);
                    if PurchLine.FindFirst() then
                        Error(PurchaseLineTypeMismatchErr, PurchLine.RecordId(), RecordId(), Format("Subc. Purchase Line Type"::LastOperation));
                end else begin
                    PurchLine.SetRange("Subc. Purchase Line Type", "Subc. Purchase Line Type"::NotLastOperation);
                    if PurchLine.FindFirst() then
                        Error(PurchaseLineTypeMismatchErr, PurchLine.RecordId(), RecordId(), Format("Subc. Purchase Line Type"::NotLastOperation));
                end;
            until ProdOrderLine.Next() = 0;
    end;

    local procedure CheckForSubcontractingPurchaseLineTypeMismatchOnDeleteLine()
    var
        ProdOrderLine: Record "Prod. Order Line";
        PurchLine: Record "Purchase Line";
        PrevProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        if Status <> "Production Order Status"::Released then
            exit;
        ProdOrderLine.SetLoadFields(SystemId);
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderLine.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderLine.SetRange("Routing No.", "Routing No.");
        if ProdOrderLine.Find('-') then
            repeat
                PurchLine.SetLoadFields(SystemId);
                PurchLine.SetCurrentKey(
                  "Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
                PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                PurchLine.SetRange(Type, PurchLine.Type::Item);
                PurchLine.SetRange("Prod. Order No.", "Prod. Order No.");
                PurchLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                if "Next Operation No." = '' then begin
                    PrevProdOrderRoutingLine := Rec;
                    PrevProdOrderRoutingLine.SetRecFilter();
                    PrevProdOrderRoutingLine.SetFilter("Operation No.", "Previous Operation No.");
                    PrevProdOrderRoutingLine.SetLoadFields(SystemId);
                    if PrevProdOrderRoutingLine.FindSet() then
                        repeat
                            PurchLine.SetRange("Operation No.", PrevProdOrderRoutingLine."Operation No.");
                            PurchLine.SetRange("Subc. Purchase Line Type", "Subc. Purchase Line Type"::NotLastOperation);
                            if PurchLine.FindFirst() then
                                Error(PurchaseLineTypeMismatchNotLastOperationErr, PurchLine.RecordId(), PrevProdOrderRoutingLine.RecordId());
                        until PrevProdOrderRoutingLine.Next() = 0;
                end;
            until ProdOrderLine.Next() = 0;
    end;
}