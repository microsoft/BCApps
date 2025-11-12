// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reversal;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Statement;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Security.User;
using System.Utilities;

table 179 "Reversal Entry"
{
    Caption = 'Reversal Entry';
    PasteIsValid = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Entry Type"; Enum "Reversal Entry Type")
        {
            Caption = 'Entry Type';
        }
        field(3; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            TableRelation = if ("Entry Type" = const("G/L Account")) "G/L Entry"
            else
            if ("Entry Type" = const(Customer)) "Cust. Ledger Entry"
            else
            if ("Entry Type" = const(Vendor)) "Vendor Ledger Entry"
            else
            if ("Entry Type" = const("Bank Account")) "Bank Account Ledger Entry"
            else
            if ("Entry Type" = const("Fixed Asset")) "FA Ledger Entry"
            else
            if ("Entry Type" = const(Maintenance)) "Maintenance Ledger Entry"
            else
            if ("Entry Type" = const(VAT)) "VAT Entry"
            else
            if ("Entry Type" = const(Employee)) "Employee Ledger Entry";
        }
        field(4; "G/L Register No."; Integer)
        {
            Caption = 'G/L Register No.';
            TableRelation = "G/L Register";
        }
        field(5; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(6; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(7; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(8; "Source Type"; Enum "Gen. Journal Source Type")
        {
            Caption = 'Source Type';
        }
        field(9; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const("Bank Account")) "Bank Account"
            else
            if ("Source Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Source Type" = const(Employee)) Employee;
        }
        field(10; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(12; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(13; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Debit Amount';
        }
        field(14; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Credit Amount';
        }
        field(15; "Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(16; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Debit Amount (LCY)';
        }
        field(17; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Credit Amount (LCY)';
        }
        field(18; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Amount';
        }
        field(19; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(20; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(21; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(22; "Account No."; Code[20])
        {
            Caption = 'Account No.';
        }
        field(23; "Account Name"; Text[100])
        {
            Caption = 'Account Name';
        }
        field(25; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(26; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const(Customer)) Customer
            else
            if ("Bal. Account Type" = const(Vendor)) Vendor
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Bal. Account Type" = const("Fixed Asset")) "Fixed Asset";
        }
        field(27; "FA Posting Category"; Enum "FA Ledger Posting Category")
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Posting Category';
        }
        field(28; "FA Posting Type"; Enum "Reversal Entry FA Posting Type")
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Posting Type';
        }
        field(30; "Reversal Type"; Option)
        {
            Caption = 'Reversal Type';
            OptionCaption = 'Transaction,Register';
            OptionMembers = Transaction,Register;
        }
        field(31; "Source Currency Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Source Currency Code";
            AutoFormatType = 1;
            Caption = 'Source Currency Amount';
            DataClassification = CustomerContent;
        }
        field(32; "Source Currency VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Source Currency Code";
            AutoFormatType = 1;
            Caption = 'Source Currency VAT Amount';
            DataClassification = CustomerContent;
        }
        field(33; "Source Currency Code"; Code[10])
        {
            Caption = 'Source Currency Code';
            TableRelation = Currency;
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Entry Type")
        {
        }
        key(Key3; "Document No.", "Posting Date", "Entry Type", "Entry No.")
        {
        }
        key(Key4; "Entry Type", "Entry No.")
        {
        }
        key(Key5; "Transaction No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
        GlobalGLEntry: Record "G/L Entry";
        GlobalCustLedgerEntry: Record "Cust. Ledger Entry";
        GlobalVendorLedgerEntry: Record "Vendor Ledger Entry";
        GlobalEmployeeLedgerEntry: Record "Employee Ledger Entry";
        GlobalBankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccountStatement: Record "Bank Account Statement";
        GlobalVATEntry: Record "VAT Entry";
        GlobalFALedgerEntry: Record "FA Ledger Entry";
        GlobalMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        GlobalGLRegister: Record "G/L Register";
        GlobalFARegister: Record "FA Register";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        JnlTemplName: Code[10];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot reverse %1 No. %2 because the entry is either applied to an entry or has been changed by a batch job.';
        Text001: Label 'You cannot reverse %1 No. %2 because the posting date is not within the allowed posting period.';
#pragma warning restore AA0470
        Text002: Label 'You cannot reverse the transaction because it is out of balance.';
#pragma warning disable AA0470
        Text003: Label 'You cannot reverse %1 No. %2 because the entry has a related check ledger entry.';
#pragma warning restore AA0470
        Text004: Label 'You can only reverse entries that were posted from a journal.';
#pragma warning disable AA0470
        Text005: Label 'You cannot reverse %1 No. %2 because the %3 is not within the allowed posting period.';
        Text006: Label 'You cannot reverse %1 No. %2 because the entry is closed.';
        Text007: Label 'You cannot reverse %1 No. %2 because the entry is included in a bank account reconciliation line. The bank reconciliation has not yet been posted.';
        Text008: Label 'You cannot reverse the transaction because the %1 has been sold.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CannotReverseDeletedErr: Label 'The transaction cannot be reversed, because the %1 has been compressed or a %2 has been deleted.', Comment = '%1 and %2 = table captions';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text010: Label 'You cannot reverse %1 No. %2 because the register has already been involved in a reversal.';
        Text011: Label 'You cannot reverse %1 No. %2 because the entry has already been involved in a reversal.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PostedAndAppliedSameTransactionErr: Label 'You cannot reverse register number %1 because it contains customer or vendor or employee ledger entries that have been posted and applied in the same transaction.\\You must reverse each transaction in register number %1 separately.', Comment = '%1="G/L Register No."';
        CaptionTxt: Label '%1 %2 %3', Locked = true;
        ReversalWithACYErr: Label 'Due to how Business Central posts and updates amounts in an additional reporting currency (ACY), you can''t use this feature if you use ACY. Business Central converts amounts in local currency to the alternate currency, but doesn''t net transactions. If you use ACY, you must manually reverse the amounts.';

    protected var
        GLSetup: Record "General Ledger Setup";
        TempReversalEntry: Record "Reversal Entry" temporary;
        AllowPostingFrom: Date;
        AllowPostingto: Date;
        HideDialog: Boolean;
        HideWarningDialogs: Boolean;
        MaxPostingDate: Date;

    procedure ReverseTransaction(TransactionNo: Integer)
    begin
        ReverseEntries(TransactionNo, "Reversal Type"::Transaction);
    end;

    procedure ReverseRegister(RegisterNo: Integer)
    begin
        CheckRegister(RegisterNo);
        ReverseEntries(RegisterNo, "Reversal Type"::Register);
    end;

    local procedure ReverseEntries(Number: Integer; RevType: Option Transaction,Register)
    var
        ReversalPost: Codeunit "Reversal-Post";
        ReverseTransactionEntries: Page "Reverse Transaction Entries";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReverseEntries(Number, RevType, IsHandled, HideDialog, Rec, HideWarningDialogs);
        if IsHandled then
            exit;

        InsertReversalEntry(Number, RevType);
        OnReverseEntriesOnAfterInsertReversalEntry(TempReversalEntry, Number, RevType);
        TempReversalEntry.SetCurrentKey("Document No.", "Posting Date", "Entry Type", "Entry No.");
        if not HideDialog then begin
            if (BankAccountStatement."Statement No." <> '') and (BankAccountStatement."Bank Account No." <> '') then
                ReverseTransactionEntries.SetBankAccountStatement(BankAccountStatement);
            ReverseTransactionEntries.SetReversalEntries(TempReversalEntry);
            ReverseTransactionEntries.RunModal();
        end
        else begin
            ReversalPost.SetPrint(false);
            ReversalPost.SetHideDialog(HideWarningDialogs);
            ReversalPost.Run(TempReversalEntry);
        end;
        TempReversalEntry.DeleteAll();

        OnAfterReverseEntries(Number, RevType, HideDialog);
    end;

    protected procedure InsertReversalEntry(Number: Integer; RevType: Option Transaction,Register)
    var
        TempTransactionNoInteger: Record "Integer" temporary;
        NextLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertReversalEntry(Rec, Number, RevType, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();
        TempReversalEntry.DeleteAll();
        NextLineNo := 1;
        TempTransactionNoInteger.Number := Number;
        TempTransactionNoInteger.Insert();
        SetReverseFilter(Number, RevType);

        InsertFromCustLedgEntry(TempTransactionNoInteger, Number, RevType, NextLineNo);
        InsertFromVendLedgEntry(TempTransactionNoInteger, Number, RevType, NextLineNo);
        InsertFromEmplLedgerEntry(TempTransactionNoInteger, Number, RevType, NextLineNo);
        InsertFromBankAccLedgEntry(TempTransactionNoInteger, Number, RevType, NextLineNo);
        InsertFromFALedgEntry(TempTransactionNoInteger, Number, RevType, NextLineNo);
        InsertFromMaintenanceLedgEntry(TempTransactionNoInteger, Number, RevType, NextLineNo);
        InsertFromVATEntry(TempTransactionNoInteger, Number, RevType, NextLineNo);
        InsertFromGLEntry(TempTransactionNoInteger, Number, RevType, NextLineNo);
        OnAfterInsertReversalEntry(TempTransactionNoInteger, Number, RevType, NextLineNo, TempReversalEntry);
        if TempReversalEntry.Find('-') then;
    end;

    procedure CheckEntries()
    var
        GLAccount: Record "G/L Account";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
        DateComprRegister: Record "Date Compr. Register";
        BalanceCheckAmount: Decimal;
        BalanceCheckAddCurrAmount: Decimal;
        SkipCheck: Boolean;
    begin
        DetailedCustLedgEntry.LockTable();
        DetailedVendorLedgEntry.LockTable();
        DetailedEmployeeLedgerEntry.LockTable();
        GlobalGLEntry.LockTable();
        GlobalCustLedgerEntry.LockTable();
        GlobalVendorLedgerEntry.LockTable();
        GlobalEmployeeLedgerEntry.LockTable();
        GlobalBankAccountLedgerEntry.LockTable();
        GlobalFALedgerEntry.LockTable();
        GlobalMaintenanceLedgerEntry.LockTable();
        GlobalVATEntry.LockTable();
        GlobalGLRegister.LockTable();
        GlobalFARegister.LockTable();
        GLSetup.Get();
        MaxPostingDate := 0D;

        SkipCheck := false;
        OnBeforeCheckEntries(Rec, DATABASE::"G/L Entry", SkipCheck);
        if not SkipCheck then begin
            if GlobalGLEntry.IsEmpty() then
                Error(CannotReverseDeletedErr, GlobalGLEntry.TableCaption(), GLAccount.TableCaption());
            if GlobalGLEntry.Find('-') then begin
                CheckGLEntry();
                repeat
                    CheckGLAcc(GlobalGLEntry, BalanceCheckAmount, BalanceCheckAddCurrAmount);
                until GlobalGLEntry.Next() = 0;
            end;
            if (BalanceCheckAmount <> 0) or (BalanceCheckAddCurrAmount <> 0) then
                Error(Text002);
        end;

        if GlobalCustLedgerEntry.Find('-') then begin
            SkipCheck := false;
            OnBeforeCheckEntries(Rec, DATABASE::"Cust. Ledger Entry", SkipCheck);
            if not SkipCheck then
                repeat
                    CheckCust(GlobalCustLedgerEntry);
                until GlobalCustLedgerEntry.Next() = 0;
        end;

        if GlobalVendorLedgerEntry.Find('-') then begin
            SkipCheck := false;
            OnBeforeCheckEntries(Rec, DATABASE::"Vendor Ledger Entry", SkipCheck);
            if not SkipCheck then
                repeat
                    CheckVend(GlobalVendorLedgerEntry);
                until GlobalVendorLedgerEntry.Next() = 0;
        end;

        if GlobalEmployeeLedgerEntry.FindSet() then begin
            SkipCheck := false;
            OnBeforeCheckEntries(Rec, DATABASE::"Employee Ledger Entry", SkipCheck);
            if not SkipCheck then
                repeat
                    CheckEmpl(GlobalEmployeeLedgerEntry);
                until GlobalEmployeeLedgerEntry.Next() = 0;
        end;

        if GlobalBankAccountLedgerEntry.Find('-') then begin
            SkipCheck := false;
            OnBeforeCheckEntries(Rec, DATABASE::"Bank Account Ledger Entry", SkipCheck);
            if not SkipCheck then
                repeat
                    CheckBankAcc(GlobalBankAccountLedgerEntry);
                until GlobalBankAccountLedgerEntry.Next() = 0;
        end;

        if GlobalFALedgerEntry.Find('-') then begin
            SkipCheck := false;
            OnBeforeCheckEntries(Rec, DATABASE::"FA Ledger Entry", SkipCheck);
            if not SkipCheck then
                repeat
                    CheckFA(GlobalFALedgerEntry);
                until GlobalFALedgerEntry.Next() = 0;
        end;

        if GlobalMaintenanceLedgerEntry.Find('-') then begin
            SkipCheck := false;
            OnBeforeCheckEntries(Rec, DATABASE::"Maintenance Ledger Entry", SkipCheck);
            if not SkipCheck then
                repeat
                    CheckMaintenance(GlobalMaintenanceLedgerEntry);
                until GlobalMaintenanceLedgerEntry.Next() = 0;
        end;

        if GlobalVATEntry.Find('-') then begin
            SkipCheck := false;
            OnBeforeCheckEntries(Rec, DATABASE::"VAT Entry", SkipCheck);
            if not SkipCheck then
                repeat
                    CheckVAT(GlobalVATEntry);
                until GlobalVATEntry.Next() = 0;
        end;

        OnAfterCheckEntries(MaxPostingDate, Rec);

        DateComprRegister.CheckMaxDateCompressed(MaxPostingDate, 1);
    end;

    local procedure CheckGLEntry()
    var
        SourceCodeSetup: Record "Source Code Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLEntry(Rec, GlobalGLEntry, IsHandled);
        if IsHandled then
            exit;

        if GlobalGLEntry."Journal Batch Name" <> '' then
            exit;

        SourceCodeSetup.Get();
        if GlobalGLEntry."Source Code" = SourceCodeSetup."Payment Reconciliation Journal" then
            exit;

        if GlobalGLEntry."Source Code" = SourceCodeSetup."Trans. Bank Rec. to Gen. Jnl." then
            exit;

        TestFieldError();
    end;

    local procedure CheckGLAcc(GLEntry: Record "G/L Entry"; var BalanceCheckAmount: Decimal; var BalanceCheckAddCurrAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
        IsHandled: Boolean;
    begin
        OnBeforeCheckGLAcc(GLEntry);

        GLAccount.Get(GLEntry."G/L Account No.");
        JnlTemplName := GLEntry."Journal Templ. Name";
        CheckPostingDate(GLEntry."Posting Date", GLEntry.TableCaption(), GLEntry."Entry No.");
        IsHandled := false;
        OnCheckGLAccOnBeforeTestFields(GLAccount, GLEntry, IsHandled);
        if not IsHandled then begin
            GLAccount.TestField(Blocked, false);
            GLEntry.TestField("Job No.", '');
        end;
        if GLEntry.Reversed then
            AlreadyReversedEntry(GLEntry.TableCaption(), GLEntry."Entry No.");
        BalanceCheckAmount := BalanceCheckAmount + GLEntry.Amount;
        if GLSetup."Additional Reporting Currency" <> '' then
            BalanceCheckAddCurrAmount := BalanceCheckAddCurrAmount + GLEntry."Additional-Currency Amount";

        OnAfterCheckGLAcc(GLAccount, GLEntry);
    end;

    local procedure CheckCust(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        Customer: Record Customer;
    begin
        OnBeforeCheckCust(CustLedgerEntry);

        Customer.Get(CustLedgerEntry."Customer No.");
        JnlTemplName := CustLedgerEntry."Journal Templ. Name";
        CheckPostingDate(CustLedgerEntry."Posting Date", CustLedgerEntry.TableCaption(), CustLedgerEntry."Entry No.");
        Customer.CheckBlockedCustOnJnls(Customer, CustLedgerEntry."Document Type", false);
        if CustLedgerEntry.Reversed then
            AlreadyReversedEntry(CustLedgerEntry.TableCaption(), CustLedgerEntry."Entry No.");
        CheckDtldCustLedgEntry(CustLedgerEntry);

        OnAfterCheckCust(Customer, CustLedgerEntry);
    end;

    local procedure CheckVend(VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        Vendor: Record Vendor;
    begin
        OnBeforeCheckVend(VendorLedgerEntry);

        Vendor.Get(VendorLedgerEntry."Vendor No.");
        JnlTemplName := VendorLedgerEntry."Journal Templ. Name";
        CheckPostingDate(VendorLedgerEntry."Posting Date", VendorLedgerEntry.TableCaption(), VendorLedgerEntry."Entry No.");
        Vendor.CheckBlockedVendOnJnls(Vendor, VendorLedgerEntry."Document Type", false);
        if VendorLedgerEntry.Reversed then
            AlreadyReversedEntry(VendorLedgerEntry.TableCaption(), VendorLedgerEntry."Entry No.");
        CheckDtldVendLedgEntry(VendorLedgerEntry);

        OnAfterCheckVend(Vendor, VendorLedgerEntry);
    end;

    local procedure CheckEmpl(EmployeeLedgerEntry2: Record "Employee Ledger Entry")
    var
        Employee: Record Employee;
    begin
        OnBeforeCheckEmpl(EmployeeLedgerEntry2);
        Employee.Get(EmployeeLedgerEntry2."Employee No.");
        JnlTemplName := EmployeeLedgerEntry2."Journal Templ. Name";
        CheckPostingDate(EmployeeLedgerEntry2."Posting Date", EmployeeLedgerEntry2.TableCaption(), EmployeeLedgerEntry2."Entry No.");
        Employee.CheckBlockedEmployeeOnJnls(false);
        if EmployeeLedgerEntry2.Reversed then
            AlreadyReversedEntry(EmployeeLedgerEntry2.TableCaption(), EmployeeLedgerEntry2."Entry No.");
        CheckDtldEmplLedgEntry(EmployeeLedgerEntry2);

        OnAfterCheckEmpl(Employee, EmployeeLedgerEntry2);
    end;

    local procedure CheckBankAcc(BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    var
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBankAcc(BankAccountLedgerEntry, IsHandled);
        if IsHandled then
            exit;

        BankAccount.Get(BankAccountLedgerEntry."Bank Account No.");
        JnlTemplName := BankAccountLedgerEntry."Journal Templ. Name";
        CheckPostingDate(BankAccountLedgerEntry."Posting Date", BankAccountLedgerEntry.TableCaption(), BankAccountLedgerEntry."Entry No.");
        BankAccount.TestField(Blocked, false);
        if BankAccountLedgerEntry.Reversed then
            AlreadyReversedEntry(BankAccountLedgerEntry.TableCaption(), BankAccountLedgerEntry."Entry No.");
        if not BankAccountLedgerEntry.Open then
            Error(
              Text006, BankAccountLedgerEntry.TableCaption(), BankAccountLedgerEntry."Entry No.");
        if BankAccountLedgerEntry."Statement No." <> '' then
            Error(
              Text007, BankAccountLedgerEntry.TableCaption(), BankAccountLedgerEntry."Entry No.");
        CheckLedgerEntry.SetRange("Bank Account Ledger Entry No.", BankAccountLedgerEntry."Entry No.");
        if not CheckLedgerEntry.IsEmpty() then
            Error(
              Text003, BankAccountLedgerEntry.TableCaption(), BankAccountLedgerEntry."Entry No.");

        OnAfterCheckBankAcc(BankAccount, BankAccountLedgerEntry);
    end;

    local procedure CheckFA(FALedgerEntry: Record "FA Ledger Entry")
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationCalculation: Codeunit "Depreciation Calculation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckFA(FALedgerEntry, IsHandled);
        if IsHandled then
            exit;

        FixedAsset.Get(FALedgerEntry."FA No.");
        CheckPostingDate(FALedgerEntry."Posting Date", FALedgerEntry.TableCaption(), FALedgerEntry."Entry No.");
        CheckFAPostingDate(FALedgerEntry."FA Posting Date", FALedgerEntry.TableCaption(), FALedgerEntry."Entry No.");
        FixedAsset.TestField(Blocked, false);
        FixedAsset.TestField(Inactive, false);
        if FALedgerEntry.Reversed then
            AlreadyReversedEntry(FALedgerEntry.TableCaption(), FALedgerEntry."Entry No.");
        FALedgerEntry.TestField("Depreciation Book Code");
        FADepreciationBook.Get(FixedAsset."No.", FALedgerEntry."Depreciation Book Code");
        if FADepreciationBook."Disposal Date" <> 0D then
            Error(Text008, DepreciationCalculation.FAName(FixedAsset, FALedgerEntry."Depreciation Book Code"));
        FALedgerEntry.TestField("G/L Entry No.");

        OnAfterCheckFA(FixedAsset, FALedgerEntry);
    end;

    local procedure CheckMaintenance(MaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        OnBeforeCheckMaintenance(MaintenanceLedgerEntry);
        FixedAsset.Get(MaintenanceLedgerEntry."FA No.");
        CheckPostingDate(MaintenanceLedgerEntry."Posting Date", MaintenanceLedgerEntry.TableCaption(), MaintenanceLedgerEntry."Entry No.");
        CheckFAPostingDate(MaintenanceLedgerEntry."FA Posting Date", MaintenanceLedgerEntry.TableCaption(), MaintenanceLedgerEntry."Entry No.");
        FixedAsset.TestField(Blocked, false);
        FixedAsset.TestField(Inactive, false);
        MaintenanceLedgerEntry.TestField("Depreciation Book Code");
        if MaintenanceLedgerEntry.Reversed then
            AlreadyReversedEntry(MaintenanceLedgerEntry.TableCaption(), MaintenanceLedgerEntry."Entry No.");
        FADepreciationBook.Get(FixedAsset."No.", MaintenanceLedgerEntry."Depreciation Book Code");
        MaintenanceLedgerEntry.TestField("G/L Entry No.");

        OnAfterCheckMaintenance(FixedAsset, MaintenanceLedgerEntry);
    end;

    local procedure CheckVAT(VATEntry: Record "VAT Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckVAT(VATEntry, IsHandled);
        if IsHandled then
            exit;

        JnlTemplName := VATEntry."Journal Templ. Name";
        CheckPostingDate(VATEntry."Posting Date", VATEntry.TableCaption(), VATEntry."Entry No.");
        if VATEntry.Closed then
            Error(
              Text006, VATEntry.TableCaption(), VATEntry."Entry No.");
        if VATEntry.Reversed then
            AlreadyReversedEntry(VATEntry.TableCaption(), VATEntry."Entry No.");

        OnAfterCheckVAT(VATEntry);
    end;

    local procedure CheckDtldCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDtldCustLedgEntry(CustLedgerEntry, IsHandled);
        if IsHandled then
            exit;

        DetailedCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.SetFilter("Entry Type", '<>%1', DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        DetailedCustLedgEntry.SetRange(Unapplied, false);
        if not DetailedCustLedgEntry.IsEmpty() then
            Error(ReversalErrorForChangedEntry(CustLedgerEntry.TableCaption(), CustLedgerEntry."Entry No."));

        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" <> '' then begin
            DetailedCustLedgEntry.Reset();
            DetailedCustLedgEntry.SetCurrentKey("Transaction No.", "Customer No.", "Entry Type");
            DetailedCustLedgEntry.SetRange("Transaction No.", CustLedgerEntry."Transaction No.");
            DetailedCustLedgEntry.SetRange("Customer No.", CustLedgerEntry."Customer No.");
            DetailedCustLedgEntry.SetFilter("Entry Type", '%1|%2',
              DetailedCustLedgEntry."Entry Type"::"Realized Gain", DetailedCustLedgEntry."Entry Type"::"Realized Loss");
            if not DetailedCustLedgEntry.IsEmpty() then
                Error(ReversalWithACYErr);
        end;

        OnAfterCheckDtldCustLedgEntry(DetailedCustLedgEntry, CustLedgerEntry);
    end;

    local procedure CheckDtldVendLedgEntry(VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCCheckDtldVendLedgEntry(VendorLedgerEntry, IsHandled);
        if IsHandled then
            exit;

        DetailedVendorLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type");
        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        DetailedVendorLedgEntry.SetFilter("Entry Type", '<>%1', DetailedVendorLedgEntry."Entry Type"::"Initial Entry");
        DetailedVendorLedgEntry.SetRange(Unapplied, false);
        if not DetailedVendorLedgEntry.IsEmpty() then
            Error(ReversalErrorForChangedEntry(VendorLedgerEntry.TableCaption(), VendorLedgerEntry."Entry No."));

        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" <> '' then begin
            DetailedVendorLedgEntry.Reset();
            DetailedVendorLedgEntry.SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
            DetailedVendorLedgEntry.SetRange("Transaction No.", VendorLedgerEntry."Transaction No.");
            DetailedVendorLedgEntry.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
            DetailedVendorLedgEntry.SetFilter("Entry Type", '%1|%2',
              DetailedVendorLedgEntry."Entry Type"::"Realized Gain", DetailedVendorLedgEntry."Entry Type"::"Realized Loss");
            if not DetailedVendorLedgEntry.IsEmpty() then
                Error(ReversalWithACYErr);
        end;
        OnAfterCheckDtldVendLedgEntry(DetailedVendorLedgEntry, VendorLedgerEntry);
    end;

    local procedure CheckDtldEmplLedgEntry(EmployeeLedgerEntry2: Record "Employee Ledger Entry")
    var
        DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
    begin
        DetailedEmployeeLedgerEntry.SetRange("Employee Ledger Entry No.", EmployeeLedgerEntry2."Entry No.");
        DetailedEmployeeLedgerEntry.SetFilter("Entry Type", '<>%1', DetailedEmployeeLedgerEntry."Entry Type"::"Initial Entry");
        DetailedEmployeeLedgerEntry.SetRange(Unapplied, false);
        if not DetailedEmployeeLedgerEntry.IsEmpty() then
            Error(ReversalErrorForChangedEntry(EmployeeLedgerEntry2.TableCaption(), EmployeeLedgerEntry2."Entry No."));

        OnAfterCheckDtldEmplLedgEntry(DetailedEmployeeLedgerEntry, EmployeeLedgerEntry2);
    end;

    local procedure CheckRegister(RegisterNo: Integer)
    var
        GLRegister: Record "G/L Register";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRegister(RegisterNo, IsHandled, Rec);
        if IsHandled then
            exit;

        GLRegister.Get(RegisterNo);
        if GLRegister.Reversed then
            Error(Text010, GLRegister.TableCaption(), GLRegister."No.");
        if GLRegister."Journal Batch Name" = '' then
            TempReversalEntry.TestFieldError();
    end;

    procedure SetReverseFilter(Number: Integer; RevType: Option Transaction,Register)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetReverseFilter(Number, RevType, GlobalGLEntry, GlobalCustLedgerEntry, GlobalVendorLedgerEntry, GlobalEmployeeLedgerEntry, GlobalBankAccountLedgerEntry, GlobalVATEntry, GlobalFALedgerEntry, GlobalMaintenanceLedgerEntry, GlobalGLRegister, Rec, IsHandled);
        if IsHandled then
            exit;

        if RevType = RevType::Transaction then begin
            GlobalGLEntry.SetCurrentKey("Transaction No.");
            GlobalCustLedgerEntry.SetCurrentKey("Transaction No.");
            GlobalVendorLedgerEntry.SetCurrentKey("Transaction No.");
            GlobalEmployeeLedgerEntry.SetCurrentKey("Transaction No.");
            GlobalBankAccountLedgerEntry.SetCurrentKey("Transaction No.");
            GlobalFALedgerEntry.SetCurrentKey("Transaction No.");
            GlobalMaintenanceLedgerEntry.SetCurrentKey("Transaction No.");
            GlobalVATEntry.SetCurrentKey("Transaction No.");
            GlobalGLEntry.SetRange("Transaction No.", Number);
            GlobalCustLedgerEntry.SetRange("Transaction No.", Number);
            GlobalVendorLedgerEntry.SetRange("Transaction No.", Number);
            GlobalEmployeeLedgerEntry.SetRange("Transaction No.", Number);
            GlobalBankAccountLedgerEntry.SetRange("Transaction No.", Number);
            GlobalFALedgerEntry.SetRange("Transaction No.", Number);
            GlobalFALedgerEntry.SetFilter("G/L Entry No.", '<>%1', 0);
            GlobalMaintenanceLedgerEntry.SetRange("Transaction No.", Number);
            GlobalVATEntry.SetRange("Transaction No.", Number);
        end else begin
            GlobalGLRegister.Get(Number);
            GlobalGLEntry.SetRange("Entry No.", GlobalGLRegister."From Entry No.", GlobalGLRegister."To Entry No.");
            GlobalCustLedgerEntry.SetRange("Entry No.", GlobalGLRegister."From Entry No.", GlobalGLRegister."To Entry No.");
            GlobalVendorLedgerEntry.SetRange("Entry No.", GlobalGLRegister."From Entry No.", GlobalGLRegister."To Entry No.");
            GlobalEmployeeLedgerEntry.SetRange("Entry No.", GlobalGLRegister."From Entry No.", GlobalGLRegister."To Entry No.");
            GlobalBankAccountLedgerEntry.SetRange("Entry No.", GlobalGLRegister."From Entry No.", GlobalGLRegister."To Entry No.");
            GlobalFALedgerEntry.SetCurrentKey("G/L Entry No.");
            GlobalFALedgerEntry.SetRange("G/L Entry No.", GlobalGLRegister."From Entry No.", GlobalGLRegister."To Entry No.");
            GlobalMaintenanceLedgerEntry.SetCurrentKey("G/L Entry No.");
            GlobalMaintenanceLedgerEntry.SetRange("G/L Entry No.", GlobalGLRegister."From Entry No.", GlobalGLRegister."To Entry No.");
            GlobalVATEntry.SetRange("Entry No.", GlobalGLRegister."From VAT Entry No.", GlobalGLRegister."To VAT Entry No.");
        end;

        OnAfterSetReverseFilter(Number, RevType, GlobalGLRegister, Rec);
    end;

    procedure CopyReverseFilters(var GLEntry: Record "G/L Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var VATEntry: Record "VAT Entry"; var FALedgerEntry: Record "FA Ledger Entry"; var MaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        GLEntry.Copy(GlobalGLEntry);
        CustLedgerEntry.Copy(GlobalCustLedgerEntry);
        VendorLedgerEntry.Copy(GlobalVendorLedgerEntry);
        EmployeeLedgerEntry.Copy(GlobalEmployeeLedgerEntry);
        BankAccountLedgerEntry.Copy(GlobalBankAccountLedgerEntry);
        VATEntry.Copy(GlobalVATEntry);
        FALedgerEntry.Copy(GlobalFALedgerEntry);
        MaintenanceLedgerEntry.Copy(GlobalMaintenanceLedgerEntry);
    end;

    procedure ShowGLEntries()
    begin
        PAGE.Run(0, GlobalGLEntry);
    end;

    procedure ShowCustLedgEntries()
    begin
        PAGE.Run(0, GlobalCustLedgerEntry);
    end;

    procedure ShowVendLedgEntries()
    begin
        PAGE.Run(0, GlobalVendorLedgerEntry);
    end;

    procedure ShowBankAccLedgEntries()
    begin
        PAGE.Run(0, GlobalBankAccountLedgerEntry);
    end;

    procedure ShowFALedgEntries()
    begin
        PAGE.Run(0, GlobalFALedgerEntry);
    end;

    procedure ShowMaintenanceLedgEntries()
    begin
        PAGE.Run(0, GlobalMaintenanceLedgerEntry);
    end;

    procedure ShowVATEntries()
    begin
        PAGE.Run(0, GlobalVATEntry);
    end;

    procedure Caption() Result: Text
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
        BankAccount: Record "Bank Account";
        FixedAsset: Record "Fixed Asset";
        NewCaption: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCaption(Rec, Result, IsHandled);
        if IsHandled then
            exit;

        case "Entry Type" of
            "Entry Type"::"G/L Account":
                begin
                    if GlobalGLEntry.Get("Entry No.") then;
                    if GLAccount.Get(GlobalGLEntry."G/L Account No.") then;
                    exit(StrSubstNo(CaptionTxt, GLAccount.TableCaption(), GLAccount."No.", GLAccount.Name));
                end;
            "Entry Type"::Customer:
                begin
                    if GlobalCustLedgerEntry.Get("Entry No.") then;
                    if Customer.Get(GlobalCustLedgerEntry."Customer No.") then;
                    exit(StrSubstNo(CaptionTxt, Customer.TableCaption(), Customer."No.", Customer.Name));
                end;
            "Entry Type"::Vendor:
                begin
                    if GlobalVendorLedgerEntry.Get("Entry No.") then;
                    if Vendor.Get(GlobalVendorLedgerEntry."Vendor No.") then;
                    exit(StrSubstNo(CaptionTxt, Vendor.TableCaption(), Vendor."No.", Vendor.Name));
                end;
            "Entry Type"::Employee:
                begin
                    if GlobalEmployeeLedgerEntry.Get("Entry No.") then;
                    if Employee.Get(GlobalEmployeeLedgerEntry."Employee No.") then;
                    exit(StrSubstNo(CaptionTxt, Employee.TableCaption(), Employee."No.", Employee.FullName()));
                end;
            "Entry Type"::"Bank Account":
                begin
                    if GlobalBankAccountLedgerEntry.Get("Entry No.") then;
                    if BankAccount.Get(GlobalBankAccountLedgerEntry."Bank Account No.") then;
                    exit(StrSubstNo(CaptionTxt, BankAccount.TableCaption(), BankAccount."No.", BankAccount.Name));
                end;
            "Entry Type"::"Fixed Asset":
                begin
                    if GlobalFALedgerEntry.Get("Entry No.") then;
                    if FixedAsset.Get(GlobalFALedgerEntry."FA No.") then;
                    exit(StrSubstNo(CaptionTxt, FixedAsset.TableCaption(), FixedAsset."No.", FixedAsset.Description));
                end;
            "Entry Type"::Maintenance:
                begin
                    if GlobalMaintenanceLedgerEntry.Get("Entry No.") then;
                    if FixedAsset.Get(GlobalMaintenanceLedgerEntry."FA No.") then;
                    exit(StrSubstNo(CaptionTxt, FixedAsset.TableCaption(), FixedAsset."No.", FixedAsset.Description));
                end;
            "Entry Type"::VAT:
                exit(StrSubstNo('%1', GlobalVATEntry.TableCaption()));
            else begin
                OnAfterCaption(Rec, NewCaption);
                exit(NewCaption);
            end;
        end;
    end;

    procedure CheckPostingDate(PostingDate: Date; TableCaption: Text; EntryNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPostingDate(PostingDate, CopyStr(TableCaption, 1, 50), EntryNo, IsHandled, Rec, MaxPostingDate);
        if IsHandled then
            exit;

        if GenJnlCheckLine.DateNotAllowed(PostingDate, JnlTemplName) then
            Error(Text001, TableCaption, EntryNo);
        if PostingDate > MaxPostingDate then
            MaxPostingDate := PostingDate;
    end;

    procedure CheckFAPostingDate(FAPostingDate: Date; TableCaption: Text; EntryNo: Integer)
    var
        UserSetup: Record "User Setup";
        FASetup: Record "FA Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckFAPostingDate(FAPostingDate, CopyStr(TableCaption, 1, 50), EntryNo, IsHandled, Rec, MaxPostingDate, AllowPostingFrom, AllowPostingto, xRec);
        if IsHandled then
            exit;

        if (AllowPostingFrom = 0D) and (AllowPostingto = 0D) then begin
            if UserId <> '' then
                if UserSetup.Get(UserId) then begin
                    AllowPostingFrom := UserSetup."Allow FA Posting From";
                    AllowPostingto := UserSetup."Allow FA Posting To";
                end;
            if (AllowPostingFrom = 0D) and (AllowPostingto = 0D) then begin
                FASetup.Get();
                AllowPostingFrom := FASetup."Allow FA Posting From";
                AllowPostingto := FASetup."Allow FA Posting To";
            end;
            if AllowPostingto = 0D then
                AllowPostingto := 99981231D;
        end;
        if (FAPostingDate < AllowPostingFrom) or (FAPostingDate > AllowPostingto) then
            Error(Text005, TableCaption, EntryNo, GlobalFALedgerEntry.FieldCaption("FA Posting Date"));
        if FAPostingDate > MaxPostingDate then
            MaxPostingDate := FAPostingDate;
    end;

    procedure TestFieldError()
    begin
        Error(Text004);
    end;

    procedure AlreadyReversedEntry(TableCaption: Text; EntryNo: Integer)
    begin
        Error(Text011, TableCaption, EntryNo);
    end;

    procedure VerifyReversalEntries(var ReversalEntry2: Record "Reversal Entry"; Number: Integer; RevType: Option Transaction,Register) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyReversalEntries(ReversalEntry2, Number, RevType, IsHandled, Result);
        if IsHandled then
            exit(Result);

        InsertReversalEntry(Number, RevType);
        Clear(TempReversalEntry);
        Clear(ReversalEntry2);
        if ReversalEntry2.FindSet() then
            repeat
                if TempReversalEntry.Next() = 0 then
                    exit(false);
                if not TempReversalEntry.Equal(ReversalEntry2) then
                    exit(false);
            until ReversalEntry2.Next() = 0;
        exit(TempReversalEntry.Next() = 0);
    end;

    procedure Equal(ReversalEntry2: Record "Reversal Entry"): Boolean
    begin
        exit(
          ("Entry Type" = ReversalEntry2."Entry Type") and
          ("Entry No." = ReversalEntry2."Entry No."));
    end;

    procedure ReversalErrorForChangedEntry(TableCaption: Text; EntryNo: Integer): Text[1024]
    begin
        exit(StrSubstNo(Text000, TableCaption, EntryNo));
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure SetHideWarningDialogs()
    begin
        HideDialog := true;
        HideWarningDialogs := true;
    end;

    procedure SetBankAccountStatement(BankAccountNo: Code[20]; StatementNo: Code[20])
    begin
        BankAccountStatement.Get(BankAccountNo, StatementNo);
    end;

    protected procedure InsertFromCustLedgEntry(var TempTransactionInteger: Record "Integer" temporary; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer)
    var
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        IsHandled: Boolean;
    begin
        DetailedCustLedgEntry.SetCurrentKey("Transaction No.", "Customer No.", "Entry Type");
        DetailedCustLedgEntry.SetFilter(
          "Entry Type", '<>%1', DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        if GlobalCustLedgerEntry.FindSet() then
            repeat
                DetailedCustLedgEntry.SetRange("Transaction No.", GlobalCustLedgerEntry."Transaction No.");
                DetailedCustLedgEntry.SetRange("Customer No.", GlobalCustLedgerEntry."Customer No.");
                IsHandled := false;
                OnInsertFromCustLedgEntryOnBeforeCheckSameTransaction(GlobalCustLedgerEntry, DetailedCustLedgEntry, IsHandled);
                if not IsHandled then
                    if (not DetailedCustLedgEntry.IsEmpty) and (RevType = RevType::Register) then
                        Error(PostedAndAppliedSameTransactionErr, Number);

                Clear(TempReversalEntry);
                if RevType = RevType::Register then
                    TempReversalEntry."G/L Register No." := Number;
                TempReversalEntry."Reversal Type" := RevType;
                TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::Customer;
                Customer.Get(GlobalCustLedgerEntry."Customer No.");
                TempReversalEntry."Account No." := Customer."No.";
                TempReversalEntry."Account Name" := Customer.Name;
                TempReversalEntry.CopyFromCustLedgEntry(GlobalCustLedgerEntry);
                TempReversalEntry."Line No." := NextLineNo;
                NextLineNo := NextLineNo + 1;
                OnInsertFromCustLedgEntryOnBeforeTempReversalEntryInsert(TempReversalEntry, GlobalCustLedgerEntry);
                TempReversalEntry.Insert();

                DetailedCustLedgEntry.SetRange(Unapplied, true);
                if DetailedCustLedgEntry.FindSet() then
                    repeat
                        InsertCustTempRevertTransNo(TempTransactionInteger, DetailedCustLedgEntry."Unapplied by Entry No.");
                    until DetailedCustLedgEntry.Next() = 0;
                DetailedCustLedgEntry.SetRange(Unapplied);
            until GlobalCustLedgerEntry.Next() = 0;

        OnAfterInsertFromCustLedgEntry(TempTransactionInteger, Number, RevType, NextLineNo, TempReversalEntry, GlobalCustLedgerEntry);
    end;

    protected procedure InsertFromVendLedgEntry(var TempTransactionNoInteger: Record "Integer" temporary; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer)
    var
        Vendor: Record Vendor;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        IsHandled: Boolean;
    begin
        DetailedVendorLedgEntry.SetCurrentKey("Transaction No.", "Vendor No.", "Entry Type");
        DetailedVendorLedgEntry.SetFilter(
          "Entry Type", '<>%1', DetailedVendorLedgEntry."Entry Type"::"Initial Entry");
        if GlobalVendorLedgerEntry.FindSet() then
            repeat
                DetailedVendorLedgEntry.SetRange("Transaction No.", GlobalVendorLedgerEntry."Transaction No.");
                DetailedVendorLedgEntry.SetRange("Vendor No.", GlobalVendorLedgerEntry."Vendor No.");
                IsHandled := false;
                OnInsertFromVendLedgEntryOnBeforeCheckSameTransaction(GlobalVendorLedgerEntry, DetailedVendorLedgEntry, IsHandled);
                if not IsHandled then
                    if (not DetailedVendorLedgEntry.IsEmpty()) and (RevType = RevType::Register) then
                        Error(PostedAndAppliedSameTransactionErr, Number);

                Clear(TempReversalEntry);
                if RevType = RevType::Register then
                    TempReversalEntry."G/L Register No." := Number;
                TempReversalEntry."Reversal Type" := RevType;
                TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::Vendor;
                Vendor.Get(GlobalVendorLedgerEntry."Vendor No.");
                TempReversalEntry."Account No." := Vendor."No.";
                TempReversalEntry."Account Name" := Vendor.Name;
                TempReversalEntry.CopyFromVendLedgEntry(GlobalVendorLedgerEntry);
                TempReversalEntry."Line No." := NextLineNo;
                NextLineNo := NextLineNo + 1;
                OnInsertFromVendLedgEntryOnBeforeTempReversalEntryInsert(TempReversalEntry, GlobalVendorLedgerEntry);
                TempReversalEntry.Insert();

                DetailedVendorLedgEntry.SetRange(Unapplied, true);
                if DetailedVendorLedgEntry.FindSet() then
                    repeat
                        InsertVendTempRevertTransNo(TempTransactionNoInteger, DetailedVendorLedgEntry."Unapplied by Entry No.");
                    until DetailedVendorLedgEntry.Next() = 0;
                DetailedVendorLedgEntry.SetRange(Unapplied);
            until GlobalVendorLedgerEntry.Next() = 0;

        OnAfterInsertFromVendLedgEntry(TempTransactionNoInteger, Number, RevType, NextLineNo, TempReversalEntry, GlobalVendorLedgerEntry);
    end;

    protected procedure InsertFromEmplLedgerEntry(var TempTransactionNoInteger: Record "Integer" temporary; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer)
    var
        DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
    begin
        DetailedEmployeeLedgerEntry.SetCurrentKey("Transaction No.", "Employee No.", "Entry Type");
        DetailedEmployeeLedgerEntry.SetFilter(
          "Entry Type", '<>%1', DetailedEmployeeLedgerEntry."Entry Type"::"Initial Entry");

        if GlobalEmployeeLedgerEntry.FindSet() then
            repeat
                DetailedEmployeeLedgerEntry.SetRange("Transaction No.", GlobalEmployeeLedgerEntry."Transaction No.");
                DetailedEmployeeLedgerEntry.SetRange("Employee No.", GlobalEmployeeLedgerEntry."Employee No.");
                if (not DetailedEmployeeLedgerEntry.IsEmpty) and (RevType = RevType::Register) then
                    Error(PostedAndAppliedSameTransactionErr, Number);

                InsertTempReversalEntryEmployee(Number, RevType, NextLineNo);
                NextLineNo += 1;

                InsertTempRevertTransactionNoUnappliedEmployeeEntries(TempTransactionNoInteger, DetailedEmployeeLedgerEntry);

            until GlobalEmployeeLedgerEntry.Next() = 0;

        OnAfterInsertFromEmplLedgEntry(TempTransactionNoInteger, Number, RevType, NextLineNo, TempReversalEntry, GlobalEmployeeLedgerEntry);
    end;

    protected procedure InsertFromBankAccLedgEntry(TempTransactionNoInteger: Record "Integer" temporary; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer)
    var
        BankAccount: Record "Bank Account";
    begin
        if GlobalBankAccountLedgerEntry.FindSet() then
            repeat
                OnInsertFromBankAccLedgEntryOnStartRepeatBankAccLedgEntry(GlobalBankAccountLedgerEntry);
                Clear(TempReversalEntry);
                if RevType = RevType::Register then
                    TempReversalEntry."G/L Register No." := Number;
                TempReversalEntry."Reversal Type" := RevType;
                TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::"Bank Account";
                BankAccount.Get(GlobalBankAccountLedgerEntry."Bank Account No.");
                TempReversalEntry."Account No." := BankAccount."No.";
                TempReversalEntry."Account Name" := BankAccount.Name;
                TempReversalEntry.CopyFromBankAccLedgEntry(GlobalBankAccountLedgerEntry);
                TempReversalEntry."Line No." := NextLineNo;
                NextLineNo := NextLineNo + 1;
                TempReversalEntry.Insert();
            until GlobalBankAccountLedgerEntry.Next() = 0;

        OnAfterInsertFromBankAccLedgEntry(TempTransactionNoInteger, Number, RevType, NextLineNo, TempReversalEntry, GlobalBankAccountLedgerEntry);
    end;

    protected procedure InsertFromFALedgEntry(TempTransactionNoInteger: Record "Integer" temporary; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer)
    var
        FixedAsset: Record "Fixed Asset";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertFromFALedgEntry(TempTransactionNoInteger, Number, RevType, NextLineNo, TempReversalEntry, GlobalFALedgerEntry, IsHandled);
        if IsHandled then
            exit;

        if GlobalFALedgerEntry.FindSet() then
            repeat
                Clear(TempReversalEntry);
                if RevType = RevType::Register then
                    TempReversalEntry."G/L Register No." := Number;
                TempReversalEntry."Reversal Type" := RevType;
                TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::"Fixed Asset";
                FixedAsset.Get(GlobalFALedgerEntry."FA No.");
                TempReversalEntry."Account No." := FixedAsset."No.";
                TempReversalEntry."Account Name" := FixedAsset.Description;
                TempReversalEntry.CopyFromFALedgEntry(GlobalFALedgerEntry);
                if GlobalFALedgerEntry."FA Posting Type" <> GlobalFALedgerEntry."FA Posting Type"::"Salvage Value" then begin
                    TempReversalEntry."Line No." := NextLineNo;
                    NextLineNo := NextLineNo + 1;
                    TempReversalEntry.Insert();
                end;
            until GlobalFALedgerEntry.Next() = 0;

        OnAfterInsertFromFALedgEntry(TempTransactionNoInteger, Number, RevType, NextLineNo, TempReversalEntry, GlobalFALedgerEntry);
    end;

    protected procedure InsertFromMaintenanceLedgEntry(TempTransactionNoInteger: Record "Integer" temporary; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer)
    var
        FixedAsset: Record "Fixed Asset";
    begin
        if GlobalMaintenanceLedgerEntry.FindSet() then
            repeat
                Clear(TempReversalEntry);
                if RevType = RevType::Register then
                    TempReversalEntry."G/L Register No." := Number;
                TempReversalEntry."Reversal Type" := RevType;
                TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::Maintenance;
                FixedAsset.Get(GlobalMaintenanceLedgerEntry."FA No.");
                TempReversalEntry."Account No." := FixedAsset."No.";
                TempReversalEntry."Account Name" := FixedAsset.Description;
                TempReversalEntry.CopyFromMaintenanceEntry(GlobalMaintenanceLedgerEntry);
                TempReversalEntry."Line No." := NextLineNo;
                NextLineNo := NextLineNo + 1;
                TempReversalEntry.Insert();
            until GlobalMaintenanceLedgerEntry.Next() = 0;

        OnAfterInsertFromMaintenanceLedgEntry(TempTransactionNoInteger, Number, RevType, NextLineNo, TempReversalEntry, GlobalMaintenanceLedgerEntry);
    end;

    protected procedure InsertFromVATEntry(var TempTransactionNoInteger: Record "Integer" temporary; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer)
    begin
        TempTransactionNoInteger.FindSet();
        repeat
            if RevType = RevType::Transaction then
                GlobalVATEntry.SetRange("Transaction No.", TempTransactionNoInteger.Number);
            OnInsertFromVATEntryOnAfterVATEntrySetRange(GlobalVATEntry, RevType, TempTransactionNoInteger);
            if GlobalVATEntry.FindSet() then
                repeat
                    OnInsertFromVATEntryOnStartRepeatVATEntry(GlobalVATEntry);
                    Clear(TempReversalEntry);
                    if RevType = RevType::Register then
                        TempReversalEntry."G/L Register No." := Number;
                    TempReversalEntry."Reversal Type" := RevType;
                    TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::VAT;
                    TempReversalEntry.CopyFromVATEntry(GlobalVATEntry);
                    TempReversalEntry."Line No." := NextLineNo;
                    NextLineNo := NextLineNo + 1;
                    OnInsertFromVATEntryOnBeforeTempReversalEntryInsert(TempReversalEntry, RevType, TempTransactionNoInteger);
                    TempReversalEntry.Insert();
                until GlobalVATEntry.Next() = 0;
        until TempTransactionNoInteger.Next() = 0;

        OnAfterInsertFromVATEntry(TempTransactionNoInteger, Number, RevType, NextLineNo, TempReversalEntry, GlobalVATEntry);
    end;

    protected procedure InsertFromGLEntry(var TempTransactionNoInteger: Record "Integer" temporary; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer)
    var
        GLAccount: Record "G/L Account";
    begin
        TempTransactionNoInteger.FindSet();
        repeat
            if RevType = RevType::Transaction then
                GlobalGLEntry.SetRange("Transaction No.", TempTransactionNoInteger.Number);
            OnInsertFromGLEntryOnAfterGLEntrySetRange(GlobalGLEntry, RevType, TempTransactionNoInteger);
            if GlobalGLEntry.FindSet() then
                repeat
                    OnInsertFromGLEntryOnBeforeClearTempReversalEntry(GlobalGLEntry);
                    Clear(TempReversalEntry);
                    if RevType = RevType::Register then
                        TempReversalEntry."G/L Register No." := Number;
                    TempReversalEntry."Reversal Type" := RevType;
                    TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::"G/L Account";
                    if not GLAccount.Get(GlobalGLEntry."G/L Account No.") then
                        Error(CannotReverseDeletedErr, GlobalGLEntry.TableCaption(), GLAccount.TableCaption());
                    TempReversalEntry."Account No." := GLAccount."No.";
                    TempReversalEntry."Account Name" := GLAccount.Name;
                    TempReversalEntry.CopyFromGLEntry(GlobalGLEntry);
                    TempReversalEntry."Line No." := NextLineNo;
                    NextLineNo := NextLineNo + 1;
                    OnInsertFromGLEntryOnBeforeTempReversalEntryInsert(TempReversalEntry, GlobalGLEntry, RevType, TempTransactionNoInteger, Rec);
                    TempReversalEntry.Insert();
                until GlobalGLEntry.Next() = 0;
        until TempTransactionNoInteger.Next() = 0;

        OnAfterInsertFromGLEntry(TempTransactionNoInteger, Number, RevType, NextLineNo, TempReversalEntry, GlobalGLEntry);
    end;

    local procedure InsertTempReversalEntryEmployee(Number: Integer; RevType: Option Transaction,Register; NextLineNo: Integer)
    var
        Employee: Record Employee;
    begin
        Clear(TempReversalEntry);
        if RevType = RevType::Register then
            TempReversalEntry."G/L Register No." := Number;
        TempReversalEntry."Reversal Type" := RevType;
        TempReversalEntry."Entry Type" := TempReversalEntry."Entry Type"::Employee;
        Employee.Get(GlobalEmployeeLedgerEntry."Employee No.");
        TempReversalEntry."Account No." := Employee."No.";
        TempReversalEntry."Account Name" := CopyStr(Employee.FullName(), 1, MaxStrLen(TempReversalEntry."Account Name"));
        TempReversalEntry.CopyFromEmployeeLedgerEntry(GlobalEmployeeLedgerEntry);
        TempReversalEntry."Line No." := NextLineNo;
        TempReversalEntry.Insert();
    end;

    procedure CopyFromCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        "Entry No." := CustLedgerEntry."Entry No.";
        "Posting Date" := CustLedgerEntry."Posting Date";
        "Source Code" := CustLedgerEntry."Source Code";
        "Journal Batch Name" := CustLedgerEntry."Journal Batch Name";
        "Transaction No." := CustLedgerEntry."Transaction No.";
        "Currency Code" := CustLedgerEntry."Currency Code";
        Description := CustLedgerEntry.Description;
        CustLedgerEntry.CalcFields(Amount, "Debit Amount", "Credit Amount",
          "Amount (LCY)", "Debit Amount (LCY)", "Credit Amount (LCY)");
        Amount := CustLedgerEntry.Amount;
        "Debit Amount" := CustLedgerEntry."Debit Amount";
        "Credit Amount" := CustLedgerEntry."Credit Amount";
        "Amount (LCY)" := CustLedgerEntry."Amount (LCY)";
        "Debit Amount (LCY)" := CustLedgerEntry."Debit Amount (LCY)";
        "Credit Amount (LCY)" := CustLedgerEntry."Credit Amount (LCY)";
        "Document Type" := CustLedgerEntry."Document Type";
        "Document No." := CustLedgerEntry."Document No.";
        "Bal. Account Type" := CustLedgerEntry."Bal. Account Type";
        "Bal. Account No." := CustLedgerEntry."Bal. Account No.";

        OnAfterCopyFromCustLedgEntry(Rec, CustLedgerEntry);
    end;

    procedure CopyFromBankAccLedgEntry(BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
        "Entry No." := BankAccountLedgerEntry."Entry No.";
        "Posting Date" := BankAccountLedgerEntry."Posting Date";
        "Source Code" := BankAccountLedgerEntry."Source Code";
        "Journal Batch Name" := BankAccountLedgerEntry."Journal Batch Name";
        "Transaction No." := BankAccountLedgerEntry."Transaction No.";
        "Currency Code" := BankAccountLedgerEntry."Currency Code";
        Description := BankAccountLedgerEntry.Description;
        Amount := BankAccountLedgerEntry.Amount;
        "Debit Amount" := BankAccountLedgerEntry."Debit Amount";
        "Credit Amount" := BankAccountLedgerEntry."Credit Amount";
        "Amount (LCY)" := BankAccountLedgerEntry."Amount (LCY)";
        "Debit Amount (LCY)" := BankAccountLedgerEntry."Debit Amount (LCY)";
        "Credit Amount (LCY)" := BankAccountLedgerEntry."Credit Amount (LCY)";
        "Document Type" := BankAccountLedgerEntry."Document Type";
        "Document No." := BankAccountLedgerEntry."Document No.";
        "Bal. Account Type" := BankAccountLedgerEntry."Bal. Account Type";
        "Bal. Account No." := BankAccountLedgerEntry."Bal. Account No.";

        OnAfterCopyFromBankAccLedgEntry(Rec, BankAccountLedgerEntry);
    end;

    procedure CopyFromFALedgEntry(FALedgerEntry: Record "FA Ledger Entry")
    begin
        "Entry No." := FALedgerEntry."Entry No.";
        "Posting Date" := FALedgerEntry."Posting Date";
        "FA Posting Category" := FALedgerEntry."FA Posting Category";
        "FA Posting Type" := Enum::"Reversal Entry FA Posting Type".FromInteger(FALedgerEntry."FA Posting Type".AsInteger() + 1);
        "Source Code" := FALedgerEntry."Source Code";
        "Journal Batch Name" := FALedgerEntry."Journal Batch Name";
        "Transaction No." := FALedgerEntry."Transaction No.";
        Description := FALedgerEntry.Description;
        "Amount (LCY)" := FALedgerEntry.Amount;
        "Debit Amount (LCY)" := FALedgerEntry."Debit Amount";
        "Credit Amount (LCY)" := FALedgerEntry."Credit Amount";
        "VAT Amount" := FALedgerEntry."VAT Amount";
        "Document Type" := FALedgerEntry."Document Type";
        "Document No." := FALedgerEntry."Document No.";
        "Bal. Account Type" := FALedgerEntry."Bal. Account Type";
        "Bal. Account No." := FALedgerEntry."Bal. Account No.";

        OnAfterCopyFromFALedgEntry(Rec, FALedgerEntry);
    end;

    procedure CopyFromGLEntry(GLEntry: Record "G/L Entry")
    begin
        "Entry No." := GLEntry."Entry No.";
        "Posting Date" := GLEntry."Posting Date";
        "Source Code" := GLEntry."Source Code";
        "Journal Batch Name" := GLEntry."Journal Batch Name";
        "Transaction No." := GLEntry."Transaction No.";
        "Source Type" := GLEntry."Source Type";
        "Source No." := GLEntry."Source No.";
        Description := GLEntry.Description;
        "Amount (LCY)" := GLEntry.Amount;
        "Source Currency Amount" := GLEntry."Source Currency Amount";
        "Debit Amount (LCY)" := GLEntry."Debit Amount";
        "Credit Amount (LCY)" := GLEntry."Credit Amount";
        "VAT Amount" := GLEntry."VAT Amount";
        "Source Currency VAT Amount" := GLEntry."Source Currency VAT Amount";
        "Document Type" := GLEntry."Document Type";
        "Document No." := GLEntry."Document No.";
        "Bal. Account Type" := GLEntry."Bal. Account Type";
        "Bal. Account No." := GLEntry."Bal. Account No.";
        "Source Currency Code" := GLEntry."Source Currency Code";

        OnAfterCopyFromGLEntry(Rec, GLEntry);
    end;

    procedure CopyFromMaintenanceEntry(MaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    begin
        "Entry No." := MaintenanceLedgerEntry."Entry No.";
        "Posting Date" := MaintenanceLedgerEntry."Posting Date";
        "Source Code" := MaintenanceLedgerEntry."Source Code";
        "Journal Batch Name" := MaintenanceLedgerEntry."Journal Batch Name";
        "Transaction No." := MaintenanceLedgerEntry."Transaction No.";
        Description := MaintenanceLedgerEntry.Description;
        "Amount (LCY)" := MaintenanceLedgerEntry.Amount;
        "Debit Amount (LCY)" := MaintenanceLedgerEntry."Debit Amount";
        "Credit Amount (LCY)" := MaintenanceLedgerEntry."Credit Amount";
        "VAT Amount" := MaintenanceLedgerEntry."VAT Amount";
        "Document Type" := MaintenanceLedgerEntry."Document Type";
        "Document No." := MaintenanceLedgerEntry."Document No.";
        "Bal. Account Type" := MaintenanceLedgerEntry."Bal. Account Type";
        "Bal. Account No." := MaintenanceLedgerEntry."Bal. Account No.";

        OnAfterCopyFromMaintenanceEntry(Rec, MaintenanceLedgerEntry);
    end;

    procedure CopyFromVATEntry(VATEntry: Record "VAT Entry")
    begin
        "Entry No." := VATEntry."Entry No.";
        "Posting Date" := VATEntry."Posting Date";
        "Source Code" := VATEntry."Source Code";
        "Transaction No." := VATEntry."Transaction No.";
        Amount := VATEntry.Amount;
        "Amount (LCY)" := VATEntry.Amount;
        "Source Currency Amount" := VATEntry."Source Currency VAT Amount";
        "Document Type" := VATEntry."Document Type";
        "Document No." := VATEntry."Document No.";

        OnAfterCopyFromVATEntry(Rec, VATEntry);
    end;

    procedure CopyFromVendLedgEntry(VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        "Entry No." := VendorLedgerEntry."Entry No.";
        "Posting Date" := VendorLedgerEntry."Posting Date";
        "Source Code" := VendorLedgerEntry."Source Code";
        "Journal Batch Name" := VendorLedgerEntry."Journal Batch Name";
        "Transaction No." := VendorLedgerEntry."Transaction No.";
        "Currency Code" := VendorLedgerEntry."Currency Code";
        Description := VendorLedgerEntry.Description;
        VendorLedgerEntry.CalcFields(Amount, "Debit Amount", "Credit Amount",
          "Amount (LCY)", "Debit Amount (LCY)", "Credit Amount (LCY)");
        Amount := VendorLedgerEntry.Amount;
        "Debit Amount" := VendorLedgerEntry."Debit Amount";
        "Credit Amount" := VendorLedgerEntry."Credit Amount";
        "Amount (LCY)" := VendorLedgerEntry."Amount (LCY)";
        "Debit Amount (LCY)" := VendorLedgerEntry."Debit Amount (LCY)";
        "Credit Amount (LCY)" := VendorLedgerEntry."Credit Amount (LCY)";
        "Document Type" := VendorLedgerEntry."Document Type";
        "Document No." := VendorLedgerEntry."Document No.";
        "Bal. Account Type" := VendorLedgerEntry."Bal. Account Type";
        "Bal. Account No." := VendorLedgerEntry."Bal. Account No.";

        OnAfterCopyFromVendLedgEntry(Rec, VendorLedgerEntry);
    end;

    procedure CopyFromEmployeeLedgerEntry(EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        "Entry No." := EmployeeLedgerEntry."Entry No.";
        "Posting Date" := EmployeeLedgerEntry."Posting Date";
        "Source Code" := EmployeeLedgerEntry."Source Code";
        "Journal Batch Name" := EmployeeLedgerEntry."Journal Batch Name";
        "Transaction No." := EmployeeLedgerEntry."Transaction No.";
        "Currency Code" := EmployeeLedgerEntry."Currency Code";
        Description := EmployeeLedgerEntry.Description;
        EmployeeLedgerEntry.CalcFields(
          Amount, "Debit Amount", "Credit Amount", "Amount (LCY)", "Debit Amount (LCY)", "Credit Amount (LCY)");
        Amount := EmployeeLedgerEntry.Amount;
        "Debit Amount" := EmployeeLedgerEntry."Debit Amount";
        "Credit Amount" := EmployeeLedgerEntry."Credit Amount";
        "Amount (LCY)" := EmployeeLedgerEntry."Amount (LCY)";
        "Debit Amount (LCY)" := EmployeeLedgerEntry."Debit Amount (LCY)";
        "Credit Amount (LCY)" := EmployeeLedgerEntry."Credit Amount (LCY)";
        "Document Type" := EmployeeLedgerEntry."Document Type";
        "Document No." := EmployeeLedgerEntry."Document No.";
        "Bal. Account Type" := EmployeeLedgerEntry."Bal. Account Type";
        "Bal. Account No." := EmployeeLedgerEntry."Bal. Account No.";

        OnAfterCopyFromEmplLedgEntry(Rec, EmployeeLedgerEntry);
    end;

    local procedure InsertCustTempRevertTransNo(var TempTransactionNoInteger: Record "Integer" temporary; CustLedgEntryNo: Integer)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertCustTempRevertTransNo(TempTransactionNoInteger, CustLedgEntryNo, IsHandled);
        if IsHandled then
            exit;

        DetailedCustLedgEntry.Get(CustLedgEntryNo);
        if DetailedCustLedgEntry."Transaction No." <> 0 then begin
            TempTransactionNoInteger.Number := DetailedCustLedgEntry."Transaction No.";
            if TempTransactionNoInteger.Insert() then;
        end;
    end;

    local procedure InsertVendTempRevertTransNo(var TempTransactionNoInteger: Record "Integer" temporary; VendLedgEntryNo: Integer)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertVendTempRevertTransNo(TempTransactionNoInteger, VendLedgEntryNo, IsHandled);
        if IsHandled then
            exit;

        DetailedVendorLedgEntry.Get(VendLedgEntryNo);
        if DetailedVendorLedgEntry."Transaction No." <> 0 then begin
            TempTransactionNoInteger.Number := DetailedVendorLedgEntry."Transaction No.";
            if TempTransactionNoInteger.Insert() then;
        end;
    end;

    local procedure InsertEmplTempRevertTransNo(var TempTransactionNoInteger: Record "Integer" temporary; EmployeeLedgEntryNo: Integer)
    var
        DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
    begin
        DetailedEmployeeLedgerEntry.Get(EmployeeLedgEntryNo);
        if DetailedEmployeeLedgerEntry."Transaction No." <> 0 then begin
            TempTransactionNoInteger.Number := DetailedEmployeeLedgerEntry."Transaction No.";
            if TempTransactionNoInteger.Insert() then;
        end;
    end;

    local procedure InsertTempRevertTransactionNoUnappliedEmployeeEntries(var TempTransactionNoInteger: Record "Integer" temporary; var DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry")
    begin
        DetailedEmployeeLedgerEntry.SetRange(Unapplied, true);
        if DetailedEmployeeLedgerEntry.FindSet() then
            repeat
                InsertEmplTempRevertTransNo(TempTransactionNoInteger, DetailedEmployeeLedgerEntry."Unapplied by Entry No.");
            until DetailedEmployeeLedgerEntry.Next() = 0;
        DetailedEmployeeLedgerEntry.SetRange(Unapplied);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCaption(ReversalEntry: Record "Reversal Entry"; var NewCaption: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckEntries(var MaxPostingDate: Date; var ReversalEntry: Record "Reversal Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckBankAcc(BankAccount: Record "Bank Account"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGLAcc(var GLAccount: Record "G/L Account"; GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckCust(Customer: Record Customer; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckVend(Vendor: Record Vendor; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckEmpl(Employee: Record Employee; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckFA(FixedAsset: Record "Fixed Asset"; FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckMaintenance(FixedAsset: Record "Fixed Asset"; MaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckVAT(var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDtldCustLedgEntry(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDtldVendLedgEntry(DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDtldEmplLedgEntry(DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromBankAccLedgEntry(var ReversalEntry: Record "Reversal Entry"; BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromCustLedgEntry(var ReversalEntry: Record "Reversal Entry"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromFALedgEntry(var ReversalEntry: Record "Reversal Entry"; FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromGLEntry(var ReversalEntry: Record "Reversal Entry"; GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromMaintenanceEntry(var ReversalEntry: Record "Reversal Entry"; MaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromVATEntry(var ReversalEntry: Record "Reversal Entry"; VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromVendLedgEntry(var ReversalEntry: Record "Reversal Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromEmplLedgEntry(var ReversalEntry: Record "Reversal Entry"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertFromBankAccLedgEntry(var TempRevertTransactionNo: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary; var BankAccLedgEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertFromCustLedgEntry(var TempRevertTransactionNo: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertFromEmplLedgEntry(var TempRevertTransactionNo: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary; var EmplLedgEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertFromFALedgEntry(var TempRevertTransactionNo: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary; var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertFromGLEntry(var TempRevertTransactionNo: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertFromMaintenanceLedgEntry(var TempRevertTransactionNo: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary; var MaintenanceLedgEntry: Record "Maintenance Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertReversalEntry(var TempRevertTransactionNo: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertFromVATEntry(var TempRevertTransactionNo: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary; var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertFromVendLedgEntry(var TempRevertTransactionNo: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReverseEntries(Number: Integer; RevType: Integer; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReverseFilter(Number: Integer; RevType: Option Transaction,Register; GLRegister: Record "G/L Register"; var ReversalEntry: Record "Reversal Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckEntries(ReversalEntry: Record "Reversal Entry"; TableID: Integer; var SkipCheck: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckEmpl(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckFA(var FALedgerEntry: Record "FA Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFAPostingDate(FAPostingDate: Date; Caption: Text[50]; EntryNo: Integer; var IsHandled: Boolean; var ReversalEntry: Record "Reversal Entry"; var MaxPostingDate: Date; var AllowPostingFrom: Date; var AllowPostingto: Date; var xReversalEntry: Record "Reversal Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckMaintenance(var MaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckGLAcc(var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLEntry(var ReversalEntry: Record "Reversal Entry"; GLEntry: Record "G/L Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRegister(RegisterNo: Integer; var IsHandled: Boolean; var ReversalEntry: Record "Reversal Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReversalEntry(var ReversalEntry: Record "Reversal Entry"; Number: Integer; RevType: Option Transaction,Register; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReverseEntries(Number: Integer; RevType: Integer; var IsHandled: Boolean; HideDialog: Boolean; var ReversalEntry: Record "Reversal Entry"; var HideWarningDialogs: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFromCustLedgEntryOnBeforeTempReversalEntryInsert(var TempReversalEntry: Record "Reversal Entry" temporary; CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFromGLEntryOnBeforeClearTempReversalEntry(GLEntry: Record "G/L Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFromGLEntryOnBeforeTempReversalEntryInsert(var TempReversalEntry: Record "Reversal Entry" temporary; GLEntry: Record "G/L Entry"; RevType: Option Transaction,Register; var TempRevertTransactionNoRecordInteger: Record "Integer" temporary; ReversalEntry: Record "Reversal Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFromVendLedgEntryOnBeforeTempReversalEntryInsert(var TempReversalEntry: Record "Reversal Entry" temporary; VendorLedgerEntry: Record "Vendor Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCaption(ReversalEntry: Record "Reversal Entry"; var Result: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckVAT(var VATEntry: Record "VAT Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckBankAcc(var BankAccLedgEntry: Record "Bank Account Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckVend(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckCust(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckGLAccOnBeforeTestFields(GLAcc: Record "G/L Account"; GLEntry: Record "G/L Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPostingDate(PostingDate: Date; Caption: Text[50]; EntryNo: Integer; var IsHandled: Boolean; var ReversalEntry: Record "Reversal Entry"; var MaxPostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDtldCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCCheckDtldVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFromVendLedgEntryOnBeforeCheckSameTransaction(VendLedgEntry: Record "Vendor Ledger Entry"; var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFromCustLedgEntryOnBeforeCheckSameTransaction(CustLedgEntry: Record "Cust. Ledger Entry"; var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseEntriesOnAfterInsertReversalEntry(var TempReversalEntry: Record "Reversal Entry" temporary; Number: Integer; RevType: Option Transaction,Register)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetReverseFilter(Number: Integer; RevType: Option Transaction,Register; var GLEntry: Record "G/L Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var VendLedgerEntry: Record "Vendor Ledger Entry"; var EmployeeLedgerEntry: Record "Employee Ledger Entry"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var VATEntry: Record "VAT Entry"; var FALedgerEntry: Record "FA Ledger Entry"; var MaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; var GLRegister: Record "G/L Register"; var ReversalEntry: Record "Reversal Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFromBankAccLedgEntryOnStartRepeatBankAccLedgEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertFromFALedgEntry(var TempRevertTransactionNoRecordInteger: Record "Integer"; Number: Integer; RevType: Option Transaction,Register; var NextLineNo: Integer; var TempReversalEntry: Record "Reversal Entry" temporary; var FALedgerEntry: Record "FA Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFromVATEntryOnAfterVATEntrySetRange(var VATEntry: Record "VAT Entry"; RevType: Option Transaction,Register; var TempRevertTransactionNoRecordInteger: Record "Integer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFromVATEntryOnStartRepeatVATEntry(var VATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFromVATEntryOnBeforeTempReversalEntryInsert(var TempReversalEntry: Record "Reversal Entry" temporary; RevType: Option Transaction,Register; var TempRevertTransactionNo: Record "Integer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertFromGLEntryOnAfterGLEntrySetRange(var GLEntry: Record "G/L Entry"; RevType: Option Transaction,Register; var TempRevertTransactionNoRecordInteger: Record "Integer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCustTempRevertTransNo(var TempRevertTransactionNoRecordInteger: Record "Integer" temporary; CustLedgEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertVendTempRevertTransNo(var TempRevertTransactionNoRecordInteger: Record "Integer" temporary; VendLedgEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyReversalEntries(var ReversalEntry2: Record "Reversal Entry"; Number: Integer; RevType: Option Transaction,Register; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;
}
