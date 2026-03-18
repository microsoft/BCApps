// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.Utilities;
using System.Utilities;

codeunit 9078 "Check Item Jnl. Line. Backgr."
{
    trigger OnRun()
    var
        TempErrorMessage: Record "Error Message" temporary;
        Args: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
    begin
        Args := Page.GetBackgroundParameters();

        RunCheck(Args, TempErrorMessage);

        PackErrorMessagesToResults(TempErrorMessage, Results);

        Page.SetBackgroundTaskResult(Results);
    end;

    procedure RunCheck(Args: Dictionary of [Text, Text]; var TempErrorMessage: Record "Error Message" temporary)
    var
        ItemJnlLine: Record "Item Journal Line";
        ErrorHandlingParameters: Record "Error Handling Parameters";
    begin
        ErrorHandlingParameters.FromArgs(Args);

        if ErrorHandlingParameters."Full Batch Check" then begin
            ItemJnlLine.SetRange("Journal Template Name", ErrorHandlingParameters."Journal Template Name");
            ItemJnlLine.SetRange("Journal Batch Name", ErrorHandlingParameters."Journal Batch Name");
            CheckItemJnlLines(ItemJnlLine, TempErrorMessage)
        end else begin
            if ItemJnlLine.Get(ErrorHandlingParameters."Journal Template Name", ErrorHandlingParameters."Journal Batch Name", ErrorHandlingParameters."Line No.") then
                CheckItemJnlLine(ItemJnlLine, TempErrorMessage);

            if ErrorHandlingParameters."Line No." <> ErrorHandlingParameters."Previous Line No." then
                if ItemJnlLine.Get(ErrorHandlingParameters."Journal Template Name", ErrorHandlingParameters."Journal Batch Name", ErrorHandlingParameters."Previous Line No.") then
                    CheckItemJnlLine(ItemJnlLine, TempErrorMessage);
        end;
    end;

    local procedure CheckItemJnlLines(var ItemJnlLine: Record "Item Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    begin
        if ItemJnlLine.FindSet() then
            repeat
                CheckItemJnlLine(ItemJnlLine, TempErrorMessage);
            until ItemJnlLine.Next() = 0;
    end;

    local procedure CheckItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    begin
        RunItemJnlCheckLineCodeunit(ItemJnlLine, TempErrorMessage);

        OnAfterCheckItemJnlLine(ItemJnlLine, TempErrorMessage);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure RunItemJnlCheckLineCodeunit(ItemJnlLine: Record "Item Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    var
        TempLineErrorMessage: Record "Error Message" temporary;
        ItemJnlCheckLine: Codeunit "Item Jnl.-Check Line";
    begin
        if not ItemJnlCheckLine.Run(ItemJnlLine) then
            InsertTempLineErrorMessage(
                TempLineErrorMessage,
                ItemJnlLine.RecordId(),
                0,
                GetLastErrorText(),
                false);

        if HasCollectedErrors then begin
            CollectErrors(ItemJnlLine, TempLineErrorMessage);
            CopyErrorsToBuffer(TempLineErrorMessage, TempErrorMessage);
        end;
    end;

    procedure CollectErrors(ItemJnlLine: Record "Item Journal Line"; var TempLineErrorMessage: Record "Error Message" temporary)
    var
        ErrorList: list of [ErrorInfo];
        ErrInfo: ErrorInfo;
    begin
        if HasCollectedErrors() then begin
            ErrorList := GetCollectedErrors(true);
            foreach ErrInfo in ErrorList do begin
                TempLineErrorMessage.Init();
                TempLineErrorMessage.ID := TempLineErrorMessage.ID + 1;
                TempLineErrorMessage."Message" := copystr(ErrInfo.Message, 1, MaxStrLen(TempLineErrorMessage."Message"));
                TempLineErrorMessage."Context Table Number" := Database::"Item Journal Line";
                TempLineErrorMessage.Validate("Context Record ID", ItemJnlLine.RecordId);
                if ErrInfo.RecordId = ItemJnlLine.RecordId then
                    TempLineErrorMessage."Context Field Number" := ErrInfo.FieldNo
                else begin
                    TempLineErrorMessage."Table Number" := ErrInfo.TableId;
                    TempLineErrorMessage."Field Number" := ErrInfo.FieldNo;
                    TempLineErrorMessage.Validate("Record ID", ErrInfo.RecordId);
                end;

                TempLineErrorMessage.SetErrorCallStack(ErrInfo.Callstack);
                TempLineErrorMessage.Insert();
            end;
        end;
    end;

    local procedure InsertTempLineErrorMessage(var TempLineErrorMessage: Record "Error Message" temporary; ContextRecordId: RecordId; ContextFieldNo: Integer; Description: Text; Duplicate: Boolean)
    begin
        TempLineErrorMessage."Record ID" := ContextRecordId;
        TempLineErrorMessage."Field Number" := ContextFieldNo;
        TempLineErrorMessage."Table Number" := Database::"Item Journal Line";
        TempLineErrorMessage."Context Record ID" := ContextRecordId;
        TempLineErrorMessage."Context Field Number" := ContextFieldNo;
        TempLineErrorMessage."Context Table Number" := Database::"Item Journal Line";
        TempLineErrorMessage."Message" := CopyStr(Description, 1, MaxStrLen(TempLineErrorMessage."Message"));
        TempLineErrorMessage.Duplicate := Duplicate;
        TempLineErrorMessage.Insert();
    end;

    local procedure CopyErrorsToBuffer(var TempLineErrorMessage: Record "Error Message" temporary; var TempErrorMessage: Record "Error Message" temporary)
    var
        ID: Integer;
    begin
        if TempErrorMessage.FindLast() then;
        ID := TempErrorMessage.ID + 1;

        if TempLineErrorMessage.FindSet() then
            repeat
                TempErrorMessage.TransferFields(TempLineErrorMessage);
                TempErrorMessage.ID := ID;
                TempErrorMessage.Insert();
                ID += 1;
            until TempLineErrorMessage.Next() = 0;
    end;

    local procedure PackErrorMessagesToResults(var TempErrorMessage: Record "Error Message" temporary; var Results: Dictionary of [Text, Text])
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
        JSON: Text;
    begin
        if TempErrorMessage.FindSet() then
            repeat
                JSON := ErrorMessageMgt.ErrorMessage2JSON(TempErrorMessage);
                Results.Add(Format(TempErrorMessage.ID), JSON);
            until TempErrorMessage.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    begin
    end;
}
