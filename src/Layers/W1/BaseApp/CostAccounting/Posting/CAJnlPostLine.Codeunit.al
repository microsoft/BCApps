// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Posting;

using Microsoft.CostAccounting.Allocation;
using Microsoft.CostAccounting.Budget;
using Microsoft.CostAccounting.Journal;
using Microsoft.CostAccounting.Ledger;
using Microsoft.CostAccounting.Setup;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;

codeunit 1102 "CA Jnl.-Post Line"
{
    Permissions = TableData "Cost Entry" = rimd,
                  TableData "Cost Register" = rimd,
                  tabledata "G/L Entry" = r;
    TableNo = "Cost Journal Line";

    trigger OnRun()
    begin
        CostAccSetup.Get();
        RunWithCheck(Rec);
    end;

    var
        CostAccSetup: Record "Cost Accounting Setup";
        CostEntry: Record "Cost Entry";
        GlEntry: Record "G/L Entry";
        CostJnlLine: Record "Cost Journal Line";
        CostRegister: Record "Cost Register";
        CostBudgetRegister: Record "Cost Budget Register";
        CostAllocationSource: Record "Cost Allocation Source";
        CostBudgetEntry: Record "Cost Budget Entry";
        GLSetup: Record "General Ledger Setup";
        CAJnlCheckLine: Codeunit "CA Jnl.-Check Line";
        PostBudget: Boolean;
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        TotalBudgetAmount: Decimal;
        NextCostEntryNo: Integer;
        NextCostBudgetEntryNo: Integer;

    procedure RunWithCheck(var CostJnlLine2: Record "Cost Journal Line")
    begin
        CostJnlLine.Copy(CostJnlLine2);
        Code();
        CostJnlLine2 := CostJnlLine;

        OnAfterRunWithCheck(CostJnlLine2);
    end;

    local procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCode(CostJnlLine, IsHandled);
        if IsHandled then
            exit;

        if CostJnlLine.EmptyLine() then
            exit;

        CAJnlCheckLine.RunCheck(CostJnlLine);
        if CostJnlLine."Budget Name" <> '' then
            PostBudget := true;

        if PostBudget then begin
            if NextCostBudgetEntryNo = 0 then begin
                CostBudgetEntry.LockTable();
                NextCostBudgetEntryNo := CostBudgetEntry.GetLastEntryNo() + 1;
            end;
        end else
            if NextCostEntryNo = 0 then begin
                CostEntry.LockTable();
                NextCostEntryNo := CostEntry.GetLastEntryNo() + 1;
            end;
        PostLine();
    end;

    local procedure PostLine()
    begin
        if PostBudget then begin
            if CostJnlLine."Cost Type No." <> '' then
                InsertBudgetEntries(CostJnlLine."Cost Type No.", CostJnlLine."Cost Center Code", CostJnlLine."Cost Object Code", CostJnlLine.Amount);

            if CostJnlLine."Bal. Cost Type No." <> '' then
                InsertBudgetEntries(CostJnlLine."Bal. Cost Type No.", CostJnlLine."Bal. Cost Center Code", CostJnlLine."Bal. Cost Object Code", -CostJnlLine.Amount);
        end else begin
            if CostJnlLine."Cost Type No." <> '' then
                InsertCostEntries(CostJnlLine."Cost Type No.", CostJnlLine."Cost Center Code", CostJnlLine."Cost Object Code", CostJnlLine.Amount);

            if CostJnlLine."Bal. Cost Type No." <> '' then
                InsertCostEntries(CostJnlLine."Bal. Cost Type No.", CostJnlLine."Bal. Cost Center Code", CostJnlLine."Bal. Cost Object Code", -CostJnlLine.Amount);
        end;
    end;

    local procedure CreateCostRegister()
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        if CostRegister."No." = 0 then begin
            CostRegister.LockTable();
            if (not CostRegister.FindLast()) or (CostRegister."To Cost Entry No." <> 0) then begin
                CostRegister.Init();
                CostRegister."Journal Batch Name" := CostJnlLine."Journal Batch Name";
                CostRegister."No." := CostRegister."No." + 1;
                CostRegister."From Cost Entry No." := NextCostEntryNo;
                CostRegister."To Cost Entry No." := NextCostEntryNo;
                CostRegister."No. of Entries" := 1;
                CostRegister."Debit Amount" := TotalDebit;
                CostRegister."Credit Amount" := TotalCredit;
                CostRegister."Posting Date" := CostJnlLine."Posting Date";
                // from last journal line
                CostRegister."User ID" := CopyStr(UserId(), 1, MaxStrLen(CostRegister."User ID"));
                CostRegister."Processed Date" := Today;

                case CostJnlLine."Source Code" of
                    SourceCodeSetup."Cost Allocation":
                        begin
                            CostRegister.Source := CostRegister.Source::Allocation;
                            CostAllocationSource.Get(CostJnlLine."Allocation ID");
                            CostRegister.Level := CostAllocationSource.Level;
                        end;
                    SourceCodeSetup."G/L Entry to CA":
                        begin
                            CostRegister.Source := CostRegister.Source::"Transfer from G/L";
                            CostRegister."From G/L Entry No." := CostJnlLine."G/L Entry No.";
                            CostRegister."To G/L Entry No." := CostJnlLine."G/L Entry No.";
                        end;
                    SourceCodeSetup."Transfer Budget to Actual":
                        CostRegister.Source := CostRegister.Source::"Transfer from Budget";
                    else
                        CostRegister.Source := CostRegister.Source::"Cost Journal";
                end;
                OnCreateCostRegisterOnBeforeInsert(CostRegister, CostJnlLine, SourceCodeSetup);
                CostRegister.Insert();
            end;
        end else begin
            CostRegister."Debit Amount" := TotalDebit;
            CostRegister."Credit Amount" := TotalCredit;
            CostRegister."To G/L Entry No." := CostJnlLine."G/L Entry No.";
            CostRegister."To Cost Entry No." := NextCostEntryNo;
            CostRegister."No. of Entries" := CostRegister."To Cost Entry No." - CostRegister."From Cost Entry No." + 1;
            OnCreateCostRegisterOnBeforeModify(CostRegister, CostJnlLine, SourceCodeSetup);
            CostRegister.Modify();
        end;
    end;

    local procedure CreateCostBudgetRegister()
    begin
        if CostBudgetRegister."No." = 0 then begin
            CostBudgetRegister.LockTable();
            if (not CostBudgetRegister.FindLast()) or (CostBudgetRegister."To Cost Budget Entry No." <> 0) then begin
                CostBudgetRegister.Init();
                CostBudgetRegister."Journal Batch Name" := CostJnlLine."Journal Batch Name";
                CostBudgetRegister."Cost Budget Name" := CostJnlLine."Budget Name";
                CostBudgetRegister."No." := CostBudgetRegister."No." + 1;
                CostBudgetRegister."From Cost Budget Entry No." := NextCostBudgetEntryNo;
                CostBudgetRegister."To Cost Budget Entry No." := NextCostBudgetEntryNo;
                CostBudgetRegister."No. of Entries" := 1;
                CostBudgetRegister.Amount := TotalBudgetAmount;
                CostBudgetRegister."Posting Date" := CostJnlLine."Posting Date";
                // from last journal line
                CostBudgetRegister."User ID" := CopyStr(UserId(), 1, MaxStrLen(CostBudgetRegister."User ID"));
                CostBudgetRegister."Processed Date" := Today;
                CostAccSetup.Get();
                if CostJnlLine."Allocation ID" <> '' then
                    CostBudgetRegister.Source := CostBudgetRegister.Source::Allocation
                else
                    CostBudgetRegister.Source := CostBudgetRegister.Source::"Cost Journal";

                if CostJnlLine."Allocation ID" <> '' then begin
                    CostAllocationSource.Get(CostJnlLine."Allocation ID");
                    CostBudgetRegister.Level := CostAllocationSource.Level;
                end;
                CostBudgetRegister.Insert();
            end;
        end;
        CostBudgetRegister."To Cost Budget Entry No." := NextCostBudgetEntryNo;
        CostBudgetRegister."No. of Entries" := CostBudgetRegister."To Cost Budget Entry No." -
          CostBudgetRegister."From Cost Budget Entry No." + 1;
        CostBudgetRegister.Modify();
    end;

    local procedure InsertCostEntries(CT: Code[20]; CC: Code[20]; CO: Code[20]; Amt: Decimal)
    begin
        GLSetup.Get();
        CostEntry.Init();
        CostEntry."Entry No." := NextCostEntryNo;
        CostEntry."Cost Type No." := CT;
        CostEntry."Posting Date" := CostJnlLine."Posting Date";
        CostEntry."Document No." := CostJnlLine."Document No.";
        CostEntry.Description := CostJnlLine.Description;
        CostEntry."Cost Center Code" := CC;
        CostEntry."Cost Object Code" := CO;

        if CostJnlLine."System-Created Entry" then begin
            CostEntry."Additional-Currency Amount" := CostJnlLine."Additional-Currency Amount";
            CostEntry."Add.-Currency Debit Amount" := CostJnlLine."Add.-Currency Debit Amount";
            CostEntry."Add.-Currency Credit Amount" := CostJnlLine."Add.-Currency Credit Amount";
        end;

        CostEntry.Amount := Amt;
        if Amt > 0 then begin
            CostEntry."Debit Amount" := Amt;
            if GLSetup."Additional Reporting Currency" <> '' then begin
                CostEntry."Additional-Currency Amount" := CalcAddCurrAmount(Amt);
                CostEntry."Add.-Currency Debit Amount" := CostEntry."Additional-Currency Amount";
            end;
        end else begin
            CostEntry."Credit Amount" := -Amt;
            if GLSetup."Additional Reporting Currency" <> '' then begin
                CostEntry."Additional-Currency Amount" := CalcAddCurrAmount(Amt);
                CostEntry."Add.-Currency Credit Amount" := -CostEntry."Additional-Currency Amount";
            end;
        end;

        CostEntry."Reason Code" := CostJnlLine."Reason Code";
        if GlEntry.Get(CostJnlLine."G/L Entry No.") then
            CostEntry."G/L Account" := GlEntry."G/L Account No.";
        CostEntry."G/L Entry No." := CostJnlLine."G/L Entry No.";
        CostEntry."Source Code" := CostJnlLine."Source Code";
        CostEntry."System-Created Entry" := CostJnlLine."System-Created Entry";
        CostEntry.Allocated := CostJnlLine.Allocated;
        CostEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(CostEntry."User ID"));
        CostEntry."Batch Name" := CostJnlLine."Journal Batch Name";
        CostEntry."Allocation Description" := CostJnlLine."Allocation Description";
        CostEntry."Allocation ID" := CostJnlLine."Allocation ID";
        OnBeforeCostEntryInsert(CostEntry, CostJnlLine);
        CostEntry.Insert();
        OnAfterCostEntryInsert(CostEntry, CostJnlLine);
        TotalCredit := TotalCredit + CostEntry."Credit Amount";
        TotalDebit := TotalDebit + CostEntry."Debit Amount";
        CreateCostRegister();
        NextCostEntryNo := NextCostEntryNo + 1;
    end;

    local procedure InsertBudgetEntries(CT: Code[20]; CC: Code[20]; CO: Code[20]; Amt: Decimal)
    begin
        CostBudgetEntry.Init();
        CostBudgetEntry."Entry No." := NextCostBudgetEntryNo;
        CostBudgetEntry."Budget Name" := CostJnlLine."Budget Name";
        CostBudgetEntry."Cost Type No." := CT;
        CostBudgetEntry.Date := CostJnlLine."Posting Date";
        CostBudgetEntry."Document No." := CostJnlLine."Document No.";
        CostBudgetEntry.Description := CostJnlLine.Description;
        CostBudgetEntry."Cost Center Code" := CC;
        CostBudgetEntry."Cost Object Code" := CO;
        CostBudgetEntry.Amount := Amt;
        CostBudgetEntry."Source Code" := CostJnlLine."Source Code";
        CostBudgetEntry."System-Created Entry" := CostJnlLine."System-Created Entry";
        CostBudgetEntry.Allocated := CostJnlLine.Allocated;
        CostBudgetEntry."Last Modified By User" := UserId();
        CostBudgetEntry."Allocation Description" := CostJnlLine."Allocation Description";
        CostBudgetEntry."Allocation ID" := CostJnlLine."Allocation ID";
        OnBeforeCostBudgetEntryInsert(CostBudgetEntry, CostJnlLine);
        CostBudgetEntry.Insert();
        OnAfterCostBudgetEntryInsert(CostBudgetEntry, CostJnlLine);
        CreateCostBudgetRegister();
        NextCostBudgetEntryNo := NextCostBudgetEntryNo + 1;

        TotalBudgetAmount := TotalBudgetAmount + Amt
    end;

    local procedure CalcAddCurrAmount(Amount: Decimal): Decimal
    var
        AddCurrency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        GetAddCurrency(AddCurrency);
        exit(
          Round(
            CurrExchRate.ExchangeAmtLCYToFCY(CostJnlLine."Posting Date", GLSetup."Additional Reporting Currency", Amount,
              CurrExchRate.ExchangeRate(CostJnlLine."Posting Date", GLSetup."Additional Reporting Currency")),
            AddCurrency."Amount Rounding Precision"));
    end;

    local procedure GetAddCurrency(var AddCurrency: Record Currency)
    begin
        if GLSetup."Additional Reporting Currency" <> '' then
            if GLSetup."Additional Reporting Currency" <> AddCurrency.Code then begin
                AddCurrency.Get(GLSetup."Additional Reporting Currency");
                AddCurrency.TestField("Amount Rounding Precision");
                AddCurrency.TestField("Residual Gains Account");
                AddCurrency.TestField("Residual Losses Account");
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCostEntryInsert(var CostEntry: Record "Cost Entry"; CostJournalLine: Record "Cost Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCostBudgetEntryInsert(var CostBudgetEntry: Record "Cost Budget Entry"; CostJournalLine: Record "Cost Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterRunWithCheck(var CostJournalLine: Record "Cost Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var CostJournalLine: Record "Cost Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCostEntryInsert(var CostEntry: Record "Cost Entry"; CostJournalLine: Record "Cost Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCostBudgetEntryInsert(var CostBudgetEntry: Record "Cost Budget Entry"; CostJournalLine: Record "Cost Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCostRegisterOnBeforeInsert(var CostRegister: Record "Cost Register"; CostJournalLine: Record "Cost Journal Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCostRegisterOnBeforeModify(var CostRegister: Record "Cost Register"; CostJournalLine: Record "Cost Journal Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;
}

