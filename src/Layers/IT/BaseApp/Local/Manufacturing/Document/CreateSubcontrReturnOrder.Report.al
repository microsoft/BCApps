#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

report 12153 "Create Subcontr. Return Order"
{
    Caption = 'Create Subcontr. Return Order';
    ProcessingOnly = true;
            ObsoleteReason = 'Preparation for replacement by Subcontracting app';
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") order(ascending);
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") order(ascending) where("Prod. Order No." = filter(<> ''));

                trigger OnAfterGetRecord()
                var
                    QtyToPost: Decimal;
                begin
                    if not "WIP Item" then
                        CheckPurchLine("Purchase Line", true, QtyToPost)
                    else
                        if CheckPurchLine("Purchase Line", false, QtyToPost) then
                            if QtyToPost > 0 then begin
                                TestField("Location Code");
                                InsertTransferHeader("Location Code");
                                TransferLine.Init();
                                TransferLine."Document No." := TransferHeader."No.";
                                LineNum := LineNum + 10000;
                                TransferLine."Line No." := LineNum;
                                TransferLine.Validate("Item No.", "No.");
                                TransferLine.Validate("Variant Code", "Variant Code");
                                TransferLine.Validate("Unit of Measure Code", "Unit of Measure Code");
                                TransferLine.Validate("WIP Quantity", QtyToPost);
                                TransferLine."Subcontr. Purch. Order No." := "Document No.";
                                TransferLine."Subcontr. Purch. Order Line" := "Line No.";
                                TransferLine."Prod. Order No." := "Prod. Order No.";
                                TransferLine."Prod. Order Line No." := "Prod. Order Line No.";
                                TransferLine."WIP Item" := true;
                                TransferLine."Routing No." := "Routing No.";
                                TransferLine."Routing Reference No." := "Routing Reference No.";
                                TransferLine."Work Center No." := "Work Center No.";
                                TransferLine."Operation No." := "Operation No.";
                                TransferLine.Insert();
                            end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                "Purchase Header".CalcFields("Subcontracting Order");
                if not "Subcontracting Order" then
                    Error(Text1130001, PurchOrderNo);

                if not CheckExistComponent() then
                    Error(Text1130003);

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
                    Error(Text1130000);
                ManufacturingSetup.Get();
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Text1130000: Label 'Warning. Specify a Purchase Order No. for the Subcontractor work.';
        Text1130001: Label 'Order %1 is not a Subcontractor work.';
        Text1130002: Label 'Order %1 for operation reference %4 of the routing %2 does not exist in Prod. Order %3.';
        Text1130003: Label 'Components to send to subcontractor do not exist.';
        ManufacturingSetup: Record "Manufacturing Setup";
        Vendor: Record Vendor;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LineNum: Integer;
        PurchOrderNo: Code[20];
        Text1130004: Label 'The Return from Subcontractor has already been created.';

    [Scope('OnPrem')]
    procedure InsertTransferHeader(ToLocationCode: Code[10])
    begin
        TransferHeader.Reset();
        TransferHeader.SetRange("Source Type", TransferHeader."Source Type"::Vendor);
        TransferHeader.SetRange("Source No.", "Purchase Header"."Buy-from Vendor No.");
        TransferHeader.SetRange(Status, TransferHeader.Status::Open);
        TransferHeader.SetRange("Completely Shipped", false);
        TransferHeader.SetRange("Transport Reason Code", ManufacturingSetup."Subcontr. Return Reason Code");
        TransferHeader.SetRange("Transfer-from Code", "Purchase Header"."Subcontracting Location Code");
        TransferHeader.SetRange("Transfer-to Code", ToLocationCode);
        TransferHeader.SetRange("Return Order", true);
        if not TransferHeader.FindFirst() then begin
            TransferHeader.Init();
            TransferHeader."No." := '';
            TransferHeader.Insert(true);

            TransferHeader.Validate("Transport Reason Code", ManufacturingSetup."Subcontr. Return Reason Code");
            TransferHeader.Validate("Transfer-from Code", "Purchase Header"."Subcontracting Location Code");
            TransferHeader.Validate("Transfer-to Code", ToLocationCode);
            TransferHeader."Source Type" := TransferHeader."Source Type"::Vendor;
            TransferHeader."Source No." := "Purchase Header"."Buy-from Vendor No.";
            TransferHeader."Return Order" := true;
            TransferHeader."Transfer-from Name" := Vendor.Name;
            TransferHeader."Transfer-from Name 2" := Vendor."Name 2";
            TransferHeader."Transfer-from Address" := Vendor.Address;
            TransferHeader."Transfer-from Address 2" := Vendor."Address 2";
            TransferHeader."Transfer-from Post Code" := Vendor."Post Code";
            TransferHeader."Transfer-from City" := Vendor.City;
            TransferHeader."Transfer-from County" := Vendor.County;
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

        OnAfterInsertTransferHeader(TransferHeader, Vendor);
    end;

    [Scope('OnPrem')]
    procedure CheckExistComponent(): Boolean
    var
        PurchLine: Record "Purchase Line";
        QtyToPost: Decimal;
    begin
        PurchLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
        PurchLine.SetRange("Document No.", PurchOrderNo);
        PurchLine.SetFilter("Prod. Order No.", '<>''''');
        PurchLine.SetFilter("Prod. Order Line No.", '<>0');
        PurchLine.SetFilter("Operation No.", '<>0');
        if PurchLine.FindSet() then
            repeat
                if CheckPurchLine(PurchLine, false, QtyToPost) then
                    exit(true);
            until PurchLine.Next() = 0;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure CheckPurchLine(PurchLine: Record "Purchase Line"; InsertLine: Boolean; var QtyToPost: Decimal): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderComponent: Record "Prod. Order Component";
        Item: Record Item;
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        UOMMgt: Codeunit "Unit of Measure Management";
        SubcontractingMgt: Codeunit SubcontractingManagement;
        QtyPerUom: Decimal;
    begin
        if not ProdOrderLine.Get(ProdOrderLine.Status::Released, PurchLine."Prod. Order No.", PurchLine."Prod. Order Line No.") then
            exit(false);
        if not ProdOrderRoutingLine.Get(ProdOrderRoutingLine.Status::Released, PurchLine."Prod. Order No.",
             PurchLine."Routing Reference No.", PurchLine."Routing No.", PurchLine."Operation No.")
        then
            Error(Text1130002, PurchOrderNo, PurchLine."Routing No.", PurchLine."Prod. Order No.", PurchLine."Operation No.");

        Item.Get(PurchLine."No.");
        QtyPerUom := UOMMgt.GetQtyPerUnitOfMeasure(Item, PurchLine."Unit of Measure Code");

        if ProdOrderRoutingLine."WIP Item" then begin
            ProdOrderRoutingLine.SetRange("Purchase Order Filter", PurchLine."Document No.");
            ProdOrderRoutingLine.CalcFields("Qty. WIP on Subcontractors");
            QtyToPost := PurchLine."Outstanding Quantity";
            if Round(QtyToPost * QtyPerUom, UOMMgt.QtyRndPrecision()) > ProdOrderRoutingLine."Qty. WIP on Subcontractors" then
                QtyToPost := Round(ProdOrderRoutingLine."Qty. WIP on Subcontractors" / QtyPerUom, UOMMgt.QtyRndPrecision());
            exit(QtyToPost > 0);
        end;

        ProdOrderComponent.SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code");
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", PurchLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", PurchLine."Prod. Order Line No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        ProdOrderComponent.SetRange("Purchase Order Filter", PurchLine."Document No.");
        if ProdOrderComponent.FindSet() then begin
            CheckTransferLineExists();
            repeat
                Item.Get(ProdOrderComponent."Item No.");
                QtyToPost := MfgCostCalcMgt.CalcActNeededQtyBase(ProdOrderLine, ProdOrderComponent,
                    Round(PurchLine."Outstanding Quantity" * QtyPerUom, UOMMgt.QtyRndPrecision()));
                ProdOrderComponent.CalcFields("Qty. in Transit (Base)", "Qty. transf. to Subcontractor");
                if QtyToPost > (ProdOrderComponent."Qty. in Transit (Base)" + ProdOrderComponent."Qty. transf. to Subcontractor") then
                    QtyToPost := (ProdOrderComponent."Qty. in Transit (Base)" + ProdOrderComponent."Qty. transf. to Subcontractor");
                if QtyToPost > 0 then
                    if InsertLine then begin
                        if Vendor."Subcontractor Procurement" then
                            InsertTransferHeader(PurchLine."Location Code")
                        else
                            if ProdOrderComponent."Original Location" <> '' then
                                InsertTransferHeader(ProdOrderComponent."Original Location")
                            else
                                InsertTransferHeader(ProdOrderComponent."Location Code");
                        LineNum := LineNum + 10000;
                        TransferLine.Init();
                        TransferLine."Document No." := TransferHeader."No.";
                        TransferLine."Line No." := LineNum;
                        TransferLine.Validate("Item No.", ProdOrderComponent."Item No.");
                        TransferLine.Validate("Variant Code", ProdOrderComponent."Variant Code");
                        TransferLine."Unit of Measure Code" := ProdOrderComponent."Unit of Measure Code";
                        TransferLine."Qty. per Unit of Measure" := ProdOrderComponent."Qty. per Unit of Measure";
                        TransferLine.Validate(Quantity, Round(QtyToPost / ProdOrderComponent."Qty. per Unit of Measure",
                            Item."Rounding Precision", '>'));
                        TransferLine."Subcontr. Purch. Order No." := PurchLine."Document No.";
                        TransferLine."Subcontr. Purch. Order Line" := PurchLine."Line No.";
                        TransferLine."Prod. Order No." := PurchLine."Prod. Order No.";
                        TransferLine."Prod. Order Line No." := PurchLine."Prod. Order Line No.";
                        TransferLine."Prod. Order Comp. Line No." := ProdOrderComponent."Line No.";
                        TransferLine.Insert();
                        if ProdOrderComponent."Original Location" = '' then
                            ProdOrderComponent."Original Location" := ProdOrderComponent."Location Code";
                        ProdOrderComponent."Location Code" := TransferHeader."Transfer-to Code";
                        ProdOrderComponent.GetDefaultBin();
                        ProdOrderComponent.Modify();
                        SubcontractingMgt.TransfSUBOrdCompToSUBTransfOrd(TransferLine, ProdOrderComponent);
                    end else
                        exit(true);
            until ProdOrderComponent.Next() = 0;
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ShowDocument()
    var
        TransfOrderForm: Page "Subcontr. Transfer Order";
    begin
        Commit();
        TransferHeader.Reset();
        TransferHeader.SetRecFilter();
        TransfOrderForm.SetTableView(TransferHeader);
        TransfOrderForm.Editable(false);
        TransfOrderForm.RunModal();
    end;

    [Scope('OnPrem')]
    procedure CheckTransferLineExists()
    var
        TransferLine2: Record "Transfer Line";
    begin
        if "Purchase Line"."Document No." = '' then
            exit;
        TransferLine2.SetRange("Subcontr. Purch. Order No.", "Purchase Line"."Document No.");
        TransferLine2.SetRange("Subcontr. Purch. Order Line", "Purchase Line"."Line No.");
        TransferLine2.SetRange("Prod. Order No.", "Purchase Line"."Prod. Order No.");
        TransferLine2.SetRange("Prod. Order Line No.", "Purchase Line"."Prod. Order Line No.");
        if TransferLine2.FindFirst() then
            Error(Text1130004);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTransferHeader(var TransferHeader: Record "Transfer Header"; Vendor: Record Vendor)
    begin
    end;
}
#endif
