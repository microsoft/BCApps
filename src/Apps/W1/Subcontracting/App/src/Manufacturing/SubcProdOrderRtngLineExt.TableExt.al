// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

tableextension 20506 "Subc. ProdOrderRtngLine Ext." extends "Prod. Order Routing Line"
{
    fields
    {
        modify(Type)
        {
            trigger OnAfterValidate()
            begin
                ClearTransferWIPItemForNonWorkCenter();
            end;
        }
        modify("No.")
        {
            trigger OnAfterValidate()
            begin
                ClearTransferWIPItemForNonSubcontractingWorkCenter();
            end;
        }
        modify("Routing Link Code")
        {
            trigger OnAfterValidate()
            begin
                UpdateLinkedComponentsAfterRoutingLinkCodeChange();
            end;
        }
        modify("Standard Task Code")
        {
            trigger OnAfterValidate()
            begin
                UpdateSubcPriceListAndTransferStandardTaskComments();
            end;
        }
        field(20550; "Vendor No. Subc. Price"; Code[20])
        {
            AllowInCustomizations = AsReadOnly;
            Caption = 'Vendor No. Subcontracting Prices';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = Vendor;
        }
        field(20551; Subcontracting; Boolean)
        {
            AllowInCustomizations = AsReadOnly;
            CalcFormula = exist("Work Center" where("No." = field("Work Center No."),
                                                    "Subcontractor No." = filter(<> '')));
            Caption = 'Subcontracting';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies whether the Work Center Group is set up with a Vendor for Subcontracting.';
        }
        field(20560; "Transfer WIP Item"; Boolean)
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Transfer WIP Item';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the production order parent item (WIP item) is transferred to the subcontractor for this operation.';

            trigger OnValidate()
            begin
                ValidateTransferWIPItemForSubcontracting();
            end;
        }
        field(20561; "Transfer Description"; Text[100])
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Transfer Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the operation-specific description used on transfer orders for the semi-finished item as it is shipped to the subcontracting location. If empty, the standard description is used.';
        }
        field(20562; "Transfer Description 2"; Text[50])
        {
            AllowInCustomizations = AsReadWrite;
            Caption = 'Transfer Description 2';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies an additional operation-specific description line used on transfer orders for the semi-finished item as it is shipped to the subcontracting location.';
        }
