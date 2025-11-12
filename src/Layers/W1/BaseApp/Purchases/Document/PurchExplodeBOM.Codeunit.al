// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;

using Microsoft.Sales.Document;

codeunit 73 "Purch.-Explode BOM"
{
    TableNo = "Purchase Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        PurchHeader := Rec.GetPurchHeader();
        PurchHeader.TestStatusOpen();
        CheckPurchaseLine(Rec);

        FromBOMComp.SetRange("Parent Item No.", Rec."No.");
        NoOfBOMComp := FromBOMComp.Count();
        OnRunOnAfterSetNoOfBOMComp(FromBOMComp, Rec, NoOfBOMComp);
        if NoOfBOMComp = 0 then
            Error(
              Text001,
              Rec."No.");

        Selection := GetSelection(Rec);
        if Selection = 0 then
            exit;

        InitParentItemLine(Rec);
        if TransferExtendedText.PurchCheckIfAnyExtText(ToPurchLine, false) then
            TransferExtendedText.InsertPurchExtText(ToPurchLine);

        ExplodeBOMCompLines(Rec);
        ClearSpecialSalesOrderLineValuesOnExplodeBOM(Rec);

        OnAfterOnRun(ToPurchLine, Rec);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The BOM cannot be exploded on the purchase lines because it is associated with sales order %1.';
        Text001: Label 'Item %1 is not a BOM.';
#pragma warning restore AA0470
        Text003: Label 'There is not enough space to explode the BOM.';
        Text005: Label '&Copy dimensions from BOM,&Retrieve dimensions from components';
#pragma warning restore AA0074
        ToPurchLine: Record "Purchase Line";
        FromBOMComp: Record "BOM Component";
        PurchHeader: Record "Purchase Header";
        ItemTranslation: Record "Item Translation";
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        LineSpacing: Integer;
        NextLineNo: Integer;
        NoOfBOMComp: Integer;
        Selection: Integer;

    local procedure GetSelection(PurchaseLine: Record "Purchase Line") Result: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSelection(PurchaseLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := StrMenu(Text005, 2);
    end;

    procedure CallExplodeBOMCompLines(PurchLine: Record "Purchase Line")
    begin
        ExplodeBOMCompLines(PurchLine);
    end;

    local procedure ExplodeBOMCompLines(PurchLine: Record "Purchase Line")
    var
        PreviousPurchLine: Record "Purchase Line";
        Resource: Record Resource;
        InsertLinesBetween: Boolean;
        SkipComponent: Boolean;
    begin
        ToPurchLine.Reset();
        ToPurchLine.SetRange("Document Type", PurchLine."Document Type");
        ToPurchLine.SetRange("Document No.", PurchLine."Document No.");
        ToPurchLine := PurchLine;
        NextLineNo := PurchLine."Line No.";
        InsertLinesBetween := false;
        if ToPurchLine.Find('>') then
            if ToPurchLine.IsExtendedText() and (ToPurchLine."Attached to Line No." = PurchLine."Line No.") then begin
                ToPurchLine.SetRange("Attached to Line No.", PurchLine."Line No.");
                ToPurchLine.FindLast();
                ToPurchLine.SetRange("Attached to Line No.");
                NextLineNo := ToPurchLine."Line No.";
                InsertLinesBetween := ToPurchLine.Find('>');
            end else
                InsertLinesBetween := true;
        if InsertLinesBetween then
            LineSpacing := (ToPurchLine."Line No." - NextLineNo) div (1 + NoOfBOMComp)
        else
            LineSpacing := 10000;
        if LineSpacing = 0 then
            Error(Text003);

        FromBOMComp.Find('-');
        OnExplodeBOMCompLinesOnBeforeLoopFromBOMComp(PurchLine, NextLineNo);
        repeat
            SkipComponent := false;
            OnExplodeBOMCompLinesOnBeforeCreatePurchLine(PurchLine, FromBOMComp, SkipComponent);
            if not SkipComponent then begin
                ToPurchLine.Init();
                NextLineNo := NextLineNo + LineSpacing;
                ToPurchLine."Line No." := NextLineNo;
                case FromBOMComp.Type of
                    FromBOMComp.Type::" ":
                        ToPurchLine.Type := ToPurchLine.Type::" ";
                    FromBOMComp.Type::Item:
                        begin
                            Item.Get(FromBOMComp."No.");
                            ToPurchLine.Type := ToPurchLine.Type::Item;
                            ToPurchLine.Validate("No.", FromBOMComp."No.");
                            ToPurchLine.Validate("Variant Code", FromBOMComp."Variant Code");
                            ToPurchLine.Validate("Unit of Measure Code", FromBOMComp."Unit of Measure Code");
                            ToPurchLine."Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, ToPurchLine."Unit of Measure Code");
                            ToPurchLine.Validate(Quantity, Round(PurchLine."Quantity (Base)" * FromBOMComp."Quantity per", UOMMgt.QtyRndPrecision()));
                        end;
                    FromBOMComp.Type::Resource:
                        begin
                            Resource.Get(FromBOMComp."No.");
                            ToPurchLine.Type := ToPurchLine.Type::Resource;
                            ToPurchLine.Validate("No.", FromBOMComp."No.");
                            ToPurchLine.Validate("Variant Code", FromBOMComp."Variant Code");
                            ToPurchLine.Validate("Unit of Measure Code", FromBOMComp."Unit of Measure Code");
                            ToPurchLine."Qty. per Unit of Measure" := UOMMgt.GetResQtyPerUnitOfMeasure(Resource, ToPurchLine."Unit of Measure Code");
                            ToPurchLine.Validate(Quantity, Round(PurchLine."Quantity (Base)" * FromBOMComp."Quantity per", UOMMgt.QtyRndPrecision()));
                        end;
                end;

                if (FromBOMComp.Type <> FromBOMComp.Type::" ") and
                   (PurchHeader."Expected Receipt Date" <> PurchLine."Expected Receipt Date")
                then
                    ToPurchLine.Validate("Expected Receipt Date", PurchLine."Expected Receipt Date");

                if PurchHeader."Language Code" = '' then
                    ToPurchLine.Description := FromBOMComp.Description
                else
                    if not ItemTranslation.Get(FromBOMComp."No.", FromBOMComp."Variant Code", PurchHeader."Language Code") then
                        ToPurchLine.Description := FromBOMComp.Description;

                OnBeforeInsertExplodedPurchLine(ToPurchLine, PurchLine, FromBOMComp, PurchHeader);
                ToPurchLine.Insert();
                OnAfterInsertExplodedPurchLine(ToPurchLine, PurchLine, FromBOMComp);

                if Selection = 1 then begin
                    ToPurchLine."Shortcut Dimension 1 Code" := PurchLine."Shortcut Dimension 1 Code";
                    ToPurchLine."Shortcut Dimension 2 Code" := PurchLine."Shortcut Dimension 2 Code";
                    ToPurchLine."Dimension Set ID" := PurchLine."Dimension Set ID";
                    ToPurchLine.Modify();
                end;

                if PreviousPurchLine."Document No." <> '' then
                    if TransferExtendedText.PurchCheckIfAnyExtText(PreviousPurchLine, false) then
                        TransferExtendedText.InsertPurchExtText(PreviousPurchLine);

                PreviousPurchLine := ToPurchLine;
            end;
        until FromBOMComp.Next() = 0;

        if TransferExtendedText.PurchCheckIfAnyExtText(ToPurchLine, false) then
            TransferExtendedText.InsertPurchExtText(ToPurchLine);
        OnAfterExplodeBOMCompLines(PurchLine, Selection, LineSpacing);
    end;

    local procedure ClearSpecialSalesOrderLineValuesOnExplodeBOM(PurchLine: Record "Purchase Line")
    var
        SalesOrderLine: Record "Sales Line";
    begin
        if PurchLine."Special Order" then begin
            SalesOrderLine.LockTable();
            if SalesOrderLine.Get(
                 SalesOrderLine."Document Type"::Order, PurchLine."Special Order Sales No.", PurchLine."Special Order Sales Line No.")
            then begin
                SalesOrderLine."Special Order Purchase No." := '';
                SalesOrderLine."Special Order Purch. Line No." := 0;
                SalesOrderLine.Modify();
            end;
        end;
    end;

    local procedure CheckPurchaseLine(PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
        PurchaseLine.TestField("Quantity Received", 0);
        PurchaseLine.TestField("Return Qty. Shipped", 0);

        PurchaseLine.CalcFields("Reserved Qty. (Base)");
        PurchaseLine.TestField("Reserved Qty. (Base)", 0);
        if PurchaseLine."Sales Order No." <> '' then
            Error(Text000, PurchaseLine."Sales Order No.");
        OnAfterCheckPurchaseLine(PurchaseLine);
    end;

    local procedure InitParentItemLine(var FromPurchaseLine: Record "Purchase Line")
    begin
        ToPurchLine := FromPurchaseLine;
        ToPurchLine.Init();
        ToPurchLine.Description := FromPurchaseLine.Description;
        ToPurchLine."Description 2" := FromPurchaseLine."Description 2";
        OnRunOnBeforeToPurchLineModify(ToPurchLine, FromPurchaseLine);
        ToPurchLine.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(ToPurchLine: Record "Purchase Line"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExplodeBOMCompLines(var PurchaseLine: Record "Purchase Line"; Selection: Integer; LineSpacing: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSelection(PurchaseLine: Record "Purchase Line"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertExplodedPurchLine(var ToPurchaseLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line"; FromBOMComp: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExplodedPurchLine(var ToPurchaseLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line"; FromBOMComp: Record "BOM Component"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExplodeBOMCompLinesOnBeforeCreatePurchLine(PurchaseLine: Record "Purchase Line"; BOMComponent: Record "BOM Component"; var IsAvailable: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeToPurchLineModify(var ToPurchLine: Record "Purchase Line"; RecPurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPurchaseLine(PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSetNoOfBOMComp(FromBOMComponent: Record "BOM Component"; PurchaseLine: Record "Purchase Line"; var NoOfBOMComp: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExplodeBOMCompLinesOnBeforeLoopFromBOMComp(PurchaseLine: Record "Purchase Line"; var NextLineNo: Integer)
    begin
    end;
}

