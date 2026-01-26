// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reversal;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.CRM.Team;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.AuditCodes;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

/// <summary>
/// Handles reversal of posted general journal entries and related ledger entries.
/// Provides comprehensive reversal functionality for G/L, customer, vendor, employee, and bank account transactions.
/// </summary>
/// <remarks>
/// Core reversal engine that creates offsetting entries to reverse the effects of posted transactions.
/// Supports reversal of entire registers or individual transactions with proper audit trail maintenance.
/// Integrates with G/L, customer ledger, vendor ledger, employee ledger, bank account ledger, and VAT systems.
/// </remarks>
codeunit 17 "Gen. Jnl.-Post Reverse"
{
    Permissions = TableData "G/L Entry" = rm,
                  TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd,
                  TableData "G/L Register" = rm,
                  TableData "G/L Entry - VAT Entry Link" = rimd,
                  TableData "VAT Entry" = rimd,
                  TableData "Bank Account Ledger Entry" = rimd,
                  TableData "Check Ledger Entry" = rimd,
                  TableData "Detailed Cust. Ledg. Entry" = rimd,
                  TableData "Detailed Vendor Ledg. Entry" = rimd,
                  TableData "Employee Ledger Entry" = rimd,
                  TableData "Detailed Employee Ledger Entry" = ri;
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
    end;

    var
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        ReversalMismatchErr: Label 'Reversal found a %1 without a matching general ledger entry.', Comment = '%1 - table caption';
        CannotReverseErr: Label 'You cannot reverse the transaction, because it has already been reversed.';
        DimCombBlockedErr: Label 'The combination of dimensions used in general ledger entry %1 is blocked. %2.', Comment = '%1 - entry no, %2 - error text';

    /// <summary>
    /// Executes the reversal process for specified entries and creates offsetting transactions.
    /// Handles complete reversal workflow including G/L entries, subsidiary ledgers, and VAT entries.
    /// </summary>
    /// <param name="ReversalEntry">Reversal entry record containing entries to be reversed</param>
    /// <param name="ReversalEntry2">Working copy of reversal entries for processing</param>
    /// <remarks>
    /// Creates offsetting entries with opposite amounts and links them to original entries.
    /// Updates reversal flags and maintains audit trail for all affected ledger entries.
    /// Supports both register-based and transaction-based reversal modes.
    /// </remarks>
    procedure Reverse(var ReversalEntry: Record "Reversal Entry"; var ReversalEntry2: Record "Reversal Entry")
    var
        SourceCodeSetup: Record "Source Code Setup";
        GLEntry2: Record "G/L Entry";
        GLRegister: Record "G/L Register";
        GLRegister2: Record "G/L Register";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary;
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        VATEntry: Record "VAT Entry";
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        TempTransactionNoInteger: Record "Integer" temporary;
        FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        NextDtldCustLedgEntryEntryNo: Integer;
        NextDtldVendLedgEntryEntryNo: Integer;
        NextDtldEmplLedgEntryNo: Integer;
        TransactionKey: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReverse(ReversalEntry, ReversalEntry2, IsHandled);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();
        if ReversalEntry2."Reversal Type" = ReversalEntry2."Reversal Type"::Register then
            GLRegister2."No." := ReversalEntry2."G/L Register No.";

        ReversalEntry.CopyReverseFilters(
          GLEntry2, CustLedgerEntry, VendorLedgerEntry, BankAccountLedgerEntry, VATEntry, FALedgerEntry, MaintenanceLedgerEntry, EmployeeLedgerEntry);

        if ReversalEntry2."Reversal Type" = ReversalEntry2."Reversal Type"::Transaction then begin
            GLRegister2."No." := GetRegisterNoForTransactionReversal(ReversalEntry2);
            if ReversalEntry2.FindFirst() then
                repeat
                    TempTransactionNoInteger.Number := ReversalEntry2."Transaction No.";
                    if TempTransactionNoInteger.Insert() then;
                until ReversalEntry2.Next() = 0;
        end;

        OnReverseOnBeforeGetTransactionKey(ReversalEntry2, TempTransactionNoInteger);
        TransactionKey := GetTransactionKey();
        SaveReversalEntries(ReversalEntry2, TransactionKey);

        GenJournalLine.Init();
        GenJournalLine."Source Code" := SourceCodeSetup.Reversal;
        GenJournalLine."Posting Date" := ReversalEntry2."Posting Date";
        GenJournalLine."Journal Template Name" := GLEntry2."Journal Templ. Name";

        OnReverseOnBeforeStartPosting(GenJournalLine, ReversalEntry2, GLEntry2, GenJnlPostLine);

        if GenJnlPostLine.GetNextEntryNo() = 0 then
            GenJnlPostLine.StartPosting(GenJournalLine)
        else
            GenJnlPostLine.ContinuePosting(GenJournalLine);

        OnReverseOnAfterStartPosting(GenJournalLine, GenJnlPostLine, GLRegister, GLRegister2);

        GenJnlPostLine.SetGLRegReverse(GLRegister);

        CopyCustLedgEntry(CustLedgerEntry, TempCustLedgerEntry);
        CopyVendLedgEntry(VendorLedgerEntry, TempVendorLedgerEntry);
        CopyEmplLedgEntry(EmployeeLedgerEntry, TempEmployeeLedgerEntry);
        CopyBankAccLedgEntry(BankAccountLedgerEntry, TempBankAccountLedgerEntry);

        if TempTransactionNoInteger.FindSet() then;
        repeat
            if ReversalEntry2."Reversal Type" = ReversalEntry2."Reversal Type"::Transaction then
                GLEntry2.SetRange("Transaction No.", TempTransactionNoInteger.Number);
            OnReverseOnBeforeReverseGLEntry(ReversalEntry2, GenJnlPostLine, GenJournalLine, TempTransactionNoInteger, GLEntry2, GLRegister);
            ReverseGLEntry(
              GLEntry2, GenJournalLine, TempCustLedgerEntry,
              TempVendorLedgerEntry, TempEmployeeLedgerEntry, TempBankAccountLedgerEntry, NextDtldCustLedgEntryEntryNo, NextDtldVendLedgEntryEntryNo,
              NextDtldEmplLedgEntryNo, FAInsertLedgerEntry);
        until TempTransactionNoInteger.Next() = 0;

        IsHandled := false;
        OnReverseOnBeforeCheckFAReverseEntry(FALedgerEntry, FAInsertLedgerEntry, ReversalEntry2, GenJnlPostLine, IsHandled);
        if not IsHandled then
            if FALedgerEntry.FindSet() then
                repeat
                    FAInsertLedgerEntry.CheckFAReverseEntry(FALedgerEntry)
                until FALedgerEntry.Next() = 0;

        if MaintenanceLedgerEntry.FindFirst() then
            repeat
                FAInsertLedgerEntry.CheckMaintReverseEntry(MaintenanceLedgerEntry)
            until FALedgerEntry.Next() = 0;

        FAInsertLedgerEntry.FinishFAReverseEntry(GLRegister);

        if not TempCustLedgerEntry.IsEmpty() then
            Error(ReversalMismatchErr, CustLedgerEntry.TableCaption());
        if not TempVendorLedgerEntry.IsEmpty() then
            Error(ReversalMismatchErr, VendorLedgerEntry.TableCaption());
        if not TempEmployeeLedgerEntry.IsEmpty() then
            Error(ReversalMismatchErr, EmployeeLedgerEntry.TableCaption());
        if not TempBankAccountLedgerEntry.IsEmpty() then
            Error(ReversalMismatchErr, BankAccountLedgerEntry.TableCaption());

        OnReverseOnBeforeFinishPosting(ReversalEntry, ReversalEntry2, GenJnlPostLine, GLRegister);

        GenJnlPostLine.FinishPosting(GenJournalLine);

        OnReverseOnAfterFinishPosting(ReversalEntry2, GenJnlPostLine, GLRegister, GLRegister2);

        if GLRegister2."No." <> 0 then
            if GLRegister2.Find() then begin
                GLRegister2.Reversed := true;
                GLRegister2.Modify();
            end;

        DeleteReversalEntries(TransactionKey);

        IsHandled := false;
        OnReverseOnBeforeUpdateAnalysisView(IsHandled);
        if not IsHandled then
            UpdateAnalysisView.UpdateAll(0, true);

        OnAfterReverse(GLRegister, GLRegister2);
    end;

    local procedure ReverseGLEntry(var GLEntry2: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; var TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary; var TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary; var NextDtldCustLedgEntryEntryNo: Integer; var NextDtldVendLedgEntryEntryNo: Integer; var NextDtldEmplLedgEntryNo: Integer; FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry")
    var
        GLEntry: Record "G/L Entry";
        ReversedGLEntry: Record "G/L Entry";
    begin
        if GLEntry2.Find('+') then
            repeat
                OnReverseGLEntryOnBeforeLoop(GLEntry2, GenJournalLine, GenJnlPostLine);
                if GLEntry2."Reversed by Entry No." <> 0 then
                    Error(CannotReverseErr);
                CheckDimComb(GLEntry2."Entry No.", GLEntry2."Dimension Set ID", Database::"G/L Account", GLEntry2."G/L Account No.", 0, '');
                GLEntry := GLEntry2;
                if GLEntry2."FA Entry No." <> 0 then
                    FAInsertLedgerEntry.InsertReverseEntry(
                      GenJnlPostLine.GetNextEntryNo(), GLEntry2."FA Entry Type", GLEntry2."FA Entry No.", GLEntry."FA Entry No.",
                      GenJnlPostLine.GetNextTransactionNo());
                GLEntry.Amount := -GLEntry2.Amount;
                GLEntry."Source Currency Amount" := -GLEntry2."Source Currency Amount";
                GLEntry."Source Currency VAT Amount" := -GLEntry2."Source Currency VAT Amount";
                GLEntry.Quantity := -GLEntry2.Quantity;
                GLEntry."VAT Amount" := -GLEntry2."VAT Amount";
                NonDeductibleVAT.Reverse(GLEntry, GLEntry2);
                GLEntry."Debit Amount" := -GLEntry2."Debit Amount";
                GLEntry."Credit Amount" := -GLEntry2."Credit Amount";
                GLEntry."Additional-Currency Amount" := -GLEntry2."Additional-Currency Amount";
                GLEntry."Add.-Currency Debit Amount" := -GLEntry2."Add.-Currency Debit Amount";
                GLEntry."Add.-Currency Credit Amount" := -GLEntry2."Add.-Currency Credit Amount";
                GLEntry."Entry No." := GenJnlPostLine.GetNextEntryNo();
                GLEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
                GLEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(GLEntry2."User ID"));
                GenJournalLine.Correction :=
                  (GLEntry."Debit Amount" < 0) or (GLEntry."Credit Amount" < 0) or
                  (GLEntry."Add.-Currency Debit Amount" < 0) or (GLEntry."Add.-Currency Credit Amount" < 0);
                GLEntry."Journal Batch Name" := '';
                GLEntry."Source Code" := GenJournalLine."Source Code";
                SetReversalDescription(GLEntry2, GLEntry.Description);
                GLEntry."Reversed Entry No." := GLEntry2."Entry No.";
                GLEntry.Reversed := true;
                // Reversal of Reversal
                if GLEntry2."Reversed Entry No." <> 0 then begin
                    ReversedGLEntry.Get(GLEntry2."Reversed Entry No.");
                    ReversedGLEntry."Reversed by Entry No." := 0;
                    ReversedGLEntry.Reversed := false;
                    ReversedGLEntry.Modify();
                    GLEntry2."Reversed Entry No." := GLEntry."Entry No.";
                    GLEntry."Reversed by Entry No." := GLEntry2."Entry No.";
                end;
                GLEntry2."Reversed by Entry No." := GLEntry."Entry No.";
                GLEntry2.Reversed := true;
                GLEntry2.Modify();
                OnReverseGLEntryOnBeforeInsertGLEntry(GLEntry, GenJournalLine, GLEntry2, GenJnlPostLine);
                GenJnlPostLine.InsertGLEntry(GenJournalLine, GLEntry, false);
                OnReverseGLEntryOnAfterInsertGLEntry(GLEntry, GenJournalLine, GLEntry2, GenJnlPostLine);

                case true of
                    TempCustLedgerEntry.Get(GLEntry2."Entry No."):
                        begin
                            OnReverseGLEntryOnBeforeTempCustLedgEntryCheckDimComb(GLEntry2, TempCustLedgerEntry);
                            CheckDimComb(GLEntry2."Entry No.", GLEntry2."Dimension Set ID",
                              Database::Customer, TempCustLedgerEntry."Customer No.",
                              Database::"Salesperson/Purchaser", TempCustLedgerEntry."Salesperson Code");
                            ReverseCustLedgEntry(
                              TempCustLedgerEntry, GLEntry."Entry No.", GenJournalLine.Correction, GenJournalLine."Source Code",
                              NextDtldCustLedgEntryEntryNo);
                            OnReverseGLEntryOnAfterReverseCustLedgEntry(TempCustLedgerEntry, GLEntry, GLEntry2);
                            TempCustLedgerEntry.Delete();
                        end;
                    TempVendorLedgerEntry.Get(GLEntry2."Entry No."):
                        begin
                            CheckDimComb(GLEntry2."Entry No.", GLEntry2."Dimension Set ID",
                              Database::Vendor, TempVendorLedgerEntry."Vendor No.",
                              Database::"Salesperson/Purchaser", TempVendorLedgerEntry."Purchaser Code");
                            ReverseVendLedgEntry(
                              TempVendorLedgerEntry, GLEntry."Entry No.", GenJournalLine.Correction, GenJournalLine."Source Code",
                              NextDtldVendLedgEntryEntryNo);
                            OnReverseGLEntryOnAfterReverseVendLedgEntry(TempVendorLedgerEntry, GLEntry, GLEntry2);
                            TempVendorLedgerEntry.Delete();
                        end;
                    TempEmployeeLedgerEntry.Get(GLEntry2."Entry No."):
                        begin
                            CheckDimComb(
                              GLEntry2."Entry No.", GLEntry2."Dimension Set ID", Database::Employee, TempEmployeeLedgerEntry."Employee No.", 0, '');
                            ReverseEmplLedgEntry(
                              TempEmployeeLedgerEntry, GLEntry."Entry No.", GenJournalLine.Correction, GenJournalLine."Source Code",
                              NextDtldEmplLedgEntryNo);
                            TempEmployeeLedgerEntry.Delete();
                        end;
                    TempBankAccountLedgerEntry.Get(GLEntry2."Entry No."):
                        begin
                            CheckDimComb(GLEntry2."Entry No.", GLEntry2."Dimension Set ID",
                              Database::"Bank Account", TempBankAccountLedgerEntry."Bank Account No.", 0, '');
                            ReverseBankAccLedgEntry(TempBankAccountLedgerEntry, GLEntry."Entry No.", GenJournalLine."Source Code");
                            TempBankAccountLedgerEntry.Delete();
                        end;
                    else
                        OnReverseGLEntryOnCaseElse(GLEntry2, GLEntry, GenJournalLine, GenJnlPostLine, TempBankAccountLedgerEntry);
                end;

                ReverseVAT(GLEntry, GenJournalLine."Source Code");
                OnReverseGLEntryOnAfterReverseVAT(GLEntry2, GLEntry, GenJnlPostLine);
            until GLEntry2.Next(-1) = 0;

        OnAfterReverseGLEntry(GLEntry);
    end;

    local procedure ReverseCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; NewEntryNo: Integer; Correction: Boolean; SourceCode: Code[10]; var NextDtldCustLedgEntryEntryNo: Integer)
    var
        NewCustLedgerEntry: Record "Cust. Ledger Entry";
        ReversedCustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        IsHandled: Boolean;
    begin
        NewCustLedgerEntry := CustLedgerEntry;
        NewCustLedgerEntry."Sales (LCY)" := -NewCustLedgerEntry."Sales (LCY)";
        NewCustLedgerEntry."Profit (LCY)" := -NewCustLedgerEntry."Profit (LCY)";
        NewCustLedgerEntry."Inv. Discount (LCY)" := -NewCustLedgerEntry."Inv. Discount (LCY)";
        NewCustLedgerEntry."Original Pmt. Disc. Possible" := -NewCustLedgerEntry."Original Pmt. Disc. Possible";
        NewCustLedgerEntry."Pmt. Disc. Given (LCY)" := -NewCustLedgerEntry."Pmt. Disc. Given (LCY)";
        NewCustLedgerEntry.Positive := not NewCustLedgerEntry.Positive;
        NewCustLedgerEntry."Adjusted Currency Factor" := NewCustLedgerEntry."Adjusted Currency Factor";
        NewCustLedgerEntry."Original Currency Factor" := NewCustLedgerEntry."Original Currency Factor";
        NewCustLedgerEntry."Remaining Pmt. Disc. Possible" := -NewCustLedgerEntry."Remaining Pmt. Disc. Possible";
        NewCustLedgerEntry."Max. Payment Tolerance" := -NewCustLedgerEntry."Max. Payment Tolerance";
        NewCustLedgerEntry."Accepted Payment Tolerance" := -NewCustLedgerEntry."Accepted Payment Tolerance";
        NewCustLedgerEntry."Pmt. Tolerance (LCY)" := -NewCustLedgerEntry."Pmt. Tolerance (LCY)";
        NewCustLedgerEntry."Amount (LCY) stats." := -NewCustLedgerEntry."Amount (LCY) stats.";
        NewCustLedgerEntry."Remaining Amount (LCY) stats." := -NewCustLedgerEntry."Remaining Amount (LCY) stats.";
        NewCustLedgerEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewCustLedgerEntry."User ID"));
        NewCustLedgerEntry."Entry No." := NewEntryNo;
        NewCustLedgerEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
        NewCustLedgerEntry."Journal Batch Name" := '';
        NewCustLedgerEntry."Source Code" := SourceCode;
        SetReversalDescription(CustLedgerEntry, NewCustLedgerEntry.Description);
        NewCustLedgerEntry."Reversed Entry No." := CustLedgerEntry."Entry No.";
        NewCustLedgerEntry.Reversed := true;
        NewCustLedgerEntry."Applies-to ID" := '';
        // Reversal of Reversal
        if CustLedgerEntry."Reversed Entry No." <> 0 then begin
            ReversedCustLedgerEntry.Get(CustLedgerEntry."Reversed Entry No.");
            ReversedCustLedgerEntry."Reversed by Entry No." := 0;
            ReversedCustLedgerEntry.Reversed := false;
            ReversedCustLedgerEntry.Modify();
            CustLedgerEntry."Reversed Entry No." := NewCustLedgerEntry."Entry No.";
            NewCustLedgerEntry."Reversed by Entry No." := CustLedgerEntry."Entry No.";
        end;
        CustLedgerEntry."Applies-to ID" := '';
        CustLedgerEntry."Reversed by Entry No." := NewCustLedgerEntry."Entry No.";
        CustLedgerEntry.Reversed := true;
        OnReverseCustLedgEntryOnBeforeModifyCustLedgerEntry(NewCustLedgerEntry, CustLedgerEntry);
        CustLedgerEntry.Modify();
        OnReverseCustLedgEntryOnBeforeInsertCustLedgEntry(NewCustLedgerEntry, CustLedgerEntry, GenJnlPostLine);
        NewCustLedgerEntry.Insert();
        OnReverseCustLedgEntryOnAfterInsertCustLedgEntry(NewCustLedgerEntry, CustLedgerEntry, GenJnlPostLine);

        if NextDtldCustLedgEntryEntryNo = 0 then begin
            OnReverseCustLedgEntryOnBeforeFindLastDetailedCustLedgEntry(DetailedCustLedgEntry);
            DetailedCustLedgEntry.FindLast();
            NextDtldCustLedgEntryEntryNo := DetailedCustLedgEntry."Entry No." + 1;
            OnReverseCustLedgEntryOnAfterAssignNextDtldCustLedgEntryEntryNo(DetailedCustLedgEntry, NextDtldCustLedgEntryEntryNo);
        end;
        DetailedCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.SetRange(Unapplied, false);
        OnReverseCustLedgEntryOnAfterDtldCustLedgEntrySetFilters(DetailedCustLedgEntry, NextDtldCustLedgEntryEntryNo);
        DetailedCustLedgEntry.FindSet();
        repeat
            DetailedCustLedgEntry.TestField("Entry Type", DetailedCustLedgEntry."Entry Type"::"Initial Entry");
            NewDetailedCustLedgEntry := DetailedCustLedgEntry;
            NewDetailedCustLedgEntry.Amount := -NewDetailedCustLedgEntry.Amount;
            NewDetailedCustLedgEntry."Amount (LCY)" := -NewDetailedCustLedgEntry."Amount (LCY)";
            NewDetailedCustLedgEntry.UpdateDebitCredit(Correction);
            NewDetailedCustLedgEntry."Cust. Ledger Entry No." := NewEntryNo;
            NewDetailedCustLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewCustLedgerEntry."User ID"));
            NewDetailedCustLedgEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
            NewDetailedCustLedgEntry."Entry No." := NextDtldCustLedgEntryEntryNo;
            NextDtldCustLedgEntryEntryNo := NextDtldCustLedgEntryEntryNo + 1;
            IsHandled := false;
            OnReverseCustLedgEntryOnBeforeInsertDtldCustLedgEntry(NewDetailedCustLedgEntry, DetailedCustLedgEntry, IsHandled, NewCustLedgerEntry);
            if not IsHandled then
                NewDetailedCustLedgEntry.Insert(true);
            OnReverseCustLedgEntryOnAfterInsertDtldCustLedgEntry(NewDetailedCustLedgEntry);
        until DetailedCustLedgEntry.Next() = 0;

        ApplyCustLedgEntryByReversal(
            CustLedgerEntry, NewCustLedgerEntry, NewDetailedCustLedgEntry, NewCustLedgerEntry."Entry No.", NextDtldCustLedgEntryEntryNo);
        ApplyCustLedgEntryByReversal(
            NewCustLedgerEntry, CustLedgerEntry, DetailedCustLedgEntry, NewCustLedgerEntry."Entry No.", NextDtldCustLedgEntryEntryNo);
    end;

    local procedure ReverseVendLedgEntry(VendorLedgerEntry: Record "Vendor Ledger Entry"; NewEntryNo: Integer; Correction: Boolean; SourceCode: Code[10]; var NextDtldVendLedgEntryEntryNo: Integer)
    var
        NewVendorLedgerEntry: Record "Vendor Ledger Entry";
        ReversedVendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        NewDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        IsHandled: Boolean;
    begin
        NewVendorLedgerEntry := VendorLedgerEntry;
        NewVendorLedgerEntry."Purchase (LCY)" := -NewVendorLedgerEntry."Purchase (LCY)";
        NewVendorLedgerEntry."Inv. Discount (LCY)" := -NewVendorLedgerEntry."Inv. Discount (LCY)";
        NewVendorLedgerEntry."Original Pmt. Disc. Possible" := -NewVendorLedgerEntry."Original Pmt. Disc. Possible";
        NewVendorLedgerEntry."Pmt. Disc. Rcd.(LCY)" := -NewVendorLedgerEntry."Pmt. Disc. Rcd.(LCY)";
        NewVendorLedgerEntry.Positive := not NewVendorLedgerEntry.Positive;
        NewVendorLedgerEntry."Adjusted Currency Factor" := NewVendorLedgerEntry."Adjusted Currency Factor";
        NewVendorLedgerEntry."Original Currency Factor" := NewVendorLedgerEntry."Original Currency Factor";
        NewVendorLedgerEntry."Remaining Pmt. Disc. Possible" := -NewVendorLedgerEntry."Remaining Pmt. Disc. Possible";
        NewVendorLedgerEntry."Max. Payment Tolerance" := -NewVendorLedgerEntry."Max. Payment Tolerance";
        NewVendorLedgerEntry."Accepted Payment Tolerance" := -NewVendorLedgerEntry."Accepted Payment Tolerance";
        NewVendorLedgerEntry."Pmt. Tolerance (LCY)" := -NewVendorLedgerEntry."Pmt. Tolerance (LCY)";
        NewVendorLedgerEntry."Amount (LCY) stats." := -NewVendorLedgerEntry."Amount (LCY) stats.";
        NewVendorLedgerEntry."Remaining Amount (LCY) stats." := -NewVendorLedgerEntry."Remaining Amount (LCY) stats.";
        NewVendorLedgerEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewVendorLedgerEntry."User ID"));
        NewVendorLedgerEntry."Entry No." := NewEntryNo;
        NewVendorLedgerEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
        NewVendorLedgerEntry."Journal Batch Name" := '';
        NewVendorLedgerEntry."Source Code" := SourceCode;
        SetReversalDescription(VendorLedgerEntry, NewVendorLedgerEntry.Description);
        NewVendorLedgerEntry."Reversed Entry No." := VendorLedgerEntry."Entry No.";
        NewVendorLedgerEntry.Reversed := true;
        NewVendorLedgerEntry."Applies-to ID" := '';
        // Reversal of Reversal
        if VendorLedgerEntry."Reversed Entry No." <> 0 then begin
            ReversedVendorLedgerEntry.Get(VendorLedgerEntry."Reversed Entry No.");
            ReversedVendorLedgerEntry."Reversed by Entry No." := 0;
            ReversedVendorLedgerEntry.Reversed := false;
            ReversedVendorLedgerEntry.Modify();
            VendorLedgerEntry."Reversed Entry No." := NewVendorLedgerEntry."Entry No.";
            NewVendorLedgerEntry."Reversed by Entry No." := VendorLedgerEntry."Entry No.";
        end;
        VendorLedgerEntry."Applies-to ID" := '';
        VendorLedgerEntry."Reversed by Entry No." := NewVendorLedgerEntry."Entry No.";
        VendorLedgerEntry.Reversed := true;
        VendorLedgerEntry.Modify();
        OnReverseVendLedgEntryOnBeforeInsertVendLedgEntry(NewVendorLedgerEntry, VendorLedgerEntry, GenJnlPostLine);
        NewVendorLedgerEntry.Insert();
        OnReverseVendLedgEntryOnAfterInsertVendLedgEntry(NewVendorLedgerEntry);

        if NextDtldVendLedgEntryEntryNo = 0 then begin
            DetailedVendorLedgEntry.FindLast();
            NextDtldVendLedgEntryEntryNo := DetailedVendorLedgEntry."Entry No." + 1;
        end;
        DetailedVendorLedgEntry.SetCurrentKey("Vendor Ledger Entry No.");
        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        DetailedVendorLedgEntry.SetRange(Unapplied, false);
        OnReverseVendLedgEntryOnAfterDtldVendLedgEntrySetFilters(DetailedVendorLedgEntry, NextDtldVendLedgEntryEntryNo);
        DetailedVendorLedgEntry.FindSet();
        repeat
            DetailedVendorLedgEntry.TestField("Entry Type", DetailedVendorLedgEntry."Entry Type"::"Initial Entry");
            NewDetailedVendorLedgEntry := DetailedVendorLedgEntry;
            NewDetailedVendorLedgEntry.Amount := -NewDetailedVendorLedgEntry.Amount;
            NewDetailedVendorLedgEntry."Amount (LCY)" := -NewDetailedVendorLedgEntry."Amount (LCY)";
            NewDetailedVendorLedgEntry.UpdateDebitCredit(Correction);
            NewDetailedVendorLedgEntry."Vendor Ledger Entry No." := NewEntryNo;
            NewDetailedVendorLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewVendorLedgerEntry."User ID"));
            NewDetailedVendorLedgEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
            NewDetailedVendorLedgEntry."Entry No." := NextDtldVendLedgEntryEntryNo;
            NextDtldVendLedgEntryEntryNo := NextDtldVendLedgEntryEntryNo + 1;
            IsHandled := false;
            OnReverseVendLedgEntryOnBeforeInsertDtldVendLedgEntry(NewDetailedVendorLedgEntry, DetailedVendorLedgEntry, IsHandled, NewVendorLedgerEntry);
            if not IsHandled then
                NewDetailedVendorLedgEntry.Insert(true);
            OnReverseVendLedgEntryOnAfterInsertDtldVendLedgEntry(NewDetailedVendorLedgEntry, DetailedVendorLedgEntry);
        until DetailedVendorLedgEntry.Next() = 0;

        ApplyVendLedgEntryByReversal(
            VendorLedgerEntry, NewVendorLedgerEntry, NewDetailedVendorLedgEntry, NewVendorLedgerEntry."Entry No.", NextDtldVendLedgEntryEntryNo);
        ApplyVendLedgEntryByReversal(
            NewVendorLedgerEntry, VendorLedgerEntry, DetailedVendorLedgEntry, NewVendorLedgerEntry."Entry No.", NextDtldVendLedgEntryEntryNo);
    end;

    local procedure ReverseEmplLedgEntry(EmployeeLedgerEntry: Record "Employee Ledger Entry"; NewEntryNo: Integer; Correction: Boolean; SourceCode: Code[10]; var NextDtldEmplLedgEntryNo: Integer)
    var
        NewEmployeeLedgerEntry: Record "Employee Ledger Entry";
        ReversedEmployeeLedgerEntry: Record "Employee Ledger Entry";
        DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
        NewDetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
    begin
        NewEmployeeLedgerEntry := EmployeeLedgerEntry;
        NewEmployeeLedgerEntry.Positive := not NewEmployeeLedgerEntry.Positive;
        NewEmployeeLedgerEntry."Adjusted Currency Factor" := NewEmployeeLedgerEntry."Adjusted Currency Factor";
        NewEmployeeLedgerEntry."Original Currency Factor" := NewEmployeeLedgerEntry."Original Currency Factor";
        NewEmployeeLedgerEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewEmployeeLedgerEntry."User ID"));
        NewEmployeeLedgerEntry."Entry No." := NewEntryNo;
        NewEmployeeLedgerEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
        NewEmployeeLedgerEntry."Journal Batch Name" := '';
        NewEmployeeLedgerEntry."Source Code" := SourceCode;
        SetReversalDescription(EmployeeLedgerEntry, NewEmployeeLedgerEntry.Description);
        NewEmployeeLedgerEntry."Reversed Entry No." := EmployeeLedgerEntry."Entry No.";
        NewEmployeeLedgerEntry.Reversed := true;
        NewEmployeeLedgerEntry."Applies-to ID" := '';
        // Reversal of Reversal
        if EmployeeLedgerEntry."Reversed Entry No." <> 0 then begin
            ReversedEmployeeLedgerEntry.Get(EmployeeLedgerEntry."Reversed Entry No.");
            ReversedEmployeeLedgerEntry."Reversed by Entry No." := 0;
            ReversedEmployeeLedgerEntry.Reversed := false;
            ReversedEmployeeLedgerEntry.Modify();
            EmployeeLedgerEntry."Reversed Entry No." := NewEmployeeLedgerEntry."Entry No.";
            NewEmployeeLedgerEntry."Reversed by Entry No." := EmployeeLedgerEntry."Entry No.";
        end;
        EmployeeLedgerEntry."Applies-to ID" := '';
        EmployeeLedgerEntry."Reversed by Entry No." := NewEmployeeLedgerEntry."Entry No.";
        EmployeeLedgerEntry.Reversed := true;
        EmployeeLedgerEntry.Modify();
        OnReverseEmplLedgEntryOnBeforeInsertEmplLedgEntry(NewEmployeeLedgerEntry, EmployeeLedgerEntry);
        NewEmployeeLedgerEntry.Insert();

        if NextDtldEmplLedgEntryNo = 0 then begin
            DetailedEmployeeLedgerEntry.FindLast();
            NextDtldEmplLedgEntryNo := DetailedEmployeeLedgerEntry."Entry No." + 1;
        end;
        DetailedEmployeeLedgerEntry.SetCurrentKey("Employee Ledger Entry No.");
        DetailedEmployeeLedgerEntry.SetRange("Employee Ledger Entry No.", EmployeeLedgerEntry."Entry No.");
        DetailedEmployeeLedgerEntry.SetRange(Unapplied, false);
        DetailedEmployeeLedgerEntry.FindSet();
        repeat
            DetailedEmployeeLedgerEntry.TestField("Entry Type", DetailedEmployeeLedgerEntry."Entry Type"::"Initial Entry");
            NewDetailedEmployeeLedgerEntry := DetailedEmployeeLedgerEntry;
            NewDetailedEmployeeLedgerEntry.Amount := -DetailedEmployeeLedgerEntry.Amount;
            NewDetailedEmployeeLedgerEntry."Amount (LCY)" := -DetailedEmployeeLedgerEntry."Amount (LCY)";
            NewDetailedEmployeeLedgerEntry.UpdateDebitCredit(Correction);
            NewDetailedEmployeeLedgerEntry."Employee Ledger Entry No." := NewEntryNo;
            NewDetailedEmployeeLedgerEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewEmployeeLedgerEntry."User ID"));
            NewDetailedEmployeeLedgerEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
            NewDetailedEmployeeLedgerEntry."Entry No." := NextDtldEmplLedgEntryNo;
            NextDtldEmplLedgEntryNo += 1;
            OnReverseEmplLedgEntryOnBeforeInsertDtldEmplLedgEntry(NewDetailedEmployeeLedgerEntry, DetailedEmployeeLedgerEntry);
            NewDetailedEmployeeLedgerEntry.Insert(true);
        until DetailedEmployeeLedgerEntry.Next() = 0;

        ApplyEmplLedgEntryByReversal(
            EmployeeLedgerEntry, NewEmployeeLedgerEntry, NewDetailedEmployeeLedgerEntry, NewEmployeeLedgerEntry."Entry No.", NextDtldEmplLedgEntryNo);
        ApplyEmplLedgEntryByReversal(
            NewEmployeeLedgerEntry, EmployeeLedgerEntry, DetailedEmployeeLedgerEntry, NewEmployeeLedgerEntry."Entry No.", NextDtldEmplLedgEntryNo);
    end;

    /// <summary>
    /// Creates a reversal entry for a bank account ledger entry with opposite amounts and signs.
    /// Handles bank account transaction reversal and maintains proper audit trail.
    /// </summary>
    /// <param name="BankAccountLedgerEntry">Original bank account ledger entry to reverse</param>
    /// <param name="NewEntryNo">Entry number for the new reversal entry</param>
    /// <param name="SourceCode">Source code to assign to the reversal entry</param>
    procedure ReverseBankAccLedgEntry(BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; NewEntryNo: Integer; SourceCode: Code[10])
    var
        NewBankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        ReversedBankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        NewBankAccountLedgerEntry := BankAccountLedgerEntry;
        NewBankAccountLedgerEntry.Amount := -NewBankAccountLedgerEntry.Amount;
        NewBankAccountLedgerEntry."Remaining Amount" := -NewBankAccountLedgerEntry."Remaining Amount";
        NewBankAccountLedgerEntry."Amount (LCY)" := -NewBankAccountLedgerEntry."Amount (LCY)";
        NewBankAccountLedgerEntry."Debit Amount" := -NewBankAccountLedgerEntry."Debit Amount";
        NewBankAccountLedgerEntry."Credit Amount" := -NewBankAccountLedgerEntry."Credit Amount";
        NewBankAccountLedgerEntry."Debit Amount (LCY)" := -NewBankAccountLedgerEntry."Debit Amount (LCY)";
        NewBankAccountLedgerEntry."Credit Amount (LCY)" := -NewBankAccountLedgerEntry."Credit Amount (LCY)";
        NewBankAccountLedgerEntry.Positive := not NewBankAccountLedgerEntry.Positive;
        NewBankAccountLedgerEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewBankAccountLedgerEntry."User ID"));
        NewBankAccountLedgerEntry."Entry No." := NewEntryNo;
        NewBankAccountLedgerEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
        NewBankAccountLedgerEntry."Journal Batch Name" := '';
        NewBankAccountLedgerEntry."Source Code" := SourceCode;
        SetReversalDescription(BankAccountLedgerEntry, NewBankAccountLedgerEntry.Description);
        NewBankAccountLedgerEntry."Reversed Entry No." := BankAccountLedgerEntry."Entry No.";
        NewBankAccountLedgerEntry.Reversed := true;
        // Reversal of Reversal
        if BankAccountLedgerEntry."Reversed Entry No." <> 0 then begin
            ReversedBankAccountLedgerEntry.Get(BankAccountLedgerEntry."Reversed Entry No.");
            ReversedBankAccountLedgerEntry."Reversed by Entry No." := 0;
            ReversedBankAccountLedgerEntry.Reversed := false;
            ReversedBankAccountLedgerEntry.Modify();
            BankAccountLedgerEntry."Reversed Entry No." := NewBankAccountLedgerEntry."Entry No.";
            NewBankAccountLedgerEntry."Reversed by Entry No." := BankAccountLedgerEntry."Entry No.";
        end;
        BankAccountLedgerEntry."Reversed by Entry No." := NewBankAccountLedgerEntry."Entry No.";
        BankAccountLedgerEntry.Reversed := true;
        BankAccountLedgerEntry.Modify();
        OnReverseBankAccLedgEntryOnBeforeInsert(NewBankAccountLedgerEntry, BankAccountLedgerEntry, GenJnlPostLine);
        NewBankAccountLedgerEntry.Insert(true);
    end;

    /// <summary>
    /// Reverses VAT entries associated with a G/L entry by creating offsetting VAT transactions.
    /// Handles VAT reversal logic including unrealized VAT and non-deductible VAT amounts.
    /// </summary>
    /// <param name="GLEntry">G/L entry whose associated VAT entries should be reversed</param>
    /// <param name="SourceCode">Source code to assign to the reversal VAT entries</param>
    procedure ReverseVAT(GLEntry: Record "G/L Entry"; SourceCode: Code[10])
    var
        VATEntry: Record "VAT Entry";
        NewVATEntry: Record "VAT Entry";
        ReversedVATEntry: Record "VAT Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
    begin
        GLEntryVATEntryLink.SetRange("G/L Entry No.", GLEntry."Reversed Entry No.");
        if GLEntryVATEntryLink.FindSet() then
            repeat
                VATEntry.Get(GLEntryVATEntryLink."VAT Entry No.");
                if VATEntry."Reversed by Entry No." <> 0 then
                    Error(CannotReverseErr);
                NewVATEntry := VATEntry;
                NewVATEntry.Base := -NewVATEntry.Base;
                NewVATEntry.Amount := -NewVATEntry.Amount;
                NewVATEntry."Source Currency VAT Base" := -NewVATEntry."Source Currency VAT Base";
                NewVATEntry."Source Currency VAT Amount" := -NewVATEntry."Source Currency VAT Amount";
                NewVATEntry."Unrealized Amount" := -NewVATEntry."Unrealized Amount";
                NewVATEntry."Unrealized Base" := -NewVATEntry."Unrealized Base";
                NewVATEntry."Remaining Unrealized Amount" := -NewVATEntry."Remaining Unrealized Amount";
                NewVATEntry."Remaining Unrealized Base" := -NewVATEntry."Remaining Unrealized Base";
                NewVATEntry."Additional-Currency Amount" := -NewVATEntry."Additional-Currency Amount";
                NewVATEntry."Additional-Currency Base" := -NewVATEntry."Additional-Currency Base";
                NewVATEntry."Add.-Currency Unrealized Amt." := -NewVATEntry."Add.-Currency Unrealized Amt.";
                NewVATEntry."Add.-Curr. Rem. Unreal. Amount" := -NewVATEntry."Add.-Curr. Rem. Unreal. Amount";
                NewVATEntry."Add.-Curr. Rem. Unreal. Base" := -NewVATEntry."Add.-Curr. Rem. Unreal. Base";
                NewVATEntry."VAT Difference" := -NewVATEntry."VAT Difference";
                NewVATEntry."Add.-Curr. VAT Difference" := -NewVATEntry."Add.-Curr. VAT Difference";
                NonDeductibleVAT.Reverse(NewVATEntry);
                NewVATEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
                NewVATEntry."Source Code" := SourceCode;
                NewVATEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewVATEntry."User ID"));
                NewVATEntry."Entry No." := GenJnlPostLine.GetNextVATEntryNo();
                NewVATEntry."Reversed Entry No." := VATEntry."Entry No.";
                NewVATEntry.Reversed := true;
                // Reversal of Reversal
                if VATEntry."Reversed Entry No." <> 0 then begin
                    ReversedVATEntry.Get(VATEntry."Reversed Entry No.");
                    ReversedVATEntry."Reversed by Entry No." := 0;
                    ReversedVATEntry.Reversed := false;
                    OnReverseVATOnBeforeReversedVATEntryModify(ReversedVATEntry, VATEntry);
                    ReversedVATEntry.Modify();
                    VATEntry."Reversed Entry No." := NewVATEntry."Entry No.";
                    NewVATEntry."Reversed by Entry No." := VATEntry."Entry No.";
                end;
                VATEntry."Reversed by Entry No." := NewVATEntry."Entry No.";
                VATEntry.Reversed := true;
                OnReverseVATOnBeforeVATEntryModify(VATEntry);
                VATEntry.Modify();
                OnReverseVATEntryOnBeforeInsert(NewVATEntry, VATEntry, GenJnlPostLine);
                NewVATEntry.Insert();
                OnReverseVATEntryOnAfterInsert(NewVATEntry, VATEntry, GenJnlPostLine);
                GLEntryVATEntryLink.InsertLink(GLEntry."Entry No.", NewVATEntry."Entry No.");
                GenJnlPostLine.IncrNextVATEntryNo();
            until GLEntryVATEntryLink.Next() = 0;
    end;

    local procedure ApplyCustLedgEntryByReversal(CustLedgerEntry: Record "Cust. Ledger Entry"; CustLedgerEntry2: Record "Cust. Ledger Entry"; DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; AppliedEntryNo: Integer; var NextDtldCustLedgEntryEntryNo: Integer)
    var
        NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApplyCustLedgEntryByReversal(CustLedgerEntry, CustLedgerEntry2, DetailedCustLedgEntry2, AppliedEntryNo, NextDtldCustLedgEntryEntryNo, GenJnlPostLine, IsHandled);
        if not IsHandled then begin
            CustLedgerEntry2.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
            CustLedgerEntry."Closed by Entry No." := CustLedgerEntry2."Entry No.";
            CustLedgerEntry."Closed at Date" := CustLedgerEntry2."Posting Date";
            CustLedgerEntry."Closed by Amount" := -CustLedgerEntry2."Remaining Amount";
            CustLedgerEntry."Closed by Amount (LCY)" := -CustLedgerEntry2."Remaining Amt. (LCY)";
            CustLedgerEntry."Closed by Currency Code" := CustLedgerEntry2."Currency Code";
            CustLedgerEntry."Closed by Currency Amount" := -CustLedgerEntry2."Remaining Amount";
            CustLedgerEntry.Open := false;
            CustLedgerEntry.Modify();
            OnApplyCustLedgEntryByReversalOnAfterCustLedgEntryModify(CustLedgerEntry);

            NewDetailedCustLedgEntry := DetailedCustLedgEntry2;
            NewDetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
            NewDetailedCustLedgEntry."Entry Type" := NewDetailedCustLedgEntry."Entry Type"::Application;
            NewDetailedCustLedgEntry."Applied Cust. Ledger Entry No." := AppliedEntryNo;
            NewDetailedCustLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewDetailedCustLedgEntry."User ID"));
            NewDetailedCustLedgEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
            NewDetailedCustLedgEntry."Entry No." := NextDtldCustLedgEntryEntryNo;
            NextDtldCustLedgEntryEntryNo := NextDtldCustLedgEntryEntryNo + 1;
            IsHandled := false;
            OnApplyCustLedgEntryByReversalOnBeforeInsertDtldCustLedgEntry(NewDetailedCustLedgEntry, DetailedCustLedgEntry2, IsHandled, GenJnlPostLine, NextDtldCustLedgEntryEntryNo);
            if not IsHandled then
                NewDetailedCustLedgEntry.Insert(true);
        end;

        OnApplyCustLedgEntryByReversalOnAfterInsertDtldCustLedgEntry(NewDetailedCustLedgEntry, CustLedgerEntry2);
    end;

    local procedure ApplyVendLedgEntryByReversal(VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorLedgerEntry2: Record "Vendor Ledger Entry"; DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry"; AppliedEntryNo: Integer; var NextDtldVendLedgEntryEntryNo: Integer)
    var
        NewDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        IsHandled: Boolean;
    begin
        VendorLedgerEntry2.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        VendorLedgerEntry."Closed by Entry No." := VendorLedgerEntry2."Entry No.";
        VendorLedgerEntry."Closed at Date" := VendorLedgerEntry2."Posting Date";
        VendorLedgerEntry."Closed by Amount" := -VendorLedgerEntry2."Remaining Amount";
        VendorLedgerEntry."Closed by Amount (LCY)" := -VendorLedgerEntry2."Remaining Amt. (LCY)";
        VendorLedgerEntry."Closed by Currency Code" := VendorLedgerEntry2."Currency Code";
        VendorLedgerEntry."Closed by Currency Amount" := -VendorLedgerEntry2."Remaining Amount";
        VendorLedgerEntry.Open := false;
        VendorLedgerEntry.Modify();
        OnApplyVendLedgEntryByReversalOnAfterVendLedgEntryModify(VendorLedgerEntry);

        NewDetailedVendorLedgEntry := DetailedVendorLedgEntry2;
        NewDetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        NewDetailedVendorLedgEntry."Entry Type" := NewDetailedVendorLedgEntry."Entry Type"::Application;
        NewDetailedVendorLedgEntry."Applied Vend. Ledger Entry No." := AppliedEntryNo;
        NewDetailedVendorLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewDetailedVendorLedgEntry."User ID"));
        NewDetailedVendorLedgEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
        NewDetailedVendorLedgEntry."Entry No." := NextDtldVendLedgEntryEntryNo;
        NextDtldVendLedgEntryEntryNo := NextDtldVendLedgEntryEntryNo + 1;
        IsHandled := false;
        OnApplyVendLedgEntryByReversalOnBeforeInsertDtldVendLedgEntry(NewDetailedVendorLedgEntry, DetailedVendorLedgEntry2, IsHandled, GenJnlPostLine, NextDtldVendLedgEntryEntryNo);
        if not IsHandled then
            NewDetailedVendorLedgEntry.Insert(true);
        OnApplyVendLedgEntryByReversalOnAfterInsertDtldVendLedgEntry(NewDetailedVendorLedgEntry, VendorLedgerEntry2);
    end;

    local procedure ApplyEmplLedgEntryByReversal(EmployeeLedgerEntry: Record "Employee Ledger Entry"; EmployeeLedgerEntry2: Record "Employee Ledger Entry"; DetailedEmployeeLedgerEntry2: Record "Detailed Employee Ledger Entry"; AppliedEntryNo: Integer; var NextDtldEmplLedgEntryNo: Integer)
    var
        NewDetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
    begin
        EmployeeLedgerEntry2.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        EmployeeLedgerEntry."Closed by Entry No." := EmployeeLedgerEntry2."Entry No.";
        EmployeeLedgerEntry."Closed at Date" := EmployeeLedgerEntry2."Posting Date";
        EmployeeLedgerEntry."Closed by Amount" := -EmployeeLedgerEntry2."Remaining Amount";
        EmployeeLedgerEntry."Closed by Amount (LCY)" := -EmployeeLedgerEntry2."Remaining Amt. (LCY)";
        EmployeeLedgerEntry."Closed by Currency Code" := EmployeeLedgerEntry2."Currency Code";
        EmployeeLedgerEntry."Closed by Currency Amount" := -EmployeeLedgerEntry2."Remaining Amount";
        EmployeeLedgerEntry.Open := false;
        EmployeeLedgerEntry.Modify();

        NewDetailedEmployeeLedgerEntry := DetailedEmployeeLedgerEntry2;
        NewDetailedEmployeeLedgerEntry."Employee Ledger Entry No." := EmployeeLedgerEntry."Entry No.";
        NewDetailedEmployeeLedgerEntry."Entry Type" := NewDetailedEmployeeLedgerEntry."Entry Type"::Application;
        NewDetailedEmployeeLedgerEntry."Applied Empl. Ledger Entry No." := AppliedEntryNo;
        NewDetailedEmployeeLedgerEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewDetailedEmployeeLedgerEntry."User ID"));
        NewDetailedEmployeeLedgerEntry."Transaction No." := GenJnlPostLine.GetNextTransactionNo();
        NewDetailedEmployeeLedgerEntry."Entry No." := NextDtldEmplLedgEntryNo;
        NextDtldEmplLedgEntryNo += 1;
        OnApplyEmplLedgEntryByReversalOnBeforeInsertDtldEmplLedgEntry(NewDetailedEmployeeLedgerEntry, DetailedEmployeeLedgerEntry2);
        NewDetailedEmployeeLedgerEntry.Insert(true);
    end;

    /// <summary>
    /// Validates dimension combinations for reversal entries to ensure posting compliance.
    /// Checks both dimension set validity and dimension value posting restrictions.
    /// </summary>
    /// <param name="EntryNo">Entry number being validated for error reporting</param>
    /// <param name="DimSetID">Dimension set ID to validate</param>
    /// <param name="TableID1">Primary table ID for dimension validation</param>
    /// <param name="AccNo1">Primary account number for dimension validation</param>
    /// <param name="TableID2">Secondary table ID for dimension validation</param>
    /// <param name="AccNo2">Secondary account number for dimension validation</param>
    procedure CheckDimComb(EntryNo: Integer; DimSetID: Integer; TableID1: Integer; AccNo1: Code[20]; TableID2: Integer; AccNo2: Code[20])
    var
        DimensionManagement: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        AccNo: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDimComb(EntryNo, DimSetID, TableID1, AccNo1, TableID2, AccNo2, IsHandled, DimensionManagement);
        if not IsHandled then begin
            if not DimensionManagement.CheckDimIDComb(DimSetID) then
                Error(DimCombBlockedErr, EntryNo, DimensionManagement.GetDimCombErr());
            Clear(TableID);
            Clear(AccNo);
            TableID[1] := TableID1;
            AccNo[1] := AccNo1;
            TableID[2] := TableID2;
            AccNo[2] := AccNo2;
            if not DimensionManagement.CheckDimValuePosting(TableID, AccNo, DimSetID) then
                Error(DimensionManagement.GetDimValuePostingErr());
        end;

        OnAfterCheckDimComb(DimensionManagement);
    end;

    local procedure CopyCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary)
    begin
        if CustLedgerEntry.FindSet() then
            repeat
                if CustLedgerEntry."Reversed by Entry No." <> 0 then
                    Error(CannotReverseErr);
                TempCustLedgerEntry := CustLedgerEntry;
                TempCustLedgerEntry.Insert();
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure CopyVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary)
    begin
        if VendorLedgerEntry.FindSet() then
            repeat
                if VendorLedgerEntry."Reversed by Entry No." <> 0 then
                    Error(CannotReverseErr);
                TempVendorLedgerEntry := VendorLedgerEntry;
                TempVendorLedgerEntry.Insert();
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure CopyEmplLedgEntry(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; var TempEmployeeLedgerEntry: Record "Employee Ledger Entry" temporary)
    begin
        if EmployeeLedgerEntry.FindSet() then
            repeat
                if EmployeeLedgerEntry."Reversed by Entry No." <> 0 then
                    Error(CannotReverseErr);
                TempEmployeeLedgerEntry := EmployeeLedgerEntry;
                TempEmployeeLedgerEntry.Insert();
            until EmployeeLedgerEntry.Next() = 0;
    end;

    local procedure CopyBankAccLedgEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary)
    begin
        if BankAccountLedgerEntry.FindSet() then
            repeat
                if BankAccountLedgerEntry."Reversed by Entry No." <> 0 then
                    Error(CannotReverseErr);
                TempBankAccountLedgerEntry := BankAccountLedgerEntry;
                TempBankAccountLedgerEntry.Insert();
            until BankAccountLedgerEntry.Next() = 0;
    end;

    /// <summary>
    /// Sets the description for a reversal entry based on the configured reversal entry description.
    /// Retrieves description from corresponding reversal entry record for the source record.
    /// </summary>
    /// <param name="RecVariant">Source record variant to find matching reversal entry description</param>
    /// <param name="Description">Description field to be updated with reversal description</param>
    procedure SetReversalDescription(RecVariant: Variant; var Description: Text[100])
    var
        ReversalEntry: Record "Reversal Entry";
    begin
        FilterReversalEntry(ReversalEntry, RecVariant);
        if ReversalEntry.FindFirst() then
            Description := ReversalEntry.Description;
    end;

    local procedure GetTransactionKey(): Integer
    var
        ReversalEntry: Record "Reversal Entry";
    begin
        ReversalEntry.SetCurrentKey("Transaction No.");
        ReversalEntry.SetFilter("Transaction No.", '<%1', 0);
        if ReversalEntry.FindFirst() then;
        exit(ReversalEntry."Transaction No." - 1);
    end;

    local procedure GetRegisterNoForTransactionReversal(var ReversalEntry: Record "Reversal Entry"): Integer
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.SetCurrentKey("To Entry No.");
        GLRegister.SetRange("To Entry No.", ReversalEntry."Entry No.");
        if GLRegister.FindFirst() then;
        exit(GLRegister."No.");
    end;

    local procedure FilterReversalEntry(var ReversalEntry: Record "Reversal Entry"; RecVar: Variant)
    var
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        case RecRef.Number of
            Database::"G/L Entry":
                begin
                    ReversalEntry.SetRange("Entry Type", ReversalEntry."Entry Type"::"G/L Account");
                    GLEntry := RecVar;
                    ReversalEntry.SetRange("Entry No.", GLEntry."Entry No.");
                end;
            Database::"Cust. Ledger Entry":
                begin
                    ReversalEntry.SetRange("Entry Type", ReversalEntry."Entry Type"::Customer);
                    CustLedgerEntry := RecVar;
                    ReversalEntry.SetRange("Entry No.", CustLedgerEntry."Entry No.");
                end;
            Database::"Vendor Ledger Entry":
                begin
                    ReversalEntry.SetRange("Entry Type", ReversalEntry."Entry Type"::Vendor);
                    VendorLedgerEntry := RecVar;
                    ReversalEntry.SetRange("Entry No.", VendorLedgerEntry."Entry No.");
                end;
            Database::"Employee Ledger Entry":
                begin
                    ReversalEntry.SetRange("Entry Type", ReversalEntry."Entry Type"::Employee);
                    EmployeeLedgerEntry := RecVar;
                    ReversalEntry.SetRange("Entry No.", EmployeeLedgerEntry."Entry No.");
                end;
            Database::"Bank Account Ledger Entry":
                begin
                    ReversalEntry.SetRange("Entry Type", ReversalEntry."Entry Type"::"Bank Account");
                    BankAccountLedgerEntry := RecVar;
                    ReversalEntry.SetRange("Entry No.", BankAccountLedgerEntry."Entry No.");
                end;
            Database::"FA Ledger Entry":
                begin
                    ReversalEntry.SetRange("Entry Type", ReversalEntry."Entry Type"::"Fixed Asset");
                    FALedgerEntry := RecVar;
                    ReversalEntry.SetRange("Entry No.", FALedgerEntry."Entry No.");
                end;
            Database::"Maintenance Ledger Entry":
                begin
                    ReversalEntry.SetRange("Entry Type", ReversalEntry."Entry Type"::Maintenance);
                    MaintenanceLedgerEntry := RecVar;
                    ReversalEntry.SetRange("Entry No.", MaintenanceLedgerEntry."Entry No.");
                end;
            else
                OnAfterFilterReversalEntry(ReversalEntry, RecVar);
        end;
    end;

    local procedure SaveReversalEntries(var TempReversalEntry: Record "Reversal Entry" temporary; TransactionKey: Integer)
    var
        ReversalEntry: Record "Reversal Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSaveReversalEntries(IsHandled);
        if IsHandled then
            exit;

        if TempReversalEntry.FindSet() then
            repeat
                ReversalEntry := TempReversalEntry;
                ReversalEntry."Transaction No." := TransactionKey;
                ReversalEntry.Insert();
            until TempReversalEntry.Next() = 0;
    end;

    local procedure DeleteReversalEntries(TransactionKey: Integer)
    var
        ReversalEntry: Record "Reversal Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteReversalEntries(IsHandled);
        if IsHandled then
            exit;
        ReversalEntry.SetRange("Transaction No.", TransactionKey);
        ReversalEntry.DeleteAll();
    end;

    /// <summary>
    /// Integration event raised after setting reversal entry filters to allow additional filter customization.
    /// </summary>
    /// <param name="ReversalEntry">Reversal entry record with applied filters</param>
    /// <param name="RecVar">Source record variant used for filtering</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterReversalEntry(var ReversalEntry: Record "Reversal Entry"; RecVar: Variant)
    begin
    end;

    /// <summary>
    /// Integration event raised after starting the reversal posting process.
    /// </summary>
    /// <param name="GenJournalLine">General journal line used for posting</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    /// <param name="GLRegister">G/L register for the reversal</param>
    /// <param name="GLRegister2">Original G/L register being reversed</param>
    [IntegrationEvent(true, false)]
    local procedure OnReverseOnAfterStartPosting(var GenJournalLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var GLRegister: Record "G/L Register"; var GLRegister2: Record "G/L Register")
    begin
    end;

    /// <summary>
    /// Integration event raised after completing the entire reversal process.
    /// </summary>
    /// <param name="GLRegister">G/L register created for the reversal</param>
    /// <param name="GLRegister2">Original G/L register that was reversed</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterReverse(GLRegister: Record "G/L Register"; var GLRegister2: Record "G/L Register")
    begin
    end;

    /// <summary>
    /// Integration event raised after reversing a G/L entry to allow additional processing.
    /// </summary>
    /// <param name="GLEntry">G/L entry that was reversed</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterReverseGLEntry(var GLEntry: Record "G/L Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before starting the reversal process to allow custom validation or preprocessing.
    /// </summary>
    /// <param name="ReversalEntry">Reversal entries to be processed</param>
    /// <param name="ReversalEntry2">Working copy of reversal entries</param>
    /// <param name="IsHandled">Set to true to skip standard reversal processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeReverse(var ReversalEntry: Record "Reversal Entry"; var ReversalEntry2: Record "Reversal Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before validating dimension combinations to allow custom dimension validation logic.
    /// </summary>
    /// <param name="EntryNo">Entry number being validated</param>
    /// <param name="DimSetID">Dimension set ID to validate</param>
    /// <param name="TableID1">Primary table ID for dimension validation</param>
    /// <param name="AccNo1">Primary account number for dimension validation</param>
    /// <param name="TableID2">Secondary table ID for dimension validation</param>
    /// <param name="AccNo2">Secondary account number for dimension validation</param>
    /// <param name="IsHandled">Set to true to skip standard dimension validation</param>
    /// <param name="DimensionManagement">Dimension management codeunit for validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimComb(EntryNo: Integer; DimSetID: Integer; TableID1: Integer; AccNo1: Code[20]; TableID2: Integer; AccNo2: Code[20]; var IsHandled: Boolean; var DimensionManagement: Codeunit DimensionManagement)
    begin
    end;

    /// <summary>
    /// Integration event raised after inserting a reversed G/L entry.
    /// </summary>
    /// <param name="GLEntry">New G/L entry created for reversal</param>
    /// <param name="GenJnlLine">General journal line used for posting</param>
    /// <param name="GLEntry2">Original G/L entry being reversed</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseGLEntryOnAfterInsertGLEntry(var GLEntry: Record "G/L Entry"; GenJnlLine: Record "Gen. Journal Line"; GLEntry2: Record "G/L Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting a reversed G/L entry to allow modification.
    /// </summary>
    /// <param name="GLEntry">New G/L entry to be created for reversal</param>
    /// <param name="GenJnlLine">General journal line used for posting</param>
    /// <param name="GLEntry2">Original G/L entry being reversed</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseGLEntryOnBeforeInsertGLEntry(var GLEntry: Record "G/L Entry"; GenJnlLine: Record "Gen. Journal Line"; GLEntry2: Record "G/L Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before processing each G/L entry in the reversal loop.
    /// </summary>
    /// <param name="GLEntry">G/L entry being processed for reversal</param>
    /// <param name="GenJournalLine">General journal line used for posting</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseGLEntryOnBeforeLoop(var GLEntry: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Integration event raised when G/L entry reversal encounters an unhandled ledger entry type.
    /// </summary>
    /// <param name="GLEntry2">Original G/L entry being processed</param>
    /// <param name="GLEntry">New reversal G/L entry</param>
    /// <param name="GenJournalLine">General journal line used for posting</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    /// <param name="TempBankAccountLedgerEntry">Temporary bank account ledger entry for processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseGLEntryOnCaseElse(GLEntry2: Record "G/L Entry"; GLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary)
    begin
    end;

    /// <summary>
    /// Integration event raised after setting filters on detailed customer ledger entries for reversal processing.
    /// </summary>
    /// <param name="DtldCustLedgEntry">Detailed customer ledger entry with applied filters</param>
    /// <param name="NextDtldCustLedgEntryEntryNo">Next entry number for detailed customer ledger entries</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseCustLedgEntryOnAfterDtldCustLedgEntrySetFilters(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; NextDtldCustLedgEntryEntryNo: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised after inserting a reversed customer ledger entry.
    /// </summary>
    /// <param name="NewCustLedgerEntry">New customer ledger entry created for reversal</param>
    /// <param name="CustLedgerEntry">Original customer ledger entry being reversed</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseCustLedgEntryOnAfterInsertCustLedgEntry(var NewCustLedgerEntry: Record "Cust. Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting a reversed customer ledger entry to allow modification.
    /// </summary>
    /// <param name="NewCustLedgerEntry">New customer ledger entry to be created for reversal</param>
    /// <param name="CustLedgerEntry">Original customer ledger entry being reversed</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseCustLedgEntryOnBeforeInsertCustLedgEntry(var NewCustLedgerEntry: Record "Cust. Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before modifying a VAT entry during reversal processing.
    /// </summary>
    /// <param name="VATEntry">VAT entry being modified for reversal</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseVATOnBeforeVATEntryModify(var VATEntry: Record "VAT Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before modifying a reversed VAT entry during reversal of reversal processing.
    /// </summary>
    /// <param name="ReversedVATEntry">Previously reversed VAT entry being restored</param>
    /// <param name="VATEntry">Current VAT entry being processed</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseVATOnBeforeReversedVATEntryModify(var ReversedVATEntry: Record "VAT Entry"; var VATEntry: Record "VAT Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after setting filters on detailed vendor ledger entries for reversal processing.
    /// </summary>
    /// <param name="DtldVendLedgEntry">Detailed vendor ledger entry with applied filters</param>
    /// <param name="NextDtldVendLedgEntryEntryNo">Next entry number for detailed vendor ledger entries</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseVendLedgEntryOnAfterDtldVendLedgEntrySetFilters(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; NextDtldVendLedgEntryEntryNo: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting a reversed vendor ledger entry to allow modification.
    /// </summary>
    /// <param name="NewVendLedgEntry">New vendor ledger entry to be created for reversal</param>
    /// <param name="VendLedgEntry">Original vendor ledger entry being reversed</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseVendLedgEntryOnBeforeInsertVendLedgEntry(var NewVendLedgEntry: Record "Vendor Ledger Entry"; VendLedgEntry: Record "Vendor Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after inserting a reversed vendor ledger entry.
    /// </summary>
    /// <param name="VendorLedgerEntry">New vendor ledger entry created for reversal</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseVendLedgEntryOnAfterInsertVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting a reversed employee ledger entry to allow modification.
    /// </summary>
    /// <param name="NewEmployeeLedgerEntry">New employee ledger entry to be created for reversal</param>
    /// <param name="EmployeeLedgerEntry">Original employee ledger entry being reversed</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseEmplLedgEntryOnBeforeInsertEmplLedgEntry(var NewEmployeeLedgerEntry: Record "Employee Ledger Entry"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting a reversed bank account ledger entry to allow modification.
    /// </summary>
    /// <param name="NewBankAccLedgEntry">New bank account ledger entry to be created for reversal</param>
    /// <param name="BankAccLedgEntry">Original bank account ledger entry being reversed</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseBankAccLedgEntryOnBeforeInsert(var NewBankAccLedgEntry: Record "Bank Account Ledger Entry"; BankAccLedgEntry: Record "Bank Account Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting a detailed customer ledger entry during reversal processing.
    /// </summary>
    /// <param name="NewDtldCustLedgEntry">New detailed customer ledger entry to be inserted</param>
    /// <param name="DtldCustLedgEntry">Original detailed customer ledger entry being reversed</param>
    /// <param name="IsHandled">Set to true to skip standard insertion processing</param>
    /// <param name="NewCustLedgerEntry">New customer ledger entry for the reversal</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseCustLedgEntryOnBeforeInsertDtldCustLedgEntry(var NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean; NewCustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting a detailed vendor ledger entry during reversal processing.
    /// </summary>
    /// <param name="NewDtldVendLedgEntry">New detailed vendor ledger entry to be inserted</param>
    /// <param name="DtldVendLedgEntry">Original detailed vendor ledger entry being reversed</param>
    /// <param name="IsHandled">Set to true to skip standard insertion processing</param>
    /// <param name="NewVendorLedgerEntry">New vendor ledger entry for the reversal</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseVendLedgEntryOnBeforeInsertDtldVendLedgEntry(var NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var IsHandled: Boolean; NewVendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting a detailed employee ledger entry during reversal processing.
    /// </summary>
    /// <param name="NewDetailedEmployeeLedgerEntry">New detailed employee ledger entry to be inserted</param>
    /// <param name="DetailedEmployeeLedgerEntry">Original detailed employee ledger entry being reversed</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseEmplLedgEntryOnBeforeInsertDtldEmplLedgEntry(var NewDetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry"; DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting a reversed VAT entry to allow modification.
    /// </summary>
    /// <param name="NewVATEntry">New VAT entry to be created for reversal</param>
    /// <param name="VATEntry">Original VAT entry being reversed</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseVATEntryOnBeforeInsert(var NewVATEntry: Record "VAT Entry"; VATEntry: Record "VAT Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before finishing the posting process in reversal to allow final modifications.
    /// </summary>
    /// <param name="ReversalEntry">Original reversal entry records</param>
    /// <param name="ReversalEntry2">Working copy of reversal entries</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    /// <param name="GLRegister">G/L register for the reversal</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseOnBeforeFinishPosting(var ReversalEntry: Record "Reversal Entry"; var ReversalEntry2: Record "Reversal Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var GLRegister: Record "G/L Register")
    begin
    end;

    /// <summary>
    /// Integration event raised before starting the posting process in reversal to allow preparation.
    /// </summary>
    /// <param name="GenJournalLine">General journal line to be used for posting</param>
    /// <param name="ReversalEntry">Reversal entry records being processed</param>
    /// <param name="GLEntry">G/L entry context for posting</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseOnBeforeStartPosting(var GenJournalLine: Record "Gen. Journal Line"; var ReversalEntry: Record "Reversal Entry"; var GLEntry: Record "G/L Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before reversing G/L entries to allow preprocessing of the reversal operation.
    /// </summary>
    /// <param name="ReversalEntry2">Working copy of reversal entries</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    /// <param name="GenJournalLine">General journal line for posting</param>
    /// <param name="TempRevertTransactionNo">Temporary integer record for transaction numbers</param>
    /// <param name="GLEntry2">G/L entry records to be reversed</param>
    /// <param name="GLRegister">G/L register for the reversal</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseOnBeforeReverseGLEntry(var ReversalEntry2: Record "Reversal Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var GenJournalLine: Record "Gen. Journal Line"; TempRevertTransactionNo: record "Integer"; var GLEntry2: Record "G/L Entry"; GLRegister: Record "G/L Register")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting a detailed customer ledger entry during customer application by reversal.
    /// </summary>
    /// <param name="NewDtldCustLedgEntry">New detailed customer ledger entry for application</param>
    /// <param name="DtldCustLedgEntry">Source detailed customer ledger entry</param>
    /// <param name="IsHandled">Set to true to skip standard insertion processing</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    /// <param name="NextDtldCustLedgEntryEntryNo">Next entry number for detailed customer ledger entries</param>
    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryByReversalOnBeforeInsertDtldCustLedgEntry(var NewDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var NextDtldCustLedgEntryEntryNo: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised after modifying a customer ledger entry during application by reversal.
    /// </summary>
    /// <param name="CustLedgerEntry">Customer ledger entry that was modified</param>
    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryByReversalOnAfterCustLedgEntryModify(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting a detailed vendor ledger entry during vendor application by reversal.
    /// </summary>
    /// <param name="NewDtldVendLedgEntry">New detailed vendor ledger entry for application</param>
    /// <param name="DtldVendLedgEntry">Source detailed vendor ledger entry</param>
    /// <param name="IsHandled">Set to true to skip standard insertion processing</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    /// <param name="NextDtldVendLedgEntryEntryNo">Next entry number for detailed vendor ledger entries</param>
    [IntegrationEvent(false, false)]
    local procedure OnApplyVendLedgEntryByReversalOnBeforeInsertDtldVendLedgEntry(var NewDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var IsHandled: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var NextDtldVendLedgEntryEntryNo: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised after modifying a vendor ledger entry during application by reversal.
    /// </summary>
    /// <param name="VendorLedgerEntry">Vendor ledger entry that was modified</param>
    [IntegrationEvent(false, false)]
    local procedure OnApplyVendLedgEntryByReversalOnAfterVendLedgEntryModify(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting a detailed employee ledger entry during employee application by reversal.
    /// </summary>
    /// <param name="NewDetailedEmployeeLedgerEntry">New detailed employee ledger entry for application</param>
    /// <param name="DetailedEmployeeLedgerEntry">Source detailed employee ledger entry</param>
    [IntegrationEvent(false, false)]
    local procedure OnApplyEmplLedgEntryByReversalOnBeforeInsertDtldEmplLedgEntry(var NewDetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry"; DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after finishing the posting process in reversal operation.
    /// </summary>
    /// <param name="ReversalEntry2">Working copy of reversal entries</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    /// <param name="GLRegister">G/L register created for the reversal</param>
    /// <param name="GLRegister2">Original G/L register being reversed</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseOnAfterFinishPosting(var ReversalEntry2: Record "Reversal Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var GLRegister: Record "G/L Register"; GLRegister2: Record "G/L Register")
    begin
    end;

    /// <summary>
    /// Integration event raised before checking Fixed Asset reversal entries to allow custom validation.
    /// </summary>
    /// <param name="FALedgerEntry">Fixed Asset ledger entry being validated</param>
    /// <param name="FAInsertLedgerEntry">Fixed Asset insertion codeunit</param>
    /// <param name="ReversalEntry2">Working copy of reversal entries</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    /// <param name="IsHandled">Set to true to skip standard Fixed Asset reversal validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseOnBeforeCheckFAReverseEntry(var FALedgerEntry: Record "FA Ledger Entry"; var FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry"; var ReversalEntry2: Record "Reversal Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after inserting a detailed vendor ledger entry during reversal processing.
    /// </summary>
    /// <param name="NewDetailedVendorLedgEntry">New detailed vendor ledger entry that was inserted</param>
    /// <param name="DetailedVendorLedgEntry">Original detailed vendor ledger entry</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseVendLedgEntryOnAfterInsertDtldVendLedgEntry(var NewDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before determining transaction key for reversal processing.
    /// </summary>
    /// <param name="ReversalEntry2">Working copy of reversal entries</param>
    /// <param name="TempIntegerAsRevertTransactionNo">Temporary integer record for transaction numbers</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseOnBeforeGetTransactionKey(var ReversalEntry2: Record "Reversal Entry"; var TempIntegerAsRevertTransactionNo: Record "Integer" temporary)
    begin
    end;

    /// <summary>
    /// Integration event raised after reversing vendor ledger entry in G/L entry processing.
    /// </summary>
    /// <param name="TempVendorLedgerEntry">Temporary vendor ledger entry that was processed</param>
    /// <param name="GLEntry">New G/L entry created for reversal</param>
    /// <param name="GLEntry2">Original G/L entry being reversed</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseGLEntryOnAfterReverseVendLedgEntry(var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; var GLEntry: Record "G/L Entry"; GLEntry2: Record "G/L Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before updating analysis views to allow custom analysis view handling.
    /// </summary>
    /// <param name="IsHandled">Set to true to skip standard analysis view update</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseOnBeforeUpdateAnalysisView(var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after reversing VAT entries in G/L entry processing.
    /// </summary>
    /// <param name="GLEntry2">Original G/L entry being reversed</param>
    /// <param name="GLEntry">New G/L entry created for reversal</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseGLEntryOnAfterReverseVAT(GLEntry2: Record "G/L Entry"; GLEntry: Record "G/L Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after reversing customer ledger entry in G/L entry processing.
    /// </summary>
    /// <param name="TempCustLedgerEntry">Temporary customer ledger entry that was processed</param>
    /// <param name="GLEntry">New G/L entry created for reversal</param>
    /// <param name="GLEntry2">Original G/L entry being reversed</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseGLEntryOnAfterReverseCustLedgEntry(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var GLEntry: Record "G/L Entry"; GLEntry2: Record "G/L Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after inserting a detailed customer ledger entry during reversal processing.
    /// </summary>
    /// <param name="NewDetailedCustLedgEntry">New detailed customer ledger entry that was inserted</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseCustLedgEntryOnAfterInsertDtldCustLedgEntry(var NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after inserting a detailed customer ledger entry during customer application by reversal.
    /// </summary>
    /// <param name="NewDetailedCustLedgEntry">New detailed customer ledger entry that was inserted</param>
    /// <param name="CustLedgerEntry2">Customer ledger entry context</param>
    [IntegrationEvent(false, false)]
    local procedure OnApplyCustLedgEntryByReversalOnAfterInsertDtldCustLedgEntry(var NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgerEntry2: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after completing dimension combination validation.
    /// </summary>
    /// <param name="DimensionManagement">Dimension management codeunit used for validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDimComb(var DimensionManagement: Codeunit DimensionManagement)
    begin
    end;

    /// <summary>
    /// Integration event raised before saving reversal entries to allow custom save processing.
    /// </summary>
    /// <param name="IsHandled">Set to true to skip standard save processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveReversalEntries(var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before deleting reversal entries to allow custom deletion processing.
    /// </summary>
    /// <param name="IsHandled">Set to true to skip standard deletion processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteReversalEntries(var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after inserting a detailed vendor ledger entry during vendor application by reversal.
    /// </summary>
    /// <param name="NewDetailedVendorLedgEntry">New detailed vendor ledger entry that was inserted</param>
    /// <param name="VendorLedgerEntry2">Vendor ledger entry context</param>
    [IntegrationEvent(false, false)]
    local procedure OnApplyVendLedgEntryByReversalOnAfterInsertDtldVendLedgEntry(var NewDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; VendorLedgerEntry2: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after inserting a reversed VAT entry.
    /// </summary>
    /// <param name="NewVATEntry">New VAT entry that was inserted</param>
    /// <param name="VATEntry">Original VAT entry being reversed</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseVATEntryOnAfterInsert(var NewVATEntry: Record "VAT Entry"; VATEntry: Record "VAT Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before finding the last detailed customer ledger entry to allow custom entry number handling.
    /// </summary>
    /// <param name="DetailedCustLedgEntry">Detailed customer ledger entry record for finding last entry</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseCustLedgEntryOnBeforeFindLastDetailedCustLedgEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after assigning the next detailed customer ledger entry number.
    /// </summary>
    /// <param name="DetailedCustLedgEntry">Detailed customer ledger entry record context</param>
    /// <param name="NextDtldCustLedgEntryEntryNo">Next entry number that was assigned</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseCustLedgEntryOnAfterAssignNextDtldCustLedgEntryEntryNo(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var NextDtldCustLedgEntryEntryNo: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised before checking dimension combinations for temporary customer ledger entry.
    /// </summary>
    /// <param name="GLEntry">G/L entry context for dimension validation</param>
    /// <param name="TempCustLedgerEntry">Temporary customer ledger entry being validated</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseGLEntryOnBeforeTempCustLedgEntryCheckDimComb(var GLEntry: Record "G/L Entry"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary)
    begin
    end;

    /// <summary>
    /// Integration event raised before applying customer ledger entry by reversal to allow custom application logic.
    /// </summary>
    /// <param name="CustLedgerEntry">Customer ledger entry being applied</param>
    /// <param name="CustLedgerEntry2">Customer ledger entry to apply against</param>
    /// <param name="DetailedCustLedgEntry2">Detailed customer ledger entry context</param>
    /// <param name="AppliedEntryNo">Entry number being applied</param>
    /// <param name="NextDtldCustLedgEntryEntryNo">Next detailed entry number</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit</param>
    /// <param name="IsHandled">Set to true to skip standard application processing</param>
#pragma warning disable AS0077
    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyCustLedgEntryByReversal(CustLedgerEntry: Record "Cust. Ledger Entry"; CustLedgerEntry2: Record "Cust. Ledger Entry"; DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry"; AppliedEntryNo: Integer; var NextDtldCustLedgEntryEntryNo: Integer; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;
#pragma warning restore AS0077

    /// <summary>
    /// Integration event raised before modifying a customer ledger entry during reversal processing.
    /// </summary>
    /// <param name="NewCustLedgerEntry">New customer ledger entry for reversal</param>
    /// <param name="CustLedgerEntry">Original customer ledger entry being modified</param>
    [IntegrationEvent(false, false)]
    local procedure OnReverseCustLedgEntryOnBeforeModifyCustLedgerEntry(NewCustLedgerEntry: Record "Cust. Ledger Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;
}

