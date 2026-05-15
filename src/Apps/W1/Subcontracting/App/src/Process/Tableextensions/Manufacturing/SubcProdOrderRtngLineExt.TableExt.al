// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

tableextension 99001506 "Subc. ProdOrderRtngLine Ext." extends "Prod. Order Routing Line"
{
    fields
    {
        modify(Type)
        {
            trigger OnAfterValidate()
            begin
                if Type = xRec.Type then
                    exit;

                if Type <> "Capacity Type"::"Work Center" then
                    "Transfer WIP Item" := false;
            end;
        }
        modify("No.")
        {
            trigger OnAfterValidate()
            var
                WorkCenter: Record "Work Center";
            begin
                if "No." = xRec."No." then
                    exit;
                if Type <> "Capacity Type"::"Work Center" then begin
                    "Transfer WIP Item" := false;
                    exit;
                end;
                WorkCenter.SetLoadFields("Subcontractor No.");
                WorkCenter.Get("No.");
                if WorkCenter."Subcontractor No." = '' then
                    "Transfer WIP Item" := false;
            end;
        }
        field(99001550; "Vendor No. Subc. Price"; Code[20])
        {
            AllowInCustomizations = AsReadOnly;
            Caption = 'Vendor No. Subcontracting Prices';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = Vendor;
        }
        field(99001551; Subcontracting; Boolean)
        {
            AllowInCustomizations = AsReadOnly;
            CalcFormula = exist("Work Center" where("No." = field("Work Center No."),
                                                    "Subcontractor No." = filter(<> '')));
            Caption = 'Subcontracting';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies whether the Work Center Group is set up with a Vendor for Subcontracting.';
        }
        field(99001560; "Transfer WIP Item"; Boolean)
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Transfer WIP Item';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the production order parent item (WIP item) is transferred to the subcontractor for this operation.';

            trigger OnValidate()
            begin
                if "Transfer WIP Item" then begin
                    CalcFields(Subcontracting);
                    TestField(Subcontracting, true);
                end;
            end;
        }
        field(99001561; "Transfer Description"; Text[100])
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Transfer Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the operation-specific description used on transfer orders for the semi-finished item as it is shipped to the subcontracting location. If empty, the standard description is used.';
        }
        field(99001562; "Transfer Description 2"; Text[50])
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Transfer Description 2';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies an additional operation-specific description line used on transfer orders for the semi-finished item as it is shipped to the subcontracting location.';
        }
#pragma warning disable AA0232
        field(99001563; "WIP Qty. (Base) at Subc."; Decimal)
#pragma warning restore AA0232
        {
            AllowInCustomizations = AsReadOnly;
            AutoFormatType = 0;
            CalcFormula = sum("Subcontractor WIP Ledger Entry"."Quantity (Base)" where("Prod. Order Status" = field(Status),
                                                                                        "Prod. Order No." = field("Prod. Order No."),
                                                                                        "Prod. Order Line No." = field("Prod. Order Line Filter"),
                                                                                        "Routing Reference No." = field("Routing Reference No."),
                                                                                        "Routing No." = field("Routing No."),
                                                                                        "Operation No." = field("Operation No."),
                                                                                        "Location Code" = field("WIP Location Filter"),
                                                                                        "In Transit" = const(false)));
            Caption = 'WIP Qty. (Base) at Subcontractor';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the total work-in-progress quantity (base) of the production order parent item currently held at the subcontractor location for this operation, as tracked by Subcontractor WIP Ledger Entries.';
        }
        field(99001564; "WIP Qty. (Base) in Transit"; Decimal)
        {
            AllowInCustomizations = AsReadOnly;
            AutoFormatType = 0;
            CalcFormula = sum("Subcontractor WIP Ledger Entry"."Quantity (Base)" where("Prod. Order Status" = field(Status),
                                                                                        "Prod. Order No." = field("Prod. Order No."),
                                                                                        "Prod. Order Line No." = field("Prod. Order Line Filter"),
                                                                                        "Routing Reference No." = field("Routing Reference No."),
                                                                                        "Routing No." = field("Routing No."),
                                                                                        "Operation No." = field("Operation No."),
                                                                                        "In Transit" = const(true)));
            Caption = 'WIP Qty. (Base) in Transit';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the outstanding quantity of the production order parent item on transfer orders that is currently in transit to the subcontractor for this operation.';
        }
        field(99001534; "WIP Location Filter"; Code[10])
        {
            Caption = 'WIP Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
            ToolTip = 'Specifies the location filter used for FlowField calculations.';
        }
        field(99001535; "Prod. Order Line Filter"; Integer)
        {
            Caption = 'Prod. Order Line Filter';
            FieldClass = FlowFilter;
            ToolTip = 'Specifies the production order line filter used for FlowField calculations.';
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