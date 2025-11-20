// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Check;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Payment;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

/// <summary>
/// Manages check printing, voiding, and electronic payment processing for bank accounts.
/// Handles complete check lifecycle from creation through financial voiding and positive pay export.
/// </summary>
/// <remarks>
/// Integrates with Gen. Jnl.-Post Line, Bank Account Ledger Entry, and vendor/customer payment applications.
/// Supports physical check printing, electronic payments, and automated reconciliation processes.
/// Extensible through OnInsertCheckOnBeforeCheckLedgEntryInsert, OnBeforeVoidCheck, and related events.
/// </remarks>
codeunit 367 CheckManagement
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "Bank Account Ledger Entry" = rm,
                  TableData "Check Ledger Entry" = rim,
                  TableData "Employee Ledger Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        GenJnlLine2: Record "Gen. Journal Line";
        BankAcc: Record "Bank Account";
        BankAccLedgEntry2: Record "Bank Account Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        VendorLedgEntry: Record "Vendor Ledger Entry";
        GLEntry: Record "G/L Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        FALedgEntry: Record "FA Ledger Entry";
        BankAccLedgEntry3: Record "Bank Account Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        NextCheckEntryNo: Integer;
        AppliesIDCounter: Integer;

        CheckAlreadyExistsErr: Label 'Check %1 already exists for this %2.', Comment = '%1=The check number., %2=The Bank Account table name.';
        VoidingCheckMsg: Label 'Voiding check %1.', Comment = '%1=The check number being voided.';
        VoidingCheckErr: Label 'You cannot Financially Void checks posted in a non-balancing transaction.';
        PaymentOrRefundErr: Label '%1 must be either %2 or %3.', Comment = '%1=Document Type for the payment., %2=Payment Document Type., %3=Refund Document Type.';
        BankAccountTypeErr: Label 'Either the %1 or the %2 must refer to a Bank Account.', Comment = '%1=Account type., %2=Balancing Account type.';
        NoAppliedEntryErr: Label 'Cannot find an applied entry within the specified filter.';

    /// <summary>
    /// Creates a new check ledger entry with sequential numbering and duplicate validation.
    /// Validates check number uniqueness within the bank account before insertion.
    /// </summary>
    /// <param name="CheckLedgEntry">Check ledger entry record to insert with initial data</param>
    /// <param name="RecordIdToPrint">RecordID reference for check printing operations</param>
    procedure InsertCheck(var CheckLedgEntry: Record "Check Ledger Entry"; RecordIdToPrint: RecordID)
    var
        CheckLedgEntry2: Record "Check Ledger Entry";
    begin
        CheckLedgEntry2.SetCurrentKey("Bank Account No.", "Entry Status", "Check No.");
        CheckLedgEntry2.SetRange("Bank Account No.", CheckLedgEntry."Bank Account No.");
        CheckLedgEntry2.SetFilter(
          "Entry Status", '%1|%2|%3',
          CheckLedgEntry2."Entry Status"::Printed,
          CheckLedgEntry2."Entry Status"::Posted,
          CheckLedgEntry2."Entry Status"::"Financially Voided");
        CheckLedgEntry2.SetRange("Check No.", CheckLedgEntry."Document No.");
        if CheckLedgEntry2.FindFirst() then
            Error(CheckAlreadyExistsErr, CheckLedgEntry."Document No.", BankAcc.TableCaption());

        if NextCheckEntryNo = 0 then begin
            CheckLedgEntry2.LockTable();
            CheckLedgEntry2.Reset();
            if CheckLedgEntry2.FindLast() then
                NextCheckEntryNo := CheckLedgEntry2."Entry No." + 1
            else
                NextCheckEntryNo := 1;
        end;

        CheckLedgEntry.Open := CheckLedgEntry.Amount <> 0;
        CheckLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(CheckLedgEntry."User ID"));
        CheckLedgEntry."Entry No." := NextCheckEntryNo;
        CheckLedgEntry."Print Gen Jnl Line SystemId" := GenJournalLineGetSystemIdFromRecordId(RecordIdToPrint);
        OnInsertCheckOnBeforeCheckLedgEntryInsert(CheckLedgEntry);
        CheckLedgEntry.Insert();
        OnInsertCheckOnAfterCheckLedgEntryInsert(CheckLedgEntry);
        NextCheckEntryNo := NextCheckEntryNo + 1;
    end;

    /// <summary>
    /// Voids a check by creating reversing entries and updating check ledger entry status.
    /// Handles currency conversion and validates payment document types.
    /// </summary>
    /// <param name="GenJnlLine">General journal line containing check information to void</param>
    procedure VoidCheck(var GenJnlLine: Record "Gen. Journal Line")
    var
        Currency: Record Currency;
        CheckLedgEntry2: Record "Check Ledger Entry";
        CheckAmountLCY: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVoidCheck(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.TestField("Bank Payment Type", GenJnlLine2."Bank Payment Type"::"Computer Check");
        GenJnlLine.TestField("Check Printed", true);
        GenJnlLine.TestField("Document No.");

        if GenJnlLine."Bal. Account No." = '' then begin
            GenJnlLine."Check Printed" := false;
            GenJnlLine.Delete(true);
        end;

        CheckAmountLCY := GenJnlLine."Amount (LCY)";
        if GenJnlLine."Currency Code" <> '' then
            Currency.Get(GenJnlLine."Currency Code");

        GenJnlLine2.Reset();
        GenJnlLine2.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
        GenJnlLine2.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine2.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJnlLine2.SetRange("Posting Date", GenJnlLine."Posting Date");
        GenJnlLine2.SetRange("Document No.", GenJnlLine."Document No.");
        if GenJnlLine2.Find('-') then
            repeat
                if (GenJnlLine2."Line No." > GenJnlLine."Line No.") and
                   (CheckAmountLCY = -GenJnlLine2."Amount (LCY)") and
                   (GenJnlLine2."Currency Code" = '') and (GenJnlLine."Currency Code" <> '') and
                   (GenJnlLine2."Account Type" = GenJnlLine2."Account Type"::"G/L Account") and
                   (GenJnlLine2."Account No." in
                    [Currency."Conv. LCY Rndg. Debit Acc.", Currency."Conv. LCY Rndg. Credit Acc."]) and
                   (GenJnlLine2."Bal. Account No." = '') and not GenJnlLine2."Check Printed"
                then
                    GenJnlLine2.Delete() // Rounding correction line
                else begin
                    if GenJnlLine."Bal. Account No." = '' then begin
                        if GenJnlLine2."Account No." = '' then begin
                            GenJnlLine2."Account Type" := GenJnlLine2."Account Type"::"Bank Account";
                            GenJnlLine2."Account No." := GenJnlLine."Account No.";
                        end else begin
                            GenJnlLine2."Bal. Account Type" := GenJnlLine2."Account Type"::"Bank Account";
                            GenJnlLine2."Bal. Account No." := GenJnlLine."Account No.";
                        end;
                        GenJnlLine2.Validate(Amount);
                        GenJnlLine2."Bank Payment Type" := GenJnlLine."Bank Payment Type";
                    end;

                    if GenJnlLine."Bal. Account No." <> '' then
                        GenJnlLine2."Document No." := '';
                    GenJnlLine2."Document Date" := 0D;
                    GenJnlLine2."Check Printed" := false;
                    GenJnlLine2.UpdateSource();
                    OnBeforeVoidCheckGenJnlLine2Modify(GenJnlLine2, GenJnlLine);
                    GenJnlLine2.Modify();
                    OnVoidCheckOnAfterGenJnlLine2Modify(GenJnlLine2, GenJnlLine);
                end;
            until GenJnlLine2.Next() = 0;

        CheckLedgEntry2.Reset();
        CheckLedgEntry2.SetCurrentKey("Bank Account No.", "Entry Status", "Check No.");
        if GenJnlLine.Amount <= 0 then
            CheckLedgEntry2.SetRange("Bank Account No.", GenJnlLine."Account No.")
        else
            CheckLedgEntry2.SetRange("Bank Account No.", GenJnlLine."Bal. Account No.");
        CheckLedgEntry2.SetRange("Entry Status", CheckLedgEntry2."Entry Status"::Printed);
        CheckLedgEntry2.SetRange("Check No.", GenJnlLine."Document No.");
        OnVoidCheckOnAfterCheckLedgEntry2SetFilters(CheckLedgEntry2, GenJnlLine);
        CheckLedgEntry2.FindFirst();
        CheckLedgEntry2."Original Entry Status" := CheckLedgEntry2."Entry Status";
        CheckLedgEntry2."Entry Status" := CheckLedgEntry2."Entry Status"::Voided;
        CheckLedgEntry2."Positive Pay Exported" := false;
        CheckLedgEntry2.Open := false;
        CheckLedgEntry2.Modify();

        OnAfterVoidCheck(GenJnlLine, CheckLedgEntry2);
    end;

    /// <summary>
    /// Performs financial voiding of a posted check by creating offsetting journal entries.
    /// Unapplies vendor/customer invoices and reverses all financial impacts while maintaining audit trail.
    /// </summary>
    /// <param name="CheckLedgEntry">Check ledger entry to financially void</param>
    procedure FinancialVoidCheck(var CheckLedgEntry: Record "Check Ledger Entry")
    var
        ConfirmFinancialVoid: Page "Confirm Financial Void";
        AmountToVoid: Decimal;
        CheckAmountLCY: Decimal;
        BalanceAmountLCY: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFinancialVoidCheck(CheckLedgEntry, IsHandled);
        if IsHandled then
            exit;

        FinancialVoidCheckPreValidation(CheckLedgEntry);

        Clear(ConfirmFinancialVoid);

        IsHandled := false;
        OnFinancialVoidCheckOnBeforeConfirmFinancialVoid(CheckLedgEntry, IsHandled);
        if not IsHandled then begin
            ConfirmFinancialVoid.SetCheckLedgerEntry(CheckLedgEntry);
            if ConfirmFinancialVoid.RunModal() <> ACTION::Yes then
                exit;
        end;

        AmountToVoid := CalcAmountToVoid(CheckLedgEntry);

        InitGenJnlLine(
          GenJnlLine2, CheckLedgEntry."Document Type", CheckLedgEntry."Document No.", ConfirmFinancialVoid.GetVoidDate(),
          GenJnlLine2."Account Type"::"Bank Account", CheckLedgEntry."Bank Account No.",
          StrSubstNo(VoidingCheckMsg, CheckLedgEntry."Check No."));
        GenJnlLine2.Validate(Amount, AmountToVoid);
        CheckAmountLCY := GenJnlLine2."Amount (LCY)";
        BalanceAmountLCY := 0;
        GenJnlLine2."Shortcut Dimension 1 Code" := BankAccLedgEntry2."Global Dimension 1 Code";
        GenJnlLine2."Shortcut Dimension 2 Code" := BankAccLedgEntry2."Global Dimension 2 Code";
        GenJnlLine2."Dimension Set ID" := BankAccLedgEntry2."Dimension Set ID";
        GenJnlLine2."Allow Zero-Amount Posting" := true;
        GenJnlLine2."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
        GenJnlLine2."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
        OnFinancialVoidCheckOnBeforePostVoidCheckLine(GenJnlLine2, CheckLedgEntry, BankAccLedgEntry2);
        GenJnlPostLine.RunWithCheck(GenJnlLine2);
        OnFinancialVoidCheckOnAfterPostVoidCheckLine(GenJnlLine2, GenJnlPostLine);

        // Mark newly posted entry as cleared for bank reconciliation purposes.
        if ConfirmFinancialVoid.GetVoidDate() = CheckLedgEntry."Check Date" then
            ClearBankLedgerEntry(BankAccLedgEntry3);

        InitGenJnlLine(
          GenJnlLine2, CheckLedgEntry."Document Type", CheckLedgEntry."Document No.", ConfirmFinancialVoid.GetVoidDate(),
          CheckLedgEntry."Bal. Account Type", CheckLedgEntry."Bal. Account No.",
          StrSubstNo(VoidingCheckMsg, CheckLedgEntry."Check No."));
        GenJnlLine2.Validate("Currency Code", BankAcc."Currency Code");
        GenJnlLine2."Allow Zero-Amount Posting" := true;
        OnFinancialVoidCheckOnBeforeCheckBalAccountType(GenJnlLine2, CheckLedgEntry, BankAccLedgEntry3);
        case CheckLedgEntry."Bal. Account Type" of
            CheckLedgEntry."Bal. Account Type"::"G/L Account":
                FinancialVoidPostGLAccount(GenJnlLine2, BankAccLedgEntry2, CheckLedgEntry, BalanceAmountLCY);
            CheckLedgEntry."Bal. Account Type"::Customer:
                begin
                    if ConfirmFinancialVoid.GetVoidType() = 0 then   // Unapply entry
                        if UnApplyCustInvoices(CheckLedgEntry, ConfirmFinancialVoid.GetVoidDate()) then
                            GenJnlLine2."Applies-to ID" := CheckLedgEntry."Document No.";
                    CustLedgEntry.SetCurrentKey("Transaction No.");
                    CustLedgEntry.SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
                    CustLedgEntry.SetRange("Document No.", BankAccLedgEntry2."Document No.");
                    CustLedgEntry.SetRange("Posting Date", BankAccLedgEntry2."Posting Date");
                    if CustLedgEntry.FindSet() then
                        repeat
                            OnFinancialVoidCheckOnBeforePostCust(GenJnlLine2, CustLedgEntry, BalanceAmountLCY);
                            CustLedgEntry.CalcFields("Original Amount");
                            SetGenJnlLine(
                              GenJnlLine2, -CustLedgEntry."Original Amount", CustLedgEntry."Currency Code", CheckLedgEntry."Document No.",
                              CustLedgEntry."Global Dimension 1 Code", CustLedgEntry."Global Dimension 2 Code", CustLedgEntry."Dimension Set ID");
                            BalanceAmountLCY := BalanceAmountLCY + GenJnlLine2."Amount (LCY)";
                            GenJnlLine2."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
                            GenJnlLine2."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
                            OnFinancialVoidCheckOnBeforePostBalAccLine(GenJnlLine2, CheckLedgEntry);
                            GenJnlPostLine.RunWithCheck(GenJnlLine2);
                            OnFinancialVoidCheckOnAfterPostBalAccLine(GenJnlLine2, CheckLedgEntry, GenJnlPostLine);
                        until CustLedgEntry.Next() = 0;
                end;
            CheckLedgEntry."Bal. Account Type"::Vendor:
                begin
                    if ConfirmFinancialVoid.GetVoidType() = 0 then // Unapply entry
                        if UnApplyVendInvoices(CheckLedgEntry, ConfirmFinancialVoid.GetVoidDate()) then
                            GenJnlLine2."Applies-to ID" := CheckLedgEntry."Document No.";
                    VendorLedgEntry.SetCurrentKey("Transaction No.");
                    VendorLedgEntry.SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
                    VendorLedgEntry.SetRange("Document No.", BankAccLedgEntry2."Document No.");
                    VendorLedgEntry.SetRange("Posting Date", BankAccLedgEntry2."Posting Date");
                    OnFinancialVoidCheckOnAfterVendorLedgEntrySetFilters(VendorLedgEntry, BankAccLedgEntry2);
                    if VendorLedgEntry.FindSet() then
                        repeat
                            OnFinancialVoidCheckOnBeforePostVend(GenJnlLine2, VendorLedgEntry, BalanceAmountLCY);
                            VendorLedgEntry.CalcFields("Original Amount");
                            SetGenJnlLine(
                              GenJnlLine2, -VendorLedgEntry."Original Amount", VendorLedgEntry."Currency Code", CheckLedgEntry."Document No.",
                              VendorLedgEntry."Global Dimension 1 Code", VendorLedgEntry."Global Dimension 2 Code", VendorLedgEntry."Dimension Set ID");
                            BalanceAmountLCY := BalanceAmountLCY + GenJnlLine2."Amount (LCY)";
                            GenJnlLine2."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
                            GenJnlLine2."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
                            if GenJnlLine2."Posting Group" <> VendorLedgEntry."Vendor Posting Group" then
                                GenJnlLine2."Posting Group" := VendorLedgEntry."Vendor Posting Group";
                            OnFinancialVoidCheckOnBeforePostBalAccLine(GenJnlLine2, CheckLedgEntry);
                            GenJnlPostLine.RunWithCheck(GenJnlLine2);
                            OnFinancialVoidCheckOnAfterPostBalAccLine(GenJnlLine2, CheckLedgEntry, GenJnlPostLine);
                        until VendorLedgEntry.Next() = 0;
                end;
            CheckLedgEntry."Bal. Account Type"::"Bank Account":
                begin
                    BankAccLedgEntry3.SetCurrentKey("Transaction No.");
                    BankAccLedgEntry3.SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
                    BankAccLedgEntry3.SetRange("Document No.", BankAccLedgEntry2."Document No.");
                    BankAccLedgEntry3.SetRange("Posting Date", BankAccLedgEntry2."Posting Date");
                    BankAccLedgEntry3.SetFilter("Entry No.", '<>%1', BankAccLedgEntry2."Entry No.");
                    if BankAccLedgEntry3.FindSet() then
                        repeat
                            OnFinancialVoidCheckOnBeforePostBankAccount(GenJnlLine2, BankAccLedgEntry3);
                            GenJnlLine2.Validate(Amount, -BankAccLedgEntry3.Amount);
                            BalanceAmountLCY := BalanceAmountLCY + GenJnlLine2."Amount (LCY)";
                            GenJnlLine2."Shortcut Dimension 1 Code" := BankAccLedgEntry3."Global Dimension 1 Code";
                            GenJnlLine2."Shortcut Dimension 2 Code" := BankAccLedgEntry3."Global Dimension 2 Code";
                            GenJnlLine2."Dimension Set ID" := BankAccLedgEntry3."Dimension Set ID";
                            GenJnlLine2."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
                            GenJnlLine2."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
                            OnFinancialVoidCheckOnBeforePostBalAccLine(GenJnlLine2, CheckLedgEntry);
                            GenJnlPostLine.RunWithCheck(GenJnlLine2);
                            OnFinancialVoidCheckOnAfterPostBalAccLine(GenJnlLine2, CheckLedgEntry, GenJnlPostLine);
                        until BankAccLedgEntry3.Next() = 0;
                end;
            CheckLedgEntry."Bal. Account Type"::"Fixed Asset":
                begin
                    FALedgEntry.SetCurrentKey("Transaction No.");
                    FALedgEntry.SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
                    FALedgEntry.SetRange("Document No.", BankAccLedgEntry2."Document No.");
                    FALedgEntry.SetRange("Posting Date", BankAccLedgEntry2."Posting Date");
                    if FALedgEntry.FindSet() then
                        repeat
                            OnFinancialVoidCheckOnBeforePostFixedAsset(GenJnlLine2, FALedgEntry);
                            GenJnlLine2.Validate(Amount, -FALedgEntry.Amount);
                            BalanceAmountLCY := BalanceAmountLCY + GenJnlLine2."Amount (LCY)";
                            GenJnlLine2."Shortcut Dimension 1 Code" := FALedgEntry."Global Dimension 1 Code";
                            GenJnlLine2."Shortcut Dimension 2 Code" := FALedgEntry."Global Dimension 2 Code";
                            GenJnlLine2."Dimension Set ID" := FALedgEntry."Dimension Set ID";
                            GenJnlLine2."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
                            GenJnlLine2."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
                            OnFinancialVoidCheckOnBeforePostBalAccLine(GenJnlLine2, CheckLedgEntry);
                            GenJnlPostLine.RunWithCheck(GenJnlLine2);
                            OnFinancialVoidCheckOnAfterPostBalAccLine(GenJnlLine2, CheckLedgEntry, GenJnlPostLine);
                        until FALedgEntry.Next() = 0;
                end;
            CheckLedgEntry."Bal. Account Type"::Employee:
                begin
                    if ConfirmFinancialVoid.GetVoidType() = 0 then // Unapply entry
                        if UnApplyEmpInvoices(CheckLedgEntry, ConfirmFinancialVoid.GetVoidDate()) then
                            GenJnlLine2."Applies-to ID" := CheckLedgEntry."Document No.";
                    EmployeeLedgerEntry.SetCurrentKey("Transaction No.");
                    EmployeeLedgerEntry.SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
                    EmployeeLedgerEntry.SetRange("Document No.", BankAccLedgEntry2."Document No.");
                    EmployeeLedgerEntry.SetRange("Posting Date", BankAccLedgEntry2."Posting Date");
                    if EmployeeLedgerEntry.FindSet() then
                        repeat
                            OnFinancialVoidCheckOnBeforePostEmp(GenJnlLine2, EmployeeLedgerEntry);
                            EmployeeLedgerEntry.CalcFields("Original Amount");
                            SetGenJnlLine(
                              GenJnlLine2, -EmployeeLedgerEntry."Original Amount", EmployeeLedgerEntry."Currency Code", CheckLedgEntry."Document No.",
                              EmployeeLedgerEntry."Global Dimension 1 Code", EmployeeLedgerEntry."Global Dimension 2 Code", EmployeeLedgerEntry."Dimension Set ID");
                            BalanceAmountLCY := BalanceAmountLCY + GenJnlLine2."Amount (LCY)";
                            OnFinancialVoidCheckOnBeforePostBalAccLine(GenJnlLine2, CheckLedgEntry);
                            GenJnlLine2."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
                            GenJnlLine2."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
                            GenJnlPostLine.RunWithCheck(GenJnlLine2);
                            OnFinancialVoidCheckOnAfterPostBalAccLine(GenJnlLine2, CheckLedgEntry, GenJnlPostLine);
                        until EmployeeLedgerEntry.Next() = 0;
                end;
            else begin
                GenJnlLine2."Bal. Account Type" := CheckLedgEntry."Bal. Account Type";
                GenJnlLine2.Validate("Bal. Account No.", CheckLedgEntry."Bal. Account No.");
                GenJnlLine2."Shortcut Dimension 1 Code" := '';
                GenJnlLine2."Shortcut Dimension 2 Code" := '';
                GenJnlLine2."Dimension Set ID" := 0;
                GenJnlLine2."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
                GenJnlLine2."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
                OnFinancialVoidCheckOnBeforePostBalAccLine(GenJnlLine2, CheckLedgEntry);
                GenJnlPostLine.RunWithCheck(GenJnlLine2);
                OnFinancialVoidCheckOnAfterPostBalAccLine(GenJnlLine2, CheckLedgEntry, GenJnlPostLine);
            end;
        end;

        if ConfirmFinancialVoid.GetVoidDate() = CheckLedgEntry."Check Date" then begin
            BankAccLedgEntry2.Open := false;
            BankAccLedgEntry2."Remaining Amount" := 0;
            BankAccLedgEntry2."Statement Status" := BankAccLedgEntry2."Statement Status"::Closed;
            BankAccLedgEntry2.Modify();
        end;

        // rounding error from currency conversion
        if CheckAmountLCY + BalanceAmountLCY <> 0 then
            PostRoundingAmount(BankAcc, CheckLedgEntry, ConfirmFinancialVoid.GetVoidDate(), -(CheckAmountLCY + BalanceAmountLCY));

        MarkCheckEntriesVoid(CheckLedgEntry, ConfirmFinancialVoid.GetVoidDate());
        Commit();
        UpdateAnalysisView.UpdateAll(0, true);

        OnAfterFinancialVoidCheck(CheckLedgEntry);
    end;

    procedure GenJournalLineGetSystemIdFromRecordId(GenJournalLineRecordId: RecordId): Guid
    var
        GenJournalLineRecordRef: RecordRef;
        GenJournalLineFieldRef: FieldRef;
        NullGuid: Guid;
    begin
        if GenJournalLineRecordId.TableNo <> Database::"Gen. Journal Line" then
            exit(NullGuid);
        if not GenJournalLineRecordRef.Get(GenJournalLineRecordId) then
            exit(NullGuid);
        GenJournalLineFieldRef := GenJournalLineRecordRef.Field(GenJournalLineRecordRef.SystemIdNo());
        exit(GenJournalLineFieldRef.Value);
    end;

    local procedure FinancialVoidPostGLAccount(var GenJnlLine: Record "Gen. Journal Line"; BankAccLedgEntry2: Record "Bank Account Ledger Entry"; CheckLedgEntry: Record "Check Ledger Entry"; var BalanceAmountLCY: Decimal)
    var
        GLEntry: Record "G/L Entry";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
        GLEntry.SetRange("Document No.", BankAccLedgEntry2."Document No.");
        GLEntry.SetRange("Posting Date", BankAccLedgEntry2."Posting Date");
        GLEntry.SetFilter("Entry No.", '<>%1', BankAccLedgEntry2."Entry No.");
        GLEntry.SetRange("G/L Account No.", CheckLedgEntry."Bal. Account No.");
        if GLEntry.FindSet() then
            repeat
                OnFinancialVoidPostGLAccountOnBeforeGLEntryLoop(GLEntry, CheckLedgEntry);
                GenJnlLine.Validate("Account No.", GLEntry."G/L Account No.");
                GenJnlLine.Description := StrSubstNo(VoidingCheckMsg, CheckLedgEntry."Check No.");
                GenJnlLine.Validate(Amount, -GLEntry.Amount - GLEntry."VAT Amount");
                BalanceAmountLCY := BalanceAmountLCY + GenJnlLine."Amount (LCY)";
                GenJnlLine."Shortcut Dimension 1 Code" := GLEntry."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := GLEntry."Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := GLEntry."Dimension Set ID";
                GenJnlLine."Gen. Posting Type" := GLEntry."Gen. Posting Type";
                GenJnlLine."Gen. Bus. Posting Group" := GLEntry."Gen. Bus. Posting Group";
                GenJnlLine."Gen. Prod. Posting Group" := GLEntry."Gen. Prod. Posting Group";
                GenJnlLine."VAT Bus. Posting Group" := GLEntry."VAT Bus. Posting Group";
                GenJnlLine."VAT Prod. Posting Group" := GLEntry."VAT Prod. Posting Group";
                if VATPostingSetup.Get(GLEntry."VAT Bus. Posting Group", GLEntry."VAT Prod. Posting Group") then
                    GenJnlLine."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
                GenJnlLine."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
                GenJnlLine."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
                OnFinancialVoidCheckOnBeforePostBalAccLine(GenJnlLine, CheckLedgEntry);
                GenJnlPostLine.RunWithCheck(GenJnlLine);
                OnFinancialVoidCheckOnAfterPostBalAccLine(GenJnlLine, CheckLedgEntry, GenJnlPostLine);
            until GLEntry.Next() = 0;
    end;

    local procedure UnApplyVendInvoices(var CheckLedgEntry: Record "Check Ledger Entry"; VoidDate: Date): Boolean
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        OrigPaymentVendorLedgerEntry: Record "Vendor Ledger Entry";
        PayDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine3: Record "Gen. Journal Line";
        AppliesID: Code[50];
        IsHandled: Boolean;
        Result: Boolean;
    begin

        IsHandled := false;
        OnBeforeUnApplyVendInvoices(CheckLedgEntry, VoidDate, IsHandled, Result);
        if IsHandled then
            exit(Result);

        // first, find first original payment line, if any
        BankAccountLedgerEntry.Get(CheckLedgEntry."Bank Account Ledger Entry No.");
        if CheckLedgEntry."Bal. Account Type" = CheckLedgEntry."Bal. Account Type"::Vendor then begin
            OrigPaymentVendorLedgerEntry.SetCurrentKey("Transaction No.");
            OrigPaymentVendorLedgerEntry.SetRange("Transaction No.", BankAccountLedgerEntry."Transaction No.");
            OrigPaymentVendorLedgerEntry.SetRange("Document No.", BankAccountLedgerEntry."Document No.");
            OrigPaymentVendorLedgerEntry.SetRange("Posting Date", BankAccountLedgerEntry."Posting Date");
            if not OrigPaymentVendorLedgerEntry.FindFirst() then
                exit(false);
        end
        else
            exit(false);

        AppliesID := CheckLedgEntry."Document No.";

        PayDetailedVendorLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
        PayDetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", OrigPaymentVendorLedgerEntry."Entry No.");
        PayDetailedVendorLedgEntry.SetRange(Unapplied, false);
        PayDetailedVendorLedgEntry.SetFilter("Applied Vend. Ledger Entry No.", '<>%1', 0);
        PayDetailedVendorLedgEntry.SetRange("Entry Type", PayDetailedVendorLedgEntry."Entry Type"::Application);
        if not PayDetailedVendorLedgEntry.FindSet() then begin
            IsHandled := false;
            OnUnApplyVendInvoicesOnBeforeErrorNoAppliedEntry(BankAccountLedgerEntry, GenJnlLine2, IsHandled);
            if not IsHandled then
                Error(NoAppliedEntryErr);
        end;
        repeat
            GenJournalLine3.CopyFromPaymentVendLedgEntry(OrigPaymentVendorLedgerEntry);
            GenJournalLine3."Posting Date" := VoidDate;
            GenJournalLine3.Description := StrSubstNo(VoidingCheckMsg, CheckLedgEntry."Check No.");
            GenJournalLine3."Source Code" := SourceCodeSetup."Financially Voided Check";
            OnUnApplyVendInvoicesOnBeforePost(GenJournalLine3, VendorLedgEntry, PayDetailedVendorLedgEntry);
            GenJnlPostLine.UnapplyVendLedgEntry(GenJournalLine3, PayDetailedVendorLedgEntry);
        until PayDetailedVendorLedgEntry.Next() = 0;

        OrigPaymentVendorLedgerEntry.FindSet(true);
        // re-get the now-modified payment entry.
        repeat
            // set up to be applied by upcoming voiding entry.
            MakeAppliesID(AppliesID, CheckLedgEntry."Document No.");
            OrigPaymentVendorLedgerEntry."Applies-to ID" := AppliesID;
            OrigPaymentVendorLedgerEntry.CalcFields("Remaining Amount");
            OnUnApplyVendInvoicesOnAfterCalcRemainingAmount(OrigPaymentVendorLedgerEntry);
            OrigPaymentVendorLedgerEntry."Amount to Apply" := OrigPaymentVendorLedgerEntry."Remaining Amount";
            OrigPaymentVendorLedgerEntry."Accepted Pmt. Disc. Tolerance" := false;
            OrigPaymentVendorLedgerEntry."Accepted Payment Tolerance" := 0;
            OrigPaymentVendorLedgerEntry.Modify();
        until OrigPaymentVendorLedgerEntry.Next() = 0;
        exit(true);
    end;

    local procedure UnApplyCustInvoices(var CheckLedgEntry: Record "Check Ledger Entry"; VoidDate: Date): Boolean
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        OrigPaymentCustLedgerEntry: Record "Cust. Ledger Entry";
        PayDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine3: Record "Gen. Journal Line";
        AppliesID: Code[50];
    begin
        // first, find first original payment line, if any
        BankAccountLedgerEntry.Get(CheckLedgEntry."Bank Account Ledger Entry No.");
        if CheckLedgEntry."Bal. Account Type" = CheckLedgEntry."Bal. Account Type"::Customer then begin
            OrigPaymentCustLedgerEntry.SetCurrentKey("Transaction No.");
            OrigPaymentCustLedgerEntry.SetRange("Transaction No.", BankAccountLedgerEntry."Transaction No.");
            OrigPaymentCustLedgerEntry.SetRange("Document No.", BankAccountLedgerEntry."Document No.");
            OrigPaymentCustLedgerEntry.SetRange("Posting Date", BankAccountLedgerEntry."Posting Date");
            if not OrigPaymentCustLedgerEntry.FindFirst() then
                exit(false);
        end
        else
            exit(false);

        AppliesID := CheckLedgEntry."Document No.";

        PayDetailedCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
        PayDetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", OrigPaymentCustLedgerEntry."Entry No.");
        PayDetailedCustLedgEntry.SetRange(Unapplied, false);
        PayDetailedCustLedgEntry.SetFilter("Applied Cust. Ledger Entry No.", '<>%1', 0);
        PayDetailedCustLedgEntry.SetRange("Entry Type", PayDetailedCustLedgEntry."Entry Type"::Application);
        if not PayDetailedCustLedgEntry.FindSet() then
            Error(NoAppliedEntryErr);
        repeat
            GenJournalLine3.CopyFromPaymentCustLedgEntry(OrigPaymentCustLedgerEntry);
            GenJournalLine3."Posting Date" := VoidDate;
            GenJournalLine3.Description := StrSubstNo(VoidingCheckMsg, CheckLedgEntry."Check No.");
            GenJournalLine3."Source Code" := SourceCodeSetup."Financially Voided Check";
            OnUnApplyCustInvoicesOnBeforePost(GenJournalLine3, CustLedgEntry, PayDetailedCustLedgEntry);
            GenJnlPostLine.UnapplyCustLedgEntry(GenJournalLine3, PayDetailedCustLedgEntry);
        until PayDetailedCustLedgEntry.Next() = 0;

        OrigPaymentCustLedgerEntry.FindSet(true);
        // re-get the now-modified payment entry.
        repeat
            // set up to be applied by upcoming voiding entry.
            MakeAppliesID(AppliesID, CheckLedgEntry."Document No.");
            OrigPaymentCustLedgerEntry."Applies-to ID" := AppliesID;
            OrigPaymentCustLedgerEntry.CalcFields("Remaining Amount");
            OnUnApplyCustInvoicesOnAfterCalcRemainingAmount(OrigPaymentCustLedgerEntry);
            OrigPaymentCustLedgerEntry."Amount to Apply" := OrigPaymentCustLedgerEntry."Remaining Amount";
            OrigPaymentCustLedgerEntry."Accepted Pmt. Disc. Tolerance" := false;
            OrigPaymentCustLedgerEntry."Accepted Payment Tolerance" := 0;
            OrigPaymentCustLedgerEntry.Modify();
        until OrigPaymentCustLedgerEntry.Next() = 0;
        exit(true);
    end;

    local procedure UnApplyEmpInvoices(var CheckLedgEntry: Record "Check Ledger Entry"; VoidDate: Date): Boolean
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        OrigPaymentEmployeeLedgerEntry: Record "Employee Ledger Entry";
        PayDetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
        GenJournalLine3: Record "Gen. Journal Line";
        AppliesID: Code[50];
    begin
        // first, find first original payment line, if any
        BankAccountLedgerEntry.Get(CheckLedgEntry."Bank Account Ledger Entry No.");
        if CheckLedgEntry."Bal. Account Type" <> CheckLedgEntry."Bal. Account Type"::Employee then
            exit(false);

        OrigPaymentEmployeeLedgerEntry.SetCurrentKey("Transaction No.");
        OrigPaymentEmployeeLedgerEntry.SetRange("Transaction No.", BankAccountLedgerEntry."Transaction No.");
        OrigPaymentEmployeeLedgerEntry.SetRange("Document No.", BankAccountLedgerEntry."Document No.");
        OrigPaymentEmployeeLedgerEntry.SetRange("Posting Date", BankAccountLedgerEntry."Posting Date");
        if not OrigPaymentEmployeeLedgerEntry.FindFirst() then
            exit(false);

        AppliesID := CheckLedgEntry."Document No.";

        PayDetailedEmployeeLedgEntry.SetCurrentKey("Employee Ledger Entry No.", "Entry Type", "Posting Date");
        PayDetailedEmployeeLedgEntry.SetRange("Employee Ledger Entry No.", OrigPaymentEmployeeLedgerEntry."Entry No.");
        PayDetailedEmployeeLedgEntry.SetRange(Unapplied, false);
        PayDetailedEmployeeLedgEntry.SetFilter("Applied Empl. Ledger Entry No.", '<>%1', 0);
        PayDetailedEmployeeLedgEntry.SetRange("Entry Type", PayDetailedEmployeeLedgEntry."Entry Type"::Application);
        if not PayDetailedEmployeeLedgEntry.FindSet() then
            Error(NoAppliedEntryErr);
        repeat
            GenJournalLine3.CopyFromPaymentEmpLedgEntry(OrigPaymentEmployeeLedgerEntry);
            GenJournalLine3."Posting Date" := VoidDate;
            GenJournalLine3.Description := StrSubstNo(VoidingCheckMsg, CheckLedgEntry."Check No.");
            GenJournalLine3."Source Code" := SourceCodeSetup."Financially Voided Check";
            GenJnlPostLine.UnapplyEmplLedgEntry(GenJournalLine3, PayDetailedEmployeeLedgEntry);
        until PayDetailedEmployeeLedgEntry.Next() = 0;

        OrigPaymentEmployeeLedgerEntry.FindSet(true);
        // re-get the now-modified payment entry.
        repeat
            // set up to be applied by upcoming voiding entry.
            MakeAppliesID(AppliesID, CheckLedgEntry."Document No.");
            OrigPaymentEmployeeLedgerEntry."Applies-to ID" := AppliesID;
            OrigPaymentEmployeeLedgerEntry.CalcFields("Remaining Amount");
            OrigPaymentEmployeeLedgerEntry."Amount to Apply" := OrigPaymentEmployeeLedgerEntry."Remaining Amount";
            OrigPaymentEmployeeLedgerEntry.Modify();
        until OrigPaymentEmployeeLedgerEntry.Next() = 0;
        exit(true);
    end;

    local procedure MarkCheckEntriesVoid(var OriginalCheckLedgerEntry: Record "Check Ledger Entry"; VoidDate: Date)
    var
        RelatedCheckLedgerEntry: Record "Check Ledger Entry";
        RelatedCheckLedgerEntry2: Record "Check Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMarkCheckEntriesVoid(OriginalCheckLedgerEntry, VoidDate, IsHandled);
        if IsHandled then
            exit;

        RelatedCheckLedgerEntry.Reset();
        RelatedCheckLedgerEntry.SetCurrentKey("Bank Account No.", "Entry Status", "Check No.");
        RelatedCheckLedgerEntry.SetRange("Bank Account No.", OriginalCheckLedgerEntry."Bank Account No.");
        RelatedCheckLedgerEntry.SetRange("Entry Status", OriginalCheckLedgerEntry."Entry Status"::Posted);
        RelatedCheckLedgerEntry.SetRange("Statement Status", OriginalCheckLedgerEntry."Statement Status"::Open);
        RelatedCheckLedgerEntry.SetRange("Check No.", OriginalCheckLedgerEntry."Check No.");
        RelatedCheckLedgerEntry.SetRange("Check Date", OriginalCheckLedgerEntry."Check Date");
        RelatedCheckLedgerEntry.SetFilter("Entry No.", '<>%1', OriginalCheckLedgerEntry."Entry No.");
        if RelatedCheckLedgerEntry.FindSet() then
            repeat
                RelatedCheckLedgerEntry2 := RelatedCheckLedgerEntry;
                RelatedCheckLedgerEntry2."Original Entry Status" := RelatedCheckLedgerEntry."Entry Status";
                RelatedCheckLedgerEntry2."Entry Status" := RelatedCheckLedgerEntry."Entry Status"::"Financially Voided";
                RelatedCheckLedgerEntry2."Positive Pay Exported" := false;
                if VoidDate = OriginalCheckLedgerEntry."Check Date" then begin
                    RelatedCheckLedgerEntry2.Open := false;
                    RelatedCheckLedgerEntry2."Statement Status" := RelatedCheckLedgerEntry2."Statement Status"::Closed;
                end;
                OnMarkCheckEntriesVoidOnBeforeRelatedCheckLedgerEntry2Modify(RelatedCheckLedgerEntry2, VoidDate);
                RelatedCheckLedgerEntry2.Modify();
            until RelatedCheckLedgerEntry.Next() = 0;

        OriginalCheckLedgerEntry."Original Entry Status" := OriginalCheckLedgerEntry."Entry Status";
        OriginalCheckLedgerEntry."Entry Status" := OriginalCheckLedgerEntry."Entry Status"::"Financially Voided";
        OriginalCheckLedgerEntry."Positive Pay Exported" := false;
        if VoidDate = OriginalCheckLedgerEntry."Check Date" then begin
            OriginalCheckLedgerEntry.Open := false;
            OriginalCheckLedgerEntry."Statement Status" := OriginalCheckLedgerEntry."Statement Status"::Closed;
        end;
        OnMarkCheckEntriesVoidOnBeforeOriginalCheckLedgerEntryModify(OriginalCheckLedgerEntry, VoidDate);
        OriginalCheckLedgerEntry.Modify();
    end;

    local procedure MakeAppliesID(var AppliesID: Code[50]; CheckDocNo: Code[20])
    begin
        if AppliesID = '' then
            exit;
        if AppliesID = CheckDocNo then
            AppliesIDCounter := 0;
        AppliesIDCounter := AppliesIDCounter + 1;
        AppliesID :=
          CopyStr(Format(AppliesIDCounter) + CheckDocNo, 1, MaxStrLen(AppliesID));
    end;

    local procedure CalcAmountToVoid(CheckLedgEntry: Record "Check Ledger Entry") AmountToVoid: Decimal
    var
        CheckLedgEntry2: Record "Check Ledger Entry";
    begin
        CheckLedgEntry2.Reset();
        CheckLedgEntry2.SetRange("Bank Account No.", CheckLedgEntry."Bank Account No.");
        CheckLedgEntry2.SetRange("Entry Status", CheckLedgEntry."Entry Status"::Posted);
        CheckLedgEntry2.SetRange("Statement Status", CheckLedgEntry."Statement Status"::Open);
        CheckLedgEntry2.SetRange("Check No.", CheckLedgEntry."Check No.");
        CheckLedgEntry2.SetRange("Check Date", CheckLedgEntry."Check Date");
        CheckLedgEntry2.CalcSums(Amount);
        AmountToVoid := CheckLedgEntry2.Amount;

        OnAfterCalcAmountToVoid(CheckLedgEntry, AmountToVoid);
    end;

    local procedure InitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; PostingDate: Date; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Description: Text[50])
    begin
        GenJnlLine.Init();
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Financial Void" := true;
        GenJnlLine."Document Type" := DocumentType;
        GenJnlLine."Document No." := DocumentNo;
        GenJnlLine."Account Type" := AccountType;
        GenJnlLine."Posting Date" := PostingDate;
        GenJnlLine."VAT Reporting Date" := PostingDate;
        GenJnlLine.Validate("Account No.", AccountNo);
        GenJnlLine.Description := Description;
        GenJnlLine."Source Code" := SourceCodeSetup."Financially Voided Check";
    end;

    local procedure SetGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; OriginalAmount: Decimal; CurrencyCode: Code[10]; DocumentNo: Code[20]; Dim1Code: Code[20]; Dim2Code: Code[20]; DimSetID: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetGenJnlLine(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.Validate(Amount, OriginalAmount);
        GenJnlLine.Validate("Currency Code", CurrencyCode);
        MakeAppliesID(GenJnlLine."Applies-to ID", DocumentNo);
        GenJnlLine."Shortcut Dimension 1 Code" := Dim1Code;
        GenJnlLine."Shortcut Dimension 2 Code" := Dim2Code;
        GenJnlLine."Dimension Set ID" := DimSetID;
        GenJnlLine."Source Currency Code" := CurrencyCode;

        OnAfterSetGenJnlLine(GenJnlLine);
    end;

    local procedure IsElectronicBankPaymentType(BankPaymentType: Enum "Bank Payment Type") IsElectronicPaymentType: Boolean
    begin
        IsElectronicPaymentType := BankPaymentType in [BankPaymentType::"Electronic Payment", BankPaymentType::"Electronic Payment-IAT"];

        OnAfterIsElectronicBankPaymentType(BankPaymentType, IsElectronicPaymentType);
    end;

    /// <summary>
    /// Processes electronic payment transmission or voiding based on specified operation type.
    /// Manages electronic payment status updates and data exchange integration.
    /// </summary>
    /// <param name="GenJournalLine">General journal line containing electronic payment information</param>
    /// <param name="WhichProcess">Process type: Void or Transmit electronic payment</param>
    procedure ProcessElectronicPayment(var GenJournalLine: Record "Gen. Journal Line"; WhichProcess: Option ,Void,Transmit)
    var
        CheckLedgEntry2: Record "Check Ledger Entry";
        CheckLedgEntry3: Record "Check Ledger Entry";
        BankAccountNo: Code[20];
    begin
        if not IsElectronicBankPaymentType(GenJournalLine."Bank Payment Type") then
            GenJournalLine.FieldError("Bank Payment Type");
        GenJournalLine.TestField("Exported to Payment File", true);
        if not (GenJournalLine."Document Type" in [GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Refund]) then
            Error(PaymentOrRefundErr, GenJournalLine.FieldCaption("Document Type"), GenJournalLine."Document Type"::Payment,
              GenJournalLine."Document Type"::Refund);
        GenJournalLine.TestField("Document No.");
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::"Bank Account" then begin
            GenJournalLine.TestField("Account No.");
            BankAccountNo := GenJournalLine."Account No.";
        end else
            if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"Bank Account" then begin
                GenJournalLine.TestField("Bal. Account No.");
                BankAccountNo := GenJournalLine."Bal. Account No.";
            end else
                Error(BankAccountTypeErr, GenJournalLine.FieldCaption("Account Type"), GenJournalLine.FieldCaption("Bal. Account Type"));

        CheckLedgEntry2.Reset();
        CheckLedgEntry2.SetRange("Bank Account No.", BankAccountNo);
        CheckLedgEntry2.SetRange("Entry Status", CheckLedgEntry2."Entry Status"::Exported);
        CheckLedgEntry2.SetRange("Check No.", GenJournalLine."Document No.");
        if CheckLedgEntry2.FindSet() then
            repeat
                CheckLedgEntry3 := CheckLedgEntry2;
                CheckLedgEntry3."Original Entry Status" := CheckLedgEntry3."Entry Status";
                case WhichProcess of
                    WhichProcess::Void:
                        begin
                            CheckLedgEntry3."Entry Status" := CheckLedgEntry3."Entry Status"::Voided;
                            CheckLedgEntry3."Positive Pay Exported" := false;
                        end;
                    WhichProcess::Transmit:
                        CheckLedgEntry3."Entry Status" := CheckLedgEntry3."Entry Status"::Transmitted;
                end;
                OnProcessElectronicPaymentOnBeforeCheckLedgEntry3Modify(CheckLedgEntry3, WhichProcess);
                CheckLedgEntry3.Modify();
            until CheckLedgEntry2.Next() = 0;

        if WhichProcess = WhichProcess::Void then begin
            RemoveCreditTransfers(GenJournalLine);
            ClearApplnLedgerEntries(GenJournalLine);
        end;
    end;

    local procedure ClearApplnLedgerEntries(GenJournalLine: Record "Gen. Journal Line")
    begin
        case GenJournalLine."Account Type" of
            GenJournalLine."Account Type"::Customer:
                ClearApplnCustLedgerEntries(GenJournalLine);
            GenJournalLine."Account Type"::Vendor:
                ClearApplnVendorLedgerEntries(GenJournalLine);
            GenJournalLine."Account Type"::Employee:
                ClearApplnEmployeeLedgerEntries(GenJournalLine);
        end
    end;

    local procedure ClearApplnCustLedgerEntries(GenJournalLine: Record "Gen. Journal Line")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ApplyingCustLedgerEntry: Record "Cust. Ledger Entry";
        CustEntrySetApplID: Codeunit "Cust. Entry-SetAppl.ID";
    begin
        CustLedgerEntry.SetRange("Applies-to ID", GenJournalLine."Document No.");
        if CustLedgerEntry.FindSet() then
            repeat
                CustEntrySetApplID.SetApplId(CustLedgerEntry, ApplyingCustLedgerEntry, '');
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure ClearApplnVendorLedgerEntries(GenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry";
        VendEntrySetApplID: Codeunit "Vend. Entry-SetAppl.ID";
    begin
        VendorLedgerEntry.SetRange("Applies-to ID", GenJournalLine."Document No.");
        if VendorLedgerEntry.FindSet() then
            repeat
                VendEntrySetApplID.SetApplId(VendorLedgerEntry, ApplyingVendorLedgerEntry, '');
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure ClearApplnEmployeeLedgerEntries(GenJournalLine: Record "Gen. Journal Line")
    var
        EmplLedgerEntry: Record "Employee Ledger Entry";
        ApplyingEmployeeLedgerEntry: Record "Employee Ledger Entry";
        EmplEntrySetApplID: Codeunit "Empl. Entry-SetAppl.ID";
    begin
        EmplLedgerEntry.SetRange("Applies-to ID", GenJournalLine."Document No.");
        if EmplLedgerEntry.FindSet() then
            repeat
                EmplEntrySetApplID.SetApplId(EmplLedgerEntry, ApplyingEmployeeLedgerEntry, '');
            until EmplLedgerEntry.Next() = 0;
    end;

    local procedure RemoveCreditTransfers(var GenJournalLine: Record "Gen. Journal Line")
    var
        CreditTransferRegister: Record "Credit Transfer Register";
        CreditTransferEntry: Record "Credit Transfer Entry";
        GenJnlShowCTEntries: Codeunit "Gen. Jnl.-Show CT Entries";
    begin
        GenJnlShowCTEntries.SetFiltersOnCreditTransferEntry(GenJournalLine, CreditTransferEntry);
        if CreditTransferEntry.FindLast() then begin
            if CreditTransferRegister.Get(CreditTransferEntry."Credit Transfer Register No.") then
                CreditTransferRegister.Delete(true);
            // For journal entries with multiple lines, the register would have already been deleted,
            // but subsequent lines still need to be deleted.
            Commit();
        end;
    end;

    local procedure PostRoundingAmount(BankAcc: Record "Bank Account"; CheckLedgEntry: Record "Check Ledger Entry"; PostingDate: Date; RoundingAmount: Decimal)
    var
        GenJnlLine2: Record "Gen. Journal Line";
        Currency: Record Currency;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostRoundingAmount(BankAcc, CheckLedgEntry, BankAccLedgEntry2, PostingDate, RoundingAmount, IsHandled);
        if IsHandled then
            exit;

        Currency.Get(BankAcc."Currency Code");
        GenJnlLine2.Init();
        GenJnlLine2."System-Created Entry" := true;
        GenJnlLine2."Financial Void" := true;
        GenJnlLine2."Document No." := CheckLedgEntry."Document No.";
        GenJnlLine2."Account Type" := GenJnlLine2."Account Type"::"G/L Account";
        GenJnlLine2."Posting Date" := PostingDate;
        if RoundingAmount > 0 then
            GenJnlLine2.Validate("Account No.", Currency.GetConvLCYRoundingDebitAccount())
        else
            GenJnlLine2.Validate("Account No.", Currency.GetConvLCYRoundingCreditAccount());
        GenJnlLine2.Validate("Currency Code", BankAcc."Currency Code");
        GenJnlLine2.Description := StrSubstNo(VoidingCheckMsg, CheckLedgEntry."Check No.");
        GenJnlLine2."Source Code" := SourceCodeSetup."Financially Voided Check";
        GenJnlLine2."Allow Zero-Amount Posting" := true;
        GenJnlLine2.Validate(Amount, 0);
        GenJnlLine2."Amount (LCY)" := RoundingAmount;
        GenJnlLine2."Shortcut Dimension 1 Code" := BankAccLedgEntry2."Global Dimension 1 Code";
        GenJnlLine2."Shortcut Dimension 2 Code" := BankAccLedgEntry2."Global Dimension 2 Code";
        GenJnlLine2."Dimension Set ID" := BankAccLedgEntry2."Dimension Set ID";
        GenJnlLine2."Journal Template Name" := BankAccLedgEntry2."Journal Templ. Name";
        GenJnlLine2."Journal Batch Name" := BankAccLedgEntry2."Journal Batch Name";
        OnPostRoundingAmountOnBeforeGenJnlPostLine(GenJnlLine2, CheckLedgEntry, BankAccLedgEntry2);
        GenJnlPostLine.RunWithCheck(GenJnlLine2);
        OnPostRoundingAmountOnAfterGenJnlPostLine(GenJnlLine2, CheckLedgEntry, GenJnlPostLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure CleanRecordIDToPrintOnAfterDeleteEventGenJournalLine(var Rec: Record "Gen. Journal Line"; RunTrigger: Boolean)
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        NullGuid: Guid;
    begin
        if Rec.IsTemporary then
            exit;
        CheckLedgerEntry.SetRange("Print Gen Jnl Line SystemId", Rec.SystemId);
        if not CheckLedgerEntry.IsEmpty() then
            CheckLedgerEntry.ModifyAll("Print Gen Jnl Line SystemId", NullGuid);
    end;

    local procedure FinancialVoidCheckPreValidation(var CheckLedgEntry: Record "Check Ledger Entry")
    var
        TransactionBalance: Decimal;
    begin
        CheckLedgEntry.TestField("Entry Status", CheckLedgEntry."Entry Status"::Posted);
        CheckLedgEntry.TestField("Statement Status", CheckLedgEntry."Statement Status"::Open);
        CheckLedgEntry.TestField("Bal. Account No.");
        BankAcc.Get(CheckLedgEntry."Bank Account No.");
        BankAccLedgEntry2.Get(CheckLedgEntry."Bank Account Ledger Entry No.");
        SourceCodeSetup.Get();
        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.SetRange("Transaction No.", BankAccLedgEntry2."Transaction No.");
        GLEntry.SetRange("Document No.", BankAccLedgEntry2."Document No.");
        GLEntry.CalcSums(Amount);
        TransactionBalance := GLEntry.Amount;
        if TransactionBalance <> 0 then
            Error(VoidingCheckErr);
        OnAfterFinancialVoidCheckPreValidation(CheckLedgEntry, BankAccLedgEntry2);
    end;

    local procedure ClearBankLedgerEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
        BankAccountLedgerEntry.Reset();
        BankAccountLedgerEntry.FindLast();
        BankAccountLedgerEntry.Open := false;
        BankAccountLedgerEntry."Remaining Amount" := 0;
        BankAccountLedgerEntry."Statement Status" := BankAccLedgEntry2."Statement Status"::Closed;
        BankAccountLedgerEntry.Modify();
    end;

    /// <summary>
    /// Integration event raised after calculating the total amount to void for a check.
    /// Enables custom calculation logic or adjustments to the void amount.
    /// </summary>
    /// <param name="CheckLedgerEntry">Check ledger entry being processed for voiding</param>
    /// <param name="AmountToVoid">Calculated amount to void (can be modified by subscribers)</param>
    /// <remarks>
    /// Raised from CalcAmountToVoid procedure after summing all related check entries.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcAmountToVoid(var CheckLedgerEntry: Record "Check Ledger Entry"; var AmountToVoid: Decimal)
    begin
    end;

    /// <summary>
    /// Integration event raised after successfully voiding a check entry.
    /// Enables custom processing or logging after the void operation completes.
    /// </summary>
    /// <param name="GenJnlLine">General journal line used for the void operation</param>
    /// <param name="CheckLedgerEntry">Check ledger entry that was voided</param>
    /// <remarks>
    /// Raised from VoidCheck procedure after updating the check status to Voided.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterVoidCheck(var GenJnlLine: Record "Gen. Journal Line"; var CheckLedgerEntry: Record "Check Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after completing a financial void operation on a check.
    /// Enables custom processing or notifications after the check has been financially voided.
    /// </summary>
    /// <param name="CheckLedgerEntry">Check ledger entry that was financially voided</param>
    /// <remarks>
    /// Raised from FinancialVoidCheck procedure after all void entries are posted and analysis view is updated.
    /// 
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFinancialVoidCheck(var CheckLedgerEntry: Record "Check Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after validating prerequisites for financial void operation.
    /// Enables additional validation or processing after standard void validation completes.
    /// </summary>
    /// <param name="CheckLedgerEntry">Check ledger entry being validated for void</param>
    /// <param name="BankAccountLedgerEntry">Associated bank account ledger entry</param>
    /// <remarks>
    /// Raised from FinancialVoidCheckPreValidation procedure after verifying transaction balance is zero.
    /// 
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFinancialVoidCheckPreValidation(CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before starting a check void operation.
    /// Enables custom validation or processing before the void operation begins.
    /// </summary>
    /// <param name="GenJnlLine">General journal line for the check being voided</param>
    /// <param name="IsHandled">Set to true to skip standard void processing</param>
    /// <remarks>
    /// Raised from VoidCheck procedure before any void processing begins.
    /// 
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeVoidCheck(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before marking check ledger entries as void.
    /// Enables custom logic for handling check entry void marking.
    /// </summary>
    /// <param name="OriginalCheckLedgerEntry">Original check ledger entry being marked as voided</param>
    /// <param name="VoidDate">Date when the void operation is performed</param>
    /// <param name="IsHandled">Set to true to skip standard void marking logic</param>
    /// <remarks>
    /// Raised from MarkCheckEntriesVoid procedure before updating entry status to Financially Voided.
    /// 
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeMarkCheckEntriesVoid(var OriginalCheckLedgerEntry: Record "Check Ledger Entry"; VoidDate: Date; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before starting a financial void operation on a check.
    /// Enables custom validation or alternative void processing.
    /// </summary>
    /// <param name="CheckLedgerEntry">Check ledger entry being financially voided</param>
    /// <param name="IsHandled">Set to true to skip standard financial void processing</param>
    /// <remarks>
    /// Raised from FinancialVoidCheck procedure before performing void validation and processing.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinancialVoidCheck(var CheckLedgerEntry: Record "Check Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before modifying a general journal line during check void operation.
    /// Enables custom field updates or validation before journal line modification.
    /// </summary>
    /// <param name="GenJournalLine2">General journal line being modified</param>
    /// <param name="GenJournalLine">Original general journal line for reference</param>
    /// <remarks>
    /// Raised from VoidCheck procedure before setting voided status on journal line.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeVoidCheckGenJnlLine2Modify(var GenJournalLine2: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before modifying related check ledger entries during void operation.
    /// Enables custom processing of related check entries before they are marked as voided.
    /// </summary>
    /// <param name="CheckLedgerEntry">Related check ledger entry being modified</param>
    /// <param name="VoidDate">Date when the void operation is performed</param>
    /// <remarks>
    /// Raised from MarkCheckEntriesVoid procedure when processing related check entries with same check number.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnMarkCheckEntriesVoidOnBeforeRelatedCheckLedgerEntry2Modify(var CheckLedgerEntry: Record "Check Ledger Entry"; var VoidDate: Date)
    begin
    end;

    /// <summary>
    /// Integration event raised before modifying the original check ledger entry during void operation.
    /// Enables custom field updates or validation before the original check entry is marked as voided.
    /// </summary>
    /// <param name="CheckLedgerEntry">Original check ledger entry being modified</param>
    /// <param name="VoidDate">Date when the void operation is performed</param>
    /// <remarks>
    /// Raised from MarkCheckEntriesVoid procedure before setting entry status to Financially Voided.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnMarkCheckEntriesVoidOnBeforeOriginalCheckLedgerEntryModify(var CheckLedgerEntry: Record "Check Ledger Entry"; var VoidDate: Date)
    begin
    end;

    /// <summary>
    /// Integration event raised after modifying a general journal line during check void operation.
    /// Enables custom processing or logging after journal line has been updated with void status.
    /// </summary>
    /// <param name="GenJournalLine2">General journal line that was modified</param>
    /// <param name="GenJournalLine">Original general journal line for reference</param>
    /// <remarks>
    /// Raised from VoidCheck procedure after marking journal line as voided.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnVoidCheckOnAfterGenJnlLine2Modify(var GenJournalLine2: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after setting filters on check ledger entry during void operation.
    /// Enables custom filter modification or additional processing on filtered check entries.
    /// </summary>
    /// <param name="CheckLedgerEntry">Check ledger entry with filters applied</param>
    /// <param name="GenJournalLine">General journal line context for the void operation</param>
    /// <remarks>
    /// Raised from VoidCheck procedure after filtering check ledger entries for void processing.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnVoidCheckOnAfterCheckLedgEntry2SetFilters(var CheckLedgerEntry: Record "Check Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before posting customer entries during financial void operation.
    /// Enables custom processing or validation before customer ledger entries are posted.
    /// </summary>
    /// <param name="GenJournalLine">General journal line for the void entry</param>
    /// <param name="CustLedgerEntry">Customer ledger entry being processed</param>
    /// <param name="BalanceAmountLCY">Balance amount in local currency</param>
    /// <remarks>
    /// Raised from FinancialVoidCheck procedure before posting customer-related void entries.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnBeforePostCust(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var BalanceAmountLCY: Decimal)
    begin
    end;

    /// <summary>
    /// Integration event raised before checking balance account type during financial void operation.
    /// Enables custom validation or processing based on the balance account type.
    /// </summary>
    /// <param name="GenJournalLine">General journal line for the void operation</param>
    /// <param name="CheckLedgerEntry">Check ledger entry being voided</param>
    /// <param name="BankAccountLedgerEntry">Bank account ledger entry associated with the check</param>
    /// <remarks>
    /// Raised from FinancialVoidCheck procedure before processing balance account type specific logic.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnBeforeCheckBalAccountType(var GenJournalLine: Record "Gen. Journal Line"; var CheckLedgerEntry: Record "Check Ledger Entry"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before posting bank account entries during financial void operation.
    /// Enables custom processing or validation before bank account ledger entries are posted.
    /// </summary>
    /// <param name="GenJournalLine">General journal line for the void entry</param>
    /// <param name="BankAccountLedgerEntry">Bank account ledger entry being processed</param>
    /// <remarks>
    /// Raised from FinancialVoidCheck procedure before posting bank account-related void entries.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnBeforePostBankAccount(var GenJournalLine: Record "Gen. Journal Line"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before posting fixed asset entries during financial void operation.
    /// Enables custom processing or validation before fixed asset ledger entries are posted.
    /// </summary>
    /// <param name="GenJournalLine">General journal line for the void entry</param>
    /// <param name="FALedgerEntry">Fixed asset ledger entry being processed</param>
    /// <remarks>
    /// Raised from FinancialVoidCheck procedure before posting fixed asset-related void entries.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnBeforePostFixedAsset(var GenJournalLine: Record "Gen. Journal Line"; var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before posting vendor entries during financial void operation.
    /// Enables custom processing or validation before vendor ledger entries are posted.
    /// </summary>
    /// <param name="GenJournalLine">General journal line for the void entry</param>
    /// <param name="VendorLedgerEntry">Vendor ledger entry being processed</param>
    /// <param name="BalanceAmountLCY">Balance amount in local currency</param>
    /// <remarks>
    /// Raised from FinancialVoidCheck procedure before posting vendor-related void entries.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnBeforePostVend(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var BalanceAmountLCY: Decimal)
    begin
    end;

    /// <summary>
    /// Integration event raised before posting employee entries during financial void operation.
    /// Enables custom processing or validation before employee ledger entries are posted.
    /// </summary>
    /// <param name="GenJournalLine">General journal line for the void entry</param>
    /// <param name="EmployeeLedgerEntry">Employee ledger entry being processed</param>
    /// <remarks>
    /// Raised from FinancialVoidCheck procedure before posting employee-related void entries.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnBeforePostEmp(var GenJournalLine: Record "Gen. Journal Line"; var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after posting a void check line during financial void operation.
    /// Enables custom processing or logging after void entries are posted.
    /// </summary>
    /// <param name="GenJournalLine">General journal line that was posted</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit reference</param>
    /// <remarks>
    /// Raised from FinancialVoidCheck procedure after posting each void journal line entry.
    /// 
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnAfterPostVoidCheckLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after setting filters on vendor ledger entries during financial void operation.
    /// Enables custom filter modification or additional processing on filtered vendor entries.
    /// </summary>
    /// <param name="VendorLedgEntry">Vendor ledger entry with filters applied</param>
    /// <param name="BankAccLedgEntry">Bank account ledger entry context for filtering</param>
    /// <remarks>
    /// Raised from FinancialVoidCheck procedure after filtering vendor ledger entries.
    /// 
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnAfterVendorLedgEntrySetFilters(var VendorLedgEntry: Record "Vendor Ledger Entry"; BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before posting a void check line during financial void operation.
    /// Enables custom processing or validation before void entries are posted.
    /// </summary>
    /// <param name="GenJournalLine">General journal line to be posted</param>
    /// <param name="CheckLedgEntry">Check ledger entry being voided</param>
    /// <param name="BankAccLedgEntry2">Bank account ledger entry associated with the check</param>
    /// <remarks>
    /// Raised from FinancialVoidCheck procedure before posting each void journal line entry.
    /// 
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnBeforePostVoidCheckLine(var GenJournalLine: Record "Gen. Journal Line"; var CheckLedgEntry: Record "Check Ledger Entry"; var BankAccLedgEntry2: Record "Bank Account Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after posting balance account line during financial void operation.
    /// Enables custom processing or logging after balance account entries are posted.
    /// </summary>
    /// <param name="GenJournalLine">General journal line that was posted</param>
    /// <param name="CheckLedgerEntry">Check ledger entry being voided</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit reference</param>
    /// <remarks>
    /// Raised from FinancialVoidCheck procedure after posting balance account entries.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnAfterPostBalAccLine(var GenJournalLine: Record "Gen. Journal Line"; CheckLedgerEntry: Record "Check Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before posting balance account line during financial void operation.
    /// Enables custom processing or validation before balance account entries are posted.
    /// </summary>
    /// <param name="GenJournalLine">General journal line to be posted</param>
    /// <param name="CheckLedgerEntry">Check ledger entry being voided</param>
    /// <remarks>
    /// Raised from FinancialVoidCheck procedure before posting balance account entries.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnBeforePostBalAccLine(var GenJournalLine: Record "Gen. Journal Line"; CheckLedgerEntry: Record "Check Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before processing G/L entries loop during financial void of G/L account.
    /// Enables custom processing or filtering of G/L entries before void operation.
    /// </summary>
    /// <param name="GLEntry">G/L entry with filters applied</param>
    /// <param name="CheckLedgerEntry">Check ledger entry being voided</param>
    /// <remarks>
    /// Raised from FinancialVoidPostGLAccount procedure before processing G/L entries for void.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidPostGLAccountOnBeforeGLEntryLoop(var GLEntry: Record "G/L Entry"; var CheckLedgerEntry: Record "Check Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after inserting a new check ledger entry.
    /// Enables custom processing or additional field updates after check entry creation.
    /// </summary>
    /// <param name="CheckLedgEntry">Check ledger entry that was inserted</param>
    /// <remarks>
    /// Raised from InsertCheck procedure after inserting check ledger entry into database.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnInsertCheckOnAfterCheckLedgEntryInsert(var CheckLedgEntry: Record "Check Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting a new check ledger entry.
    /// Enables custom field updates or validation before check entry creation.
    /// </summary>
    /// <param name="CheckLedgEntry">Check ledger entry to be inserted</param>
    /// <remarks>
    /// Raised from InsertCheck procedure before inserting check ledger entry into database.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnInsertCheckOnBeforeCheckLedgEntryInsert(var CheckLedgEntry: Record "Check Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after posting rounding amount entries during financial void operation.
    /// Enables custom processing or logging after currency rounding entries are posted.
    /// </summary>
    /// <param name="GenJournalLine">General journal line for the rounding entry that was posted</param>
    /// <param name="CheckLedgerEntry">Check ledger entry being voided</param>
    /// <param name="GenJnlPostLine">General journal posting codeunit reference</param>
    /// <remarks>
    /// Raised from PostRoundingAmount procedure after posting currency conversion rounding entries.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnPostRoundingAmountOnAfterGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; CheckLedgerEntry: Record "Check Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before modifying check ledger entry during electronic payment processing.
    /// Enables custom field updates or validation before electronic payment status changes.
    /// </summary>
    /// <param name="CheckLedgerEntry">Check ledger entry being modified for electronic payment</param>
    /// <param name="WhichProcess">Process type being performed (Void or Transmit)</param>
    /// <remarks>
    /// Raised from ProcessElectronicPayment procedure before updating check entry status.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnProcessElectronicPaymentOnBeforeCheckLedgEntry3Modify(var CheckLedgerEntry: Record "Check Ledger Entry"; var WhichProcess: Option)
    begin
    end;

    /// <summary>
    /// Integration event raised before posting rounding amount entries during financial void operation.
    /// Enables custom processing or validation before currency rounding entries are posted.
    /// </summary>
    /// <param name="GenJournalLine">General journal line for the rounding entry to be posted</param>
    /// <param name="CheckLedgerEntry">Check ledger entry being voided</param>
    /// <param name="BankAccountLedgerEntry">Bank account ledger entry associated with the check</param>
    /// <remarks>
    /// Raised from PostRoundingAmount procedure before posting currency conversion rounding entries.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnPostRoundingAmountOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; CheckLedgerEntry: Record "Check Ledger Entry"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before posting unapplication entries for customer invoices during void operation.
    /// Enables custom processing or validation before customer unapplication entries are posted.
    /// </summary>
    /// <param name="GenJournalLine">General journal line for the unapplication entry</param>
    /// <param name="CustLedgerEntry">Customer ledger entry being unapplied</param>
    /// <param name="DetailedCustLedgEntry">Detailed customer ledger entry for the application being reversed</param>
    /// <remarks>
    /// Raised from UnApplyCustInvoices procedure before posting customer unapplication entries.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnUnApplyCustInvoicesOnBeforePost(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before posting unapplication entries for vendor invoices during void operation.
    /// Enables custom processing or validation before vendor unapplication entries are posted.
    /// </summary>
    /// <param name="GenJournalLine">General journal line for the unapplication entry</param>
    /// <param name="VendorLedgerEntry">Vendor ledger entry being unapplied</param>
    /// <param name="DetailedVendorLedgEntry">Detailed vendor ledger entry for the application being reversed</param>
    /// <remarks>
    /// Raised from UnApplyVendInvoices procedure before posting vendor unapplication entries.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnUnApplyVendInvoicesOnBeforePost(var GenJournalLine: Record "Gen. Journal Line"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after determining if a bank payment type is electronic.
    /// Enables custom logic for identifying electronic payment types.
    /// </summary>
    /// <param name="BankPaymenType">Bank payment type being evaluated</param>
    /// <param name="IsElectronicPaymentType">Whether the payment type is electronic (can be modified by subscribers)</param>
    /// <remarks>
    /// Raised from IsElectronicBankPaymentType procedure after standard electronic payment type evaluation.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterIsElectronicBankPaymentType(BankPaymenType: Enum "Bank Payment Type"; var IsElectronicPaymentType: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after calculating remaining amount for customer entries during void operation.
    /// Enables custom processing or adjustments after remaining amount calculation for customer ledger entries.
    /// </summary>
    /// <param name="CustLedgerEntry">Customer ledger entry with calculated remaining amount</param>
    /// <remarks>
    /// Raised from UnApplyCustInvoices procedure after calculating remaining amount for customer entries.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnUnApplyCustInvoicesOnAfterCalcRemainingAmount(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after calculating remaining amount for vendor entries during void operation.
    /// Enables custom processing or adjustments after remaining amount calculation for vendor ledger entries.
    /// </summary>
    /// <param name="VendorLedgerEntry">Vendor ledger entry with calculated remaining amount</param>
    /// <remarks>
    /// Raised from UnApplyVendInvoices procedure after calculating remaining amount for vendor entries.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnUnApplyVendInvoicesOnAfterCalcRemainingAmount(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before showing error for missing applied entries during vendor invoice unapplication.
    /// Enables custom error handling or alternative processing when no applied entries are found.
    /// </summary>
    /// <param name="BankAccLedgEntry">Bank account ledger entry context</param>
    /// <param name="GenJnlLine">General journal line context</param>
    /// <param name="IsHandled">Set to true to skip standard error handling</param>
    /// <remarks>
    /// Raised from UnApplyVendInvoices procedure when no applied entries are found for unapplication.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnUnApplyVendInvoicesOnBeforeErrorNoAppliedEntry(var BankAccLedgEntry: Record "Bank Account Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Integration event raised before setting general journal line fields during check operations.
    /// Enables custom field updates or validation before journal line field assignment.
    /// </summary>
    /// <param name="GenJnlLine">General journal line being updated</param>
    /// <param name="IsHandled">Set to true to skip standard field setting logic</param>
    /// <remarks>
    /// Raised from SetGenJnlLine procedure before setting standard journal line fields.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Integration event raised after setting general journal line fields during check operations.
    /// Enables custom field updates or additional processing after journal line field assignment.
    /// </summary>
    /// <param name="GenJnlLine">General journal line that was updated</param>
    /// <remarks>
    /// Raised from SetGenJnlLine procedure after setting standard journal line fields.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetGenJnlLine(var GenJnlLine: Record "Gen. Journal Line");
    begin
    end;

    /// <summary>
    /// Integration event raised before starting vendor invoice unapplication during void operation.
    /// Enables custom logic for handling vendor invoice unapplication or skipping standard processing.
    /// </summary>
    /// <param name="CheckLedgEntry">Check ledger entry being processed for void</param>
    /// <param name="VoidDate">Date when the void operation is performed</param>
    /// <param name="IsHandled">Set to true to skip standard vendor unapplication logic</param>
    /// <param name="Result">Result of the unapplication operation (can be set by subscribers)</param>
    /// <remarks>
    /// Raised from UnApplyVendInvoices procedure before performing vendor invoice unapplication.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUnApplyVendInvoices(var CheckLedgEntry: Record "Check Ledger Entry"; var VoidDate: Date; var IsHandled: Boolean; var Result: Boolean);
    begin
    end;

    /// <summary>
    /// Integration event raised before confirming financial void operation on a check.
    /// Enables custom confirmation dialog or validation before financial void confirmation.
    /// </summary>
    /// <param name="CheckLedgEntry">Check ledger entry being considered for financial void</param>
    /// <param name="IsHandled">Set to true to skip standard confirmation dialog</param>
    /// <remarks>
    /// Raised from FinancialVoidCheck procedure before showing confirmation dialog to user.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnFinancialVoidCheckOnBeforeConfirmFinancialVoid(var CheckLedgEntry: Record "Check Ledger Entry"; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Integration event raised before posting rounding amount during financial void operation.
    /// Enables custom processing or validation before currency rounding entries are posted.
    /// </summary>
    /// <param name="BankAcc">Bank account for the check being voided</param>
    /// <param name="CheckLedgEntry">Check ledger entry being voided</param>
    /// <param name="BankAccLedgEntry2">Bank account ledger entry associated with the check</param>
    /// <param name="PostingDate">Date when the rounding entry will be posted</param>
    /// <param name="RoundingAmount">Currency rounding amount to be posted</param>
    /// <param name="IsHandled">Set to true to skip standard rounding amount posting</param>
    /// <remarks>
    /// Raised from PostRoundingAmount procedure before posting currency conversion rounding entries.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostRoundingAmount(var BankAcc: Record "Bank Account"; var CheckLedgEntry: Record "Check Ledger Entry"; BankAccLedgEntry2: Record "Bank Account Ledger Entry"; var PostingDate: Date; var RoundingAmount: Decimal; var IsHandled: Boolean)
    begin
    end;
}
