// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

/// <summary>
/// Records payment applications linking bank statement lines to customer, vendor, and general ledger entries.
/// This table serves as the detailed application registry for payment reconciliation processes, tracking
/// which specific ledger entries have been matched to bank statement transactions and the amounts applied.
/// Supports complex application scenarios including partial payments, payment discounts, and multi-currency applications.
/// </summary>
/// <remarks>
/// Key features include automatic matching confidence scoring, payment discount calculations, tolerance handling,
/// and comprehensive validation of application logic. Integrates with customer, vendor, employee, and G/L ledger
/// entries to provide complete payment application functionality across all account types.
/// </remarks>
table 1294 "Applied Payment Entry"
{
    Caption = 'Applied Payment Entry';
    LookupPageID = "Payment Application";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Bank account number for the payment reconciliation statement.
        /// Links the payment application to the specific bank account being reconciled.
        /// </summary>
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        /// <summary>
        /// Statement number identifying the bank reconciliation or payment application batch.
        /// Groups related payment applications under a single processing session.
        /// </summary>
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Bank Acc. Reconciliation"."Statement No." where("Bank Account No." = field("Bank Account No."),
                                                                              "Statement Type" = field("Statement Type"));
        }
        /// <summary>
        /// Line number within the bank statement being applied.
        /// References the specific bank transaction line from the imported statement.
        /// </summary>
        field(3; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
        }
        /// <summary>
        /// Type of reconciliation statement being processed.
        /// Determines whether this is a bank reconciliation or payment application scenario.
        /// </summary>
        field(20; "Statement Type"; Enum "Bank Acc. Rec. Stmt. Type")
        {
            Caption = 'Statement Type';
        }
        /// <summary>
        /// Type of account that the payment is being applied to.
        /// Determines the ledger entry type for payment application (Customer, Vendor, G/L Account, etc.).
        /// </summary>
        field(21; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';

            trigger OnValidate()
            begin
                Validate("Account No.", '');
            end;
        }
        /// <summary>
        /// Account number for the payment application.
        /// Specifies the customer, vendor, G/L account, or other account receiving the payment.
        /// </summary>
        field(22; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Account" where("Account Type" = const(Posting),
                                                                                          Blocked = const(false))
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Account Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Account Type" = const("IC Partner")) "IC Partner";

            trigger OnValidate()
            begin
                if "Account No." = '' then
                    CheckApplnIsSameAcc();

                GetAccInfo();
                Validate("Applies-to Entry No.", 0);
            end;
        }
        /// <summary>
        /// Entry number of the specific ledger entry being applied.
        /// Links the payment to a particular customer invoice, vendor bill, or other transaction.
        /// </summary>
        field(23; "Applies-to Entry No."; Integer)
        {
            Caption = 'Applies-to Entry No.';
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Entry"
            else
            if ("Account Type" = const(Customer)) "Cust. Ledger Entry" where(Open = const(true))
            else
            if ("Account Type" = const(Vendor)) "Vendor Ledger Entry" where(Open = const(true))
            else
            if ("Account Type" = const("Bank Account")) "Bank Account Ledger Entry" where(Open = const(true));

            trigger OnLookup()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
                VendLedgEntry: Record "Vendor Ledger Entry";
                BankAccLedgEntry: Record "Bank Account Ledger Entry";
                GLEntry: Record "G/L Entry";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeAppliesToEntryNoLookup(Rec, IsHandled);
                if IsHandled then
                    exit;

                case "Account Type" of
                    "Account Type"::"G/L Account":
                        begin
                            GLEntry.SetRange("G/L Account No.", "Account No.");
                            if PAGE.RunModal(0, GLEntry) = ACTION::LookupOK then
                                Validate("Applies-to Entry No.", GLEntry."Entry No.");
                        end;
                    "Account Type"::Customer:
                        begin
                            CustLedgEntry.SetRange(Open, true);
                            CustLedgEntry.SetRange("Customer No.", "Account No.");
                            if PAGE.RunModal(0, CustLedgEntry) = ACTION::LookupOK then
                                Validate("Applies-to Entry No.", CustLedgEntry."Entry No.");
                        end;
                    "Account Type"::Vendor:
                        begin
                            VendLedgEntry.SetRange(Open, true);
                            VendLedgEntry.SetRange("Vendor No.", "Account No.");
                            if PAGE.RunModal(0, VendLedgEntry) = ACTION::LookupOK then
                                Validate("Applies-to Entry No.", VendLedgEntry."Entry No.");
                        end;
                    "Account Type"::"Bank Account":
                        begin
                            BankAccLedgEntry.SetRange(Open, true);
                            BankAccLedgEntry.SetRange("Bank Account No.", "Account No.");
                            if PAGE.RunModal(0, BankAccLedgEntry) = ACTION::LookupOK then
                                Validate("Applies-to Entry No.", BankAccLedgEntry."Entry No.");
                        end;
                end;

                OnAfterLookupAppliesToEntryNo(Rec);
            end;

            trigger OnValidate()
            begin
                if "Applies-to Entry No." = 0 then begin
                    Validate("Applied Amount", 0);
                    exit;
                end;

                CheckCurrencyCombination();
                GetLedgEntryInfo();
                UpdatePaymentDiscount(SuggestDiscToApply(false));
                Validate("Applied Amount", SuggestAmtToApply());
            end;
        }
        /// <summary>
        /// Amount being applied from the bank statement to the ledger entry.
        /// Represents the portion of the bank transaction applied to this specific entry.
        /// </summary>
        field(24; "Applied Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Applied Amount';

            trigger OnValidate()
            begin
                if "Applies-to Entry No." <> 0 then
                    TestField("Applied Amount");
                CheckEntryAmt();
                UpdatePaymentDiscount(SuggestDiscToApply(true));
                if "Applied Pmt. Discount" <> 0 then
                    "Applied Amount" := SuggestAmtToApply();

                UpdateParentBankAccReconLine(false);
            end;
        }
        /// <summary>
        /// Payment discount amount applied with this payment.
        /// Calculated based on payment terms and payment timing for early payment discounts.
        /// </summary>
        field(29; "Applied Pmt. Discount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Applied Pmt. Discount';
        }
        /// <summary>
        /// Quality score or matching confidence indicator for the payment application.
        /// Used internally to track automatic matching quality and validation results.
        /// </summary>
        field(30; Quality; Integer)
        {
            Caption = 'Quality';
        }
        /// <summary>
        /// Posting date of the applied ledger entry.
        /// Inherited from the ledger entry being applied to for reference and validation.
        /// </summary>
        field(31; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        /// <summary>
        /// Document type of the applied ledger entry.
        /// Inherited from the ledger entry being applied (Invoice, Credit Memo, Payment, etc.).
        /// </summary>
        field(32; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        /// <summary>
        /// Document number of the applied ledger entry.
        /// Inherited from the ledger entry being applied for reference and audit purposes.
        /// </summary>
        field(33; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        /// <summary>
        /// Description of the applied ledger entry.
        /// Inherited from the ledger entry being applied for display and identification purposes.
        /// </summary>
        field(34; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// Currency code of the applied ledger entry.
        /// Used for multi-currency payment applications and exchange rate calculations.
        /// </summary>
        field(35; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        /// <summary>
        /// Due date of the applied ledger entry.
        /// Inherited from the ledger entry being applied for payment timing analysis.
        /// </summary>
        field(36; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        /// <summary>
        /// External document number of the applied ledger entry.
        /// Inherited from the ledger entry being applied for external reference and audit.
        /// </summary>
        field(37; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        /// <summary>
        /// Confidence level of the automatic matching algorithm for this payment application.
        /// Indicates how certain the system is that this application is correct.
        /// </summary>
        field(50; "Match Confidence"; Enum "Bank Rec. Match Confidence")
        {
            Caption = 'Match Confidence';
            Editable = false;
            InitValue = "None";
        }
    }

    keys
    {
        key(Key1; "Statement Type", "Bank Account No.", "Statement No.", "Statement Line No.", "Account Type", "Account No.", "Applies-to Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        "Applied Amount" := 0;
        "Applied Pmt. Discount" := 0;
        UpdateParentBankAccReconLine(true);
        ClearCustVendEntryApplicationData();
    end;

    trigger OnInsert()
    begin
        if "Applies-to Entry No." <> 0 then
            TestField("Applied Amount");

        CheckApplnIsSameAcc();
    end;

    trigger OnModify()
    begin
        TestField("Applied Amount");
        CheckApplnIsSameAcc();
    end;

    var
        CurrencyExchRate: Record "Currency Exchange Rate";
#pragma warning disable AA0470
        CurrencyMismatchErr: Label 'Currency codes on bank account %1 and ledger entry %2 do not match.';
        AmtCannotExceedErr: Label 'The Amount to Apply cannot exceed %1. This is because the Remaining Amount on the entry is %2 and the amount assigned to other statement lines is %3.';
#pragma warning restore AA0470
        CannotApplyStmtLineErr: Label 'You cannot apply to %1 %2 because the statement line already contains an application to %3 %4.', Comment = '%1 = Account Type, %2 = Account No., %3 = Account Type, %4 = Account No.';

    local procedure CheckApplnIsSameAcc()
    var
        ExistingAppliedPmtEntry: Record "Applied Payment Entry";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        if "Account No." = '' then
            exit;
        BankAccReconLine.Get("Statement Type", "Bank Account No.", "Statement No.", "Statement Line No.");
        ExistingAppliedPmtEntry.FilterAppliedPmtEntry(BankAccReconLine);
        if ExistingAppliedPmtEntry.FindFirst() then
            CheckCurrentMatchesExistingAppln(ExistingAppliedPmtEntry);
        if ExistingAppliedPmtEntry.FindLast() then
            CheckCurrentMatchesExistingAppln(ExistingAppliedPmtEntry);
    end;

    local procedure CheckCurrentMatchesExistingAppln(ExistingAppliedPmtEntry: Record "Applied Payment Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCurrentMatchesExistingAppln(ExistingAppliedPmtEntry, IsHandled);
        if IsHandled then
            exit;

        if ("Account Type" = ExistingAppliedPmtEntry."Account Type") and
           ("Account No." = ExistingAppliedPmtEntry."Account No.")
        then
            exit;

        Error(
          CannotApplyStmtLineErr,
          "Account Type", "Account No.",
          ExistingAppliedPmtEntry."Account Type",
          ExistingAppliedPmtEntry."Account No.");
    end;

    local procedure CheckEntryAmt()
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        AmtAvailableToApply: Decimal;
    begin
        if "Applied Amount" = 0 then
            exit;

        BankAccReconLine.Get("Statement Type", "Bank Account No.", "Statement No.", "Statement Line No.");
        // Amount should not exceed Remaining Amount
        AmtAvailableToApply := GetRemAmt() - GetAmtAppliedToOtherStmtLines();
        if "Applies-to Entry No." <> 0 then
            if "Applied Amount" > 0 then begin
                if not ("Applied Amount" in [0 .. AmtAvailableToApply]) then
                    Error(AmtCannotExceedErr, AmtAvailableToApply, GetRemAmt(), GetAmtAppliedToOtherStmtLines());
            end else
                if not ("Applied Amount" in [AmtAvailableToApply .. 0]) then
                    Error(AmtCannotExceedErr, AmtAvailableToApply, GetRemAmt(), GetAmtAppliedToOtherStmtLines());
    end;

    local procedure UpdateParentBankAccReconLine(IsDelete: Boolean)
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        NewAppliedAmt: Decimal;
    begin
        BankAccReconLine.Get("Statement Type", "Bank Account No.", "Statement No.", "Statement Line No.");

        NewAppliedAmt := GetTotalAppliedAmountInclPmtDisc(IsDelete);

        BankAccReconLine."Applied Entries" := GetNoOfAppliedEntries(IsDelete);

        if IsDelete then begin
            if NewAppliedAmt = 0 then begin
                BankAccReconLine.Validate("Applied Amount", 0);
                BankAccReconLine.Validate("Account No.", '')
            end
        end else
            if BankAccReconLine."Applied Amount" = 0 then begin
                BankAccReconLine.Validate("Account Type", "Account Type");
                BankAccReconLine.Validate("Account No.", "Account No.");
            end else
                CheckApplnIsSameAcc();

        BankAccReconLine.Validate("Applied Amount", NewAppliedAmt);
        OnUpdateParentBankAccReconLineOnBeforeBankAccReconLineModify(Rec, BankAccReconLine, IsDelete);
        BankAccReconLine.Modify();
    end;

    local procedure CheckCurrencyCombination()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendorLedgEntry: Record "Vendor Ledger Entry";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
    begin
        if IsBankLCY() then
            exit;

        if "Applies-to Entry No." = 0 then
            exit;

        case "Account Type" of
            "Account Type"::Customer:
                begin
                    CustLedgEntry.Get("Applies-to Entry No.");
                    if not CurrencyMatches("Bank Account No.", CustLedgEntry."Currency Code", GetLCYCode()) then
                        Error(CurrencyMismatchErr, "Bank Account No.", "Applies-to Entry No.");
                end;
            "Account Type"::Vendor:
                begin
                    VendorLedgEntry.Get("Applies-to Entry No.");
                    if not CurrencyMatches("Bank Account No.", VendorLedgEntry."Currency Code", GetLCYCode()) then
                        Error(CurrencyMismatchErr, "Bank Account No.", "Applies-to Entry No.");
                end;
            "Account Type"::"Bank Account":
                begin
                    BankAccLedgEntry.Get("Applies-to Entry No.");
                    if not CurrencyMatches("Bank Account No.", BankAccLedgEntry."Currency Code", GetLCYCode()) then
                        Error(CurrencyMismatchErr, "Bank Account No.", "Applies-to Entry No.");
                end;
        end;

        OnAfterCheckCurrencyCombination(Rec);
    end;

    local procedure CurrencyMatches(BankAccNo: Code[20]; LedgEntryCurrCode: Code[10]; LCYCode: Code[10]): Boolean
    var
        BankAcc: Record "Bank Account";
        BankAccCurrCode: Code[10];
    begin
        BankAcc.Get(BankAccNo);
        BankAccCurrCode := BankAcc."Currency Code";
        if BankAccCurrCode = '' then
            BankAccCurrCode := LCYCode;
        if LedgEntryCurrCode = '' then
            LedgEntryCurrCode := LCYCode;
        exit(LedgEntryCurrCode = BankAccCurrCode);
    end;

    local procedure IsBankLCY(): Boolean
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get("Bank Account No.");
        exit(BankAcc.IsInLocalCurrency());
    end;

    local procedure GetLCYCode(): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        exit(GLSetup.GetCurrencyCode(''));
    end;

    /// <summary>
    /// Calculates the suggested amount to apply based on remaining amounts and payment application logic.
    /// Takes into account amounts already applied to other statement lines, payment discounts, and document type specific rules.
    /// For credit memos, applies special logic based on account type and amount direction.
    /// </summary>
    /// <returns>Decimal value representing the suggested amount to apply for this payment entry.</returns>
    procedure SuggestAmtToApply(): Decimal
    var
        RemAmtToApply: Decimal;
        LineRemAmtToApply: Decimal;
        IsHandled: Boolean;
        Result: Decimal;
    begin
        IsHandled := false;
        OnBeforeSuggestAmtToApply(Rec, IsHandled, Result);
        if IsHandled then
            exit(Result);

        RemAmtToApply := GetRemAmt() - GetAmtAppliedToOtherStmtLines();
        LineRemAmtToApply := GetStmtLineRemAmtToApply() + "Applied Pmt. Discount";

        if "Account Type" = "Account Type"::Customer then
            if (LineRemAmtToApply >= 0) and ("Document Type" = "Document Type"::"Credit Memo") then
                exit(RemAmtToApply);
        if "Account Type" = "Account Type"::Vendor then
            if (LineRemAmtToApply <= 0) and ("Document Type" = "Document Type"::"Credit Memo") then
                exit(RemAmtToApply);

        exit(
          AbsMin(
            RemAmtToApply,
            LineRemAmtToApply));
    end;

    /// <summary>
    /// Calculates the suggested payment discount amount to apply based on discount terms and timing.
    /// Evaluates payment discount eligibility using due dates, tolerance periods, and applied amounts.
    /// </summary>
    /// <param name="UseAppliedAmt">If true, uses the applied amount for discount calculation; otherwise uses suggested amount.</param>
    /// <returns>Decimal value representing the suggested payment discount amount to apply.</returns>
    procedure SuggestDiscToApply(UseAppliedAmt: Boolean): Decimal
    var
        PmtDiscDueDate: Date;
        PmtDiscToleranceDate: Date;
        RemPmtDiscPossible: Decimal;
    begin
        if InclPmtDisc(UseAppliedAmt) then begin
            GetDiscInfo(PmtDiscDueDate, PmtDiscToleranceDate, RemPmtDiscPossible);
            exit(RemPmtDiscPossible + GetAcceptedPmtTolerance());
        end;
        exit(GetAcceptedPmtTolerance());
    end;

    /// <summary>
    /// Retrieves payment discount information including due dates and remaining discount amounts.
    /// Populates payment discount details from customer or vendor ledger entries based on account type.
    /// </summary>
    /// <param name="PmtDiscDueDate">Payment discount due date when discount expires.</param>
    /// <param name="PmtDiscToleranceDate">Payment discount tolerance date for extended discount period.</param>
    /// <param name="RemPmtDiscPossible">Remaining payment discount amount available for application.</param>
    procedure GetDiscInfo(var PmtDiscDueDate: Date; var PmtDiscToleranceDate: Date; var RemPmtDiscPossible: Decimal)
    begin
        PmtDiscDueDate := 0D;
        RemPmtDiscPossible := 0;

        if "Account No." = '' then
            exit;
        if "Applies-to Entry No." = 0 then
            exit;

        case "Account Type" of
            "Account Type"::Customer:
                GetCustLedgEntryDiscInfo(PmtDiscDueDate, PmtDiscToleranceDate, RemPmtDiscPossible);
            "Account Type"::Vendor:
                GetVendLedgEntryDiscInfo(PmtDiscDueDate, PmtDiscToleranceDate, RemPmtDiscPossible);
        end;

        OnAfterGetDiscInfo(Rec, PmtDiscDueDate, PmtDiscToleranceDate, RemPmtDiscPossible);
    end;

    local procedure GetCustLedgEntryDiscInfo(var PmtDiscDueDate: Date; var PmtDiscToleranceDate: Date; var RemPmtDiscPossible: Decimal)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.Get("Applies-to Entry No.");
        PmtDiscDueDate := CustLedgEntry."Pmt. Discount Date";
        PmtDiscToleranceDate := CustLedgEntry."Pmt. Disc. Tolerance Date";
        if IsBankLCY() and (CustLedgEntry."Currency Code" <> '') then
            RemPmtDiscPossible :=
              Round(CustLedgEntry."Remaining Pmt. Disc. Possible" / CustLedgEntry."Adjusted Currency Factor")
        else
            RemPmtDiscPossible := CustLedgEntry."Remaining Pmt. Disc. Possible";
    end;

    local procedure GetVendLedgEntryDiscInfo(var PmtDiscDueDate: Date; var PmtDiscToleranceDate: Date; var RemPmtDiscPossible: Decimal)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.Get("Applies-to Entry No.");
        PmtDiscDueDate := VendLedgEntry."Pmt. Discount Date";
        PmtDiscToleranceDate := VendLedgEntry."Pmt. Disc. Tolerance Date";
        VendLedgEntry.CalcFields("Amount (LCY)", Amount);
        if IsBankLCY() and (VendLedgEntry."Currency Code" <> '') then
            RemPmtDiscPossible :=
              Round(VendLedgEntry."Remaining Pmt. Disc. Possible" / VendLedgEntry."Adjusted Currency Factor")
        else
            RemPmtDiscPossible := VendLedgEntry."Remaining Pmt. Disc. Possible";
    end;

    /// <summary>
    /// Calculates the remaining amount available for application from the target ledger entry.
    /// Returns different amounts based on account type (Customer, Vendor, Employee, Bank Account) and entry status.
    /// For unassigned entries, returns the statement line remaining amount.
    /// </summary>
    /// <returns>Decimal value representing the remaining amount available for application.</returns>
    procedure GetRemAmt() Result: Decimal
    begin
        if "Account No." = '' then
            exit(0);
        if "Applies-to Entry No." = 0 then
            exit(GetStmtLineRemAmtToApply());

        case "Account Type" of
            "Account Type"::Customer:
                exit(GetCustLedgEntryRemAmt());
            "Account Type"::Vendor:
                exit(GetVendLedgEntryRemAmt());
            "Account Type"::Employee:
                exit(GetEmployeeLedgEntryRemAmt());
            "Account Type"::"Bank Account":
                exit(GetBankAccLedgEntryRemAmt());
        end;

        OnAfterGetRemAmt(Rec, Result);
    end;

    local procedure GetAcceptedPmtTolerance() Result: Decimal
    begin
        if ("Account No." = '') or ("Applies-to Entry No." = 0) then
            exit(0);
        case "Account Type" of
            "Account Type"::Customer:
                exit(GetCustLedgEntryPmtTolAmt());
            "Account Type"::Vendor:
                exit(GetVendLedgEntryPmtTolAmt());
        end;

        OnAfterGetAcceptedPmtTolerance(Rec, Result);
    end;

    local procedure GetCustLedgEntryRemAmt() Result: Decimal
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnGetCustLedgEntryRemAmtOnBeforeCalcFields(Rec, IsHandled, Result);
        if IsHandled then
            exit(Result);

        CustLedgEntry.Get("Applies-to Entry No.");
        if IsBankLCY() and (CustLedgEntry."Currency Code" <> '') then begin
            BankAccReconLine.Get("Statement Type", "Bank Account No.", "Statement No.", "Statement Line No.");
            CustLedgEntry.CalcFields("Remaining Amount");
            exit(
                CurrencyExchRate.ExchangeAmount(
                    CustLedgEntry."Remaining Amount", CustLedgEntry."Currency Code", '', BankAccReconLine."Transaction Date"));
        end;
        CustLedgEntry.CalcFields("Remaining Amount");
        exit(CustLedgEntry."Remaining Amount");
    end;

    local procedure GetVendLedgEntryRemAmt() Result: Decimal
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnGetVendLedgEntryRemAmtOnBeforeCalcFields(Rec, IsHandled, Result);
        if IsHandled then
            exit(Result);

        VendLedgEntry.Get("Applies-to Entry No.");
        if IsBankLCY() and (VendLedgEntry."Currency Code" <> '') then begin
            BankAccReconLine.Get("Statement Type", "Bank Account No.", "Statement No.", "Statement Line No.");
            VendLedgEntry.CalcFields("Remaining Amount");
            exit(
                CurrencyExchRate.ExchangeAmount(
                    VendLedgEntry."Remaining Amount", VendLedgEntry."Currency Code", '', BankAccReconLine."Transaction Date"));
        end;
        VendLedgEntry.CalcFields("Remaining Amount");
        exit(VendLedgEntry."Remaining Amount");
    end;

    local procedure GetEmployeeLedgEntryRemAmt(): Decimal
    var
        EmployeeLedgEntry: Record "Employee Ledger Entry";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        EmployeeLedgEntry.Get("Applies-to Entry No.");
        if IsBankLCY() and (EmployeeLedgEntry."Currency Code" <> '') then begin
            BankAccReconLine.Get("Statement Type", "Bank Account No.", "Statement No.", "Statement Line No.");
            EmployeeLedgEntry.CalcFields("Remaining Amount");
            exit(
                CurrencyExchRate.ExchangeAmount(
                    EmployeeLedgEntry."Remaining Amount", EmployeeLedgEntry."Currency Code", '', BankAccReconLine."Transaction Date"));
        end;
        EmployeeLedgEntry.CalcFields("Remaining Amount");
        exit(EmployeeLedgEntry."Remaining Amount");
    end;

    local procedure GetBankAccLedgEntryRemAmt(): Decimal
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccLedgEntry.Get("Applies-to Entry No.");
        if IsBankLCY() then
            exit(
              Round(
                BankAccLedgEntry."Remaining Amount" *
                BankAccLedgEntry."Amount (LCY)" / BankAccLedgEntry.Amount));
        exit(BankAccLedgEntry."Remaining Amount");
    end;

    local procedure GetCustLedgEntryPmtTolAmt(): Decimal
    var
        BankAccountReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        BankAccountReconciliationLine.Get(Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.", Rec."Statement Line No.");
        CustLedgEntry.SetLoadFields("Applies-to ID", "Accepted Payment Tolerance");
        CustLedgEntry.SetRange("Applies-to ID", BankAccountReconciliationLine.GetAppliesToID());
        if CustLedgEntry.IsEmpty() then
            exit(0);
        CustLedgEntry.CalcSums("Accepted Payment Tolerance");
        exit(CustLedgEntry."Accepted Payment Tolerance");
    end;

    local procedure GetVendLedgEntryPmtTolAmt(): Decimal
    var
        BankAccountReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        BankAccountReconciliationLine.Get(Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.", Rec."Statement Line No.");
        VendorLedgerEntry.SetLoadFields("Applies-to ID", "Accepted Payment Tolerance");
        VendorLedgerEntry.SetRange("Applies-to ID", BankAccountReconciliationLine.GetAppliesToID());
        if VendorLedgerEntry.IsEmpty() then
            exit(0);
        VendorLedgerEntry.CalcSums("Accepted Payment Tolerance");
        exit(VendorLedgerEntry."Accepted Payment Tolerance");
    end;

    /// <summary>
    /// Calculates the remaining amount available on the statement line for payment application.
    /// Considers the difference amount on the bank reconciliation line and any previously applied amounts.
    /// Returns zero if the line difference is already fully allocated.
    /// </summary>
    /// <returns>Decimal value representing the remaining amount available for application on the statement line.</returns>
    procedure GetStmtLineRemAmtToApply(): Decimal
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconLine.Get("Statement Type", "Bank Account No.", "Statement No.", "Statement Line No.");

        if BankAccReconLine.Difference = 0 then
            exit(0);

        exit(BankAccReconLine.Difference + GetOldAppliedAmtInclDisc());
    end;

    local procedure GetOldAppliedAmtInclDisc(): Decimal
    var
        OldAppliedPmtEntry: Record "Applied Payment Entry";
    begin
        OldAppliedPmtEntry := Rec;
        if not OldAppliedPmtEntry.Find() then
            exit(0);
        exit(OldAppliedPmtEntry."Applied Amount" - OldAppliedPmtEntry."Applied Pmt. Discount");
    end;

    local procedure IsAcceptedPmtDiscTolerance() Result: Boolean
    begin
        if ("Account No." = '') or ("Applies-to Entry No." = 0) then
            exit(false);
        case "Account Type" of
            "Account Type"::Customer:
                exit(IsCustLedgEntryPmtDiscTol());
            "Account Type"::Vendor:
                exit(IsVendLedgEntryPmtDiscTol());
        end;

        OnAfterIsAcceptedPmtDiscTolerance(rec, Result);
    end;

    local procedure IsCustLedgEntryPmtDiscTol(): Boolean
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.Get("Applies-to Entry No.");
        exit(CustLedgEntry."Accepted Pmt. Disc. Tolerance");
    end;

    local procedure IsVendLedgEntryPmtDiscTol(): Boolean
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.Get("Applies-to Entry No.");
        exit(VendLedgEntry."Accepted Pmt. Disc. Tolerance");
    end;

    local procedure AbsMin(Amt1: Decimal; Amt2: Decimal): Decimal
    begin
        if Abs(Amt1) < Abs(Amt2) then
            exit(Amt1);
        exit(Amt2)
    end;

    local procedure GetAccInfo()
    begin
        if "Account No." = '' then
            exit;

        case "Account Type" of
            "Account Type"::Customer:
                GetCustInfo();
            "Account Type"::Vendor:
                GetVendInfo();
            "Account Type"::Employee:
                GetEmployeeInfo();
            "Account Type"::"Bank Account":
                GetBankAccInfo();
            "Account Type"::"G/L Account":
                GetGLAccInfo();
        end;
    end;

    local procedure GetCustInfo()
    var
        Cust: Record Customer;
    begin
        Cust.Get("Account No.");
        Description := Cust.Name;
    end;

    local procedure GetVendInfo()
    var
        Vend: Record Vendor;
    begin
        Vend.Get("Account No.");
        Description := Vend.Name;
    end;

    local procedure GetEmployeeInfo()
    var
        Employee: Record Employee;
    begin
        Employee.Get("Account No.");
        Description := Employee.FullName();
    end;

    local procedure GetBankAccInfo()
    var
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get("Account No.");
        Description := BankAcc.Name;
        "Currency Code" := BankAcc."Currency Code";
    end;

    local procedure GetGLAccInfo()
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.Get("Account No.");
        Description := GLAcc.Name;
    end;

    /// <summary>
    /// Retrieves and populates ledger entry information based on the applied entry number and account type.
    /// Loads relevant details from customer, vendor, employee, or bank account ledger entries
    /// into the current applied payment entry record fields.
    /// </summary>
    procedure GetLedgEntryInfo()
    begin
        if "Applies-to Entry No." = 0 then
            exit;

        case "Account Type" of
            "Account Type"::Customer:
                GetCustLedgEntryInfo();
            "Account Type"::Vendor:
                GetVendLedgEntryInfo();
            "Account Type"::Employee:
                GetEmployeeLedgEntryInfo();
            "Account Type"::"Bank Account":
                GetBankAccLedgEntryInfo();
        end;

        OnAfterGetLedgEntryInfo(Rec);
    end;

    local procedure GetCustLedgEntryInfo()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.Get("Applies-to Entry No.");
        Description := CustLedgEntry.Description;
        "Posting Date" := CustLedgEntry."Posting Date";
        "Due Date" := CustLedgEntry."Due Date";
        "Document Type" := CustLedgEntry."Document Type";
        "Document No." := CustLedgEntry."Document No.";
        "External Document No." := CustLedgEntry."External Document No.";
        "Currency Code" := CustLedgEntry."Currency Code";
    end;

    local procedure GetVendLedgEntryInfo()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.Get("Applies-to Entry No.");
        Description := VendLedgEntry.Description;
        "Posting Date" := VendLedgEntry."Posting Date";
        "Due Date" := VendLedgEntry."Due Date";
        "Document Type" := VendLedgEntry."Document Type";
        "Document No." := VendLedgEntry."Document No.";
        "External Document No." := VendLedgEntry."External Document No.";
        "Currency Code" := VendLedgEntry."Currency Code";
    end;

    local procedure GetEmployeeLedgEntryInfo()
    var
        EmployeeLedgEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgEntry.Get("Applies-to Entry No.");
        Description := EmployeeLedgEntry.Description;
        "Posting Date" := EmployeeLedgEntry."Posting Date";
        "Document Type" := EmployeeLedgEntry."Document Type";
        "Document No." := EmployeeLedgEntry."Document No.";
        "Currency Code" := EmployeeLedgEntry."Currency Code";
    end;

    local procedure GetBankAccLedgEntryInfo()
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccLedgEntry.Get("Applies-to Entry No.");
        Description := BankAccLedgEntry.Description;
        "Posting Date" := BankAccLedgEntry."Posting Date";
        "Due Date" := 0D;
        "Document Type" := BankAccLedgEntry."Document Type";
        "Document No." := BankAccLedgEntry."Document No.";
        "External Document No." := BankAccLedgEntry."External Document No.";
        "Currency Code" := BankAccLedgEntry."Currency Code";
    end;

    procedure GetAmtAppliedToOtherStmtLines(): Decimal
    var
        AppliedPmtEntry: Record "Applied Payment Entry";
    begin
        if "Applies-to Entry No." = 0 then
            exit(0);

        AppliedPmtEntry := Rec;
        AppliedPmtEntry.FilterEntryAppliedToOtherStmtLines();
        AppliedPmtEntry.CalcSums("Applied Amount");
        exit(AppliedPmtEntry."Applied Amount");
    end;

    procedure FilterEntryAppliedToOtherStmtLines()
    begin
        Reset();
        SetRange("Statement Type", "Statement Type");
        SetRange("Bank Account No.", "Bank Account No.");
        SetRange("Statement No.", "Statement No.");
        SetFilter("Statement Line No.", '<>%1', "Statement Line No.");
        SetRange("Account Type", "Account Type");
        SetRange("Account No.", "Account No.");
        SetRange("Applies-to Entry No.", "Applies-to Entry No.");
        OnAfterFilterEntryAppliedToOtherStmtLines(Rec);
    end;

    /// <summary>
    /// Sets filters on the applied payment entry table to match a specific bank reconciliation line.
    /// Filters by statement type, bank account number, statement number, and statement line number
    /// to retrieve all payment applications for the specified reconciliation line.
    /// </summary>
    /// <param name="BankAccReconLine">Bank reconciliation line record to filter applied payment entries for.</param>
    procedure FilterAppliedPmtEntry(BankAccReconLine: Record "Bank Acc. Reconciliation Line")
    begin
        Reset();
        SetRange("Statement Type", BankAccReconLine."Statement Type");
        SetRange("Bank Account No.", BankAccReconLine."Bank Account No.");
        SetRange("Statement No.", BankAccReconLine."Statement No.");
        SetRange("Statement Line No.", BankAccReconLine."Statement Line No.");
    end;

    /// <summary>
    /// Checks if applied payment entry lines exist for a specific bank reconciliation line.
    /// Uses FilterAppliedPmtEntry to set appropriate filters and then checks for record existence.
    /// </summary>
    /// <param name="BankAccReconLine">Bank reconciliation line record to check for applied payment entries.</param>
    /// <returns>True if applied payment entries exist for the specified reconciliation line; false otherwise.</returns>
    procedure AppliedPmtEntryLinesExist(BankAccReconLine: Record "Bank Acc. Reconciliation Line"): Boolean
    begin
        FilterAppliedPmtEntry(BankAccReconLine);
        exit(FindSet());
    end;

    /// <summary>
    /// Transfers key identification fields from a bank reconciliation line to this applied payment entry.
    /// Copies statement type, bank account number, statement number, and statement line number
    /// to establish the relationship between the payment entry and its source reconciliation line.
    /// </summary>
    /// <param name="BankAccReconLine">Bank reconciliation line record to transfer identification fields from.</param>
    procedure TransferFromBankAccReconLine(BankAccReconLine: Record "Bank Acc. Reconciliation Line")
    begin
        "Statement Type" := BankAccReconLine."Statement Type";
        "Bank Account No." := BankAccReconLine."Bank Account No.";
        "Statement No." := BankAccReconLine."Statement No.";
        "Statement Line No." := BankAccReconLine."Statement Line No.";
    end;

    /// <summary>
    /// Creates an applied payment entry from bank statement matching buffer results and text mapper amounts.
    /// Initializes a new payment application based on automatic matching results, including account details,
    /// applied amounts, and quality scoring. Handles both regular matching and text-to-account mapping scenarios.
    /// </summary>
    /// <param name="BankAccReconLine">Bank reconciliation line that the payment is being applied to.</param>
    /// <param name="BankStmtMatchingBuffer">Matching buffer containing the identified payment candidate details.</param>
    /// <param name="TextMapperAmount">Amount determined by text-to-account mapping rules; zero if not applicable.</param>
    /// <param name="EntryNo">Entry number of the target ledger entry for application.</param>
    procedure ApplyFromBankStmtMatchingBuf(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; BankStmtMatchingBuffer: Record "Bank Statement Matching Buffer"; TextMapperAmount: Decimal; EntryNo: Integer)
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        Init();
        TransferFromBankAccReconLine(BankAccReconLine);
        Validate("Account Type", BankStmtMatchingBuffer."Account Type");
        Validate("Account No.", BankStmtMatchingBuffer."Account No.");
        if (EntryNo < 0) and (not BankStmtMatchingBuffer."One to Many Match") then begin // text mapper
            Validate("Applies-to Entry No.", 0);
            Validate("Applied Amount", TextMapperAmount);
        end else
            Validate("Applies-to Entry No.", EntryNo);
        Validate(Quality, BankStmtMatchingBuffer.Quality);
        Validate("Match Confidence", BankPmtApplRule.GetMatchConfidence(BankStmtMatchingBuffer.Quality));
        OnApplyFromBankStmtMatchingBufOnBeforeInsert(BankAccReconLine, BankStmtMatchingBuffer, TextMapperAmount, EntryNo, Rec);
        Insert(true);
    end;

    local procedure InclPmtDisc(UseAppliedAmt: Boolean): Boolean
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        PaymentToleranceManagement: Codeunit "Payment Tolerance Management";
        UsePmtDisc: Boolean;
        AmtApplied: Decimal;
        PmtDiscDueDate: Date;
        PmtDiscToleranceDate: Date;
        RemPmtDiscPossible: Decimal;
    begin
        GetDiscInfo(PmtDiscDueDate, PmtDiscToleranceDate, RemPmtDiscPossible);
        if not ("Document Type" in ["Document Type"::"Credit Memo", "Document Type"::Invoice]) then
            exit(false);
        BankAccReconLine.Get("Statement Type", "Bank Account No.", "Statement No.", "Statement Line No.");
        if (BankAccReconLine."Account Type" = BankAccReconLine."Account Type"::"G/L Account") or (BankAccReconLine."Account No." = '') then begin
            BankAccReconLine."Account Type" := "Account Type";
            BankAccReconLine."Account No." := "Account No.";
        end;
        UsePmtDisc := (BankAccReconLine."Transaction Date" <= PmtDiscDueDate) and (RemPmtDiscPossible <> 0);
        if UseAppliedAmt then
            PaymentToleranceManagement.PmtTolPmtReconJnl(BankAccReconLine);
        if (not UsePmtDisc) and (not IsAcceptedPmtDiscTolerance()) then
            exit(false);

        if UseAppliedAmt then
            AmtApplied := "Applied Amount" + GetAmtAppliedToOtherStmtLines()
        else
            AmtApplied := BankAccReconLine.Difference + GetOldAppliedAmtInclDisc() + GetAmtAppliedToOtherStmtLines();

        exit(Abs(AmtApplied) >= Abs(GetRemAmt() - RemPmtDiscPossible - GetAcceptedPmtTolerance()));
    end;

    procedure GetTotalAppliedAmountInclPmtDisc(IsDelete: Boolean): Decimal
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
        TotalAmountIncludingPmtDisc: Decimal;
    begin
        AppliedPaymentEntry.SetRange("Statement Type", "Statement Type");
        AppliedPaymentEntry.SetRange("Statement No.", "Statement No.");
        AppliedPaymentEntry.SetRange("Statement Line No.", "Statement Line No.");
        AppliedPaymentEntry.SetRange("Bank Account No.", "Bank Account No.");
        AppliedPaymentEntry.SetRange("Account Type", "Account Type");
        AppliedPaymentEntry.SetRange("Account No.", "Account No.");
        AppliedPaymentEntry.SetFilter("Applies-to Entry No.", '<>%1', "Applies-to Entry No.");
        OnAfterAppliedPaymentEntryFilterOnGetTotalAppliedAmountInclPmtDisc(AppliedPaymentEntry, Rec);

        if IsDelete then
            TotalAmountIncludingPmtDisc := 0
        else
            TotalAmountIncludingPmtDisc := "Applied Amount" - "Applied Pmt. Discount";

        if AppliedPaymentEntry.FindSet() then
            repeat
                TotalAmountIncludingPmtDisc += AppliedPaymentEntry."Applied Amount";
                TotalAmountIncludingPmtDisc -= AppliedPaymentEntry."Applied Pmt. Discount";
            until AppliedPaymentEntry.Next() = 0;

        exit(TotalAmountIncludingPmtDisc);
    end;

    local procedure GetNoOfAppliedEntries(IsDelete: Boolean): Decimal
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.SetRange("Statement Type", "Statement Type");
        AppliedPaymentEntry.SetRange("Statement No.", "Statement No.");
        AppliedPaymentEntry.SetRange("Statement Line No.", "Statement Line No.");
        AppliedPaymentEntry.SetRange("Bank Account No.", "Bank Account No.");
        AppliedPaymentEntry.SetRange("Account Type", "Account Type");
        AppliedPaymentEntry.SetRange("Account No.", "Account No.");
        AppliedPaymentEntry.SetFilter("Applies-to Entry No.", '<>%1', "Applies-to Entry No.");
        OnAfterAppliedPaymentEntryFiltersGetNoOfAppliedEntries(AppliedPaymentEntry, Rec);

        if IsDelete then
            exit(AppliedPaymentEntry.Count);

        exit(AppliedPaymentEntry.Count + 1);
    end;

    procedure UpdatePaymentDiscount(PaymentDiscountAmount: Decimal)
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        // Payment discount must go to last entry only because of posting
        AppliedPaymentEntry.SetRange("Statement Type", "Statement Type");
        AppliedPaymentEntry.SetRange("Bank Account No.", "Bank Account No.");
        AppliedPaymentEntry.SetRange("Statement No.", "Statement No.");
        AppliedPaymentEntry.SetRange("Account Type", "Account Type");
        AppliedPaymentEntry.SetRange("Applies-to Entry No.", "Applies-to Entry No.");
        AppliedPaymentEntry.SetFilter("Applied Pmt. Discount", '<>0');

        if AppliedPaymentEntry.FindFirst() then
            AppliedPaymentEntry.RemovePaymentDiscount();

        if PaymentDiscountAmount = 0 then
            exit;

        AppliedPaymentEntry.SetRange("Applied Pmt. Discount");

        if AppliedPaymentEntry.FindLast() then
            if "Statement Line No." < AppliedPaymentEntry."Statement Line No." then begin
                AppliedPaymentEntry.SetPaymentDiscount(PaymentDiscountAmount, true);
                exit;
            end;

        SetPaymentDiscount(PaymentDiscountAmount, false);
    end;

    procedure SetPaymentDiscount(PaymentDiscountAmount: Decimal; DifferentLineThanCurrent: Boolean)
    begin
        Validate("Applied Pmt. Discount", PaymentDiscountAmount);

        if DifferentLineThanCurrent then begin
            "Applied Amount" += "Applied Pmt. Discount";
            Modify(true);
        end;
    end;

    procedure RemovePaymentDiscount()
    begin
        "Applied Amount" := "Applied Amount" - "Applied Pmt. Discount";
        "Applied Pmt. Discount" := 0;
        Modify(true);
    end;

    local procedure ClearCustVendEntryApplicationData()
    begin
        if "Applies-to Entry No." = 0 then
            exit;

        case "Account Type" of
            "Account Type"::Customer:
                ClearCustApplicationData("Applies-to Entry No.");
            "Account Type"::Vendor:
                ClearVendApplicationData("Applies-to Entry No.");
            "Account Type"::Employee:
                ClearEmployeeApplicationData("Applies-to Entry No.");
        end;
    end;

    local procedure ClearCustApplicationData(EntryNo: Integer)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.Get(EntryNo);
        CustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
        CustLedgEntry."Accepted Payment Tolerance" := 0;
        CustLedgEntry."Amount to Apply" := 0;
        CustLedgEntry."Applies-to ID" := '';
        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgEntry);
    end;

    local procedure ClearVendApplicationData(EntryNo: Integer)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.Get(EntryNo);
        VendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
        VendLedgEntry."Accepted Payment Tolerance" := 0;
        VendLedgEntry."Amount to Apply" := 0;
        VendLedgEntry."Applies-to ID" := '';
        CODEUNIT.Run(CODEUNIT::"Vend. Entry-Edit", VendLedgEntry);
    end;

    local procedure ClearEmployeeApplicationData(EntryNo: Integer)
    var
        EmployeeLedgEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgEntry.Get(EntryNo);
        EmployeeLedgEntry."Amount to Apply" := 0;
        EmployeeLedgEntry."Applies-to ID" := '';
        CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", EmployeeLedgEntry);
    end;

    procedure CalcAmountToApply(PostingDate: Date) AmountToApply: Decimal
    var
        BankAccount: Record "Bank Account";
        CurrExchRate: Record "Currency Exchange Rate";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        RemainingAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAmountToApply(Rec, PostingDate, AmountToApply, IsHandled);
        if IsHandled then
            exit(AmountToApply);

        BankAccount.Get("Bank Account No.");
        if BankAccount.IsInLocalCurrency() then begin
            AmountToApply :=
              CurrExchRate.ExchangeAmount("Applied Amount", '', "Currency Code", PostingDate);
            case "Account Type" of
                "Account Type"::Customer:
                    begin
                        CustLedgerEntry.Get("Applies-to Entry No.");
                        CustLedgerEntry.CalcFields("Remaining Amount");
                        RemainingAmount := CustLedgerEntry."Remaining Amount";
                    end;
                "Account Type"::Vendor:
                    begin
                        VendorLedgerEntry.Get("Applies-to Entry No.");
                        VendorLedgerEntry.CalcFields("Remaining Amount");
                        RemainingAmount := VendorLedgerEntry."Remaining Amount";
                    end;
                "Account Type"::Employee:
                    begin
                        EmployeeLedgerEntry.Get("Applies-to Entry No.");
                        EmployeeLedgerEntry.CalcFields("Remaining Amount");
                        RemainingAmount := EmployeeLedgerEntry."Remaining Amount";
                    end;
            end;
            if Abs(AmountToApply) > Abs(RemainingAmount) then
                AmountToApply := RemainingAmount;
        end else
            exit("Applied Amount");
        exit(AmountToApply);
    end;

    /// <summary>
    /// Event raised after checking the currency combination for applied payment entries.
    /// </summary>
    /// <param name="AppliedPaymentEntry">The applied payment entry record being validated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckCurrencyCombination(var AppliedPaymentEntry: Record "Applied Payment Entry")
    begin
    end;

    /// <summary>
    /// Event raised after filtering applied payment entries when getting the total applied amount including payment discount.
    /// </summary>
    /// <param name="AppliedPaymentEntry">The applied payment entry record being filtered.</param>
    /// <param name="AppliedPaymentEntryRec">The reference applied payment entry record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAppliedPaymentEntryFilterOnGetTotalAppliedAmountInclPmtDisc(var AppliedPaymentEntry: Record "Applied Payment Entry"; AppliedPaymentEntryRec: Record "Applied Payment Entry")
    begin
    end;

    /// <summary>
    /// Event raised after filtering entries that are applied to other statement lines.
    /// </summary>
    /// <param name="AppliedPaymentEntry">The applied payment entry record being filtered.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterEntryAppliedToOtherStmtLines(var AppliedPaymentEntry: Record "Applied Payment Entry")
    begin
    end;

    /// <summary>
    /// Event raised after getting discount information for an applied payment entry.
    /// </summary>
    /// <param name="AppliedPaymentEntry">The applied payment entry record.</param>
    /// <param name="PmtDiscDueDate">The payment discount due date.</param>
    /// <param name="PmtDiscToleranceDate">The payment discount tolerance date.</param>
    /// <param name="RemPmtDiscPossible">The remaining payment discount possible amount.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDiscInfo(var AppliedPaymentEntry: Record "Applied Payment Entry"; var PmtDiscDueDate: Date; var PmtDiscToleranceDate: Date; var RemPmtDiscPossible: Decimal)
    begin
    end;

    /// <summary>
    /// Event raised before checking if the current match exists for an existing application.
    /// </summary>
    /// <param name="ExistingAppliedPmtEntry">The existing applied payment entry record.</param>
    /// <param name="IsHandled">Indicates whether the event has been handled.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCurrentMatchesExistingAppln(ExistingAppliedPmtEntry: Record "Applied Payment Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event raised after applying filters on applied payment entries to get the number of applied entries.
    /// </summary>
    /// <param name="AppliedPaymentEntry">The applied payment entry record being filtered.</param>
    /// <param name="AppliedPaymentEntryRec">The reference applied payment entry record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAppliedPaymentEntryFiltersGetNoOfAppliedEntries(var AppliedPaymentEntry: Record "Applied Payment Entry"; AppliedPaymentEntryRec: Record "Applied Payment Entry")
    begin
    end;

    /// <summary>
    /// Event raised after getting the accepted payment tolerance for an applied payment entry.
    /// </summary>
    /// <param name="AppliedPaymentEntry">The applied payment entry record.</param>
    /// <param name="Result">The calculated payment tolerance result.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAcceptedPmtTolerance(AppliedPaymentEntry: Record "Applied Payment Entry"; var Result: Decimal)
    begin
    end;

    /// <summary>
    /// Event raised after checking if the payment discount tolerance is accepted for an applied payment entry.
    /// </summary>
    /// <param name="AppliedPaymentEntry">The applied payment entry record.</param>
    /// <param name="Result">Indicates whether the payment discount tolerance is accepted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterIsAcceptedPmtDiscTolerance(AppliedPaymentEntry: Record "Applied Payment Entry"; var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Event raised after looking up the applies-to entry number for an applied payment entry.
    /// </summary>
    /// <param name="AppliedPaymentEntry">The applied payment entry record being updated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupAppliesToEntryNo(var AppliedPaymentEntry: Record "Applied Payment Entry")
    begin
    end;

    /// <summary>
    /// Event raised after getting ledger entry information for an applied payment entry.
    /// </summary>
    /// <param name="AppliedPaymentEntry">The applied payment entry record being updated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLedgEntryInfo(var AppliedPaymentEntry: Record "Applied Payment Entry")
    begin
    end;

    /// <summary>
    /// Event raised after getting the remaining amount for an applied payment entry.
    /// </summary>
    /// <param name="AppliedPaymentEntry">The applied payment entry record.</param>
    /// <param name="Result">The calculated remaining amount.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRemAmt(AppliedPaymentEntry: Record "Applied Payment Entry"; var Result: Decimal)
    begin
    end;

    /// <summary>
    /// Event raised before calculating the amount to apply for an applied payment entry.
    /// </summary>
    /// <param name="AppliedPaymentEntry">The applied payment entry record.</param>
    /// <param name="PostingDate">The posting date for the calculation.</param>
    /// <param name="AmountToApply">The calculated amount to apply.</param>
    /// <param name="IsHandled">Indicates whether the event has been handled.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAmountToApply(var AppliedPaymentEntry: Record "Applied Payment Entry"; PostingDate: Date; var AmountToApply: Decimal; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Event raised when updating the parent bank account reconciliation line before modifying the bank account reconciliation line record.
    /// </summary>
    /// <param name="AppliedPaymentEntry">The applied payment entry record.</param>
    /// <param name="BankAccReconciliationLine">The bank account reconciliation line record being modified.</param>
    /// <param name="IsDelete">Indicates whether this is a delete operation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateParentBankAccReconLineOnBeforeBankAccReconLineModify(var AppliedPaymentEntry: Record "Applied Payment Entry"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; IsDelete: Boolean)
    begin
    end;

    /// <summary>
    /// Event raised when applying from bank statement matching buffer before inserting the applied payment entry.
    /// </summary>
    /// <param name="BankAccReconLine">The bank account reconciliation line record.</param>
    /// <param name="BankStmtMatchingBuffer">The bank statement matching buffer record.</param>
    /// <param name="TextMapperAmount">The text mapper amount.</param>
    /// <param name="EntryNo">The entry number.</param>
    /// <param name="AppliedPaymentEntry">The applied payment entry record being inserted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnApplyFromBankStmtMatchingBufOnBeforeInsert(BankAccReconLine: Record "Bank Acc. Reconciliation Line"; BankStmtMatchingBuffer: Record "Bank Statement Matching Buffer"; TextMapperAmount: Decimal; EntryNo: Integer; var AppliedPaymentEntry: Record "Applied Payment Entry")
    begin
    end;

    /// <summary>
    /// Event raised when getting customer ledger entry remaining amount before calculating fields.
    /// </summary>
    /// <param name="AppliedPaymentEntry">The applied payment entry record.</param>
    /// <param name="IsHandled">Indicates whether the event has been handled.</param>
    /// <param name="Result">The remaining amount result if handled.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetCustLedgEntryRemAmtOnBeforeCalcFields(AppliedPaymentEntry: Record "Applied Payment Entry"; var IsHandled: Boolean; var Result: Decimal)
    begin
    end;

    /// <summary>
    /// Event raised when getting vendor ledger entry remaining amount before calculating fields.
    /// </summary>
    /// <param name="AppliedPaymentEntry">The applied payment entry record.</param>
    /// <param name="IsHandled">Indicates whether the event has been handled.</param>
    /// <param name="Result">The remaining amount result if handled.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetVendLedgEntryRemAmtOnBeforeCalcFields(AppliedPaymentEntry: Record "Applied Payment Entry"; var IsHandled: Boolean; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSuggestAmtToApply(var AppliedPaymentEntry: Record "Applied Payment Entry"; var IsHandled: Boolean; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAppliesToEntryNoLookup(var AppliedPaymentEntry: Record "Applied Payment Entry"; var IsHandled: boolean)
    begin
    end;
}
