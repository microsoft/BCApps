// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Company;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

report 99001502 "Subc. Create SubCReturnOrder"
{
    ApplicationArea = Manufacturing;
    Caption = 'Create Subcontracting Return Order';
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
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") order(ascending) where("Prod. Order No." = filter(<> ''));
                trigger OnAfterGetRecord()
                var
                    QtyToPost: Decimal;
                begin
                    HandleSubcontractingForPurchLine("Purchase Line", true, QtyToPost);
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
        ComponentsDoesNotExistErr: Label 'Components to return from subcontractor do not exist.';
        OrderNoDoesNotExistInProdOrderErr: Label 'Operation %1 in the subcontracting order %2 does not exist in the routing %3 of the production order %4.', Comment = '%1=Operation No., %2=Purchase Order No., %3=Routing No., %4=Production Order No.';
        OrderNoIsNotSubcontractorErr: Label 'Order %1 is not a Subcontractor work.', Comment = '%1=Purchase Order No.';
        ReturnTransferOrderAlreadyCreatedErr: Label 'The Return from Subcontractor has already been created.';
        WarningToSpecifyPurchOrderErr: Label 'Warning. Specify a Purchase Order No. for the Subcontractor work.';

    local procedure InsertTransferHeader(SubcontractingType: Enum "Subcontracting Type"; OrigCompLineLocation: Code[10])
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
        TransferFromLocationCode, TransferToLocationCode : Code[10];
    begin
        if not SubcManagementSetup.Get() then
            Clear(SubcManagementSetup);

        GetTransferFromLocationCode(TransferFromLocationCode);
        GetTransferToLocationCode(TransferToLocationCode, SubcontractingType);

        TransferHeader.Reset();
        TransferHeader.SetRange("Source Subtype", TransferHeader."Source Subtype"::"2");
        TransferHeader.SetRange("Source ID", "Purchase Header"."Buy-from Vendor No.");
        TransferHeader.SetRange(Status, TransferHeader.Status::Open);
        TransferHeader.SetRange("Completely Shipped", false);
        TransferHeader.SetRange("Transfer-from Code", TransferFromLocationCode);
        TransferHeader.SetRange("Transfer-to Code", OrigCompLineLocation);
        TransferHeader.SetRange("Return Order", true);
        if not TransferHeader.FindFirst() then begin
            TransferHeader.Init();
            TransferHeader."No." := '';
            TransferHeader.Insert(true);

            TransferHeader.Validate("Transfer-from Code", TransferFromLocationCode);
            TransferHeader.Validate("Transfer-to Code", OrigCompLineLocation);

            if SubcManagementSetup."Direct Transfer" then begin
                SubcontractingManagement.CheckDirectTransferIsAllowedForTransferHeader(TransferHeader);
                TransferHeader.Validate("Direct Transfer Posting", "Direct Transfer Post. Type"::"Direct Transfer");
            end;

            TransferHeader."Source Type" := TransferHeader."Source Type"::Subcontracting;
            TransferHeader."Source Subtype" := TransferHeader."Source Subtype"::"2";
            TransferHeader."Source ID" := "Purchase Header"."Buy-from Vendor No.";
            TransferHeader."Subcontr. Purch. Order No." := "Purchase Header"."No.";
            TransferHeader."Subcontr. PO Line No." := "Purchase Line"."Line No.";
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
    end;

    local procedure CheckExistComponent(): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        QtyToPost: Decimal;
    begin
        PurchaseLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
        PurchaseLine.SetRange("Document No.", PurchOrderNo);
        PurchaseLine.SetFilter("Prod. Order No.", '<>''''');
        PurchaseLine.SetFilter("Prod. Order Line No.", '<>0');
        PurchaseLine.SetFilter("Operation No.", '<>0');
        if PurchaseLine.FindSet() then
            repeat
                if HandleSubcontractingForPurchLine(PurchaseLine, false, QtyToPost) then
                    exit(true);
            until PurchaseLine.Next() = 0;

        exit(false);
    end;

    local procedure HandleSubcontractingForPurchLine(PurchaseLine: Record "Purchase Line"; InsertLine: Boolean; var QtyToPost: Decimal): Boolean
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        MfgCostCalculationMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        SubcontractingManagement: Codeunit "Subcontracting Management";
        UnitofMeasureManagement: Codeunit "Unit of Measure Management";
        QtyPerUom: Decimal;
    begin
        if not ProdOrderLine.Get(ProdOrderLine.Status::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
            exit(false);

        if not ProdOrderRoutingLine.Get(ProdOrderRoutingLine.Status::Released, PurchaseLine."Prod. Order No.",
             PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.")
        then
            Error(OrderNoDoesNotExistInProdOrderErr, PurchaseLine."Operation No.", PurchOrderNo, PurchaseLine."Routing No.", PurchaseLine."Prod. Order No.");

        Item.SetLoadFields("Base Unit of Measure", "Rounding Precision");
        Item.Get(PurchaseLine."No.");
        QtyPerUom := UnitofMeasureManagement.GetQtyPerUnitOfMeasure(Item, PurchaseLine."Unit of Measure Code");

        ProdOrderComponent.SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code");
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        ProdOrderComponent.SetRange("Purchase Order Filter", PurchaseLine."Document No.");
        ProdOrderComponent.SetRange("Subcontracting Type", ProdOrderComponent."Subcontracting Type"::Transfer);
        if ProdOrderComponent.FindSet() then begin
            CheckTransferLineExists();
            repeat
                Item.Get(ProdOrderComponent."Item No.");
                QtyToPost := MfgCostCalculationMgt.CalcActNeededQtyBase(ProdOrderLine, ProdOrderComponent,
                    Round(PurchaseLine."Outstanding Quantity" * QtyPerUom, UnitofMeasureManagement.QtyRndPrecision()));
                ProdOrderComponent.CalcFields("Qty. in Transit (Base)", "Qty. transf. to Subcontr");
                if QtyToPost > (Abs(ProdOrderComponent."Qty. in Transit (Base)") + Abs(ProdOrderComponent."Qty. transf. to Subcontr")) then
                    QtyToPost := (Abs(ProdOrderComponent."Qty. in Transit (Base)") + Abs(ProdOrderComponent."Qty. transf. to Subcontr"));
                if QtyToPost > 0 then
                    if InsertLine then begin

                        InsertTransferHeader(ProdOrderComponent."Subcontracting Type", ProdOrderComponent."Orig. Location Code");

                        LineNum := LineNum + 10000;

                        TransferLine.Init();
                        TransferLine."Document No." := TransferHeader."No.";
                        TransferLine."Line No." := LineNum;
                        TransferLine.Validate("Item No.", ProdOrderComponent."Item No.");
                        TransferLine.Validate("Variant Code", ProdOrderComponent."Variant Code");
                        TransferLine."Unit of Measure Code" := ProdOrderComponent."Unit of Measure Code";
                        TransferLine."Qty. per Unit of Measure" := ProdOrderComponent."Qty. per Unit of Measure";
                        TransferLine.Validate(Quantity, Round(QtyToPost / ProdOrderComponent."Qty. per Unit of Measure", Item."Rounding Precision", '>'));
                        TransferLine."Subcontr. Purch. Order No." := PurchaseLine."Document No.";
                        TransferLine."Subcontr. PO Line No." := PurchaseLine."Line No.";
                        TransferLine."Prod. Order No." := PurchaseLine."Prod. Order No.";
                        TransferLine."Prod. Order Line No." := PurchaseLine."Prod. Order Line No.";
                        TransferLine."Prod. Order Comp. Line No." := ProdOrderComponent."Line No.";

                        TransferLine.Insert();

                        SubcontractingManagement.TransferReservationEntryFromProdOrderCompToTransferOrder(TransferLine, ProdOrderComponent);

                        if ProdOrderComponent."Orig. Location Code" = '' then
                            ProdOrderComponent."Orig. Location Code" := ProdOrderComponent."Location Code";
                        if ProdOrderComponent."Orig. Bin Code" = '' then
                            ProdOrderComponent."Orig. Bin Code" := ProdOrderComponent."Bin Code";
                        if TransferHeader."Transfer-to Code" <> ProdOrderComponent."Location Code" then begin
                            ProdOrderComponent.Validate("Location Code", TransferHeader."Transfer-to Code");
                            ProdOrderComponent.GetDefaultBin();
                        end;
                        ProdOrderComponent.Modify();

                        SubcontractingManagement.CreateReservEntryForTransferReceiptToProdOrderComp(TransferLine, ProdOrderComponent);
                    end else
                        exit(true);
            until ProdOrderComponent.Next() = 0;
        end;
        exit(false);
    end;

    local procedure ShowDocument()
    begin
        Commit(); // Used for following call of Transfer Order Pages
        TransferHeader.Reset();
        TransferHeader.SetCurrentKey("Subcontr. Purch. Order No.");
        TransferHeader.SetRange("Subcontr. Purch. Order No.", "Purchase Line"."Document No.");
        TransferHeader.SetRecFilter();
        if TransferHeader.Count() > 1 then
            Page.Run(Page::"Transfer Orders", TransferHeader)
        else
            Page.Run(Page::"Transfer Order", TransferHeader);
    end;

    local procedure CheckTransferLineExists()
    var
        TransferLine2: Record "Transfer Line";
    begin
        if "Purchase Line"."Document No." = '' then
            exit;
        TransferLine2.SetRange("Subcontr. Purch. Order No.", "Purchase Line"."Document No.");
        TransferLine2.SetRange("Subcontr. PO Line No.", "Purchase Line"."Line No.");
        TransferLine2.SetRange("Prod. Order No.", "Purchase Line"."Prod. Order No.");
        TransferLine2.SetRange("Prod. Order Line No.", "Purchase Line"."Prod. Order Line No.");
        if not TransferLine2.IsEmpty() then
            Error(ReturnTransferOrderAlreadyCreatedErr);
    end;

    local procedure GetTransferToLocationCode(var TransferFromLocationCode: Code[10]; SubcontractingType: Enum "Subcontracting Type")
    var
        CompanyInformation: Record "Company Information";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if SubcontractingType = "Subcontracting Type"::Purchase then
            TransferFromLocationCode := "Purchase Line"."Location Code"
        else begin
            SubcManagementSetup.TestField("Component at Location");
            case SubcManagementSetup."Component at Location" of
                "Components at Location"::Purchase:
                    begin
                        "Purchase Line".TestField("Location Code");
                        TransferFromLocationCode := "Purchase Line"."Location Code";
                    end;
                "Components at Location"::Company:
                    begin
                        CompanyInformation.Get();
                        CompanyInformation.TestField("Location Code");
                        TransferFromLocationCode := CompanyInformation."Location Code";
                    end;
                "Components at Location"::Manufacturing:
                    begin
                        ManufacturingSetup.Get();
                        ManufacturingSetup.TestField("Components at Location");
                        TransferFromLocationCode := ManufacturingSetup."Components at Location";
                    end;
                else
            end;
        end;
    end;

    local procedure GetTransferFromLocationCode(var TransferToLocationCode: Code[10])
    begin
        TransferToLocationCode := "Purchase Header"."Subc. Location Code";
        if TransferToLocationCode = '' then begin
            TransferToLocationCode := Vendor."Subcontr. Location Code";
            if TransferToLocationCode = '' then
                Vendor.TestField("Subcontr. Location Code");
        end;
    end;
}