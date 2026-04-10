// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;

codeunit 5624 "Cancel FA Ledger Entries"
{

    trigger OnRun()
    begin
    end;

    var
        FAJnlSetup: Record "FA Journal Setup";
        DeprBook: Record "Depreciation Book";
        GenJnlLine: Record "Gen. Journal Line";
        FAJnlLine: Record "FA Journal Line";
        FA: Record "Fixed Asset";
        GLIntegration: array[9] of Boolean;
        FAJnlNextLineNo: Integer;
        GenJnlNextLineNo: Integer;
        DeprBookCode: Code[10];
        GenJnlUsedOnce: Boolean;
        FAJnlUsedOnce: Boolean;
        FAJnlDocumentNo: Code[20];
        GenJnlDocumentNo: Code[20];
        HideValidationDialog: Boolean;

#pragma warning disable AA0074
        Text001: Label 'must be the same in all canceled ledger entries';
#pragma warning disable AA0470
        Text002: Label '%1 = %2 has already been canceled.';
#pragma warning restore AA0470
        Text003: Label 'The ledger entries have been transferred to the journal.';
#pragma warning disable AA0470
        Text004: Label '%1 = %2 cannot be canceled. Use %3 = %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure TransferLine(var FALedgEntry: Record "FA Ledger Entry"; BalAccount: Boolean; NewPostingDate: Date)
    var
        IsHandled: Boolean;
    begin
        ClearAll();
        if FALedgEntry.Find('+') then
            repeat
                if DeprBookCode = '' then
                    DeprBookCode := FALedgEntry."Depreciation Book Code";
                if DeprBookCode <> FALedgEntry."Depreciation Book Code" then
                    FALedgEntry.FieldError("Depreciation Book Code", Text001);
                if FALedgEntry."FA No." = '' then
                    Error(Text002, FALedgEntry.FieldCaption("Entry No."), FALedgEntry."Entry No.");
                FA.Get(FALedgEntry."FA No.");
                DeprBook.Get(FALedgEntry."Depreciation Book Code");
                IsHandled := false;
                OnTransferLineOnBeforeIndexGLIntegration(DeprBook, IsHandled);
                if not IsHandled then begin
                    DeprBook.IndexGLIntegration(GLIntegration);
                    CheckType(FALedgEntry);
                    if NewPostingDate > 0D then begin
                        FALedgEntry."Posting Date" := NewPostingDate;
                        DeprBook.TestField("Use Same FA+G/L Posting Dates", false);
                    end;
                    IsHandled := false;
                    OnTransferLineOnBeforeInsertJnlLine(FALedgEntry, BalAccount, FA."Budgeted Asset", IsHandled);
                    if not IsHandled then
                        if GLIntegration[FALedgEntry.ConvertPostingType() + 1] and not FA."Budgeted Asset" then
                            InsertGenJnlLine(FALedgEntry, BalAccount)
                        else
                            InsertFAJnlLine(FALedgEntry);
                end;
            until FALedgEntry.Next(-1) = 0;

        if not HideValidationDialog and GuiAllowed then
            Message(Text003);
    end;

    local procedure CheckType(var FALedgEntry: Record "FA Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckType(FALedgEntry, IsHandled);
        if IsHandled then
            exit;

        if (FALedgEntry."FA Posting Type".AsInteger() > FALedgEntry."FA Posting Type"::"Salvage Value".AsInteger()) or
               (FALedgEntry."FA Posting Category" <> FALedgEntry."FA Posting Category"::" ")
        then begin
            FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Proceeds on Disposal";
            Error(
              Text004,
              FALedgEntry.FieldCaption("Entry No."), FALedgEntry."Entry No.", FALedgEntry.FieldCaption("FA Posting Type"), FALedgEntry."FA Posting Type");
        end;
    end;

    procedure InsertFAJnlLine(var FALedgEntry: Record "FA Ledger Entry")
    begin
        if not FAJnlUsedOnce then begin
            FAJnlLine.LockTable();
            if DeprBook.Code = '' then
                DeprBook.Get(FALedgEntry."Depreciation Book Code");
            FAJnlSetup.FAJnlName(DeprBook, FAJnlLine, FAJnlNextLineNo);
            FAJnlUsedOnce := true;
            FAJnlDocumentNo :=
              FAJnlSetup.GetFAJnlDocumentNo(FAJnlLine, FALedgEntry."FA Posting Date", false);
        end;

        FALedgEntry.MoveToFAJnl(FAJnlLine);
        FAJnlLine."Document No." := FAJnlDocumentNo;
        FAJnlLine."Document Type" := FAJnlLine."Document Type"::" ";
        FAJnlLine."External Document No." := '';
        FAJnlLine."Shortcut Dimension 1 Code" := FALedgEntry."Global Dimension 1 Code";
        FAJnlLine."Shortcut Dimension 2 Code" := FALedgEntry."Global Dimension 2 Code";
        FAJnlLine."Dimension Set ID" := FALedgEntry."Dimension Set ID";
        FAJnlLine."FA Error Entry No." := FALedgEntry."Entry No.";
        FAJnlLine."Posting No. Series" := FAJnlSetup.GetFANoSeries(FAJnlLine);
        FAJnlLine.Validate(Amount, -FAJnlLine.Amount);
        FAJnlLine.Validate(Correction, DeprBook."Mark Errors as Corrections");
        FAJnlLine."Line No." := FAJnlLine."Line No." + 10000;
        OnBeforeFAJnlLineInsert(FAJnlLine, FALedgEntry);
        FAJnlLine.Insert(true);

        OnAfterInsertFAJnlLine(FAJnlLine, FALedgEntry);
    end;

    procedure InsertGenJnlLine(var FALedgEntry: Record "FA Ledger Entry"; BalAccount: Boolean)
    var
        FAInsertGLAcc: Codeunit "FA Insert G/L Account";
    begin
        if not GenJnlUsedOnce then begin
            GenJnlLine.LockTable();
            if DeprBook.Code = '' then
                DeprBook.Get(FALedgEntry."Depreciation Book Code");
            FAJnlSetup.GenJnlName(DeprBook, GenJnlLine, GenJnlNextLineNo);
            GenJnlUsedOnce := true;
            GenJnlDocumentNo :=
              FAJnlSetup.GetGenJnlDocumentNo(GenJnlLine, FALedgEntry."FA Posting Date", false);
        end;

        FALedgEntry.MoveToGenJnl(GenJnlLine);
        GenJnlLine."Document No." := GenJnlDocumentNo;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
        GenJnlLine."External Document No." := '';
        GenJnlLine."Shortcut Dimension 1 Code" := FALedgEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := FALedgEntry."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := FALedgEntry."Dimension Set ID";
        GenJnlLine."FA Error Entry No." := FALedgEntry."Entry No.";
        GenJnlLine.Validate(Amount, -GenJnlLine.Amount);
        GenJnlLine.Validate(Correction, DeprBook."Mark Errors as Corrections");
        GenJnlLine."Posting No. Series" := FAJnlSetup.GetGenNoSeries(GenJnlLine);
        GenJnlLine."Line No." := GenJnlLine."Line No." + 10000;
        OnBeforeGenJnlLineInsert(GenJnlLine, FALedgEntry, BalAccount);
        GenJnlLine.Insert(true);
        if BalAccount then
            FAInsertGLAcc.GetBalAcc(GenJnlLine);

        OnAfterInsertGenJnlLine(GenJnlLine, FALedgEntry, BalAccount);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertFAJnlLine(var FAJournalLine: Record "FA Journal Line"; var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var FALedgerEntry: Record "FA Ledger Entry"; BalAccount: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckType(FALedgerEntry: Record "FA Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFAJnlLineInsert(var FAJournalLine: Record "FA Journal Line"; FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; FALedgerEntry: Record "FA Ledger Entry"; BalAccount: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferLineOnBeforeInsertJnlLine(FALedgerEntry: Record "FA Ledger Entry"; BalAccount: Boolean; BudgetedAsset: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferLineOnBeforeIndexGLIntegration(DepreciationBook: Record "Depreciation Book"; var IsHandled: Boolean)
    begin
    end;
}

