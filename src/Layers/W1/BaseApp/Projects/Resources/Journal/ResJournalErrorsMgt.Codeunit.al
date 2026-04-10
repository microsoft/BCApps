// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Journal;

using Microsoft.Utilities;
using System.Utilities;

codeunit 9076 "Res. Journal Errors Mgt."
{
    SingleInstance = true;

    trigger OnRun()
    begin

    end;

    var
        TempErrorMessage: Record "Error Message" temporary;
        TempResJnlLineModified: Record "Res. Journal Line" temporary;
        TempDeletedResJnlLine: Record "Res. Journal Line" temporary;
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

    procedure SetResJnlLineOnModify(Rec: Record "Res. Journal Line")
    begin
        if BackgroundErrorHandlingMgt.BackgroundValidationFeatureEnabled() then
            SaveResJournalLineToBuffer(Rec, TempResJnlLineModified);
    end;

    local procedure SaveResJournalLineToBuffer(ResJournalLine: Record "Res. Journal Line"; var BufferLine: Record "Res. Journal Line" temporary)
    begin
        if BufferLine.Get(ResJournalLine."Journal Template Name", ResJournalLine."Journal Batch Name", ResJournalLine."Line No.") then begin
            BufferLine.TransferFields(ResJournalLine);
            BufferLine.Modify();
        end else begin
            BufferLine := ResJournalLine;
            BufferLine.Insert();
        end;
    end;

    procedure GetResJnlLinePreviousLineNo() PrevLineNo: Integer
    begin
        if TempResJnlLineModified.FindFirst() then begin
            PrevLineNo := TempResJnlLineModified."Line No.";
            if TempResJnlLineModified.Delete() then;
        end;
    end;

    procedure SetFullBatchCheck(NewFullBatchCheck: Boolean)
    begin
        FullBatchCheck := NewFullBatchCheck;
    end;

    procedure GetDeletedResJnlLine(var TempResJnlLine: Record "Res. Journal Line" temporary; ClearBuffer: Boolean): Boolean
    begin
        if TempDeletedResJnlLine.FindSet() then begin
            repeat
                TempResJnlLine := TempDeletedResJnlLine;
                TempResJnlLine.Insert();
            until TempDeletedResJnlLine.Next() = 0;

            if ClearBuffer then
                TempDeletedResJnlLine.DeleteAll();
            exit(true);
        end;

        exit(false);
    end;

    procedure CollectResJnlCheckParameters(ResJnlLine: Record "Res. Journal Line"; var ErrorHandlingParameters: Record "Error Handling Parameters")
    begin
        ErrorHandlingParameters."Journal Template Name" := ResJnlLine."Journal Template Name";
        ErrorHandlingParameters."Journal Batch Name" := ResJnlLine."Journal Batch Name";
        ErrorHandlingParameters."Line No." := ResJnlLine."Line No.";
        ErrorHandlingParameters."Full Batch Check" := FullBatchCheck;
        ErrorHandlingParameters."Previous Line No." := GetResJnlLinePreviousLineNo();
    end;

    procedure InsertDeletedResJnlLine(ResJnlLine: Record "Res. Journal Line")
    begin
        if BackgroundErrorHandlingMgt.BackgroundValidationFeatureEnabled() then begin
            TempDeletedResJnlLine := ResJnlLine;
            if TempDeletedResJnlLine.Insert() then;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Resource Journal", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventResJournal(var Rec: Record "Res. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedResJnlLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Resource Journal", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventResJournal(var Rec: Record "Res. Journal Line"; var xRec: Record "Res. Journal Line"; var AllowModify: Boolean)
    begin
        SetResJnlLineOnModify(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Resource Journal", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventResJournal(var Rec: Record "Res. Journal Line"; var xRec: Record "Res. Journal Line"; var AllowInsert: Boolean)
    begin
        SetResJnlLineOnModify(Rec);
    end;
}