#pragma warning disable AA0232
        field(20563; "WIP Qty. (Base) at Subc."; Decimal)
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
            ToolTip = 'Specifies the total work-in-progress quantity (base) of the production order parent item currently held at the subcontractor location for this operation, as tracked by Subcontracting WIP Entries.';
        }
        field(20564; "WIP Qty. (Base) in Transit"; Decimal)
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
        field(20534; "WIP Location Filter"; Code[10])
        {
            Caption = 'WIP Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
            ToolTip = 'Specifies the location filter used for FlowField calculations.';
        }
        field(20535; "Prod. Order Line Filter"; Integer)
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

    local procedure ClearTransferWIPItemForNonWorkCenter()
    var
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if Type = xRec.Type then
            exit;

        if Type <> "Capacity Type"::"Work Center" then
            "Transfer WIP Item" := false;
    end;

    local procedure ClearTransferWIPItemForNonSubcontractingWorkCenter()
    var
        WorkCenter: Record "Work Center";
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if "No." = xRec."No." then
            exit;
        if Type <> "Capacity Type"::"Work Center" then begin
            "Transfer WIP Item" := false;
            exit;
        end;
        if "No." = '' then begin
            "Transfer WIP Item" := false;
            exit;
        end;
        WorkCenter.SetLoadFields("Subcontractor No.");
        WorkCenter.Get("No.");
        if WorkCenter."Subcontractor No." = '' then
            "Transfer WIP Item" := false;
    end;

    local procedure UpdateLinkedComponentsAfterRoutingLinkCodeChange()
    var
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if Rec.IsTemporary then
            exit;
        if Rec."Routing Link Code" <> xRec."Routing Link Code" then
            if xRec."Routing Link Code" <> '' then begin
                SubcontractingManagement.DelLocationLinkedComponents(xRec, true);
                if Rec."Routing Link Code" <> '' then
                    SubcontractingManagement.UpdLinkedComponents(Rec, false);
            end else
                if Rec."Routing Link Code" <> '' then
                    SubcontractingManagement.UpdLinkedComponents(Rec, true);
    end;

    local procedure UpdateSubcPriceListAndTransferStandardTaskComments()
    var
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
        SubcPriceManagement: Codeunit "Subc. Price Management";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if Rec.IsTemporary then
            exit;
        SubcPriceManagement.GetSubcPriceList(Rec);
        if "Standard Task Code" = '' then
            exit;

        CalcFields(Subcontracting);
        if not Subcontracting then
            exit;

        Rec.TransferStandardTaskComments("Standard Task Code");
    end;

    local procedure ValidateTransferWIPItemForSubcontracting()
    begin
        if "Transfer WIP Item" then begin
            CalcFields(Subcontracting);
            TestField(Subcontracting, true);
            TestField(Type, Type::"Work Center");
        end;
    end;

    /// <summary>
    /// Replaces the dedicated production-order routing comments for the operation with the comments from the specified Routing Line.
    /// </summary>
    /// <param name="RoutingLine">The Routing Line whose dedicated comments are transferred.</param>
    internal procedure TransferRoutingComments(RoutingLine: Record "Routing Line")
    var
        RoutingComment: Record "Subc. Routing Comment Line";
        ProdOrderRoutingComment: Record "Subc. Prod. Rtng. Comment";
        CommentExists: Boolean;
    begin
        ProdOrderRoutingComment.SetRange(Status, Rec.Status);
        ProdOrderRoutingComment.SetRange("Prod. Order No.", Rec."Prod. Order No.");
        ProdOrderRoutingComment.SetRange("Routing Reference No.", Rec."Routing Reference No.");
        ProdOrderRoutingComment.SetRange("Routing No.", Rec."Routing No.");
        ProdOrderRoutingComment.SetRange("Operation No.", Rec."Operation No.");

        RoutingComment.SetRange("Routing No.", RoutingLine."Routing No.");
        RoutingComment.SetRange("Version Code", RoutingLine."Version Code");
        RoutingComment.SetRange("Operation No.", RoutingLine."Operation No.");
        if RoutingComment.FindSet() then
            repeat
                ProdOrderRoutingComment.SetRange("Line No.", RoutingComment."Line No.");
                CommentExists := not ProdOrderRoutingComment.IsEmpty();
                ProdOrderRoutingComment.Init();
                ProdOrderRoutingComment.Status := Rec.Status;
                ProdOrderRoutingComment."Prod. Order No." := Rec."Prod. Order No.";
                ProdOrderRoutingComment."Routing Reference No." := Rec."Routing Reference No.";
                ProdOrderRoutingComment."Routing No." := Rec."Routing No.";
                ProdOrderRoutingComment."Operation No." := Rec."Operation No.";
                ProdOrderRoutingComment."Line No." := RoutingComment."Line No.";
                ProdOrderRoutingComment.Description := RoutingComment.Description;
                ProdOrderRoutingComment."Description 2" := RoutingComment."Description 2";
                if CommentExists then
                    ProdOrderRoutingComment.Modify()
                else
                    ProdOrderRoutingComment.Insert();
            until RoutingComment.Next() = 0;
    end;

    /// <summary>
    /// Replaces the dedicated production-order routing comments for the operation with the comments defined for the specified Standard Task.
    /// </summary>
    /// <param name="StandardTaskCode">The Standard Task Code whose comments are transferred.</param>
    internal procedure TransferStandardTaskComments(StandardTaskCode: Code[10])
    var
        StandardTaskComment: Record "Subc. Standard Task Comment";
        ProdOrderRoutingComment: Record "Subc. Prod. Rtng. Comment";
    begin
        ProdOrderRoutingComment.SetRange(Status, Rec.Status);
        ProdOrderRoutingComment.SetRange("Prod. Order No.", Rec."Prod. Order No.");
        ProdOrderRoutingComment.SetRange("Routing Reference No.", Rec."Routing Reference No.");
        ProdOrderRoutingComment.SetRange("Routing No.", Rec."Routing No.");
        ProdOrderRoutingComment.SetRange("Operation No.", Rec."Operation No.");

        StandardTaskComment.SetRange("Standard Task Code", StandardTaskCode);
        if StandardTaskComment.FindSet() then
            repeat
                ProdOrderRoutingComment.Init();
                ProdOrderRoutingComment.Status := Rec.Status;
                ProdOrderRoutingComment."Prod. Order No." := Rec."Prod. Order No.";
                ProdOrderRoutingComment."Routing Reference No." := Rec."Routing Reference No.";
                ProdOrderRoutingComment."Routing No." := Rec."Routing No.";
                ProdOrderRoutingComment."Operation No." := Rec."Operation No.";
                ProdOrderRoutingComment."Line No." := StandardTaskComment."Line No.";
                ProdOrderRoutingComment.Description := StandardTaskComment.Description;
                ProdOrderRoutingComment."Description 2" := StandardTaskComment."Description 2";
                ProdOrderRoutingComment.Insert();
            until StandardTaskComment.Next() = 0;
    end;

    /// <summary>
    /// Checks if the prod. order routing line has a linked purchase order line. In case of mismatching last operation or not last operation on changing
    /// the prod. order routing line order an error will be thrown if the type does not match with purchase line
    /// </summary>
    internal procedure CheckForSubcontractingPurchaseLineTypeMismatch()
    var
        ProdOrderLine: Record "Prod. Order Line";
        PurchLine: Record "Purchase Line";
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
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
                PurchLine.SetCurrentKey("Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
                PurchLine.SetRange("Prod. Order No.", "Prod. Order No.");
                PurchLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                PurchLine.SetRange("Operation No.", "Operation No.");
                PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                PurchLine.SetRange(Type, PurchLine.Type::Item);
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
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
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
                PurchLine.SetCurrentKey("Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
                PurchLine.SetRange("Prod. Order No.", "Prod. Order No.");
                PurchLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
                PurchLine.SetRange(Type, PurchLine.Type::Item);
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