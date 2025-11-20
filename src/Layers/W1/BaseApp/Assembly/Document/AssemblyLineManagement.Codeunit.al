// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Assembly.Setup;
using Microsoft.Inventory;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.Environment.Configuration;

codeunit 905 "Assembly Line Management"
{
    Permissions = TableData "Assembly Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        WarningModeOff: Boolean;
        HideValidationDialog: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Do you want to update the %1 on the lines?';
#pragma warning restore AA0470
        Text002: Label 'Do you want to update the Dimensions on the lines?';
#pragma warning disable AA0470
        Text003: Label 'Changing %1 will change all the lines. Do you want to change the %1 from %2 to %3?';
#pragma warning restore AA0470
        Text004: Label 'This assembly order may have customized lines. Are you sure that you want to reset the lines according to the assembly BOM?';
#pragma warning disable AA0470
        Text005: Label 'Due Date %1 is before work date %2 in one or more of the assembly lines.';
        Text006: Label 'Item %1 is not a BOM.';
#pragma warning restore AA0470
        Text007: Label 'There is not enough space to explode the BOM.';
#pragma warning restore AA0074
        AssembleAvailabilityNotificationMsg: Label 'The inventory is not sufficient to cover request to assemble requested quantity of Item %1.', Comment = '%1=Item No.';
        AssembleAvailabilityCheckMsg: Label 'Assembly availability check for requested quantity of Item %1.', Comment = '%1=Item No.';

    local procedure LinesExist(AsmHeader: Record "Assembly Header"): Boolean
    var
        AssemblyLine: Record "Assembly Line";
    begin
        SetLinkToLines(AsmHeader, AssemblyLine);
        exit(not AssemblyLine.IsEmpty);
    end;

    local procedure SetLinkToLines(AsmHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line")
    begin
        AssemblyLine.SetRange("Document Type", AsmHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AsmHeader."No.");
    end;

    local procedure SetLinkToItemLines(AsmHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line")
    begin
        SetLinkToLines(AsmHeader, AssemblyLine);
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
    end;

    local procedure SetLinkToBOM(AsmHeader: Record "Assembly Header"; var BOMComponent: Record "BOM Component")
    begin
        BOMComponent.SetRange("Parent Item No.", AsmHeader."Item No.");

        OnAfterSetLinkToBOM(BOMComponent, AsmHeader);
    end;

    procedure GetNextAsmLineNo(var AsmLine: Record "Assembly Line"; AsmLineRecordIsTemporary: Boolean): Integer
    var
        TempAssemblyLine2: Record "Assembly Line" temporary;
        AssemblyLine2: Record "Assembly Line";
    begin
        if AsmLineRecordIsTemporary then begin
            TempAssemblyLine2.Copy(AsmLine, true);
            TempAssemblyLine2.SetRange("Document Type", AsmLine."Document Type");
            TempAssemblyLine2.SetRange("Document No.", AsmLine."Document No.");
            if TempAssemblyLine2.FindLast() then
                exit(TempAssemblyLine2."Line No." + 10000);
        end else begin
            AssemblyLine2.SetRange("Document Type", AsmLine."Document Type");
            AssemblyLine2.SetRange("Document No.", AsmLine."Document No.");
            if AssemblyLine2.FindLast() then
                exit(AssemblyLine2."Line No." + 10000);
        end;
        exit(10000);
    end;

    procedure InsertAsmLine(AsmHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; AsmLineRecordIsTemporary: Boolean)
    begin
        AssemblyLine.Init();
        AssemblyLine."Document Type" := AsmHeader."Document Type";
        AssemblyLine."Document No." := AsmHeader."No.";
        AssemblyLine."Line No." := GetNextAsmLineNo(AssemblyLine, AsmLineRecordIsTemporary);
        AssemblyLine.Insert(true);
    end;

    procedure AddBOMLine(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; AsmLineRecordIsTemporary: Boolean; BOMComponent: Record "BOM Component"; ShowDueDateBeforeWorkDateMessage: Boolean; QtyPerUoM: Decimal)
    var
        DueDateBeforeWorkDateMsgShown: Boolean;
        SkipVerificationsThatChangeDatabase: Boolean;
        IsHandled: Boolean;
    begin
        SkipVerificationsThatChangeDatabase := AsmLineRecordIsTemporary;
        AssemblyLine.SetSkipVerificationsThatChangeDatabase(SkipVerificationsThatChangeDatabase);
        AssemblyLine.Validate(Type, BOMComponent.Type);
        AssemblyLine.Validate("No.", BOMComponent."No.");
        OnAddBOMLineOnAfterValidatedNo(AssemblyHeader, AssemblyLine, BOMComponent);
        if AssemblyLine.Type = AssemblyLine.Type::Resource then
            case BOMComponent."Resource Usage Type" of
                BOMComponent."Resource Usage Type"::Direct:
                    AssemblyLine.Validate("Resource Usage Type", AssemblyLine."Resource Usage Type"::Direct);
                BOMComponent."Resource Usage Type"::Fixed:
                    AssemblyLine.Validate("Resource Usage Type", AssemblyLine."Resource Usage Type"::Fixed);
            end;
        AssemblyLine.Validate("Unit of Measure Code", BOMComponent."Unit of Measure Code");
        OnAddBOMLineOnAfterValidateUOMCode(AssemblyLine, BOMComponent, AssemblyHeader);
        if AssemblyLine.Type <> AssemblyLine.Type::" " then
            AssemblyLine."Quantity per" := BOMComponent."Quantity per" * QtyPerUoM;
        IsHandled := false;
        OnAddBOMLineOnBeforeValidateQuantity(AssemblyHeader, AssemblyLine, BOMComponent, IsHandled, QtyPerUoM);
        if not IsHandled then begin
            AssemblyLine.Validate(
                Quantity,
                AssemblyLine.CalcBOMQuantity(
                    BOMComponent.Type, BOMComponent."Quantity per", AssemblyHeader.Quantity, QtyPerUoM, AssemblyLine."Resource Usage Type"));
            AssemblyLine.Validate(
                "Quantity to Consume",
                AssemblyLine.CalcBOMQuantity(
                    BOMComponent.Type, BOMComponent."Quantity per", AssemblyHeader."Quantity to Assemble", QtyPerUoM, AssemblyLine."Resource Usage Type"));
        end;
        AssemblyLine.ValidateDueDate(AssemblyHeader, AssemblyHeader."Starting Date", ShowDueDateBeforeWorkDateMessage);
        DueDateBeforeWorkDateMsgShown := (AssemblyLine."Due Date" < WorkDate()) and ShowDueDateBeforeWorkDateMessage;
        AssemblyLine.ValidateLeadTimeOffset(
            AssemblyHeader, BOMComponent."Lead-Time Offset", not DueDateBeforeWorkDateMsgShown and ShowDueDateBeforeWorkDateMessage);
        if AssemblyLine.Type = AssemblyLine.Type::Item then
            AssemblyLine.Validate("Variant Code", BOMComponent."Variant Code");
        AssemblyLine.Description := BOMComponent.Description;
        AssemblyLine.Position := BOMComponent.Position;
        AssemblyLine."Position 2" := BOMComponent."Position 2";
        AssemblyLine."Position 3" := BOMComponent."Position 3";
        UpdateAssemblyLineLocationCode(AssemblyHeader, AssemblyLine);
        AssemblyLine.Validate("Consumed Quantity", AssemblyHeader."Assembled Quantity");

        OnAfterTransferBOMComponent(AssemblyLine, BOMComponent, AssemblyHeader);

        AssemblyLine.Modify(true);
    end;

    local procedure UpdateAssemblyLineLocationCode(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAssemblyLineLocationCode(AssemblyHeader, AssemblyLine, IsHandled);
        if IsHandled then
            exit;

        if (AssemblyHeader."Location Code" <> '') and (AssemblyLine.Type = AssemblyLine.Type::Item) then
            AssemblyLine.Validate("Location Code", AssemblyHeader."Location Code");
    end;

    procedure AddBOMLine(AsmHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; BOMComponent: Record "BOM Component")
    begin
        InsertAsmLine(AsmHeader, AssemblyLine, false);
        AddBOMLine(AsmHeader, AssemblyLine, false, BOMComponent, GetWarningMode(), AsmHeader."Qty. per Unit of Measure");
    end;

    procedure ExplodeAsmList(var AssemblyLine: Record "Assembly Line")
    var
        AssemblyHeader: Record "Assembly Header";
        FromBOMComp: Record "BOM Component";
        ToAssemblyLine: Record "Assembly Line";
        TempAssemblyLine: Record "Assembly Line" temporary;
        NoOfBOMCompLines: Integer;
        LineSpacing: Integer;
        NextLineNo: Integer;
        DueDateBeforeWorkDate: Boolean;
        NewLineDueDate: Date;
    begin
        AssemblyLine.TestField(Type, AssemblyLine.Type::Item);
        AssemblyLine.TestField("Consumed Quantity", 0);
        AssemblyLine.CalcFields("Reserved Qty. (Base)");
        AssemblyLine.TestField("Reserved Qty. (Base)", 0);

        AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
        FromBOMComp.SetRange("Parent Item No.", AssemblyLine."No.");
        NoOfBOMCompLines := FromBOMComp.Count();
        if NoOfBOMCompLines = 0 then
            Error(Text006, AssemblyLine."No.");

        ToAssemblyLine.Reset();
        ToAssemblyLine.SetRange("Document Type", AssemblyLine."Document Type");
        ToAssemblyLine.SetRange("Document No.", AssemblyLine."Document No.");
        ToAssemblyLine := AssemblyLine;
        LineSpacing := 10000;
        if ToAssemblyLine.Find('>') then begin
            LineSpacing := (ToAssemblyLine."Line No." - AssemblyLine."Line No.") div (1 + NoOfBOMCompLines);
            if LineSpacing = 0 then
                Error(Text007);
        end;

        TempAssemblyLine := AssemblyLine;
        TempAssemblyLine.Init();
        TempAssemblyLine.Description := AssemblyLine.Description;
        TempAssemblyLine."Description 2" := AssemblyLine."Description 2";
        TempAssemblyLine."No." := AssemblyLine."No.";
        TempAssemblyLine.Insert();

        NextLineNo := AssemblyLine."Line No.";
        FromBOMComp.FindSet();
        repeat
            TempAssemblyLine.Init();
            TempAssemblyLine."Document Type" := AssemblyLine."Document Type";
            TempAssemblyLine."Document No." := AssemblyLine."Document No.";
            NextLineNo := NextLineNo + LineSpacing;
            TempAssemblyLine."Line No." := NextLineNo;
            TempAssemblyLine.Insert(true);
            AddBOMLine(AssemblyHeader, TempAssemblyLine, true, FromBOMComp, false, 1);
            CalcTempAssemblyLineQuantityRelatedFields(AssemblyHeader, AssemblyLine, TempAssemblyLine);
            TempAssemblyLine."Cost Amount" := TempAssemblyLine."Unit Cost" * TempAssemblyLine.Quantity;
            TempAssemblyLine."Dimension Set ID" := AssemblyLine."Dimension Set ID";
            TempAssemblyLine."Shortcut Dimension 1 Code" := AssemblyLine."Shortcut Dimension 1 Code";
            TempAssemblyLine."Shortcut Dimension 2 Code" := AssemblyLine."Shortcut Dimension 2 Code";
            TempAssemblyLine.Modify(true);
        until FromBOMComp.Next() = 0;

        TempAssemblyLine.Reset();
        TempAssemblyLine.FindSet();
        ToAssemblyLine := TempAssemblyLine;
        ToAssemblyLine.Modify();
        OnExplodeAsmListOnAfterToAssemblyLineModify(TempAssemblyLine, ToAssemblyLine);
        while TempAssemblyLine.Next() <> 0 do begin
            ToAssemblyLine := TempAssemblyLine;
            ToAssemblyLine.Insert();
            OnExplodeAsmListOnAfterToAssemblyLineInsert(TempAssemblyLine, ToAssemblyLine);
            if ToAssemblyLine."Due Date" < WorkDate() then begin
                DueDateBeforeWorkDate := true;
                NewLineDueDate := ToAssemblyLine."Due Date";
            end;
        end;

        if DueDateBeforeWorkDate then
            ShowDueDateBeforeWorkDateMsg(NewLineDueDate);
    end;

    local procedure CalcTempAssemblyLineQuantityRelatedFields(AssemblyHeader: Record "Assembly Header"; AssemblyLine: Record "Assembly Line"; var TempAssemblyLine: Record "Assembly Line" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcTempAssemblyLineQuantityRelatedFields(AssemblyHeader, TempAssemblyLine, AssemblyLine, IsHandled);
        if IsHandled then
            exit;

        TempAssemblyLine.Quantity := TempAssemblyLine.Quantity * AssemblyLine."Quantity per" * AssemblyLine."Qty. per Unit of Measure";
        TempAssemblyLine."Quantity (Base)" := TempAssemblyLine."Quantity (Base)" * AssemblyLine."Quantity per" * AssemblyLine."Qty. per Unit of Measure";
        TempAssemblyLine."Quantity per" := TempAssemblyLine."Quantity per" * AssemblyLine."Quantity per" * AssemblyLine."Qty. per Unit of Measure";
        TempAssemblyLine."Remaining Quantity" := TempAssemblyLine."Remaining Quantity" * AssemblyLine."Quantity per" * AssemblyLine."Qty. per Unit of Measure";
        TempAssemblyLine."Remaining Quantity (Base)" :=
            TempAssemblyLine."Remaining Quantity (Base)" * AssemblyLine."Quantity per" * AssemblyLine."Qty. per Unit of Measure";
        TempAssemblyLine."Quantity to Consume" :=
            TempAssemblyLine."Quantity to Consume" * AssemblyLine."Quantity per" * AssemblyLine."Qty. per Unit of Measure";
        TempAssemblyLine."Quantity to Consume (Base)" :=
            TempAssemblyLine."Quantity to Consume (Base)" * AssemblyLine."Quantity per" * AssemblyLine."Qty. per Unit of Measure";
    end;

    procedure UpdateWarningOnLines(AsmHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        Window: Dialog;
        LineNo: Integer;
        PrevValue: Boolean;
        PrevUpdateTime: DateTime;
        WindowLbl: Label 'Checking availability. Line no. #1#########.', Comment = '#1 is an integer counter';
    begin
        PrevUpdateTime := CurrentDateTime();
        Window.Open(WindowLbl);
        SetLinkToLines(AsmHeader, AssemblyLine);
        if AssemblyLine.FindSet(true) then
            repeat
                LineNo += 1;
                if CurrentDateTime > PrevUpdateTime + 1000 then begin
                    Window.Update(1, LineNo);
                    PrevUpdateTime := CurrentDateTime();
                end;
                PrevValue := AssemblyLine."Avail. Warning";
                AssemblyLine.UpdateAvailWarning();
                if PrevValue <> AssemblyLine."Avail. Warning" then
                    AssemblyLine.Modify();
            until AssemblyLine.Next() = 0;
        Window.Close();
    end;

    procedure UpdateAssemblyLines(var AsmHeader: Record "Assembly Header"; OldAsmHeader: Record "Assembly Header"; FieldNum: Integer; ReplaceLinesFromBOM: Boolean; CurrFieldNo: Integer; CurrentFieldNum: Integer)
    var
        AssemblyLine: Record "Assembly Line";
        TempAssemblyHeader: Record "Assembly Header" temporary;
        TempAssemblyLine: Record "Assembly Line" temporary;
        BOMComponent: Record "BOM Component";
        TempCurrAsmLine: Record "Assembly Line" temporary;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        NoOfLinesFound: Integer;
        UpdateDueDate: Boolean;
        UpdateLocation: Boolean;
        UpdateQuantity: Boolean;
        UpdateUOM: Boolean;
        UpdateQtyToConsume: Boolean;
        UpdateDimension: Boolean;
        DueDateBeforeWorkDate: Boolean;
        NewLineDueDate: Date;
        IsHandled: Boolean;
        ShouldReplaceAsmLines: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAssemblyLines(AsmHeader, OldAsmHeader, FieldNum, ReplaceLinesFromBOM, CurrFieldNo, CurrentFieldNum, IsHandled, HideValidationDialog);
        if IsHandled then
            exit;

        if (FieldNum <> CurrentFieldNum) or // Update has been called from OnValidate of another field than was originally intended.
           ((not (FieldNum in [AsmHeader.FieldNo("Item No."),
                               AsmHeader.FieldNo("Variant Code"),
                               AsmHeader.FieldNo("Location Code"),
                               AsmHeader.FieldNo("Starting Date"),
                               AsmHeader.FieldNo(Quantity),
                               AsmHeader.FieldNo("Unit of Measure Code"),
                               AsmHeader.FieldNo("Quantity to Assemble"),
                               AsmHeader.FieldNo("Dimension Set ID")])) and (not ReplaceLinesFromBOM))
        then
            exit;

        NoOfLinesFound := CopyAssemblyData(AsmHeader, TempAssemblyHeader, TempAssemblyLine);
        OnUpdateAssemblyLinesOnAfterCopyAssemblyData(TempAssemblyLine, ReplaceLinesFromBOM);
        if ReplaceLinesFromBOM then begin
            TempAssemblyLine.DeleteAll();
            ShouldReplaceAsmLines := not ((AsmHeader."Quantity (Base)" = 0) or (AsmHeader."Item No." = '')); // condition to replace asm lines
            OnUpdateAssemblyLinesOnAfterCalcShouldReplaceAsmLines(AsmHeader, TempAssemblyLine, ShouldReplaceAsmLines);
            if ShouldReplaceAsmLines then begin
                IsHandled := false;
                OnBeforeReplaceAssemblyLines(AsmHeader, TempAssemblyLine, IsHandled);
                if not IsHandled then begin
                    SetLinkToBOM(AsmHeader, BOMComponent);
                    if BOMComponent.FindSet() then
                        repeat
                            InsertAsmLine(AsmHeader, TempAssemblyLine, true);
                            AddBOMLine(AsmHeader, TempAssemblyLine, true, BOMComponent, false, AsmHeader."Qty. per Unit of Measure");
                        until BOMComponent.Next() <= 0;
                end;
            end;
        end else
            if NoOfLinesFound = 0 then
                exit; // MODIFY condition but no lines to modify

        // make pre-checks OR ask user to confirm
        if PreCheckAndConfirmUpdate(AsmHeader, OldAsmHeader, FieldNum, ReplaceLinesFromBOM, TempAssemblyLine,
             UpdateDueDate, UpdateLocation, UpdateQuantity, UpdateUOM, UpdateQtyToConsume, UpdateDimension)
        then
            exit;

        if not ReplaceLinesFromBOM then
            if TempAssemblyLine.Find('-') then
                repeat
                    TempCurrAsmLine := TempAssemblyLine;
                    TempCurrAsmLine.Insert();
                    TempAssemblyLine.SetSkipVerificationsThatChangeDatabase(true);
                    UpdateExistingLine(
                        AsmHeader, OldAsmHeader, CurrFieldNo, TempAssemblyLine,
                        UpdateDueDate, UpdateLocation, UpdateQuantity, UpdateUOM, UpdateQtyToConsume, UpdateDimension);
                until TempAssemblyLine.Next() = 0;

        if not (FieldNum in [AsmHeader.FieldNo("Quantity to Assemble"), AsmHeader.FieldNo("Dimension Set ID")]) then
            if ShowAvailability(false, TempAssemblyHeader, TempAssemblyLine) then
                ItemCheckAvail.RaiseUpdateInterruptedError();

        DoVerificationsSkippedEarlier(
            ReplaceLinesFromBOM, TempAssemblyLine, TempCurrAsmLine, UpdateDimension, AsmHeader."Dimension Set ID",
            OldAsmHeader."Dimension Set ID");

        AssemblyLine.Reset();
        if ReplaceLinesFromBOM then begin
            AsmHeader.DeleteAssemblyLines();
            TempAssemblyLine.Reset();
        end;

        if TempAssemblyLine.Find('-') then
            repeat
                if not ReplaceLinesFromBOM then
                    AssemblyLine.Get(TempAssemblyLine."Document Type", TempAssemblyLine."Document No.", TempAssemblyLine."Line No.");
                AssemblyLine := TempAssemblyLine;
                if ReplaceLinesFromBOM then
                    AssemblyLine.Insert(true)
                else
                    AssemblyLine.Modify(true);
                OnUpdateAssemblyLinesOnBeforeAutoReserveAsmLine(AssemblyLine, ReplaceLinesFromBOM);
                AsmHeader.AutoReserveAsmLine(AssemblyLine);
                if AssemblyLine."Due Date" < WorkDate() then begin
                    DueDateBeforeWorkDate := true;
                    NewLineDueDate := AssemblyLine."Due Date";
                end;
            until TempAssemblyLine.Next() = 0;

        if ReplaceLinesFromBOM or UpdateDueDate then
            if DueDateBeforeWorkDate then
                ShowDueDateBeforeWorkDateMsg(NewLineDueDate);

        OnAfterUpdateAssemblyLines(AsmHeader, OldAsmHeader, FieldNum, ReplaceLinesFromBOM, CurrFieldNo, CurrentFieldNum);
    end;

    local procedure PreCheckAndConfirmUpdate(AsmHeader: Record "Assembly Header"; OldAsmHeader: Record "Assembly Header"; FieldNum: Integer; var ReplaceLinesFromBOM: Boolean; var TempAssemblyLine: Record "Assembly Line" temporary; var UpdateDueDate: Boolean; var UpdateLocation: Boolean; var UpdateQuantity: Boolean; var UpdateUOM: Boolean; var UpdateQtyToConsume: Boolean; var UpdateDimension: Boolean): Boolean
    begin
        UpdateDueDate := false;
        UpdateLocation := false;
        UpdateQuantity := false;
        UpdateUOM := false;
        UpdateQtyToConsume := false;
        UpdateDimension := false;

        case FieldNum of
            AsmHeader.FieldNo("Item No."):
                if AsmHeader."Item No." <> OldAsmHeader."Item No." then
                    if LinesExist(AsmHeader) then
                        if GuiAllowed then
                            if not Confirm(StrSubstNo(Text003, AsmHeader.FieldCaption("Item No."), OldAsmHeader."Item No.", AsmHeader."Item No."), true) then
                                Error('');
            AsmHeader.FieldNo("Variant Code"):
                UpdateDueDate := true;
            AsmHeader.FieldNo("Location Code"):
                begin
                    UpdateDueDate := true;
                    if AsmHeader."Location Code" <> OldAsmHeader."Location Code" then begin
                        TempAssemblyLine.SetRange(Type, TempAssemblyLine.Type::Item);
                        TempAssemblyLine.SetFilter("Location Code", '<>%1', AsmHeader."Location Code");
                        if not TempAssemblyLine.IsEmpty() then
                            if GuiAllowed then begin
                                if Confirm(StrSubstNo(Text001, TempAssemblyLine.FieldCaption("Location Code")), false) then
                                    UpdateLocation := true;
                            end else
                                UpdateLocation := true;
                        TempAssemblyLine.SetRange("Location Code");
                        TempAssemblyLine.SetRange(Type);
                    end;
                end;
            AsmHeader.FieldNo("Starting Date"):
                UpdateDueDate := true;
            AsmHeader.FieldNo(Quantity):
                if AsmHeader.Quantity <> OldAsmHeader.Quantity then begin
                    UpdateQuantity := true;
                    UpdateQtyToConsume := true;
                end;
            AsmHeader.FieldNo("Unit of Measure Code"):
                if AsmHeader."Unit of Measure Code" <> OldAsmHeader."Unit of Measure Code" then
                    UpdateUOM := true;
            AsmHeader.FieldNo("Quantity to Assemble"):
                UpdateQtyToConsume := true;
            AsmHeader.FieldNo("Dimension Set ID"):
                if AsmHeader."Dimension Set ID" <> OldAsmHeader."Dimension Set ID" then
                    if LinesExist(AsmHeader) then begin
                        UpdateDimension := true;
                        if GuiAllowed and not HideValidationDialog then
                            if not Confirm(Text002) then
                                UpdateDimension := false;
                    end;
            else
                if CalledFromRefreshBOM(ReplaceLinesFromBOM, FieldNum) then
                    if LinesExist(AsmHeader) then
                        if GuiAllowed then
                            if not Confirm(Text004, false) then
                                ReplaceLinesFromBOM := false;
        end;

        if not (UpdateDueDate or UpdateLocation or UpdateQuantity or UpdateUOM or UpdateQtyToConsume or UpdateDimension) and
           // nothing to update
           not ReplaceLinesFromBOM
        then
            exit(true);
    end;

    local procedure UpdateExistingLine(var AsmHeader: Record "Assembly Header"; OldAsmHeader: Record "Assembly Header"; CurrFieldNo: Integer; var AssemblyLine: Record "Assembly Line"; UpdateDueDate: Boolean; UpdateLocation: Boolean; UpdateQuantity: Boolean; UpdateUOM: Boolean; UpdateQtyToConsume: Boolean; UpdateDimension: Boolean)
    var
        QtyRatio: Decimal;
        QtyToConsume: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateExistingLine(
            AsmHeader, OldAsmHeader, CurrFieldNo, AssemblyLine, UpdateDueDate, UpdateLocation,
            UpdateQuantity, UpdateUOM, UpdateQtyToConsume, UpdateDimension, IsHandled);
        if IsHandled then
            exit;

        if AsmHeader."Gen. Bus. Posting Group" <> OldAsmHeader."Gen. Bus. Posting Group" then
            AssemblyLine.Validate("Gen. Bus. Posting Group", AsmHeader."Gen. Bus. Posting Group");

        if AsmHeader.IsStatusCheckSuspended() then
            AssemblyLine.SuspendStatusCheck(true);

        if UpdateLocation and (AssemblyLine.Type = AssemblyLine.Type::Item) then
            AssemblyLine.Validate("Location Code", AsmHeader."Location Code");

        if UpdateDueDate then begin
            AssemblyLine.SetTestReservationDateConflict(CurrFieldNo <> 0);
            AssemblyLine.ValidateLeadTimeOffset(AsmHeader, AssemblyLine."Lead-Time Offset", false);
        end;

        if UpdateQuantity then begin
            QtyRatio := AsmHeader.Quantity / OldAsmHeader.Quantity;
            UpdateAssemblyLineQuantity(AsmHeader, AssemblyLine, QtyRatio);
            AssemblyLine.InitQtyToConsume();
        end;

        if UpdateUOM then begin
            QtyRatio := AsmHeader."Qty. per Unit of Measure" / OldAsmHeader."Qty. per Unit of Measure";
            if AssemblyLine.FixedUsage() then
                AssemblyLine.Validate("Quantity per")
            else
                AssemblyLine.Validate("Quantity per", AssemblyLine."Quantity per" * QtyRatio);
            AssemblyLine.InitQtyToConsume();
        end;

        if UpdateQtyToConsume then
            if not AssemblyLine.FixedUsage() then begin
                QtyToConsume := AssemblyLine.Quantity * AsmHeader."Quantity to Assemble" / AsmHeader.Quantity;
                AssemblyLine.RoundQty(QtyToConsume);
                UpdateQuantityToConsume(AsmHeader, AssemblyLine, QtyToConsume);
            end;

        if UpdateDimension then
            AssemblyLine.UpdateDim(AsmHeader."Dimension Set ID", OldAsmHeader."Dimension Set ID");

        AssemblyLine.Modify(true);
    end;

    local procedure UpdateQuantityToConsume(AsmHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; QtyToConsume: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateQuantityToConsume(AsmHeader, AssemblyLine, QtyToConsume, IsHandled);
        if IsHandled then
            exit;

        if QtyToConsume < AssemblyLine.MaxQtyToConsume() then
            AssemblyLine.Validate("Quantity to Consume", QtyToConsume)
        else
            AssemblyLine.Validate("Quantity to Consume", AssemblyLine.MaxQtyToConsume());
    end;

    local procedure UpdateAssemblyLineQuantity(AsmHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; QtyRatio: Decimal)
    var
        IsHandled: Boolean;
        RoundedQty: Decimal;
    begin
        IsHandled := false;
        OnBeforeUpdateAssemblyLineQuantity(AsmHeader, AssemblyLine, QtyRatio, IsHandled);
        if IsHandled then
            exit;

        if AssemblyLine.FixedUsage() then
            AssemblyLine.Validate(Quantity)
        else begin
            if AssemblyLine."Qty. Rounding Precision" = 0 then
                RoundedQty := AssemblyLine.Quantity * QtyRatio
            else
                RoundedQty := GetAssemblyLineQty(AsmHeader, AssemblyLine);
            AssemblyLine.RoundQty(RoundedQty);
            AssemblyLine.Validate(Quantity, RoundedQty);
        end;
    end;

    procedure ShowDueDateBeforeWorkDateMsg(ActualLineDueDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDueDateBeforeWorkDateMsg(ActualLineDueDate, IsHandled);
        if IsHandled then
            exit;

        if GuiAllowed then
            if GetWarningMode() then
                Message(Text005, ActualLineDueDate, WorkDate());
    end;

    procedure CopyAssemblyData(FromAssemblyHeader: Record "Assembly Header"; var ToAssemblyHeader: Record "Assembly Header"; var ToAssemblyLine: Record "Assembly Line") NoOfLinesInserted: Integer
    var
        AssemblyLine: Record "Assembly Line";
    begin
        ToAssemblyHeader := FromAssemblyHeader;
        ToAssemblyHeader.Insert();

        SetLinkToLines(FromAssemblyHeader, AssemblyLine);
        AssemblyLine.SetFilter(Type, '%1|%2', AssemblyLine.Type::Item, AssemblyLine.Type::Resource);
        ToAssemblyLine.Reset();
        ToAssemblyLine.DeleteAll();
        if AssemblyLine.Find('-') then
            repeat
                ToAssemblyLine := AssemblyLine;
                ToAssemblyLine.Insert();
                OnCopyAssemblyDataOnAfterToAssemblyLineInsert(AssemblyLine, ToAssemblyLine, ToAssemblyHeader);
                NoOfLinesInserted += 1;
            until AssemblyLine.Next() = 0;
    end;

    procedure ShowAvailability(ShowPageEvenIfEnoughComponentsAvailable: Boolean; var TempAssemblyHeader: Record "Assembly Header" temporary; var TempAssemblyLine: Record "Assembly Line" temporary) Rollback: Boolean
    var
        TempAssemblyLine2: Record "Assembly Line" temporary;
        AssemblySetup: Record "Assembly Setup";

        EarliestAvailableDateX: Date;
        QtyAvailToMake: Decimal;
        QtyAvailTooLow: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowAvailability(TempAssemblyHeader, TempAssemblyLine, ShowPageEvenIfEnoughComponentsAvailable, IsHandled, Rollback, WarningModeOff);
        if IsHandled then
            exit(Rollback);

        AssemblySetup.Get();
        if not GuiAllowed or
           TempAssemblyLine.IsEmpty() or
           (not AssemblySetup."Stockout Warning" and not ShowPageEvenIfEnoughComponentsAvailable) or
           not GetWarningMode()
        then
            exit(false);

        TempAssemblyHeader.TestField("Item No.");
        CopyInventoriableItemAsmLines(TempAssemblyLine2, TempAssemblyLine);
        AvailToPromise(TempAssemblyHeader, TempAssemblyLine2, QtyAvailToMake, EarliestAvailableDateX);
        QtyAvailTooLow := QtyAvailToMake < TempAssemblyHeader."Remaining Quantity";

        if QtyAvailTooLow and not ShowPageEvenIfEnoughComponentsAvailable then
            Rollback := CreateAndSendNotification(TempAssemblyHeader, TempAssemblyLine)
        else
            if ShowPageEvenIfEnoughComponentsAvailable then
                ShowAssemblyAvailability(TempAssemblyHeader, TempAssemblyLine2, '');
    end;

    #region Notification
    local procedure CreateAndSendNotification(var TempAssemblyHeader: Record "Assembly Header" temporary; var TempAssemblyLine: Record "Assembly Line" temporary) Rollback: Boolean
    var
        DummyAssemblyHeader: Record "Assembly Header" temporary;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        AssemblyAvailability2: Page "Assembly Availability Check";
        AssemblyAvailCheckNotification: Notification;
        IsHandled: Boolean;
        DetailsTxt: Label 'Show details';
        DontShowAgainTxt: Label 'Don''t show again';
    begin
        IsHandled := false;
        OnBeforeCreateAndSendNotification(TempAssemblyHeader, TempAssemblyLine, IsHandled, Rollback);
        if IsHandled then
            exit(Rollback);

        //remove initial notifications for assembly if exists
        if TempAssemblyHeader."No." <> '' then begin
            DummyAssemblyHeader := TempAssemblyHeader;
            DummyAssemblyHeader."No." := '';
            NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(DummyAssemblyHeader.RecordId, GetAssemblyAvailabilityNotificationId(), true);
        end;
        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(TempAssemblyHeader.RecordId, GetAssemblyAvailabilityNotificationId(), true);

        AssemblyAvailCheckNotification.Id(CreateGuid());
        AssemblyAvailCheckNotification.Message(StrSubstNo(AssembleAvailabilityNotificationMsg, TempAssemblyHeader."Item No."));
        AssemblyAvailCheckNotification.Scope(NotificationScope::LocalScope);
        AssemblyAvailCheckNotification.AddAction(DetailsTxt, Codeunit::"Assembly Line Management", 'ShowNotificationDetails');
        AssemblyAvailCheckNotification.AddAction(DontShowAgainTxt, Codeunit::"Assembly Line Management", 'DeactivateNotification');
        AssemblyAvailability2.PopulateDataOnNotification(AssemblyAvailCheckNotification, TempAssemblyHeader);
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(
          AssemblyAvailCheckNotification, TempAssemblyHeader.RecordId, GetAssemblyAvailabilityNotificationId());
        exit(false);
    end;

    local procedure GetAssemblyAvailabilityNotificationId(): Guid
    begin
        exit('3531EDA8-b30E-4422-B742-1F418B865596');
    end;

    procedure ShowNotificationDetails(AvailabilityCheckNotification: Notification)
    var
        TempAssemblyHeader: Record "Assembly Header" temporary;
        TempAssemblyLine: Record "Assembly Line" temporary;
        AssemblyAvailabilityCheck: Page "Assembly Availability Check";
        ExistingDocument: Boolean;
    begin
        AssemblyAvailabilityCheck.InitializeFromNotification(AvailabilityCheckNotification, TempAssemblyHeader, ExistingDocument);
        GetAssemblyLines(TempAssemblyHeader, TempAssemblyLine, ExistingDocument);

        ShowAssemblyAvailability(TempAssemblyHeader, TempAssemblyLine, AvailabilityCheckNotification.Message);
    end;

    local procedure ShowAssemblyAvailability(var TempAssemblyHeader: Record "Assembly Header" temporary; var TempAssemblyLine: Record "Assembly Line" temporary; HeadinMessage: Text)
    var
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        AssemblyAvailabilityCheck: Page "Assembly Availability Check";
        EarliestAvailableDateX: Date;
        Inventory: Decimal;
        GrossRequirement: Decimal;
        ReservedRequirement: Decimal;
        ScheduledReceipts: Decimal;
        ReservedReceipts: Decimal;
        QtyAvailToMake: Decimal;
    begin
        ItemCheckAvail.AsmOrderCalculate(TempAssemblyHeader, Inventory, GrossRequirement, ReservedRequirement, ScheduledReceipts, ReservedReceipts);
        AvailToPromise(TempAssemblyHeader, TempAssemblyLine, QtyAvailToMake, EarliestAvailableDateX);

        AssemblyAvailabilityCheck.SetAssemblyHeader(TempAssemblyHeader);
        AssemblyAvailabilityCheck.SetHeaderInventoryData(
                  Inventory, GrossRequirement, ReservedRequirement, ScheduledReceipts, ReservedReceipts,
                  EarliestAvailableDateX, QtyAvailToMake, QtyAvailToMake < TempAssemblyHeader."Remaining Quantity");
        AssemblyAvailabilityCheck.SetAssemblyLines(TempAssemblyLine);

        if HeadinMessage = '' then
            if QtyAvailToMake < TempAssemblyHeader."Remaining Quantity" then
                HeadinMessage := StrSubstNo(AssembleAvailabilityNotificationMsg, TempAssemblyHeader."Item No.")
            else
                HeadinMessage := StrSubstNo(AssembleAvailabilityCheckMsg, TempAssemblyHeader."Item No.");

        AssemblyAvailabilityCheck.SetHeading(HeadinMessage);
        AssemblyAvailabilityCheck.RunModal();
    end;

    local procedure GetAssemblyLines(var TempAssemblyHeader: Record "Assembly Header" temporary; var TempAssemblyLine: Record "Assembly Line" temporary; ExistingDocument: Boolean)
    var
        AssembleToOrderLink: Record "Assemble-to-Order Link";
        AssemblyLine: Record "Assembly Line";
        TempAssemblyLine2: Record "Assembly Line" temporary;
    begin
        TempAssemblyLine.DeleteAll();

        if not ExistingDocument then begin
            AssembleToOrderLink.TransAvailBOMCompToAsmLines(TempAssemblyHeader, TempAssemblyLine2);
            if TempAssemblyLine2.FindSet() then
                repeat
                    if TempAssemblyLine2.IsInventoriableItem() then begin
                        TempAssemblyLine.Init();
                        TempAssemblyLine := TempAssemblyLine2;
                        TempAssemblyLine.Insert();
                    end;
                until TempAssemblyLine2.Next() = 0;
            exit;
        end;

        AssemblyLine.Reset();
        AssemblyLine.SetRange("Document Type", TempAssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", TempAssemblyHeader."No.");
        if AssemblyLine.FindSet() then
            repeat
                if AssemblyLine.IsInventoriableItem() then begin
                    TempAssemblyLine.Init();
                    TempAssemblyLine := AssemblyLine;
                    TempAssemblyLine.UpdateAvailWarning();
                    TempAssemblyLine.Insert();
                end;
            until AssemblyLine.Next() = 0;
    end;

    procedure DeactivateNotification(SetupNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        // Insert notification in case the My Notifications page has not been opened yet
        OnInitializingNotificationWithDefaultState();
        MyNotifications.Disable(GetAssemblyAvailabilityNotificationId())
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState()
    var
        MyNotifications: Record "My Notifications";
        ItemToAssemblyAvailabilityNotificationTxt: Label 'Assembly BOM availability is low.';
        ItemToAssemblyAvailabilityNotificationDescriptionTxt: Label 'Show a warning when someone creates a sales order line with item which should be assebled and which BOM components are out of stock.';
    begin
        MyNotifications.InsertDefaultWithTableNum(GetAssemblyAvailabilityNotificationId(),
          ItemToAssemblyAvailabilityNotificationTxt,
          ItemToAssemblyAvailabilityNotificationDescriptionTxt,
          DATABASE::"Assembly Header");
    end;
    #endregion

    local procedure DoVerificationsSkippedEarlier(ReplaceLinesFromBOM: Boolean; var TempNewAsmLine: Record "Assembly Line" temporary; var TempOldAsmLine: Record "Assembly Line" temporary; UpdateDimension: Boolean; NewHeaderSetID: Integer; OldHeaderSetID: Integer)
    begin
        if TempNewAsmLine.Find('-') then
            repeat
                TempNewAsmLine.SetSkipVerificationsThatChangeDatabase(false);
                if not ReplaceLinesFromBOM then
                    TempOldAsmLine.Get(TempNewAsmLine."Document Type", TempNewAsmLine."Document No.", TempNewAsmLine."Line No.");
                TempNewAsmLine.VerifyReservationQuantity(TempNewAsmLine, TempOldAsmLine);
                TempNewAsmLine.VerifyReservationChange(TempNewAsmLine, TempOldAsmLine);
                TempNewAsmLine.VerifyReservationDateConflict(TempNewAsmLine);

                if ReplaceLinesFromBOM then
                    case TempNewAsmLine.Type of
                        TempNewAsmLine.Type::Item:
                            TempNewAsmLine.CreateDimFromDefaultDim(NewHeaderSetID);
                        TempNewAsmLine.Type::Resource:
                            TempNewAsmLine.CreateDimFromDefaultDim(NewHeaderSetID);
                    end
                else
                    if UpdateDimension then
                        TempNewAsmLine.UpdateDim(NewHeaderSetID, OldHeaderSetID);

                TempNewAsmLine.Modify();
                OnDoVerificationsSkippedEarlierOnAfterTempNewAsmLineModify(TempNewAsmLine);
            until TempNewAsmLine.Next() = 0;
    end;

    local procedure AvailToPromise(AsmHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; var OrderAbleToAssemble: Decimal; var EarliestDueDate: Date)
    var
        LineAvailabilityDate: Date;
        LineStartingDate: Date;
        EarliestStartingDate: Date;
        LineAbleToAssemble: Decimal;
        IsHandled: Boolean;
    begin
        SetLinkToItemLines(AsmHeader, AssemblyLine);
        AssemblyLine.SetFilter("No.", '<>%1', '');
        AssemblyLine.SetFilter("Quantity per", '<>%1', 0);
        OrderAbleToAssemble := AsmHeader."Remaining Quantity";
        EarliestStartingDate := 0D;
        if AssemblyLine.FindSet() then
            repeat
                LineAbleToAssemble := CalcAvailToAssemble(AssemblyLine, AsmHeader, LineAvailabilityDate);

                IsHandled := false;
                OnAvailToPromiseOnBeforeAssignOrderAbleToAssemble(AssemblyLine, IsHandled);
                if not IsHandled then
                    if LineAbleToAssemble < OrderAbleToAssemble then
                        OrderAbleToAssemble := LineAbleToAssemble;

                if LineAvailabilityDate > 0D then begin
                    LineStartingDate := CalcDate(AssemblyLine."Lead-Time Offset", LineAvailabilityDate);
                    if LineStartingDate > EarliestStartingDate then
                        EarliestStartingDate := LineStartingDate; // latest of all line starting dates
                end;
            until AssemblyLine.Next() = 0;

        EarliestDueDate := CalcEarliestDueDate(AsmHeader, EarliestStartingDate);
    end;

    local procedure CalcAvailToAssemble(AssemblyLine: Record "Assembly Line"; AsmHeader: Record "Assembly Header"; var LineAvailabilityDate: Date) LineAbleToAssemble: Decimal
    var
        Item: Record Item;
        GrossRequirement: Decimal;
        ScheduledRcpt: Decimal;
        ExpectedInventory: Decimal;
        LineInventory: Decimal;
    begin
        AssemblyLine.CalcAvailToAssemble(
          AsmHeader, Item, GrossRequirement, ScheduledRcpt, ExpectedInventory, LineInventory,
          LineAvailabilityDate, LineAbleToAssemble);
    end;

    local procedure CalcEarliestDueDate(AsmHeader: Record "Assembly Header"; EarliestStartingDate: Date) EarliestDueDate: Date
    var
        ReqLine: Record "Requisition Line";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        EarliestEndingDate: Date;
    begin
        OnBeforeCalcEarliestDueDate(AsmHeader);

        EarliestDueDate := 0D;
        if EarliestStartingDate > 0D then begin
            EarliestEndingDate := // earliest starting date + lead time calculation
                LeadTimeMgt.GetPlannedEndingDate(
                    AsmHeader."Item No.", AsmHeader."Location Code", AsmHeader."Variant Code",
                    '', LeadTimeMgt.ManufacturingLeadTime(AsmHeader."Item No.", AsmHeader."Location Code", AsmHeader."Variant Code"),
                    ReqLine."Ref. Order Type"::Assembly, EarliestStartingDate);
            EarliestDueDate := // earliest ending date + (default) safety lead time
                LeadTimeMgt.GetPlannedDueDate(
                    AsmHeader."Item No.", AsmHeader."Location Code", AsmHeader."Variant Code",
                    EarliestEndingDate, '', ReqLine."Ref. Order Type"::Assembly);
        end;

        OnAfterCalcEarliestDueDate(AsmHeader);
    end;

    procedure CompletelyPicked(AsmHeader: Record "Assembly Header"): Boolean
    var
        AssemblyLine: Record "Assembly Line";
    begin
        SetLinkToItemLines(AsmHeader, AssemblyLine);
        if AssemblyLine.Find('-') then
            repeat
                if not AssemblyLine.CompletelyPicked() then
                    exit(false);
            until AssemblyLine.Next() = 0;
        exit(true);
    end;

    procedure SetWarningsOff()
    begin
        WarningModeOff := true;
    end;

    procedure SetWarningsOn()
    begin
        WarningModeOff := false;
    end;

    local procedure GetWarningMode(): Boolean
    begin
        exit(not WarningModeOff);
    end;

    local procedure CalledFromRefreshBOM(ReplaceLinesFromBOM: Boolean; FieldNum: Integer): Boolean
    begin
        exit(ReplaceLinesFromBOM and (FieldNum = 0));
    end;

    procedure CreateWhseItemTrkgForAsmLines(AsmHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateWhseItemTrkgForAsmLines(AsmHeader, IsHandled);
        if IsHandled then
            exit;

        SetLinkToItemLines(AsmHeader, AssemblyLine);
        if AssemblyLine.FindSet() then
            repeat
                if ItemTrackingMgt.GetWhseItemTrkgSetup(AssemblyLine."No.") then
                    ItemTrackingMgt.InitItemTrackingForTempWhseWorksheetLine(
                        Enum::"Warehouse Worksheet Document Type"::Assembly, AssemblyLine."Document No.", AssemblyLine."Line No.",
                        Database::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", 0);
            until AssemblyLine.Next() = 0;
    end;

    local procedure CopyInventoriableItemAsmLines(var TempToAssemblyLine: Record "Assembly Line" temporary; var TempFromAssemblyLine: Record "Assembly Line" temporary)
    begin
        if TempFromAssemblyLine.FindSet() then
            repeat
                if TempFromAssemblyLine.IsInventoriableItem() then begin
                    TempToAssemblyLine := TempFromAssemblyLine;
                    TempToAssemblyLine.Insert();
                end;
            until TempFromAssemblyLine.Next() = 0;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure GetAssemblyLineQty(AssemblyHeader: Record "Assembly Header"; AssemblyLine: Record "Assembly Line"): Decimal
    var
        BomComponent: Record "Bom Component";
        AssemblyLineQty: Decimal;
    begin
        SetLinkToBOM(AssemblyHeader, BomComponent);
        BomComponent.SetRange("No.", AssemblyLine."No.");
        if not BomComponent.FindFirst() then
            exit(0);

        AssemblyLineQty := AssemblyLine.CalcBOMQuantity(
                    BOMComponent.Type, BOMComponent."Quantity per",
                    AssemblyHeader.Quantity, AssemblyHeader."Qty. per Unit of Measure",
                    AssemblyLine."Resource Usage Type");

        exit(AssemblyLineQty);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcEarliestDueDate(var AsmHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddBOMLineOnAfterValidateUOMCode(var AssemblyLine: Record "Assembly Line"; BOMComponent: Record "BOM Component"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddBOMLineOnBeforeValidateQuantity(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; BOMComponent: Record "BOM Component"; var IsHandled: Boolean; QtyPerUoM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddBOMLineOnAfterValidatedNo(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; BOMComponent: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetLinkToBOM(var BOMComponent: Record "BOM Component"; var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferBOMComponent(var AssemblyLine: Record "Assembly Line"; BOMComponent: Record "BOM Component"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReplaceAssemblyLines(AssemblyHeader: Record "Assembly Header"; var TempAssemblyLine: Record "Assembly Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowAvailability(var TempAssemblyHeader: Record "Assembly Header" temporary; var TempAssemblyLine: Record "Assembly Line" temporary; ShowPageEvenIfEnoughComponentsAvailable: Boolean; var IsHandled: Boolean; var RollBack: Boolean; WarningModeOff: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAssemblyLines(var AsmHeader: Record "Assembly Header"; OldAsmHeader: Record "Assembly Header"; FieldNum: Integer; ReplaceLinesFromBOM: Boolean; CurrFieldNo: Integer; CurrentFieldNum: Integer; var IsHandled: Boolean; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAssemblyLines(var AsmHeader: Record "Assembly Header"; OldAsmHeader: Record "Assembly Header"; FieldNum: Integer; ReplaceLinesFromBOM: Boolean; CurrFieldNo: Integer; CurrentFieldNum: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateExistingLine(var AsmHeader: Record "Assembly Header"; OldAsmHeader: Record "Assembly Header"; CurrFieldNo: Integer; var AssemblyLine: Record "Assembly Line"; UpdateDueDate: Boolean; UpdateLocation: Boolean; UpdateQuantity: Boolean; UpdateUOM: Boolean; UpdateQtyToConsume: Boolean; UpdateDimension: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcEarliestDueDate(var AsmHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseItemTrkgForAsmLines(var AsmHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcTempAssemblyLineQuantityRelatedFields(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; FromAssemblyLine: Record "Assembly Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateQuantityToConsume(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; var QtyToConsume: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAssemblyLineLocationCode(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAssemblyLineQuantity(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; var QtyRatio: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyAssemblyDataOnAfterToAssemblyLineInsert(var AssemblyLine: Record "Assembly Line"; var ToAssemblyLine: Record "Assembly Line"; var ToAssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDoVerificationsSkippedEarlierOnAfterTempNewAsmLineModify(var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExplodeAsmListOnAfterToAssemblyLineInsert(var FromAssemblyLine: Record "Assembly Line"; var ToAssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExplodeAsmListOnAfterToAssemblyLineModify(var FromAssemblyLine: Record "Assembly Line"; var ToAssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAssemblyLinesOnBeforeAutoReserveAsmLine(var AssemblyLine: Record "Assembly Line"; ReplaceLinesFromBOM: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAssemblyLinesOnAfterCalcShouldReplaceAsmLines(AssemblyHeader: Record "Assembly Header"; TempAssemblyLine: Record "Assembly Line" temporary; var ShouldReplaceAsmLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAssemblyLinesOnAfterCopyAssemblyData(var AssemblyLine: Record "Assembly Line"; var ReplaceLinesFromBOM: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateAndSendNotification(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; var IsHandled: Boolean; var Rollback: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAvailToPromiseOnBeforeAssignOrderAbleToAssemble(var AssemblyLine: Record "Assembly Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDueDateBeforeWorkDateMsg(ActualLineDueDate: Date; var IsHandled: Boolean)
    begin
    end;
}

