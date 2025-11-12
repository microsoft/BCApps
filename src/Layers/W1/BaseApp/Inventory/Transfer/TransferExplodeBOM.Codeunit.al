// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using System.Utilities;

codeunit 67 "Transfer-Explode BOM"
{
    TableNo = "Transfer Line";

    trigger OnRun()
    var
        TransferHeader: Record "Transfer Header";
        ConfirmManagement: Codeunit "Confirm Management";
        ReservationManagement: Codeunit "Reservation Management";
        IsHandled: Boolean;
        NotBOMErr: Label 'Item %1 is not a BOM.', Comment = '%1 - Item No.';
        BOMContainsNonItemLinesQst: Label 'The BOM %1 has non item lines. These lines will be skipped. Do you want to continue?', Comment = '%1 - Item No.';
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        TransferHeader := Rec.GetTransferHeader();
        TransferHeader.TestStatusOpen();
        CheckTransferLine(Rec);

        ReservationManagement.SetReservSource(Rec, Enum::"Transfer Direction"::Outbound);
        ReservationManagement.SetItemTrackingHandling(1);
        ReservationManagement.DeleteReservEntries(true, 0);
        Clear(ReservationManagement);
        ReservationManagement.SetReservSource(Rec, Enum::"Transfer Direction"::Inbound);
        ReservationManagement.SetItemTrackingHandling(1);
        ReservationManagement.DeleteReservEntries(true, 0);

        FromBOMComponent.SetRange("Parent Item No.", Rec."Item No.");
        FromBOMComponent.SetRange(Type, FromBOMComponent.Type::Item);

        NoOfBOMComponents := FromBOMComponent.Count();
        if NoOfBOMComponents = 0 then
            Error(NotBOMErr, Rec."Item No.");

        IsHandled := false;
        OnBeforeConfirmBOMContainsNonItemLines(Rec, IsHandled);
        if not IsHandled then begin
            FromBOMComponent.SetFilter(Type, '<>%1', FromBOMComponent.Type::Item);
            if not FromBOMComponent.IsEmpty() then
                if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(BOMContainsNonItemLinesQst, Rec."Item No."), true) then
                    Error('');
            FromBOMComponent.SetRange(Type, FromBOMComponent.Type::Item);
        end;

        Selection := GetSelection(Rec);
        if Selection = 0 then
            exit;

        InitParentItemLine(Rec);
        ExplodeBOMComponentLines(Rec);

        OnAfterOnRun(ToTransferLine, Rec);
    end;

    var
        ToTransferLine: Record "Transfer Line";
        FromBOMComponent: Record "BOM Component";
        NoOfBOMComponents: Integer;
        Selection: Integer;

    local procedure GetSelection(TransferLine: Record "Transfer Line") Result: Integer
    var
        IsHandled: Boolean;
        CopyOrRetrieveDimensionsQst: Label '&Copy dimensions from BOM,&Retrieve dimensions from components';
    begin
        IsHandled := false;
        OnBeforeGetSelection(TransferLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Result := StrMenu(CopyOrRetrieveDimensionsQst, 2);
    end;

    local procedure ExplodeBOMComponentLines(TransferLine: Record "Transfer Line")
    var
        Item: Record Item;
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        LineSpacing: Integer;
        NextLineNo: Integer;
        SkipComponent: Boolean;
        NotEnoughSpaceErr: Label 'There is not enough space to explode the BOM.';
    begin
        ToTransferLine.Reset();
        ToTransferLine.SetRange("Document No.", TransferLine."Document No.");
        ToTransferLine := TransferLine;


        NextLineNo := TransferLine."Line No.";
        LineSpacing := 10000;
        if ToTransferLine.Find('>') then
            LineSpacing := (ToTransferLine."Line No." - NextLineNo) div (1 + NoOfBOMComponents);
        if LineSpacing = 0 then
            Error(NotEnoughSpaceErr);

        FromBOMComponent.FindSet();
        repeat
            FromBOMComponent.TestField(Type, FromBOMComponent.Type::Item);
            SkipComponent := false;
            OnExplodeBOMComponentLinesOnBeforeCreateTransferLine(TransferLine, FromBOMComponent, SkipComponent);
            if not SkipComponent then begin
                ToTransferLine.Init();
                NextLineNo := NextLineNo + LineSpacing;
                ToTransferLine."Line No." := NextLineNo;

                Item.Get(FromBOMComponent."No.");
                ToTransferLine.Validate("Item No.", FromBOMComponent."No.");
                ToTransferLine.Validate("Variant Code", FromBOMComponent."Variant Code");
                ToTransferLine.Validate("Unit of Measure Code", FromBOMComponent."Unit of Measure Code");
                ToTransferLine."Qty. per Unit of Measure" := UnitOfMeasureManagement.GetQtyPerUnitOfMeasure(Item, ToTransferLine."Unit of Measure Code");
                ToTransferLine.Validate(Quantity, Round(TransferLine."Quantity (Base)" * FromBOMComponent."Quantity per", UnitOfMeasureManagement.QtyRndPrecision()));
                ToTransferLine.Description := FromBOMComponent.Description;

                OnBeforeInsertExplodedTransferLine(ToTransferLine, TransferLine, FromBOMComponent);
                ToTransferLine.Insert();
                OnAfterInsertExplodedTransferLine(ToTransferLine, TransferLine, FromBOMComponent);

                if Selection = 1 then begin
                    ToTransferLine."Shortcut Dimension 1 Code" := TransferLine."Shortcut Dimension 1 Code";
                    ToTransferLine."Shortcut Dimension 2 Code" := TransferLine."Shortcut Dimension 2 Code";
                    ToTransferLine."Dimension Set ID" := TransferLine."Dimension Set ID";
                    ToTransferLine.Modify();
                end;
            end;
        until FromBOMComponent.Next() = 0;

        OnAfterExplodeBOMComponentLines(TransferLine, Selection, LineSpacing);
    end;

    local procedure CheckTransferLine(TransferLine: Record "Transfer Line")
    begin
        TransferLine.TestField("Quantity Shipped", 0);
        TransferLine.TestField("Quantity Received", 0);

        TransferLine.CalcFields("Reserved Qty. Outbnd. (Base)", "Reserved Qty. Inbnd. (Base)");
        TransferLine.TestField("Reserved Qty. Outbnd. (Base)", 0);
        TransferLine.TestField("Reserved Qty. Inbnd. (Base)", 0);
        OnAfterCheckTransferLine(TransferLine);
    end;

    local procedure InitParentItemLine(var FromTransferLine: Record "Transfer Line")
    begin
        ToTransferLine := FromTransferLine;
        ToTransferLine.Init();
        ToTransferLine.Description := FromTransferLine.Description;
        ToTransferLine."Description 2" := FromTransferLine."Description 2";
        OnRunOnBeforeToTransferLineModify(ToTransferLine, FromTransferLine);
        ToTransferLine.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(ToTransferLine: Record "Transfer Line"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExplodeBOMComponentLines(var TransferLine: Record "Transfer Line"; Selection: Integer; LineSpacing: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSelection(TransferLine: Record "Transfer Line"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertExplodedTransferLine(var ToTransferLine: Record "Transfer Line"; TransferLine: Record "Transfer Line"; FromBOMComp: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExplodedTransferLine(var ToTransferLine: Record "Transfer Line"; TransferLine: Record "Transfer Line"; FromBOMComp: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExplodeBOMComponentLinesOnBeforeCreateTransferLine(TransferLine: Record "Transfer Line"; BOMComponent: Record "BOM Component"; var IsAvailable: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeToTransferLineModify(var ToTransferLine: Record "Transfer Line"; RecTransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTransferLine(TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmBOMContainsNonItemLines(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;
}

