// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

using Microsoft.Warehouse.Structure;
using Microsoft.Manufacturing.Document;

codeunit 7351 "Create Prod. Movement Wksht."
{
    procedure SetContext(NewWorksheetTemplName: Code[10]; NewWorksheetName: Text; NewLocationCode: Code[10]; NewFromBinCode: Code[20]; NewToBinCode: Code[20]; NewToZoneCode: Code[20])
    begin
        WorksheetTemplName := NewWorksheetTemplName;
        WorksheetName := NewWorksheetName;
        LocationCode := NewLocationCode;
        FromBinCode := NewFromBinCode;
        ToBinCode := NewToBinCode;
        ToZoneCode := NewToZoneCode;
    end;

    procedure StartMovement()
    var
        BinContent: Record "Bin Content";
    begin
        ValidateInput();
        RemoveExistingLines();
        FilterBinContent(BinContent, LocationCode, FromBinCode);
        OpenDialog();
        CreateMovementWorksheetLinesForBin(BinContent);
        CloseDialog();

        if Counter > 0 then
            Message(MovementLinesCreatedMsg, Counter)
        else
            Message(NoMovementLinesCreatedMsg);
    end;

    local procedure RemoveExistingLines()
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        WhseWorksheetLine.SetLoadFields("Worksheet Template Name", Name, "Location Code");
        WhseWorksheetLine.SetRange("Worksheet Template Name", WorksheetTemplName);
        WhseWorksheetLine.SetRange(Name, WorksheetName);
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        if not WhseWorksheetLine.IsEmpty() then
            WhseWorksheetLine.DeleteAll(true);
    end;

    local procedure ValidateInput()
    begin
        if ToZoneCode = '' then
            Error(ToZoneCannotBeBlankErr);

        if ToBinCode = '' then
            Error(ToBinCannotBeBlankErr);

        if WorksheetTemplName = '' then
            Error(WorksheetTemplateNameCannotBeBlankErr);

        if WorksheetName = '' then
            Error(WorksheetNameCannotBeBlankErr);

        if FromBinCode = '' then
            Error(BinCodeCannotBeBlankErr);
    end;

    local procedure FilterBinContent(var BinContent: Record "Bin Content"; LocationCode: Code[10]; BinCode: Code[20])
    begin
        BinContent.Reset();
        BinContent.SetRange("Location Code", LocationCode);
        if BinCode <> '' then
            BinContent.SetRange("Bin Code", BinCode);
    end;

    local procedure CreateMovementWorksheetLinesForBin(var BinContent: Record "Bin Content")
    var
        LineNo: Integer;
    begin
        BinContent.SetAutoCalcFields("Quantity (Base)");
        if BinContent.FindSet() then
            repeat
                ProcessBinContent(BinContent, LineNo);
                UpdateDialog(BinContent);
            until BinContent.Next() = 0;
    end;

    local procedure ProcessBinContent(BinContent: Record "Bin Content"; var LineNo: Integer)
    var
        RemainingQty: Decimal;
        ShouldCreateMovementWorksheet: Boolean;
    begin
        GetRemainingQty(BinContent, ShouldCreateMovementWorksheet, RemainingQty);
        if not ShouldCreateMovementWorksheet then
            exit;

        if (BinContent."Quantity (Base)" - RemainingQty) > 0 then
            CreateMovementWorksheetLine(BinContent, LineNo, BinContent."Quantity (Base)" - RemainingQty);
    end;

    local procedure GetRemainingQty(BinContent: Record "Bin Content"; var ShouldCreateMovementWorksheet: Boolean; var RemainingQty: Decimal)
    var
        ProdOrderCompLine: Record "Prod. Order Component";
    begin
        ProdOrderCompLine.SetLoadFields(Status, "Item No.", "Variant Code", "Location Code", "Bin Code", "Remaining Qty. (Base)", "Qty. Picked (Base)");
        ProdOrderCompLine.SetFilter(Status, '%1|%2', ProdOrderCompLine.Status::Released, ProdOrderCompLine.Status::Finished);
        ProdOrderCompLine.SetRange("Item No.", BinContent."Item No.");
        ProdOrderCompLine.SetRange("Variant Code", BinContent."Variant Code");
        ProdOrderCompLine.SetRange("Location Code", BinContent."Location Code");
        ProdOrderCompLine.SetRange("Bin Code", BinContent."Bin Code");
        ProdOrderCompLine.SetFilter("Qty. Picked (Base)", '<>%1', 0);
        if not ProdOrderCompLine.IsEmpty() then begin
            ProdOrderCompLine.CalcSums("Remaining Qty. (Base)");
            RemainingQty := ProdOrderCompLine."Remaining Qty. (Base)";
            ShouldCreateMovementWorksheet := true;
        end;
    end;

    local procedure CreateMovementWorksheetLine(BinContent: Record "Bin Content"; var LineNo: Integer; QtyToTransfer: Decimal)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        LineNo += 10000;

        WhseWorksheetLine.Init();
        WhseWorksheetLine.Validate("Worksheet Template Name", WorksheetTemplName);
        WhseWorksheetLine.Validate(Name, WorksheetName);
        WhseWorksheetLine.Validate("Location Code", LocationCode);
        WhseWorksheetLine.Validate("Line No.", LineNo);
        WhseWorksheetLine.Validate("Item No.", BinContent."Item No.");
        WhseWorksheetLine.Validate("From Zone Code", BinContent."Zone Code");
        WhseWorksheetLine.Validate("From Bin Code", BinContent."Bin Code");
        WhseWorksheetLine.Validate("To Zone Code", ToZoneCode);
        WhseWorksheetLine.Validate("To Bin Code", ToBinCode);
        WhseWorksheetLine.Validate(Quantity, QtyToTransfer);
        WhseWorksheetLine.Insert(true);

        Counter += 1;
    end;

    local procedure OpenDialog()
    begin
        if not GuiAllowed() then
            exit;

        Window.Open(LocationCodeMsg + FromBinCodeMsg + ToBinCodeMsg + ToZoneCodeMsg + ItemNoMsg + ProcessBarMsg);
    end;

    local procedure UpdateDialog(BinContent: Record "Bin Content")
    begin
        if not GuiAllowed then
            exit;

        Window.Update(1, LocationCode);
        Window.Update(2, FromBinCode);
        Window.Update(3, ToBinCode);
        Window.Update(4, ToZoneCode);
        Window.Update(5, BinContent."Item No.");
        Window.Update(6, Counter);
    end;

    local procedure CloseDialog()
    begin
        if not GuiAllowed() then
            exit;

        Window.Close();
    end;

    var
        Window: Dialog;
        WorksheetName: Text;
        WorksheetTemplName: Code[10];
        LocationCode: Code[10];
        FromBinCode: Code[20];
        ToBinCode: Code[20];
        ToZoneCode: Code[20];
        Counter: Integer;
        LocationCodeMsg: Label 'Location Code: #1#########\', Comment = ' %1 = Location Code';
        FromBinCodeMsg: Label 'From Bin Code: #2###################\', Comment = ' %2 = From Bin Code';
        ToBinCodeMsg: Label 'To Bin Code: #3###################\', Comment = ' %3 = To Bin Code';
        ToZoneCodeMsg: Label 'To Zone Code: #4###################\', Comment = ' %4 = To Zone Code';
        ItemNoMsg: Label 'Item No.: #5###################\', Comment = ' %5 = Item No.';
        ProcessBarMsg: Label 'Processed: #6#########', Comment = '%6 = No. of lines created';
        MovementLinesCreatedMsg: Label '%1 Movement Lines are created.', Comment = '%1 - Count of lines';
        ToZoneCannotBeBlankErr: Label 'To Zone cannot be blank';
        ToBinCannotBeBlankErr: Label 'To Bin cannot be blank';
        WorksheetTemplateNameCannotBeBlankErr: Label 'Worksheet Template Name cannot be blank';
        WorksheetNameCannotBeBlankErr: Label 'Worksheet Name cannot be blank';
        BinCodeCannotBeBlankErr: Label 'Bin Code cannot be blank';
        NoMovementLinesCreatedMsg: Label 'No movement lines were created.';
}
