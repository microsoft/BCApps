// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Utilities;
using System.Utilities;

codeunit 9081 "Check Gen. Jnl. Line. Backgr."
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

    var
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        DocumentOutOfBalanceErr: Label 'Document No. %1 is out of balance by %2', Comment = '%1 - document number, %2 = amount';
        RecurringDocumentOutOfBalanceErr: Label 'Document No. %1 is out of balance.', Comment = '%1 - document number';
        RecurringLineIsExpiredErr: Label 'The posting date %1 must be less or equal the expiration date %2 in the document %3.', Comment = '%1 - posting date, %2 - expiration date, %3 - document number';
        RecurringLineIsOutOfWorkdateErr: Label 'The posting date %1 must be less or equal the working date %2 in the document %3.', Comment = '%1 - posting date, %2 - working date, %3 - document number';

    procedure RunCheck(Args: Dictionary of [Text, Text]; var TempErrorMessage: Record "Error Message" temporary)
    var
        GenJnlLine: Record "Gen. Journal Line";
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        ErrorHandlingParameters: Record "Error Handling Parameters";
    begin
        ErrorHandlingParameters.FromArgs(Args);

        GenJnlLine.SetRange("Journal Template Name", ErrorHandlingParameters."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", ErrorHandlingParameters."Journal Batch Name");
        if ErrorHandlingParameters."Full Batch Check" then
            CheckGenJnlLines(GenJnlLine, TempErrorMessage)
        else
            if ErrorHandlingParameters."Line Modified" then begin
                CheckDocument(GenJnlLine, ErrorHandlingParameters."Previous Document No.", ErrorHandlingParameters."Previous Posting Date", TempErrorMessage);

                if ErrorHandlingParameters.IsGenJnlDocumentChanged() then
                    CheckDocument(GenJnlLine, ErrorHandlingParameters."Document No.", ErrorHandlingParameters."Posting Date", TempErrorMessage);
            end;

        BackgroundErrorHandlingMgt.GetDeletedDocumentsFromArgs(Args, TempGenJnlLine);
        if TempGenJnlLine.FindSet() then
            repeat
                CheckDocument(GenJnlLine, TempGenJnlLine."Document No.", TempGenJnlLine."Posting Date", TempErrorMessage);
            until TempGenJnlLine.Next() = 0;
    end;

    local procedure CheckDocument(var GenJnlLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; PostingDate: Date; var TempErrorMessage: Record "Error Message" temporary)
    begin
        GenJnlLine.SetRange("Document No.", DocumentNo);
        GenJnlLine.SetRange("Posting Date", PostingDate);
        CheckGenJnlLines(GenJnlLine, TempErrorMessage);
    end;

    local procedure CheckGenJnlLines(var GenJnlLine: Record "Gen. Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    begin
        if GenJnlLine.FindSet() then
            repeat
                CheckGenJnlLine(GenJnlLine, TempErrorMessage);
            until GenJnlLine.Next() = 0;
    end;

    local procedure CheckGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    begin
        RunGenJnlCheckLineCodeunit(GenJnlLine, TempErrorMessage);
        CheckRecurringGenJnlLine(GenJnlLine, TempErrorMessage);
        CheckGenJnlLineDocBalance(GenJnlLine, TempErrorMessage);

        OnAfterCheckGenJnlLine(GenJnlLine, TempErrorMessage);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure RunGenJnlCheckLineCodeunit(GenJnlLine: Record "Gen. Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    var
        TempLineErrorMessage: Record "Error Message" temporary;
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        GenJnlCheckLine.SetLogErrorMode(true);

        if GenJnlCheckLine.Run(GenJnlLine) then begin
            GenJnlCheckLine.GetErrors(TempLineErrorMessage);
            ErrorMessageMgt.CollectErrors(TempLineErrorMessage);
            CopyErrorsToBuffer(TempLineErrorMessage, TempErrorMessage);
        end else begin
            InsertTempLineErrorMessage(
                TempLineErrorMessage,
                GenJnlLine.RecordId(),
                0,
                GetLastErrorText(),
                false);

            CopyErrorsToBuffer(TempLineErrorMessage, TempErrorMessage);
        end;
    end;

    local procedure CheckRecurringGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    var
        TempLineErrorMessage: Record "Error Message" temporary;
        Description: Text;
    begin
        if GenJnlLine."Recurring Method" = GenJnlLine."Recurring Method"::" " then
            exit;

        if (GenJnlLine."Expiration Date" <> 0D) and (GenJnlLine."Expiration Date" < GenJnlLine."Posting Date") then begin
            Description := StrSubstNo(RecurringLineIsExpiredErr, GenJnlLine."Posting Date", GenJnlLine."Expiration Date", GenJnlLine."Document No.");
            InsertTempLineErrorMessage(
                    TempLineErrorMessage,
                    GenJnlLine.RecordId(),
                    GenJnlLine.FieldNo("Expiration Date"),
                    Description,
                    false);
            CopyErrorsToBuffer(TempLineErrorMessage, TempErrorMessage);
        end;

        if GenJnlLine."Posting Date" > WorkDate() then begin
            Description := StrSubStNo(RecurringLineIsOutOfWorkdateErr, GenJnlLine."Posting Date", WorkDate(), GenJnlLine."Document No.");
            InsertTempLineErrorMessage(
                TempLineErrorMessage,
                GenJnlLine.RecordId(),
                GenJnlLine.FieldNo("Posting Date"),
                Description,
                false);
            CopyErrorsToBuffer(TempLineErrorMessage, TempErrorMessage);
        end;
    end;

    local procedure CheckGenJnlLineDocBalance(GenJnlLine: Record "Gen. Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    var
        TempLineErrorMessage: Record "Error Message" temporary;
        DocumentBalance: Decimal;
        Description: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGenJnlLineDocBalance(GenJnlLine, TempErrorMessage, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        DocumentBalance := GenJnlLine.GetDocumentBalance(GenJnlLine);
        if DocumentBalance <> 0 then begin
            if GenJnlLine."Recurring Method" <> GenJnlLine."Recurring Method"::" " then
                Description := StrSubstNo(RecurringDocumentOutOfBalanceErr, GenJnlLine."Document No.")
            else
            Description := StrSubstNo(DocumentOutOfBalanceErr, GenJnlLine."Document No.", DocumentBalance);
            InsertTempLineErrorMessage(
                TempLineErrorMessage,
                GenJnlLine.RecordId(),
                GenJnlLine.FieldNo("Balance (LCY)"),
                Description,
                DocumentBalanceErrorExists(Description, TempErrorMessage));

            TempErrorMessage.Reset();
            CopyErrorsToBuffer(TempLineErrorMessage, TempErrorMessage);
        end;
    end;

    local procedure DocumentBalanceErrorExists(Description: Text; var TempErrorMessage: Record "Error Message" temporary): Boolean
    begin
        TempErrorMessage.SetRange("Message", Description);
        exit(not TempErrorMessage.IsEmpty());
    end;

    local procedure InsertTempLineErrorMessage(var TempLineErrorMessage: Record "Error Message" temporary; ContextRecordId: RecordId; ContextFieldNo: Integer; Description: Text; Duplicate: Boolean)
    begin
        TempLineErrorMessage."Record ID" := ContextRecordId;
        TempLineErrorMessage."Field Number" := ContextFieldNo;
        TempLineErrorMessage."Table Number" := Database::"Gen. Journal Line";
        TempLineErrorMessage."Context Record ID" := ContextRecordId;
        TempLineErrorMessage."Context Field Number" := ContextFieldNo;
        TempLineErrorMessage."Context Table Number" := Database::"Gen. Journal Line";
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
                TempErrorMessage.SetErrorCallStack(TempLineErrorMessage.GetErrorCallStack());
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
    local procedure OnAfterCheckGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGenJnlLineDocBalance(GenJnlLine: Record "Gen. Journal Line"; var TempErrorMessage: Record "Error Message"; var IsHandled: Boolean)
    begin
    end;
}
