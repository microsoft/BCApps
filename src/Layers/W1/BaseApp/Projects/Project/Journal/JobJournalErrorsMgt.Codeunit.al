// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

using Microsoft.Utilities;
using System.Utilities;

codeunit 9074 "Job Journal Errors Mgt."
{
    SingleInstance = true;

    trigger OnRun()
    begin

    end;

    var
        TempErrorMessage: Record "Error Message" temporary;
        TempJobJnlLineModified: Record "Job Journal Line" temporary;
        TempDeletedJobJnlLine: Record "Job Journal Line" temporary;
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        FullBatchCheck: Boolean;

    procedure SetErrorMessages(var SourceTempErrorMessage: Record "Error Message" temporary)
    begin
        TempErrorMessage.Copy(SourceTempErrorMessage, true);
    end;

    procedure GetErrorMessages(var NewTempErrorMessage: Record "Error Message" temporary)
    begin
        NewTempErrorMessage.Copy(TempErrorMessage, true);
    end;

    procedure SetJobJnlLineOnModify(Rec: Record "Job Journal Line")
    begin
        if BackgroundErrorHandlingMgt.BackgroundValidationFeatureEnabled() then
            SaveJobJournalLineToBuffer(Rec, TempJobJnlLineModified);
    end;

    local procedure SaveJobJournalLineToBuffer(JobJournalLine: Record "Job Journal Line"; var BufferLine: Record "Job Journal Line" temporary)
    begin
        if BufferLine.Get(JobJournalLine."Journal Template Name", JobJournalLine."Journal Batch Name", JobJournalLine."Line No.") then begin
            BufferLine.TransferFields(JobJournalLine);
            BufferLine.Modify();
        end else begin
            BufferLine := JobJournalLine;
            BufferLine.Insert();
        end;
    end;

    procedure GetJobJnlLinePreviousLineNo() PrevLineNo: Integer
    begin
        if TempJobJnlLineModified.FindFirst() then begin
            PrevLineNo := TempJobJnlLineModified."Line No.";
            if TempJobJnlLineModified.Delete() then;
        end;
    end;

    procedure SetFullBatchCheck(NewFullBatchCheck: Boolean)
    begin
        FullBatchCheck := NewFullBatchCheck;
    end;

    procedure GetDeletedJobJnlLine(var TempJobJnlLine: Record "Job Journal Line" temporary; ClearBuffer: Boolean): Boolean
    begin
        if TempDeletedJobJnlLine.FindSet() then begin
            repeat
                TempJobJnlLine := TempDeletedJobJnlLine;
                TempJobJnlLine.Insert();
            until TempDeletedJobJnlLine.Next() = 0;

            if ClearBuffer then
                TempDeletedJobJnlLine.DeleteAll();
            exit(true);
        end;

        exit(false);
    end;

    procedure CollectJobJnlCheckParameters(JobJnlLine: Record "Job Journal Line"; var ErrorHandlingParameters: Record "Error Handling Parameters")
    begin
        ErrorHandlingParameters."Journal Template Name" := JobJnlLine."Journal Template Name";
        ErrorHandlingParameters."Journal Batch Name" := JobJnlLine."Journal Batch Name";
        ErrorHandlingParameters."Line No." := JobJnlLine."Line No.";
        ErrorHandlingParameters."Full Batch Check" := FullBatchCheck;
        ErrorHandlingParameters."Previous Line No." := GetJobJnlLinePreviousLineNo();
    end;

    procedure InsertDeletedJobJnlLine(JobJnlLine: Record "Job Journal Line")
    begin
        if BackgroundErrorHandlingMgt.BackgroundValidationFeatureEnabled() then begin
            TempDeletedJobJnlLine := JobJnlLine;
            if TempDeletedJobJnlLine.Insert() then;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Job Journal", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventJobJournal(var Rec: Record "Job Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedJobJnlLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Job Journal", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventJobJournal(var Rec: Record "Job Journal Line"; var xRec: Record "Job Journal Line"; var AllowModify: Boolean)
    begin
        SetJobJnlLineOnModify(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Job Journal", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventJobJournal(var Rec: Record "Job Journal Line"; var xRec: Record "Job Journal Line"; var AllowInsert: Boolean)
    begin
        SetJobJnlLineOnModify(Rec);
    end;
}
