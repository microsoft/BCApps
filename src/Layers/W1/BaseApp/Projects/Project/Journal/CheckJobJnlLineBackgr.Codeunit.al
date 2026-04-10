// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

using Microsoft.Projects.Project.Posting;
using Microsoft.Utilities;
using System.Utilities;

codeunit 9073 "Check Job Jnl. Line. Backgr."
{
    trigger OnRun()
    var
        TempErrorMessage: Record "Error Message" temporary;
        Args: Dictionary of [Text, Text];
        Jobults: Dictionary of [Text, Text];
    begin
        Args := Page.GetBackgroundParameters();

        RunCheck(Args, TempErrorMessage);

        PackErrorMessagesToJobults(TempErrorMessage, Jobults);

        Page.SetBackgroundTaskResult(Jobults);
    end;

    procedure RunCheck(Args: Dictionary of [Text, Text]; var TempErrorMessage: Record "Error Message" temporary)
    var
        JobJnlLine: Record "Job Journal Line";
        ErrorHandlingParameters: Record "Error Handling Parameters";
    begin
        ErrorHandlingParameters.FromArgs(Args);

        if ErrorHandlingParameters."Full Batch Check" then begin
            JobJnlLine.SetRange("Journal Template Name", ErrorHandlingParameters."Journal Template Name");
            JobJnlLine.SetRange("Journal Batch Name", ErrorHandlingParameters."Journal Batch Name");
            CheckJobJnlLines(JobJnlLine, TempErrorMessage)
        end else begin
            if JobJnlLine.Get(ErrorHandlingParameters."Journal Template Name", ErrorHandlingParameters."Journal Batch Name", ErrorHandlingParameters."Line No.") then
                CheckJobJnlLine(JobJnlLine, TempErrorMessage);

            if ErrorHandlingParameters."Line No." <> ErrorHandlingParameters."Previous Line No." then
                if JobJnlLine.Get(ErrorHandlingParameters."Journal Template Name", ErrorHandlingParameters."Journal Batch Name", ErrorHandlingParameters."Previous Line No.") then
                    CheckJobJnlLine(JobJnlLine, TempErrorMessage);
        end;
    end;

    local procedure CheckJobJnlLines(var JobJnlLine: Record "Job Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    begin
        if JobJnlLine.FindSet() then
            repeat
                CheckJobJnlLine(JobJnlLine, TempErrorMessage);
            until JobJnlLine.Next() = 0;
    end;

    local procedure CheckJobJnlLine(var JobJnlLine: Record "Job Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    begin
        RunJobJnlCheckLineCodeunit(JobJnlLine, TempErrorMessage);

        OnAfterCheckJobJnlLine(JobJnlLine, TempErrorMessage);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure RunJobJnlCheckLineCodeunit(JobJnlLine: Record "Job Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    var
        TempLineErrorMessage: Record "Error Message" temporary;
        JobJnlCheckLine: Codeunit "Job Jnl.-Check Line";
    begin
        if not JobJnlCheckLine.Run(JobJnlLine) then
            InsertTempLineErrorMessage(
                TempLineErrorMessage,
                JobJnlLine.RecordId(),
                0,
                GetLastErrorText(),
                false);

        if HasCollectedErrors then begin
            CollectErrors(JobJnlLine, TempLineErrorMessage);
            CopyErrorsToBuffer(TempLineErrorMessage, TempErrorMessage);
        end;
    end;

    procedure CollectErrors(JobJnlLine: Record "Job Journal Line"; var TempLineErrorMessage: Record "Error Message" temporary)
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
                TempLineErrorMessage."Context Table Number" := Database::"Job Journal Line";
                TempLineErrorMessage.Validate("Context Record ID", JobJnlLine.RecordId);
                if ErrInfo.RecordId = JobJnlLine.RecordId then
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
        TempLineErrorMessage."Table Number" := Database::"Job Journal Line";
        TempLineErrorMessage."Context Record ID" := ContextRecordId;
        TempLineErrorMessage."Context Field Number" := ContextFieldNo;
        TempLineErrorMessage."Context Table Number" := Database::"Job Journal Line";
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

    local procedure PackErrorMessagesToJobults(var TempErrorMessage: Record "Error Message" temporary; var Jobults: Dictionary of [Text, Text])
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
        JSON: Text;
    begin
        if TempErrorMessage.FindSet() then
            repeat
                JSON := ErrorMessageMgt.ErrorMessage2JSON(TempErrorMessage);
                Jobults.Add(Format(TempErrorMessage.ID), JSON);
            until TempErrorMessage.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckJobJnlLine(var JobJnlLine: Record "Job Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    begin
    end;
}
