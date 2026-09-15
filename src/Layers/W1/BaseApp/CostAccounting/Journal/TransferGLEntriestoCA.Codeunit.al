// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Journal;

using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Ledger;
using Microsoft.CostAccounting.Posting;
using Microsoft.CostAccounting.Setup;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.AuditCodes;
using System.Utilities;

codeunit 1105 "Transfer GL Entries to CA"
{
    Permissions = TableData "G/L Entry" = rm;

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRun(IsHandled);
        if IsHandled then
            exit;

        ConfirmTransferGLtoCA();
    end;

    var
        CostAccSetup: Record "Cost Accounting Setup";
        GLEntry: Record "G/L Entry";
        CostType: Record "Cost Type";
        TempCostJnlLine: Record "Cost Journal Line" temporary;
        CostRegister: Record "Cost Register";
        CostAccMgt: Codeunit "Cost Account Mgt";
        Window: Dialog;
        LastLineNo: Integer;
        NoOfCombinedEntries: Integer;
        FirstGLEntryNo: Integer;
        LastGLEntryNo: Integer;
        NoOfJnlLines: Integer;
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        PostingDate: Date;
        BatchRun: Boolean;
        GotCostAccSetup: Boolean;
#pragma warning disable AA0074
        Text000: Label 'Income statement accounts that have cost centers or cost objects will be transferred to Cost Accounting.\All entries since the last transfer will be processed.\\The link between cost type and G/L account will be verified.\\Do you want to start the transfer?';
#pragma warning disable AA0470
        Text001: Label 'Transfer G/L Entries to Cost Accounting.\G/L Entry No.          #1########\Cost Type              #2########\Combined entries       #3########\No. of Cost Entries    #4########';
        Text002: Label 'G/L entries from No. %1 have been processed. %2 cost entries have been created.';
#pragma warning restore AA0470
        Text003: Label 'Combined entries per month %1', Comment = '%1 - Posting Date.';
        Text004: Label 'Combined entries per day %1', Comment = '%1 - Posting Date';
        Text005: Label 'There are no G/L entries that meet the criteria for transfer to cost accounting.';
        Text006: Label 'Posting Cost Entries @1@@@@@@@@@@\';
#pragma warning restore AA0074

    local procedure ConfirmTransferGLtoCA()
    var
        ConfirmMgt: Codeunit "Confirm Management";
    begin
        if not ConfirmMgt.GetResponseOrDefault(Text000, true) then
            exit;
        TransferGLtoCA();

        Message(Text002, FirstGLEntryNo, NoOfJnlLines);
    end;

    procedure TransferGLtoCA()
    begin
        ClearAll();

        LinkCostTypesToGLAccounts();

        Window.Open(Text001);

        BatchRun := true;
        GetGLEntries();

        Window.Close();
    end;

    local procedure LinkCostTypesToGLAccounts()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLinkCostTypesToGLAccounts(IsHandled);
        if IsHandled then
            exit;

        CostAccMgt.LinkCostTypesToGLAccounts();
    end;

    procedure GetGLEntries()
    var
        SourceCodeSetup: Record "Source Code Setup";
        CostCenterCode: Code[20];
        CostObjectCode: Code[20];
        CombinedEntryText: Text[50];
        CombineEntries: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetGLEntries(IsHandled);
        if IsHandled then
            exit;

        GetCostAccSetup();
        SourceCodeSetup.Get();
        SourceCodeSetup.TestField("G/L Entry to CA");

        if not BatchRun then begin
            if not CostAccSetup."Auto Transfer from G/L" then
                exit;
            TempCostJnlLine.DeleteAll();
            ClearAll();
            GetCostAccSetup();
        end;

        CostRegister.LockTable();
        CostRegister.SetCurrentKey(Source);
        CostRegister.SetRange(Source, CostRegister.Source::"Transfer from G/L");
        if CostRegister.FindLast() then
            FirstGLEntryNo := CostRegister."To G/L Entry No." + 1
        else
            FirstGLEntryNo := 1;

        if GLEntry.FindLast() then
            LastGLEntryNo := GLEntry."Entry No.";

        GLEntry.SetRange("Entry No.", FirstGLEntryNo, LastGLEntryNo);
        GLEntry.SetFilter("Posting Date", '%1..', CostAccSetup."Starting Date for G/L Transfer");
        OnGetGLEntriesOnAfterSetGLEntryFilters(GLEntry, FirstGLEntryNo, LastGLEntryNo, CostAccSetup."Starting Date for G/L Transfer");
        GLEntry.SetLoadFields("Entry No.", "Dimension Set ID", "Posting Date", "G/L Account No.", Amount, "Document No.", Description, "Additional-Currency Amount", "Add.-Currency Credit Amount", "Add.-Currency Debit Amount");
        if GLEntry.FindSet() then
            repeat
                if BatchRun and ((GLEntry."Entry No." mod 100) = 0) then
                    Window.Update(1, Format(GLEntry."Entry No."));
                CostCenterCode := '';
                CostObjectCode := '';

                if not SkipGLEntry(GLEntry) then
                    case true of // only need Cost Center or Cost Object
                        GetCostCenterCode(GLEntry."Dimension Set ID", CostCenterCode),
                        GetCostObjectCode(GLEntry."Dimension Set ID", CostObjectCode):
                            begin
                                IsHandled := false;
                                OnBeforeProcessGLEntryInGetGLEntries(GLEntry, CostCenterCode, CostObjectCode, BatchRun, IsHandled);
                                if not IsHandled then begin
                                    case CostType."Combine Entries" of
                                        CostType."Combine Entries"::None:
                                            PostingDate := GLEntry."Posting Date";
                                        CostType."Combine Entries"::Month:
                                            begin
                                                PostingDate := CalcDate('<CM>', GLEntry."Posting Date");
                                                CombinedEntryText := StrSubstNo(Text003, PostingDate);
                                            end;
                                        CostType."Combine Entries"::Day:
                                            begin
                                                PostingDate := GLEntry."Posting Date";
                                                CombinedEntryText := StrSubstNo(Text004, PostingDate);
                                            end;
                                    end;

                                    CombineEntries := CostType."Combine Entries" <> CostType."Combine Entries"::None;
                                    IsHandled := false;
                                    OnGetGLEntriesOnBeforeCombineEntries(CostObjectCode, GLEntry, CostType, CombineEntries, CostCenterCode, IsHandled);
                                    if not IsHandled then
                                        if CombineEntries then begin
                                            TempCostJnlLine.Reset();
                                            TempCostJnlLine.SetRange("Cost Type No.", CostType."No.");
                                            if CostCenterCode <> '' then
                                                TempCostJnlLine.SetRange("Cost Center Code", CostCenterCode)
                                            else
                                                TempCostJnlLine.SetRange("Cost Object Code", CostObjectCode);
                                            TempCostJnlLine.SetRange("Posting Date", PostingDate);
                                            if TempCostJnlLine.FindFirst() then
                                                ModifyCostJournalLine(CombinedEntryText)
                                            else
                                                InsertCostJournalLine(CostCenterCode, CostObjectCode);
                                        end else
                                            InsertCostJournalLine(CostCenterCode, CostObjectCode);

                                    if BatchRun and ((GLEntry."Entry No." mod 100) = 0) then begin
                                        Window.Update(2, CostType."No.");
                                        Window.Update(3, Format(NoOfCombinedEntries));
                                        Window.Update(4, Format(NoOfJnlLines));
                                    end;
                                end;
                            end;
                    end;
            until GLEntry.Next() = 0;

        OnAfterPrepareCostJournalLines(TempCostJnlLine, TotalDebit, TotalCredit, NoOfJnlLines, BatchRun);

        if NoOfJnlLines = 0 then begin
            if BatchRun then begin
                Window.Close();
                Error(Text005);
            end;
            exit;
        end;

        PostCostJournalLines();
    end;

    local procedure InsertCostJournalLine(CostCenterCode: Code[20]; CostObjectCode: Code[20])
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        TempCostJnlLine.Init();
        LastLineNo += 1;
        TempCostJnlLine."Line No." := LastLineNo;
        TempCostJnlLine."Cost Type No." := CostType."No.";
        TempCostJnlLine."Posting Date" := PostingDate;
        TempCostJnlLine."Document No." := GLEntry."Document No.";
        TempCostJnlLine.Description := GLEntry.Description;
        TempCostJnlLine.Amount := GLEntry.Amount;
        TempCostJnlLine."Additional-Currency Amount" := GLEntry."Additional-Currency Amount";
        TempCostJnlLine."Add.-Currency Credit Amount" := GLEntry."Add.-Currency Credit Amount";
        TempCostJnlLine."Add.-Currency Debit Amount" := GLEntry."Add.-Currency Debit Amount";
        if CostAccMgt.CostCenterExists(CostCenterCode) then
            TempCostJnlLine."Cost Center Code" := CostCenterCode;
        if CostAccMgt.CostObjectExists(CostObjectCode) then
            TempCostJnlLine."Cost Object Code" := CostObjectCode;
        TempCostJnlLine."Source Code" := SourceCodeSetup."G/L Entry to CA";
        TempCostJnlLine."G/L Entry No." := GLEntry."Entry No.";
        TempCostJnlLine."System-Created Entry" := true;
        OnBeforeInsertCostJournalLine(TempCostJnlLine, GLEntry);
        TempCostJnlLine.Insert();
        OnAfterInsertCostJournalLine(TempCostJnlLine);

        NoOfJnlLines := NoOfJnlLines + 1;
        MaintainTotals(GLEntry.Amount);
    end;

    local procedure ModifyCostJournalLine(EntryText: Text[50])
    begin
        TempCostJnlLine.Description := EntryText;
        TempCostJnlLine.Amount := TempCostJnlLine.Amount + GLEntry.Amount;
        TempCostJnlLine."Additional-Currency Amount" :=
          TempCostJnlLine."Additional-Currency Amount" + GLEntry."Additional-Currency Amount";
        TempCostJnlLine."Add.-Currency Debit Amount" :=
          TempCostJnlLine."Add.-Currency Debit Amount" + GLEntry."Add.-Currency Debit Amount";
        TempCostJnlLine."Add.-Currency Credit Amount" :=
          TempCostJnlLine."Add.-Currency Credit Amount" + GLEntry."Add.-Currency Credit Amount";
        TempCostJnlLine."Document No." := GLEntry."Document No.";
        TempCostJnlLine."G/L Entry No." := GLEntry."Entry No.";
        TempCostJnlLine.Modify();
        NoOfCombinedEntries := NoOfCombinedEntries + 1;
        MaintainTotals(GLEntry.Amount);
    end;

    local procedure PostCostJournalLines()
    var
        CostJnlLine: Record "Cost Journal Line";
        CAJnlPostLine: Codeunit "CA Jnl.-Post Line";
        Window2: Dialog;
        HideDialog: Boolean;
    begin
        TempCostJnlLine.Reset();
        HideDialog := false;
        OnBeforePostCostJournalLinesOpenDialog(TempCostJnlLine, HideDialog);
        if not HideDialog then
            Window2.Open(Text006);
        TempCostJnlLine.SetCurrentKey("G/L Entry No.");
        if TempCostJnlLine.FindSet() then
            repeat
                if not HideDialog then
                    Window2.Update(1, TempCostJnlLine."Line No.");
                CostJnlLine := TempCostJnlLine;
                CAJnlPostLine.RunWithCheck(CostJnlLine);
            until TempCostJnlLine.Next() = 0;
        if not HideDialog then
            Window2.Close();
    end;

    local procedure GetCostAccSetup()
    begin
        if not GotCostAccSetup then begin
            CostAccSetup.Get();
            GotCostAccSetup := true;
        end;
    end;

    local procedure MaintainTotals(Amount: Decimal)
    begin
        if Amount > 0 then
            TotalDebit := TotalDebit + GLEntry.Amount
        else
            TotalCredit := TotalCredit - GLEntry.Amount;
    end;

    local procedure SkipGLEntry(GLEntry: Record "G/L Entry"): Boolean
    var
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeSkipGLEntry(GLEntry, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        GLAcc.Get(GLEntry."G/L Account No.");
        case true of // exit on first TRUE, skipping the other checks
            GLEntry.Amount = 0,
          IsBalanceSheetAccount(GLAcc),
          not IsLinkedToCostType(GLAcc),
          not IsNormalDate(GLEntry."Posting Date"):
                exit(true);
        end;
    end;

    local procedure IsBalanceSheetAccount(GLAcc: Record "G/L Account"): Boolean
    begin
        exit(GLAcc."Income/Balance" = GLAcc."Income/Balance"::"Balance Sheet");
    end;

    local procedure IsLinkedToCostType(GLAcc: Record "G/L Account"): Boolean
    begin
        exit(CostType.Get(GLAcc."Cost Type No."));
    end;

    local procedure IsNormalDate(Date: Date): Boolean
    begin
        exit(Date = NormalDate(Date));
    end;

    local procedure GetCostCenterCode(DimSetID: Integer; var CostCenterCode: Code[20]): Boolean
    begin
        CostCenterCode := CostAccMgt.GetCostCenterCodeFromDimSet(DimSetID);
        exit(CostCenterCode <> '');
    end;

    local procedure GetCostObjectCode(DimSetID: Integer; var CostObjectCode: Code[20]): Boolean
    begin
        CostObjectCode := CostAccMgt.GetCostObjectCodeFromDimSet(DimSetID);
        exit(CostObjectCode <> '');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertCostJournalLine(var TempCostJnlLine: Record "Cost Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareCostJournalLines(var TempCostJnlLine: Record "Cost Journal Line" temporary; var TotalDebit: Decimal; var TotalCredit: Decimal; var NoOfJnlLines: Integer; var BatchRun: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetGLEntries(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCostJournalLine(var TempCostJnlLine: Record "Cost Journal Line" temporary; GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeLinkCostTypesToGLAccounts(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSkipGLEntry(GLEntry: Record "G/L Entry"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCostJournalLinesOpenDialog(var TempCostJnlLine: Record "Cost Journal Line" temporary; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetGLEntriesOnAfterSetGLEntryFilters(var GLEntry: Record "G/L Entry"; FirstGLEntryNo: Integer; LastGLEntryNo: Integer; StartingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetGLEntriesOnBeforeCombineEntries(var CostObjectCode: Code[20]; GLEntry: Record "G/L Entry"; CostType: Record "Cost Type"; var CombineEntries: Boolean; var CostCenterCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessGLEntryInGetGLEntries(GLEntry: Record "G/L Entry"; var CostCenterCode: Code[20]; var CostObjectCode: Code[20]; BatchRun: Boolean; var IsHandled: Boolean)
    begin
    end;
}

