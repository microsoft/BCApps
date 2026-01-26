// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

report 99001501 "Subc. Create Transf. Order"
{
    ApplicationArea = Manufacturing;
    Caption = 'Create Subcontracting Transfer Order';
    ProcessingOnly = true;
    UsageCategory = Tasks;
    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") order(ascending);
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") order(ascending) where("Prod. Order No." = filter(<> ''), "Operation No." = filter(<> ''));
                trigger OnAfterGetRecord()
                begin
                    HandleSubcontractingForPurchLine("Purchase Line", true);
                end;
            }
            trigger OnAfterGetRecord()
            begin
                "Purchase Header".CalcFields("Subcontracting Order");
                if not "Subcontracting Order" then
                    Error(OrderNoIsNotSubcontractorErr, PurchOrderNo);

                if not CheckExistComponent() then
                    Error(ComponentsDoesNotExistErr);

                Vendor.Get("Purchase Header"."Buy-from Vendor No.");
            end;

            trigger OnPostDataItem()
            begin
                ShowDocument();
            end;

            trigger OnPreDataItem()
            begin
                PurchOrderNo := CopyStr("Purchase Header".GetFilter("No."), 1, MaxStrLen(PurchOrderNo));
                if PurchOrderNo = '' then
                    Error(WarningToSpecifyPurchOrderErr);
            end;
        }
    }
    trigger OnPostReport()
    begin
    end;

    var
        SubcManagementSetup: Record "Subc. Management Setup";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        PurchOrderNo: Code[20];
        LineNum: Integer;
        ComponentsDoesNotExistErr: Label 'Components to send to subcontractor do not exist.';
        OrderNoDoesNotExistInProdOrderErr: Label 'Operation %1 in the subcontracting order %2 does not exist in the routing %3 of the production order %4.', Comment = '%1=Operation No., %2=Purchase Order No., %3=Routing No., %4=Production Order No.';
        OrderNoIsNotSubcontractorErr: Label 'Order %1 is not a Subcontractor work.', Comment = '%1=Purchase Order No.';
        WarningToSpecifyPurchOrderErr: Label 'Warning. Specify a Purchase Order No. for the Subcontractor work.';

    local procedure InsertTransferHeader(CompLineLocation: Code[10])
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
        TransferToLocationCode: Code[10];
    begin
        if not SubcManagementSetup.Get() then
            Clear(SubcManagementSetup);

        GetTransferToLocationCode(TransferToLocationCode);

        TransferHeader.Reset();
        TransferHeader.SetRange("Source Subtype", TransferHeader."Source Subtype"::"2");
        TransferHeader.SetRange("Source ID", "Purchase Header"."Buy-from Vendor No.");
        TransferHeader.SetRange(Status, TransferHeader.Status::Open);
        TransferHeader.SetRange("Completely Shipped", false);
        TransferHeader.SetRange("Transfer-from Code", CompLineLocation);
        TransferHeader.SetRange("Transfer-to Code", TransferToLocationCode);
        TransferHeader.SetRange("Return Order", false);
        if not TransferHeader.FindFirst() then begin
            TransferHeader.Init();
            TransferHeader."No." := '';
            TransferHeader.Insert(true);
            TransferHeader.Validate("Transfer-from Code", CompLineLocation);
            TransferHeader.Validate("Transfer-to Code", TransferToLocationCode);
            if SubcManagementSetup."Direct Transfer" then begin
                SubcontractingManagement.CheckDirectTransferIsAllowedForTransferHeader(TransferHeader);
                TransferHeader.Validate("Direct Transfer Posting", "Direct Transfer Post. Type"::"Direct Transfer");
            end;

            TransferHeader."Source Type" := TransferHeader."Source Type"::Subcontracting;
            TransferHeader."Source Subtype" := TransferHeader."Source Subtype"::"2";
            TransferHeader."Source ID" := "Purchase Header"."Buy-from Vendor No.";
            TransferHeader."Subcontr. Purch. Order No." := "Purchase Header"."No.";
            TransferHeader."Subcontr. PO Line No." := "Purchase Line"."Line No.";

            TransferHeader."Transfer-to Name" := Vendor.Name;
            TransferHeader."Transfer-to Name 2" := Vendor."Name 2";
            TransferHeader."Transfer-to Address" := Vendor.Address;
            TransferHeader."Transfer-to Address 2" := Vendor."Address 2";
            TransferHeader."Transfer-to Post Code" := Vendor."Post Code";
            TransferHeader."Transfer-to City" := Vendor.City;
            TransferHeader."Transfer-to County" := Vendor.County;
            TransferHeader."Trsf.-from Country/Region Code" := Vendor."Country/Region Code";

            TransferHeader.Modify();

            LineNum := 0;
        end else begin
            TransferLine.SetRange("Document No.", TransferHeader."No.");
            if TransferLine.FindLast() then
                LineNum := TransferLine."Line No."
            else
                LineNum := 0;
        end;
    end;

    local procedure CheckExistComponent(): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
        PurchaseLine.SetRange("Document No.", PurchOrderNo);
        PurchaseLine.SetFilter("Prod. Order No.", '<>''''');
        PurchaseLine.SetFilter("Prod. Order Line No.", '<>0');
        PurchaseLine.SetFilter("Operation No.", '<>0');
        if PurchaseLine.FindSet() then
            repeat
                if HandleSubcontractingForPurchLine(PurchaseLine, false) then
                    exit(true);
            until PurchaseLine.Next() = 0;

        exit(false);
    end;

    local procedure HandleSubcontractingForPurchLine(PurchaseLine: Record "Purchase Line"; InsertLine: Boolean): Boolean
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        MfgCostCalculationMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        SubcontractingManagement: Codeunit "Subcontracting Management";
        SubcProdOrdCompRes: Codeunit "Subc. Prod. Ord. Comp. Res.";
        UnitofMeasureManagement: Codeunit "Unit of Measure Management";
        TransferFromLocationCode: Code[10];
        QtyPerUom: Decimal;
        QtyToPost: Decimal;
    begin
        if not ProdOrderLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
            exit(false);

        if not ProdOrderRoutingLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.",
             PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.")
        then
            Error(OrderNoDoesNotExistInProdOrderErr, PurchaseLine."Operation No.", PurchOrderNo, PurchaseLine."Routing No.", PurchaseLine."Prod. Order No.");

        Item.SetLoadFields("Base Unit of Measure", "Rounding Precision");
        Item.Get(PurchaseLine."No.");
        QtyPerUom := UnitofMeasureManagement.GetQtyPerUnitOfMeasure(Item, PurchaseLine."Unit of Measure Code");

        ProdOrderComponent.SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code");
        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        ProdOrderComponent.SetRange("Purchase Order Filter", PurchaseLine."Document No.");
        ProdOrderComponent.SetRange("Subcontracting Type", ProdOrderComponent."Subcontracting Type"::Transfer);
        if ProdOrderComponent.FindSet() then
            repeat
                Item.SetLoadFields("Rounding Precision", "Order Tracking Policy");
                Item.Get(ProdOrderComponent."Item No.");
                QtyToPost := MfgCostCalculationMgt.CalcActNeededQtyBase(ProdOrderLine, ProdOrderComponent, Round(PurchaseLine.Quantity * QtyPerUom, UnitofMeasureManagement.QtyRndPrecision()));
                ProdOrderComponent.CalcFields("Qty. on Trans Order (Base)", "Qty. in Transit (Base)", "Qty. transf. to Subcontr");
                if QtyToPost > (ProdOrderComponent."Qty. on Trans Order (Base)" +
                                ProdOrderComponent."Qty. in Transit (Base)" +
                                Abs(ProdOrderComponent."Qty. transf. to Subcontr"))
                then
                    if InsertLine then begin
                        TransferFromLocationCode := GetTransferFromLocationForComponent(ProdOrderComponent);
                        InsertTransferHeader(TransferFromLocationCode);

                        LineNum := LineNum + 10000;

                        TransferLine.Init();
                        TransferLine."Document No." := TransferHeader."No.";
                        TransferLine."Line No." := LineNum;

                        TransferLine.Insert();

                        TransferLine.Validate("Item No.", ProdOrderComponent."Item No.");
                        TransferLine.Validate("Variant Code", ProdOrderComponent."Variant Code");

                        TransferLine."Unit of Measure Code" := ProdOrderComponent."Unit of Measure Code";
                        TransferLine."Qty. per Unit of Measure" := ProdOrderComponent."Qty. per Unit of Measure";

                        QtyToPost := QtyToPost -
                            (ProdOrderComponent."Qty. on Trans Order (Base)" +
                             ProdOrderComponent."Qty. in Transit (Base)" +
                             Abs(ProdOrderComponent."Qty. transf. to Subcontr"));

                        TransferLine.Validate(Quantity, Round(QtyToPost / ProdOrderComponent."Qty. per Unit of Measure", Item."Rounding Precision", '>'));

                        if ProdOrderComponent."Due Date" <> 0D then
                            TransferLine.Validate("Receipt Date", SubcontractingManagement.CalcReceiptDateFromProdCompDueDateWithInbWhseHandlingTime(ProdOrderComponent));

                        TransferLine."Subcontr. Purch. Order No." := PurchaseLine."Document No.";
                        TransferLine."Subcontr. PO Line No." := PurchaseLine."Line No.";
                        TransferLine."Prod. Order No." := PurchaseLine."Prod. Order No.";
                        TransferLine."Prod. Order Line No." := PurchaseLine."Prod. Order Line No.";
                        TransferLine."Prod. Order Comp. Line No." := ProdOrderComponent."Line No.";
                        TransferLine."Routing No." := PurchaseLine."Routing No.";
                        TransferLine."Routing Reference No." := PurchaseLine."Routing Reference No.";
                        TransferLine."Work Center No." := PurchaseLine."Work Center No.";
                        TransferLine."Operation No." := PurchaseLine."Operation No.";
                        TransferLine.Modify();

                        if ProdOrderComponent."Orig. Location Code" = '' then
                            ProdOrderComponent."Orig. Location Code" := ProdOrderComponent."Location Code";
                        if ProdOrderComponent."Orig. Bin Code" = '' then
                            ProdOrderComponent."Orig. Bin Code" := ProdOrderComponent."Bin Code";

                        SubcontractingManagement.TransferReservationEntryFromProdOrderCompToTransferOrder(TransferLine, ProdOrderComponent);
                        if TransferHeader."Transfer-to Code" <> ProdOrderComponent."Location Code" then begin
                            if Item."Order Tracking Policy" = Item."Order Tracking Policy"::None then
                                ProdOrderComponent.Validate("Location Code", TransferHeader."Transfer-to Code")
                            else begin
                                BindSubscription(SubcProdOrdCompRes);
                                ProdOrderComponent.Validate("Location Code", TransferHeader."Transfer-to Code");
                                UnbindSubscription(SubcProdOrdCompRes);
                            end;
                            ProdOrderComponent.GetDefaultBin();
                        end;
                        ProdOrderComponent.Modify();

                        SubcontractingManagement.CreateReservEntryForTransferReceiptToProdOrderComp(TransferLine, ProdOrderComponent);
                    end else
                        exit(true);
            until ProdOrderComponent.Next() = 0;

        exit(false);
    end;

    local procedure ShowDocument()
    begin
        Commit(); // Used for following call of Transfer Pages
        TransferHeader.Reset();
        TransferHeader.SetCurrentKey("Subcontr. Purch. Order No.");
        TransferHeader.SetRange("Subcontr. Purch. Order No.", "Purchase Line"."Document No.");
        if TransferHeader.Count() > 1 then
            Page.Run(Page::"Transfer Orders", TransferHeader)
        else
            Page.Run(Page::"Transfer Order", TransferHeader);
    end;

    local procedure GetTransferFromLocationForComponent(ProdOrderComponent: Record "Prod. Order Component"): Code[10]
    var
        SubcontrLocationCode: Code[10];
        ResultLocationCode: Code[10];
    begin
        SubcontrLocationCode := "Purchase Header"."Subc. Location Code";
        if SubcontrLocationCode = '' then
            SubcontrLocationCode := Vendor."Subcontr. Location Code";

        if (ProdOrderComponent."Location Code" = SubcontrLocationCode) and
           (ProdOrderComponent."Orig. Location Code" <> '')
        then
            ResultLocationCode := ProdOrderComponent."Orig. Location Code"
        else
            ResultLocationCode := ProdOrderComponent."Location Code";
        exit(ResultLocationCode);
    end;

    local procedure GetTransferToLocationCode(var TransferToLocationCode: Code[10])
    begin
        TransferToLocationCode := "Purchase Header"."Subc. Location Code";
        if TransferToLocationCode = '' then begin
            TransferToLocationCode := Vendor."Subcontr. Location Code";
            if TransferToLocationCode = '' then
                Vendor.TestField("Subcontr. Location Code");
        end;
    end;
}