// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

table 1293 "Payment Application Proposal"
{
    Caption = 'Payment Application Proposal';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Bank Acc. Reconciliation"."Statement No." where("Bank Account No." = field("Bank Account No."),
                                                                              "Statement Type" = field("Statement Type"));
        }
        field(3; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
        }
        field(20; "Statement Type"; Enum "Bank Acc. Rec. Stmt. Type")
        {
            Caption = 'Statement Type';
        }
        field(21; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';

            trigger OnValidate()
            begin
                VerifyLineIsNotApplied();
            end;
        }
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
                VerifyLineIsNotApplied();
            end;
        }
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
        }
        field(24; "Applied Amount"; Decimal)
        {
            Caption = 'Applied Amount';
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                if ("Applied Amount" = 0) and (xRec."Applied Amount" <> 0) then
                    Unapply()
                else
                    UpdateAppliedAmt();
            end;
        }
        field(25; Applied; Boolean)
        {
            Caption = 'Applied';

            trigger OnValidate()
            var
                BankAccReconLine: Record "Bank Acc. Reconciliation Line";
            begin
                if xRec.Applied = Applied then
                    exit;

                if not Applied then
                    Unapply();

                if Applied then begin
                    if "Document Type" = "Document Type"::"Credit Memo" then
                        CrMemoSelectedToApply()
                    else begin
                        BankAccReconLine.Get("Statement Type", "Bank Account No.", "Statement No.", "Statement Line No.");
                        if BankAccReconLine.Difference = 0 then
                            Error(PaymentAppliedErr);
                        ValidateEntryNotApplied(Rec, BankAccReconLine);
                    end;
                    Apply(GetRemainingAmountAfterPosting(), "Applies-to Entry No." <> 0);
                end;
            end;
        }
        field(29; "Applied Pmt. Discount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Applied Pmt. Discount';
            AutoFormatType = 1;
        }
        field(30; Quality; Integer)
        {
            Caption = 'Quality';
        }
        field(31; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(32; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(33; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(34; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(35; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(36; "Due Date"; Date)
        {
            Caption = 'Due Date';
            Editable = false;
        }
        field(37; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(50; "Match Confidence"; Enum "Bank Rec. Match Confidence")
        {
            Caption = 'Match Confidence';
            Editable = false;
            InitValue = "None";
        }
        field(51; "Pmt. Disc. Due Date"; Date)
        {
            Caption = 'Pmt. Disc. Due Date';

            trigger OnValidate()
            begin
                ChangeDiscountAmounts();
            end;
        }
        field(52; "Remaining Pmt. Disc. Possible"; Decimal)
        {
            Caption = 'Remaining Pmt. Disc. Possible';
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                ChangeDiscountAmounts();
            end;
        }
        field(53; "Pmt. Disc. Tolerance Date"; Date)
        {
            Caption = 'Pmt. Disc. Tolerance Date';

            trigger OnValidate()
            begin
                ChangeDiscountAmounts();
            end;
        }
        field(60; "Applied Amt. Incl. Discount"; Decimal)
        {
            Caption = 'Applied Amt. Incl. Discount';
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;

            trigger OnValidate()
            begin
                if ("Applied Amt. Incl. Discount" = 0) and Applied then
                    Unapply()
                else
                    Validate("Applied Amount", "Applied Amt. Incl. Discount");
            end;
        }
        field(61; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
            Editable = false;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
        }
        field(62; "Remaining Amt. Incl. Discount"; Decimal)
        {
            Caption = 'Remaining Amt. Incl. Discount';
            Editable = false;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
        }
        field(63; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Bank Account Ledger Entry,Check Ledger Entry';
            OptionMembers = "Bank Account Ledger Entry","Check Ledger Entry";
        }
        field(100; "Sorting Order"; Integer)
        {
            Caption = 'Sorting Order';
            Editable = false;
        }
        field(101; "Stmt To Rem. Amount Difference"; Decimal)
        {
            Caption = 'Stmt To Rem. Amount Difference';
            Editable = false;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
        }
    }

    keys
    {
        key(Key1; "Statement Type", "Bank Account No.", "Statement No.", "Statement Line No.", "Account Type", "Account No.", "Applies-to Entry No.")
        {
            Clustered = true;
        }
        key(Key2; Applied, Quality)
        {
        }
        key(Key3; "Sorting Order")
        {
        }
        key(Key4; Applied, "Account Type", "Account No.", Type)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField("Applies-to Entry No.", 0);
        if Applied then
            Unapply();
    end;

    trigger OnInsert()
    begin
        UpdateSortingOrder();
    end;

    trigger OnModify()
    begin
        UpdateSortingOrder();
    end;

    trigger OnRename()
    begin
        VerifyLineIsNotApplied();
    end;

    var
        StmtAmtIsFullyAppliedErr: Label 'The statement amount is already fully applied.';
        EntryDoesntExistErr: Label 'The entry does not exist.';
        CannotChangeAppliedLineErr: Label 'You cannot change the line because the entry is applied. Remove the applied entry first.';
        TransactionDateIsBeforePostingDateMsg: Label 'The transaction date %1 is before the posting date %2.', Comment = '%1 Transaction Date; %2: Posting Date';
        PaymentAppliedErr: Label 'The payment is fully applied. To apply the payment to this entry, you must first unapply the payment from another entry.';
        WantToApplyCreditMemoAndInvoicesMsg: Label 'If you want to apply credit memos and invoices, we recommend that you start by applying credit memos and then apply all others entries.';
        EntryAlreadyHasAnApplicationErr: Label 'This entry has an ongoing application process ''%1'', it is applied in another journal. Process this journal before proceeding.', Comment = '%1 a code for the payment application process';

    local procedure Unapply()
    var
        AppliedPmtEntry: Record "Applied Payment Entry";
    begin
        if not GetAppliedPaymentEntry(AppliedPmtEntry) then
            Error(EntryDoesntExistErr);

        AppliedPmtEntry.Delete(true);

        TransferFields(AppliedPmtEntry, false);
        Applied := false;

        "Applied Amt. Incl. Discount" := 0;

        Modify(true);
    end;

    local procedure UpdateAppliedAmt()
    var
        AmountToApply: Decimal;
    begin
        AmountToApply := "Applied Amount";
        if Applied then
            Unapply();

        if AmountToApply = 0 then
            exit;

        Apply(AmountToApply, false);
    end;

    procedure GetAppliedPaymentEntry(var AppliedPaymentEntry: Record "Applied Payment Entry"): Boolean
    begin
        exit(
          AppliedPaymentEntry.Get(
            "Statement Type", "Bank Account No.",
            "Statement No.", "Statement Line No.",
            "Account Type", "Account No.", "Applies-to Entry No."));
    end;

    local procedure GetLedgEntryInfo()
    var
        TempAppliedPmtEntry: Record "Applied Payment Entry" temporary;
    begin
        TempAppliedPmtEntry.TransferFields(Rec);
        TempAppliedPmtEntry.GetLedgEntryInfo();
        TransferFields(TempAppliedPmtEntry);
    end;

    procedure TransferFromBankAccReconLine(BankAccReconLine: Record "Bank Acc. Reconciliation Line")
    begin
        "Statement Type" := BankAccReconLine."Statement Type";
        "Bank Account No." := BankAccReconLine."Bank Account No.";
        "Statement No." := BankAccReconLine."Statement No.";
        "Statement Line No." := BankAccReconLine."Statement Line No.";
    end;

    procedure CreateFromAppliedPaymentEntry(AppliedPaymentEntry: Record "Applied Payment Entry")
    var
        BankAccount: Record "Bank Account";
    begin
        Init();
        TransferFields(AppliedPaymentEntry);
        UpdatePaymentDiscInfo();

        if AppliedPaymentEntry."Applied Amount" <> 0 then
            Applied := true;

        BankAccount.Get(AppliedPaymentEntry."Bank Account No.");

        UpdateDefaultCalculatedFields(BankAccount, AppliedPaymentEntry."Applies-to Entry No.");
        "Applied Amt. Incl. Discount" := "Applied Amount" - "Applied Pmt. Discount";
        Insert(true);
    end;

    procedure CreateFromBankStmtMacthingBuffer(TempBankStmtMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccount: Record "Bank Account")
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        Init();
        "Account Type" := TempBankStmtMatchingBuffer."Account Type";
        "Account No." := TempBankStmtMatchingBuffer."Account No.";

        if TempBankStmtMatchingBuffer."Entry No." < 0 then
            "Applies-to Entry No." := 0
        else
            "Applies-to Entry No." := TempBankStmtMatchingBuffer."Entry No.";

        GetLedgEntryInfo();
        Quality := TempBankStmtMatchingBuffer.Quality;
        "Match Confidence" :=
            Enum::"Bank Rec. Match Confidence".FromInteger(BankPmtApplRule.GetMatchConfidence(TempBankStmtMatchingBuffer.Quality));

        UpdateDefaultCalculatedFields(BankAccount, Rec."Applies-to Entry No.");

        "Stmt To Rem. Amount Difference" := Abs(BankAccReconciliationLine."Statement Amount" - "Remaining Amount");
        "Applied Amt. Incl. Discount" := "Applied Amount" - "Applied Pmt. Discount";

        OnAfterCreateFromBankStmtMacthingBuffer(Rec, TempBankStmtMatchingBuffer, BankAccReconciliationLine, BankAccount);
    end;

    procedure UpdateDefaultCalculatedFields(var BankAccount: Record "Bank Account"; AppliesToEntryNo: Integer)
    begin
        UpdatePaymentDiscInfo();
        UpdateRemainingAmount(BankAccount);
        UpdateRemainingAmountExclDiscount();

        if AppliesToEntryNo > 0 then
            UpdateTypeOption(AppliesToEntryNo);
    end;

    local procedure UpdateSortingOrder()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        "Sorting Order" := -Quality;
        if Applied then
            "Sorting Order" -= BankPmtApplRule.GetHighestPossibleScore();
    end;

    local procedure Apply(AmtToApply: Decimal; SuggestDiscAmt: Boolean)
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        MatchBankPayments: Codeunit "Match Bank Payments";
        ShowMessage: Boolean;
    begin
        AppliedPaymentEntry.TransferFields(Rec);
        BankAccReconciliationLine.Get(
          AppliedPaymentEntry."Statement Type", AppliedPaymentEntry."Bank Account No.",
          AppliedPaymentEntry."Statement No.", AppliedPaymentEntry."Statement Line No.");
        MatchBankPayments.SetApplicationDataInCVLedgEntry(
          "Account Type", "Applies-to Entry No.", BankAccReconciliationLine.GetAppliesToID());

        if AmtToApply = 0 then
            Error(StmtAmtIsFullyAppliedErr);

        if SuggestDiscAmt then
            AppliedPaymentEntry.Validate("Applies-to Entry No.")
        else
            AppliedPaymentEntry.Validate("Applied Amount", AmtToApply);

        AppliedPaymentEntry.Insert(true);

        TransferFields(AppliedPaymentEntry);
        Applied := true;
        UpdateRemainingAmountExclDiscount();
        "Applied Amt. Incl. Discount" := "Applied Amount" - "Applied Pmt. Discount";
        Modify(true);

        if BankAccReconciliationLine."Transaction Date" < "Posting Date" then begin
            ShowMessage := true;
            OnApplyOnBeforeShowMessage(BankAccReconciliationLine, "Posting Date", ShowMessage);
            if ShowMessage then
                Message(StrSubstNo(TransactionDateIsBeforePostingDateMsg, BankAccReconciliationLine."Transaction Date", "Posting Date"));
        end;
    end;

    procedure GetRemainingAmountAfterPostingValue(): Decimal
    begin
        if "Applies-to Entry No." = 0 then
            exit(0);

        exit(GetRemainingAmountAfterPosting());
    end;

    local procedure GetRemainingAmountAfterPosting(): Decimal
    var
        TempAppliedPaymentEntry: Record "Applied Payment Entry" temporary;
    begin
        TempAppliedPaymentEntry.TransferFields(Rec);
        exit(
          TempAppliedPaymentEntry.GetRemAmt() -
          TempAppliedPaymentEntry."Applied Amount" -
          TempAppliedPaymentEntry.GetAmtAppliedToOtherStmtLines());
    end;

    procedure RemoveApplications()
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
    begin
        TempPaymentApplicationProposal := Rec;

        AddFilterOnAppliedPmtEntry(AppliedPaymentEntry);

        if AppliedPaymentEntry.FindSet() then
            repeat
                Get(
                  AppliedPaymentEntry."Statement Type", AppliedPaymentEntry."Bank Account No.",
                  AppliedPaymentEntry."Statement No.", AppliedPaymentEntry."Statement Line No.",
                  AppliedPaymentEntry."Account Type", AppliedPaymentEntry."Account No.",
                  AppliedPaymentEntry."Applies-to Entry No.");
                Unapply();
            until AppliedPaymentEntry.Next() = 0;

        Rec := TempPaymentApplicationProposal;
    end;

    procedure AccountNameDrillDown()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        AccountType: Enum "Gen. Journal Account Type";
        AccountNo: Code[20];
    begin
        AccountType := GetAppliedToAccountType();
        AccountNo := GetAppliedToAccountNo();
        case AccountType of
            "Account Type"::Customer:
                begin
                    Customer.Get(AccountNo);
                    PAGE.Run(PAGE::"Customer Card", Customer);
                end;
            "Account Type"::Vendor:
                begin
                    Vendor.Get(AccountNo);
                    PAGE.Run(PAGE::"Vendor Card", Vendor);
                end;
            "Account Type"::Employee:
                begin
                    Employee.Get(AccountNo);
                    PAGE.Run(PAGE::"Employee Card", Employee);
                end;
            "Account Type"::"G/L Account":
                begin
                    GLAccount.Get(AccountNo);
                    PAGE.Run(PAGE::"G/L Account Card", GLAccount);
                end;
            "Account Type"::"Bank Account":
                begin
                    BankAccount.Get(AccountNo);
                    PAGE.Run(PAGE::"Bank Account Card", BankAccount);
                end;
        end;
    end;

    procedure GetAccountName(): Text
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        AccountType: Enum "Gen. Journal Account Type";
        AccountNo: Code[20];
        Name: Text;
    begin
        AccountType := GetAppliedToAccountType();
        AccountNo := GetAppliedToAccountNo();
        Name := '';

        case AccountType of
            "Account Type"::Customer:
                if Customer.Get(AccountNo) then
                    Name := Customer.Name;
            "Account Type"::Vendor:
                if Vendor.Get(AccountNo) then
                    Name := Vendor.Name;
            "Account Type"::Employee:
                if Employee.Get(AccountNo) then
                    Name := Employee.FullName();
            "Account Type"::"G/L Account":
                if GLAccount.Get(AccountNo) then
                    Name := GLAccount.Name;
            "Account Type"::"Bank Account":
                if BankAccount.Get(AccountNo) then
                    Name := BankAccount.Name;
        end;

        exit(Name);
    end;

    local procedure GetAppliedToAccountType(): Enum "Gen. Journal Account Type"
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if "Account Type" = "Account Type"::"Bank Account" then
            if BankAccountLedgerEntry.Get("Applies-to Entry No.") then
                exit(BankAccountLedgerEntry."Bal. Account Type");
        exit("Account Type");
    end;

    local procedure GetAppliedToAccountNo(): Code[20]
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if "Account Type" = "Account Type"::"Bank Account" then
            if BankAccountLedgerEntry.Get("Applies-to Entry No.") then
                exit(BankAccountLedgerEntry."Bal. Account No.");
        exit("Account No.");
    end;

    local procedure ChangeDiscountAmounts()
    begin
        UpdateLedgEntryDisc();
        UpdateRemainingAmountExclDiscount();

        if "Applied Pmt. Discount" <> 0 then begin
            "Applied Amount" -= "Applied Pmt. Discount";
            "Applied Pmt. Discount" := 0;
        end;

        UpdateAppliedAmt();
    end;

    local procedure UpdateLedgEntryDisc()
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        AppliedPmtEntry: Record "Applied Payment Entry";
        BankAccReconPost: Codeunit "Bank Acc. Reconciliation Post";
    begin
        TestField("Applies-to Entry No.");
        AppliedPmtEntry.TransferFields(Rec);
        BankAccReconLine.Get("Statement Type", "Bank Account No.", "Statement No.", "Statement Line No.");

        case "Account Type" of
            "Account Type"::Customer:
                BankAccReconPost.ApplyCustLedgEntry(
                  AppliedPmtEntry, '', BankAccReconLine."Transaction Date",
                  "Pmt. Disc. Due Date", "Pmt. Disc. Tolerance Date", "Remaining Pmt. Disc. Possible");
            "Account Type"::Vendor:
                BankAccReconPost.ApplyVendLedgEntry(
                  AppliedPmtEntry, '', BankAccReconLine."Transaction Date",
                  "Pmt. Disc. Due Date", "Pmt. Disc. Tolerance Date", "Remaining Pmt. Disc. Possible");
        end;
    end;

    local procedure UpdateRemainingAmountExclDiscount()
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        "Remaining Amt. Incl. Discount" := "Remaining Amount";

        if not ("Document Type" in ["Document Type"::"Credit Memo", "Document Type"::Invoice]) then
            exit;

        BankAccReconLine.Get("Statement Type", "Bank Account No.", "Statement No.", "Statement Line No.");
        if BankAccReconLine."Transaction Date" > "Pmt. Disc. Due Date" then
            exit;

        "Remaining Amt. Incl. Discount" -= "Remaining Pmt. Disc. Possible";
    end;

    local procedure UpdateRemainingAmount(BankAccount: Record "Bank Account")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        EmployeeLedgEntry: Record "Employee Ledger Entry";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        RemainingAmount: Decimal;
        RemainingAmountLCY: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateRemainingAmount(Rec, BankAccount, IsHandled);
        if IsHandled then
            exit;

        "Remaining Amount" := 0;

        if "Applies-to Entry No." = 0 then
            exit;

        case "Account Type" of
            "Account Type"::"Bank Account":
                begin
                    BankAccLedgEntry.SetRange(Open, true);
                    BankAccLedgEntry.SetRange("Bank Account No.", "Account No.");
                    BankAccLedgEntry.Get("Applies-to Entry No.");
                    "Remaining Amount" := BankAccLedgEntry."Remaining Amount";
                    exit;
                end;
            "Account Type"::Customer:
                begin
                    CustLedgEntry.SetRange(Open, true);
                    CustLedgEntry.SetRange("Customer No.", "Account No.");
                    CustLedgEntry.SetAutoCalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                    CustLedgEntry.Get("Applies-to Entry No.");

                    RemainingAmount := CustLedgEntry."Remaining Amount";
                    RemainingAmountLCY := CustLedgEntry."Remaining Amt. (LCY)";
                end;
            "Account Type"::Vendor:
                begin
                    VendLedgEntry.SetRange(Open, true);
                    VendLedgEntry.SetRange("Vendor No.", "Account No.");
                    VendLedgEntry.SetAutoCalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                    VendLedgEntry.Get("Applies-to Entry No.");

                    RemainingAmount := VendLedgEntry."Remaining Amount";
                    RemainingAmountLCY := VendLedgEntry."Remaining Amt. (LCY)";
                end;
            "Account Type"::Employee:
                begin
                    EmployeeLedgEntry.SetRange(Open, true);
                    EmployeeLedgEntry.SetRange("Employee No.", "Account No.");
                    EmployeeLedgEntry.SetAutoCalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                    EmployeeLedgEntry.Get("Applies-to Entry No.");

                    RemainingAmount := EmployeeLedgEntry."Remaining Amount";
                    RemainingAmountLCY := EmployeeLedgEntry."Remaining Amt. (LCY)";
                end;
        end;

        if BankAccount.IsInLocalCurrency() then
            "Remaining Amount" := RemainingAmountLCY
        else
            "Remaining Amount" := RemainingAmount;
    end;

    local procedure UpdatePaymentDiscInfo()
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.TransferFields(Rec);
        AppliedPaymentEntry.GetDiscInfo("Pmt. Disc. Due Date", "Pmt. Disc. Tolerance Date", "Remaining Pmt. Disc. Possible");
        if "Remaining Pmt. Disc. Possible" = 0 then begin
            "Pmt. Disc. Due Date" := 0D;
            "Pmt. Disc. Tolerance Date" := 0D;
        end;
    end;

    local procedure VerifyLineIsNotApplied()
    begin
        if Applied then
            Error(CannotChangeAppliedLineErr);
    end;

    procedure AppliesToEntryNoDrillDown()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        EmployeeLedgEntry: Record "Employee Ledger Entry";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        GLEntry: Record "G/L Entry";
    begin
        if "Applies-to Entry No." = 0 then
            exit;

        case "Account Type" of
            "Account Type"::"G/L Account":
                begin
                    GLEntry.SetRange("G/L Account No.", "Account No.");
                    PAGE.RunModal(0, GLEntry);
                end;
            "Account Type"::Customer:
                begin
                    CustLedgEntry.SetRange(Open, true);
                    CustLedgEntry.SetRange("Customer No.", "Account No.");
                    CustLedgEntry.Get("Applies-to Entry No.");
                    PAGE.RunModal(0, CustLedgEntry);
                end;
            "Account Type"::Vendor:
                begin
                    VendLedgEntry.SetRange(Open, true);
                    VendLedgEntry.SetRange("Vendor No.", "Account No.");
                    VendLedgEntry.Get("Applies-to Entry No.");
                    PAGE.RunModal(0, VendLedgEntry);
                end;
            "Account Type"::Employee:
                begin
                    EmployeeLedgEntry.SetRange(Open, true);
                    EmployeeLedgEntry.SetRange("Employee No.", "Account No.");
                    EmployeeLedgEntry.Get("Applies-to Entry No.");
                    PAGE.RunModal(0, EmployeeLedgEntry);
                end;
            "Account Type"::"Bank Account":
                begin
                    BankAccLedgEntry.SetRange(Open, true);
                    BankAccLedgEntry.SetRange("Bank Account No.", "Account No.");
                    BankAccLedgEntry.Get("Applies-to Entry No.");
                    PAGE.RunModal(0, BankAccLedgEntry);
                end;
        end;
    end;

    local procedure CrMemoSelectedToApply()
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AddFilterOnAppliedPmtEntry(AppliedPaymentEntry);
        if AppliedPaymentEntry.Count > 0 then begin
            AppliedPaymentEntry.SetRange("Document Type", "Document Type"::"Credit Memo");
            if AppliedPaymentEntry.Count = 0 then
                Message(WantToApplyCreditMemoAndInvoicesMsg);
        end;
    end;

    local procedure AddFilterOnAppliedPmtEntry(var AppliedPaymentEntry: Record "Applied Payment Entry")
    begin
        AppliedPaymentEntry.SetRange("Statement Type", "Statement Type");
        AppliedPaymentEntry.SetRange("Bank Account No.", "Bank Account No.");
        AppliedPaymentEntry.SetRange("Statement No.", "Statement No.");
        AppliedPaymentEntry.SetRange("Statement Line No.", "Statement Line No.");
    end;

    local procedure UpdateTypeOption(EntryNo: Integer)
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetRange("Bank Account Ledger Entry No.", EntryNo);
        if CheckLedgerEntry.FindFirst() then
            Type := Type::"Check Ledger Entry"
        else
            Type := Type::"Bank Account Ledger Entry";
    end;

    local procedure AppliesToIDHasDifferentPrefixAndItsNotEmpty(AppliesToID: Code[50]; AppliesToIDPrefix: Code[50]): Boolean
    begin
        if AppliesToID = '' then
            exit(false);
        exit(CopyStr(AppliestoID, 1, StrLen(AppliesToIDPrefix)) <> AppliesToIDPrefix);
    end;

    local procedure ValidateEntryNotApplied(var PaymentApplicationProposal: Record "Payment Application Proposal"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        AppliesToIDPrefix: Code[50];
    begin
        AppliesToIDPrefix := BankAccReconciliationLine.GetAppliesToIDForBankStatement();
        case PaymentApplicationProposal."Account Type" of
            PaymentApplicationProposal."Account Type"::Customer:
                if CustLedgerEntry.Get(PaymentApplicationProposal."Applies-to Entry No.") then
                    if AppliesToIDHasDifferentPrefixAndItsNotEmpty(CustLedgerEntry."Applies-to ID", AppliesToIDPrefix) then
                        Error(EntryAlreadyHasAnApplicationErr, CustLedgerEntry."Applies-to ID");
            PaymentApplicationProposal."Account Type"::Vendor:
                if VendorLedgerEntry.Get(PaymentApplicationProposal."Applies-to Entry No.") then
                    if AppliesToIDHasDifferentPrefixAndItsNotEmpty(VendorLedgerEntry."Applies-to ID", AppliesToIDPrefix) then
                        Error(EntryAlreadyHasAnApplicationErr, VendorLedgerEntry."Applies-to ID");
            PaymentApplicationProposal."Account Type"::Employee:
                if EmployeeLedgerEntry.Get(PaymentApplicationProposal."Applies-to Entry No.") then
                    if AppliesToIDHasDifferentPrefixAndItsNotEmpty(EmployeeLedgerEntry."Applies-to ID", AppliesToIDPrefix) then
                        Error(EntryAlreadyHasAnApplicationErr, EmployeeLedgerEntry."Applies-to ID");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateFromBankStmtMacthingBuffer(var PaymentApplicationProposal: Record "Payment Application Proposal"; TempBankStmtMatchingBuffer: Record "Bank Statement Matching Buffer" temporary; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccount: Record "Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRemainingAmount(var PaymentApplicationProposal: Record "Payment Application Proposal"; BankAccount: Record "Bank Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyOnBeforeShowMessage(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; PostingDate: Date; var ShowMessage: Boolean)
    begin
    end;
}

