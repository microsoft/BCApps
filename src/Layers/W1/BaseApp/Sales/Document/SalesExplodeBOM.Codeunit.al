// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Resources.Resource;

codeunit 63 "Sales-Explode BOM"
{
    TableNo = "Sales Line";

    trigger OnRun()
    var
        AssembleToOrderLink: Record "Assemble-to-Order Link";
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        SalesHeader := Rec.GetSalesHeader();
        SalesHeader.TestStatusOpen();
        CheckSalesLine(Rec);

        ReservMgt.SetReservSource(Rec);
        ReservMgt.SetItemTrackingHandling(1);
        ReservMgt.DeleteReservEntries(true, 0);

        FromBOMComp.SetRange("Parent Item No.", Rec."No.");
        OnRunOnBeforeCalcNoOfBOMComp(FromBOMComp, Rec);
        NoOfBOMComp := FromBOMComp.Count();

        OnBeforeConfirmExplosion(Rec, Selection, HideDialog, NoOfBOMComp);

        if not HideDialog then begin
            if NoOfBOMComp = 0 then
                Error(Text001, Rec."No.");

            Selection := StrMenu(Text004, 2);
            if Selection = 0 then
                exit;
        end else
            Selection := 2;

        OnAfterConfirmExplosion(Rec, Selection, HideDialog);

        if Rec."Document Type" in [Rec."Document Type"::Order, Rec."Document Type"::Invoice] then begin
            ToSalesLine := Rec;
            FromBOMComp.SetRange(Type, FromBOMComp.Type::Item);
            FromBOMComp.SetFilter("No.", '<>%1', '');
            IsHandled := false;
            OnRunOnAfterFromBOMCompSetFilters(FromBOMComp, Rec, IsHandled, ToSalesLine);
            if not IsHandled then
                if FromBOMComp.FindSet() then
                    repeat
                        FromBOMComp.TestField(Type, FromBOMComp.Type::Item);
                        OnBeforeCopyFromBOMToSalesLine(ToSalesLine, FromBOMComp);
                        Item.Get(FromBOMComp."No.");
                        ToSalesLine."Line No." := 0;
                        ToSalesLine."No." := FromBOMComp."No.";
                        ToSalesLine."Variant Code" := FromBOMComp."Variant Code";
                        ToSalesLine."Unit of Measure Code" := FromBOMComp."Unit of Measure Code";
                        ToSalesLine."Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, FromBOMComp."Unit of Measure Code");
                        ToSalesLine."Outstanding Quantity" := Round(Rec."Quantity (Base)" * FromBOMComp."Quantity per", UOMMgt.QtyRndPrecision());
                        IsHandled := false;
                        OnRunOnBeforeItemCheckAvailSalesLineCheck(ToSalesLine, FromBOMComp, Rec, IsHandled, HideDialog);
                        if not IsHandled then
                            if ToSalesLine."Outstanding Quantity" > 0 then
                                if ItemCheckAvail.SalesLineCheck(ToSalesLine) then
                                    ItemCheckAvail.RaiseUpdateInterruptedError();
                    until FromBOMComp.Next() = 0;
        end;

        if Rec."BOM Item No." = '' then
            BOMItemNo := Rec."No."
        else
            BOMItemNo := Rec."BOM Item No.";

        if Rec.Type = Rec.Type::Item then
            AssembleToOrderLink.DeleteAsmFromSalesLine(Rec);

        InitParentItemLine(Rec);
        if TransferExtendedText.SalesCheckIfAnyExtText(ToSalesLine, false) then
            TransferExtendedText.InsertSalesExtText(ToSalesLine);

        IsHandled := false;
        OnRunOnBeforeExplodeBOMCompLines(Rec, ToSalesLine, NoOfBOMComp, Selection, IsHandled, BOMItemNo);
        if not IsHandled then
            ExplodeBOMCompLines(Rec);

        OnAfterOnRun(ToSalesLine, Rec);
    end;

    var
        ToSalesLine: Record "Sales Line";
        FromBOMComp: Record "BOM Component";
        SalesHeader: Record "Sales Header";
        ItemTranslation: Record "Item Translation";
        Item: Record Item;
        Resource: Record Resource;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        UOMMgt: Codeunit "Unit of Measure Management";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        ReservMgt: Codeunit "Reservation Management";
        BOMItemNo: Code[20];
        LineSpacing: Integer;
        NextLineNo: Integer;
        NoOfBOMComp: Integer;
        Selection: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The BOM cannot be exploded on the sales lines because it is associated with purchase order %1.';
        Text001: Label 'Item %1 is not a BOM.';
#pragma warning restore AA0470
        Text003: Label 'There is not enough space to explode the BOM.';
        Text004: Label '&Copy dimensions from BOM,&Retrieve dimensions from components';
#pragma warning restore AA0074

    procedure CallExplodeBOMCompLines(SalesLine: Record "Sales Line")
    begin
        ExplodeBOMCompLines(SalesLine);
    end;

    local procedure ExplodeBOMCompLines(SalesLine: Record "Sales Line")
    var
        PreviousSalesLine: Record "Sales Line";
        InsertLinesBetween: Boolean;
    begin
        ToSalesLine.Reset();
        ToSalesLine.SetRange("Document Type", SalesLine."Document Type");
        ToSalesLine.SetRange("Document No.", SalesLine."Document No.");
        ToSalesLine := SalesLine;
        NextLineNo := SalesLine."Line No.";
        InsertLinesBetween := false;
        if ToSalesLine.Find('>') then
            if ToSalesLine.IsExtendedText() and (ToSalesLine."Attached to Line No." = SalesLine."Line No.") then begin
                ToSalesLine.SetRange("Attached to Line No.", SalesLine."Line No.");
                ToSalesLine.FindLast();
                ToSalesLine.SetRange("Attached to Line No.");
                NextLineNo := ToSalesLine."Line No.";
                InsertLinesBetween := ToSalesLine.Find('>');
            end else
                InsertLinesBetween := true;
        if InsertLinesBetween then
            LineSpacing := (ToSalesLine."Line No." - NextLineNo) div (1 + NoOfBOMComp)
        else
            LineSpacing := 10000;
        if LineSpacing = 0 then
            Error(Text003);

        FromBOMComp.Reset();
        FromBOMComp.SetRange("Parent Item No.", SalesLine."No.");
        OnExplodeBOMCompLinesOnAfterFromBOMCompSetFilters(FromBOMComp, SalesLine, LineSpacing, NextLineNo);
        FromBOMComp.FindSet();
        repeat
            ToSalesLine.Init();
            NextLineNo := NextLineNo + LineSpacing;
            ToSalesLine."Line No." := NextLineNo;

            case FromBOMComp.Type of
                FromBOMComp.Type::" ":
                    ToSalesLine.Type := ToSalesLine.Type::" ";
                FromBOMComp.Type::Item:
                    ToSalesLine.Type := ToSalesLine.Type::Item;
                FromBOMComp.Type::Resource:
                    ToSalesLine.Type := ToSalesLine.Type::Resource;
            end;
            OnExplodeBOMCompLinesOnAfterAssignType(ToSalesLine, SalesLine, FromBOMComp, SalesHeader);
            if ToSalesLine.Type <> ToSalesLine.Type::" " then begin
                FromBOMComp.TestField("No.");
                ToSalesLine.Validate("No.", FromBOMComp."No.");
                if SalesHeader."Location Code" <> SalesLine."Location Code" then
                    ToSalesLine.Validate("Location Code", SalesLine."Location Code");
                if FromBOMComp."Variant Code" <> '' then
                    ToSalesLine.Validate("Variant Code", FromBOMComp."Variant Code");
                if ToSalesLine.Type = ToSalesLine.Type::Item then begin
                    ToSalesLine."Drop Shipment" := SalesLine."Drop Shipment";
                    Item.Get(FromBOMComp."No.");
                    ToSalesLine.Validate("Unit of Measure Code", FromBOMComp."Unit of Measure Code");
                    ToSalesLine."Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, ToSalesLine."Unit of Measure Code");
                    ToSalesLine.Validate(Quantity, Round(SalesLine."Quantity (Base)" * FromBOMComp."Quantity per", UOMMgt.QtyRndPrecision()));
                end else
                    if ToSalesLine.Type = ToSalesLine.Type::Resource then begin
                        Resource.Get(FromBOMComp."No.");
                        ToSalesLine.Validate("Unit of Measure Code", FromBOMComp."Unit of Measure Code");
                        ToSalesLine."Qty. per Unit of Measure" := UOMMgt.GetResQtyPerUnitOfMeasure(Resource, ToSalesLine."Unit of Measure Code");
                        ToSalesLine.Validate(Quantity, Round(SalesLine."Quantity (Base)" * FromBOMComp."Quantity per", UOMMgt.QtyRndPrecision()));
                    end else
                        ToSalesLine.Validate(Quantity, SalesLine."Quantity (Base)" * FromBOMComp."Quantity per");

                if SalesHeader."Shipment Date" <> SalesLine."Shipment Date" then
                    ToSalesLine.Validate("Shipment Date", SalesLine."Shipment Date");
            end;
            if SalesHeader."Language Code" = '' then
                ToSalesLine.Description := FromBOMComp.Description
            else
                if not ItemTranslation.Get(FromBOMComp."No.", FromBOMComp."Variant Code", SalesHeader."Language Code") then
                    ToSalesLine.Description := FromBOMComp.Description;

            ToSalesLine."BOM Item No." := BOMItemNo;

            OnInsertOfExplodedBOMLineToSalesLine(ToSalesLine, SalesLine, FromBOMComp, SalesHeader, LineSpacing);

            ToSalesLine.Insert();
            OnExplodeBOMCompLinesOnAfterToSalesLineInsert(ToSalesLine, SalesLine, FromBOMComp, SalesHeader, NextLineNo);

            ToSalesLine.Validate("Qty. to Assemble to Order");

            if (ToSalesLine.Type = ToSalesLine.Type::Item) and (ToSalesLine.Reserve = ToSalesLine.Reserve::Always) then
                ToSalesLine.AutoReserve();

            if Selection = 1 then begin
                ToSalesLine."Shortcut Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
                ToSalesLine."Shortcut Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
                ToSalesLine."Dimension Set ID" := SalesLine."Dimension Set ID";
                ToSalesLine.Modify();
            end;

            if PreviousSalesLine."Document No." <> '' then
                if TransferExtendedText.SalesCheckIfAnyExtText(PreviousSalesLine, false) then
                    TransferExtendedText.InsertSalesExtText(PreviousSalesLine);

            PreviousSalesLine := ToSalesLine;
        until FromBOMComp.Next() = 0;

        if TransferExtendedText.SalesCheckIfAnyExtText(ToSalesLine, false) then
            TransferExtendedText.InsertSalesExtText(ToSalesLine);

        OnAfterExplodeBOMCompLines(SalesLine, Selection, LineSpacing);
    end;

    local procedure CheckSalesLine(SalesLine: Record "Sales Line")
    begin
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("Quantity Shipped", 0);
        SalesLine.TestField("Return Qty. Received", 0);

        SalesLine.CalcFields("Reserved Qty. (Base)");
        SalesLine.TestField("Reserved Qty. (Base)", 0);

        if SalesLine."Purch. Order Line No." <> 0 then
            Error(Text000, SalesLine."Purchase Order No.");
        if SalesLine."Job Contract Entry No." <> 0 then begin
            SalesLine.TestField("Job No.", '');
            SalesLine.TestField("Job Contract Entry No.", 0);
        end;

        OnAfterCheckSalesLine(SalesLine);
    end;

    local procedure InitParentItemLine(var FromSalesLine: Record "Sales Line")
    begin
        ToSalesLine := FromSalesLine;
        ToSalesLine.Init();
        ToSalesLine.Description := FromSalesLine.Description;
        ToSalesLine."Description 2" := FromSalesLine."Description 2";
        ToSalesLine."BOM Item No." := BOMItemNo;
        OnBeforeToSalesLineModify(ToSalesLine, FromSalesLine);
        ToSalesLine.Modify();
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmExplosion(var SalesLine: Record "Sales Line"; var Selection: Integer; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExplodeBOMCompLines(var SalesLine: Record "Sales Line"; Selection: Integer; LineSpacing: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmExplosion(var SalesLine: Record "Sales Line"; var Selection: Integer; var HideDialog: Boolean; var NoOfBOMComp: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromBOMToSalesLine(var SalesLine: Record "Sales Line"; BOMComponent: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExplodeBOMCompLinesOnAfterFromBOMCompSetFilters(var BOMComponent: Record "BOM Component"; SalesLine: Record "Sales Line"; var LineSpacing: Integer; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToSalesLineModify(var ToSalesLine: Record "Sales Line"; FromSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOfExplodedBOMLineToSalesLine(var ToSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line"; BOMComponent: Record "BOM Component"; var SalesHeader: Record "Sales Header"; LineSpacing: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeItemCheckAvailSalesLineCheck(var ToSalesLine: Record "Sales Line"; FromBOMComp: Record "BOM Component"; SalesLine: Record "Sales Line"; var IsHandled: Boolean; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExplodeBOMCompLinesOnAfterToSalesLineInsert(ToSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line"; FromBOMComp: Record "BOM Component"; SalesHeader: Record "Sales Header"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExplodeBOMCompLinesOnAfterAssignType(var ToSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line"; BOMComponent: Record "BOM Component"; var SalesHeader: Record "Sales Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(ToSalesLine: Record "Sales Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCalcNoOfBOMComp(var BOMComponent: Record "BOM Component"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterFromBOMCompSetFilters(var BOMComponent: Record "BOM Component"; SalesLine: Record "Sales Line"; var IsHandled: Boolean; var ToSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeExplodeBOMCompLines(var SalesLine: Record "Sales Line"; var ToSalesLine: Record "Sales Line"; var NoOfBOMComp: Integer; var Selection: Integer; var IsHandled: Boolean; var BOMItemNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSalesLine(SalesLine: Record "Sales Line")
    begin
    end;
}

