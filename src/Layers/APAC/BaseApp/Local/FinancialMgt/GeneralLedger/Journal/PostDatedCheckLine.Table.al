// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;

table 28090 "Post Dated Check Line"
{
    Caption = 'Post Dated Check Line';
    LookupPageID = "Post Dated Checks List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line Number"; Integer)
        {
            AutoIncrement = false;
            Caption = 'Line Number';
            Editable = false;
            //This property is currently not supported
            //TestTableRelation = true;
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = true;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(9; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = ' ,Customer,Vendor,G/L Account';
            OptionMembers = " ",Customer,Vendor,"G/L Account";
        }
        field(10; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor;

            trigger OnValidate()
            begin
                case "Account Type" of
                    "Account Type"::Customer:
                        begin
                            Customer.Get("Account No.");
                            Description := Customer.Name;
                            SalesSetup.Get();
                            SalesSetup.TestField("Post Dated Check Batch");
                            SalesSetup.TestField("Post Dated Check Template");
                            "Batch Name" := SalesSetup."Post Dated Check Batch";
                            "Template Name" := SalesSetup."Post Dated Check Template";
                            JnlBatch.Get(SalesSetup."Post Dated Check Template", SalesSetup."Post Dated Check Batch");
                            JnlBatch.SetRange("Journal Template Name", SalesSetup."Post Dated Check Template");
                            JnlBatch.SetRange(Name, SalesSetup."Post Dated Check Batch");
                            "Bank Account" := JnlBatch."Bal. Account No.";
                        end;
                    "Account Type"::Vendor:
                        begin
                            Vendor.Get("Account No.");
                            Description := Vendor.Name;
                            PurchSetup.Get();
                            PurchSetup.TestField("Post Dated Check Batch");
                            PurchSetup.TestField("Post Dated Check Template");
                            if "Batch Name" = '' then
                                "Batch Name" := PurchSetup."Post Dated Check Batch";
                            "Template Name" := PurchSetup."Post Dated Check Template";
                            JnlBatch.Get(PurchSetup."Post Dated Check Template", PurchSetup."Post Dated Check Batch");
                            JnlBatch.SetRange("Journal Template Name", PurchSetup."Post Dated Check Template");
                            JnlBatch.SetRange(Name, PurchSetup."Post Dated Check Batch");
                            "Bank Account" := JnlBatch."Bal. Account No.";
                        end;
                    "Account Type"::"G/L Account":
                        begin
                            GLAccount.Get("Account No.");
                            Description := GLAccount.Name;
                        end;
                end;
                "Date Received" := WorkDate();
            end;
        }
        field(11; "Check Date"; Date)
        {
            Caption = 'Check Date';

            trigger OnValidate()
            begin
                Validate(Amount);
            end;
        }
        field(12; "Check No."; Code[20])
        {
            Caption = 'Check No.';
        }
        field(17; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                if "Currency Code" <> '' then begin
                    if ("Currency Code" <> xRec."Currency Code") or
                       ("Check Date" <> xRec."Check Date") or
                       (CurrFieldNo = FieldNo("Currency Code")) or
                       ("Currency Factor" = 0)
                    then
                        "Currency Factor" :=
                          CurrExchRate.ExchangeRate("Check Date", "Currency Code");
                end else
                    "Currency Factor" := 0;
                Validate("Currency Factor");
            end;
        }
        field(18; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';

            trigger OnValidate()
            begin
                if ("Currency Code" = '') and ("Currency Factor" <> 0) then
                    FieldError("Currency Factor", StrSubstNo(Text002, FieldCaption("Currency Code")));
                Validate(Amount);
            end;
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(21; "Date Received"; Date)
        {
            Caption = 'Date Received';
        }
        field(22; Amount; Decimal)
        {
            Caption = 'Amount';

            trigger OnValidate()
            begin
                if "Account Type" = "Account Type"::Customer then
                    if Amount > 0 then
                        FieldError(Amount, Text006);

                if "Account Type" = "Account Type"::Vendor then
                    if Amount < 0 then
                        FieldError(Amount, Text007);

                GetCurrency();
                if "Currency Code" = '' then
                    "Amount (LCY)" := Amount
                else
                    "Amount (LCY)" := Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          "Check Date", "Currency Code",
                          Amount, "Currency Factor"));

                Amount := Round(Amount, Currency."Amount Rounding Precision");
            end;
        }
        field(23; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';

            trigger OnValidate()
            begin
                if "Account Type" = "Account Type"::Customer then
                    if Amount > 0 then
                        FieldError(Amount, Text006);

                if "Account Type" = "Account Type"::Vendor then
                    if Amount < 0 then
                        FieldError(Amount, Text007);

                TempAmount := "Amount (LCY)";
                Validate("Currency Code", '');
                Amount := TempAmount;
                "Amount (LCY)" := TempAmount;
            end;
        }
        field(24; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(30; "Bank Account"; Code[20])
        {
            Caption = 'Bank Account';
            TableRelation = if ("Account Type" = const(Customer)) "Customer Bank Account".Code where("Customer No." = field("Account No."))
            else
            if ("Account Type" = const(Vendor)) "Bank Account"."No.";
        }
        field(34; "Replacement Check"; Boolean)
        {
            Caption = 'Replacement Check';
        }
        field(40; Comment; Text[90])
        {
            Caption = 'Comment';
        }
        field(41; "Batch Name"; Code[10])
        {
            Caption = 'Batch Name';

            trigger OnLookup()
            begin
                Clear(JournalBatch);
                JnlBatch.SetRange("Bal. Account Type", JnlBatch."Bal. Account Type"::"Bank Account");
                case "Account Type" of
                    "Account Type"::Customer:
                        begin
                            SalesSetup.Get();
                            JnlBatch.SetRange("Journal Template Name", SalesSetup."Post Dated Check Template");
                        end;
                    "Account Type"::Vendor:
                        begin
                            PurchSetup.Get();
                            JnlBatch.SetRange("Journal Template Name", PurchSetup."Post Dated Check Template");
                        end;
                end;
                JournalBatch.SetTableView(JnlBatch);
                JournalBatch.SetRecord(JnlBatch);
                JournalBatch.LookupMode(true);
                if JournalBatch.RunModal() = ACTION::LookupOK then
                    JournalBatch.GetRecord(JnlBatch);
                "Batch Name" := JnlBatch.Name;
                "Template Name" := JnlBatch."Journal Template Name";
                "Bank Account" := JnlBatch."Bal. Account No.";
            end;

            trigger OnValidate()
            begin
                if "Batch Name" = '' then
                    exit;

                case "Account Type" of
                    "Account Type"::Customer:
                        begin
                            SalesSetup.Get();
                            JnlBatch.Get(SalesSetup."Post Dated Check Template", "Batch Name");
                        end;
                    "Account Type"::Vendor:
                        begin
                            PurchSetup.Get();
                            JnlBatch.Get(PurchSetup."Post Dated Check Template", "Batch Name");
                        end;
                end;

                JnlBatch.TestField("Bal. Account Type", JnlBatch."Bal. Account Type"::"Bank Account");
            end;
        }
        field(42; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        field(43; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';

            trigger OnLookup()
            var
                PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
            begin
                if xRec."Line Number" = 0 then
                    xRec.Amount := Amount;

                if "Account Type" in
                   ["Account Type"::Customer]
                then begin
                    AccNo := "Account No.";
                    AccType := AccType::Customer;
                    Clear(CustLedgEntry);
                end;
                if "Account Type" in
                   ["Account Type"::Vendor]
                then begin
                    AccNo := "Account No.";
                    AccType := AccType::Vendor;
                    Clear(VendLedgEntry);
                end;

                xRec."Currency Code" := "Currency Code";
                xRec."Check Date" := "Check Date";

                case AccType of
                    AccType::Customer:
                        begin
                            CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive, "Due Date");
                            CustLedgEntry.SetRange("Customer No.", AccNo);
                            CustLedgEntry.SetRange(Open, true);
                            if "Applies-to Doc. No." <> '' then begin
                                CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                                CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                                if not CustLedgEntry.FindFirst() then begin
                                    CustLedgEntry.SetRange("Document Type");
                                    CustLedgEntry.SetRange("Document No.");
                                end;
                            end;
                            if "Applies-to ID" <> '' then begin
                                CustLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                                if not CustLedgEntry.FindFirst() then
                                    CustLedgEntry.SetRange("Applies-to ID");
                            end;
                            if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::" " then begin
                                CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                                if not CustLedgEntry.FindFirst() then
                                    CustLedgEntry.SetRange("Document Type");
                            end;
                            if "Applies-to Doc. No." <> '' then begin
                                CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                                if not CustLedgEntry.FindFirst() then
                                    CustLedgEntry.SetRange("Document No.");
                            end;
                            if Amount <> 0 then begin
                                CustLedgEntry.SetRange(Positive, Amount < 0);
                                if CustLedgEntry.FindFirst() then;
                                CustLedgEntry.SetRange(Positive);
                            end;
                            SetGenJnlLine(Rec);
                            ApplyCustEntries.SetGenJnlLine(GenJnlLine, GenJnlLine.FieldNo("Applies-to Doc. No."));
                            ApplyCustEntries.SetTableView(CustLedgEntry);
                            ApplyCustEntries.SetRecord(CustLedgEntry);
                            ApplyCustEntries.LookupMode(true);
                            if ApplyCustEntries.RunModal() = ACTION::LookupOK then begin
                                ApplyCustEntries.GetRecord(CustLedgEntry);
                                Clear(ApplyCustEntries);
                                if "Currency Code" <> CustLedgEntry."Currency Code" then
                                    if Amount = 0 then begin
                                        FromCurrencyCode := GetShowCurrencyCode("Currency Code");
                                        ToCurrencyCode := GetShowCurrencyCode(CustLedgEntry."Currency Code");
                                        if not
                                           Confirm(
                                             Text003 +
                                             Text004, true,
                                             FieldCaption("Currency Code"), TableCaption(), FromCurrencyCode,
                                             ToCurrencyCode)
                                        then
                                            Error(Text005);
                                        Validate("Currency Code", CustLedgEntry."Currency Code");
                                    end else
                                        GenJnlApply.CheckAgainstApplnCurrency(
                                          "Currency Code", CustLedgEntry."Currency Code", GenJnlLine."Account Type"::Customer, true);
                                if Amount = 0 then begin
                                    CustLedgEntry.CalcFields("Remaining Amount");
                                    if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlCust(GenJnlLine, CustLedgEntry, 0, false) then
                                        Amount := (CustLedgEntry."Remaining Amount" -
                                                   CustLedgEntry."Remaining Pmt. Disc. Possible")
                                    else
                                        Amount := CustLedgEntry."Remaining Amount";
                                    if "Account Type" in
                                       ["Account Type"::Customer]
                                    then
                                        Amount := -Amount;
                                    Validate(Amount);
                                end;
                                "Applies-to Doc. Type" := CustLedgEntry."Document Type";
                                "Applies-to Doc. No." := CustLedgEntry."Document No.";
                                "Applies-to ID" := '';
                            end else
                                Clear(ApplyCustEntries);
                        end;
                    AccType::Vendor:
                        begin
                            VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
                            VendLedgEntry.SetRange("Vendor No.", AccNo);
                            VendLedgEntry.SetRange(Open, true);
                            if "Applies-to Doc. No." <> '' then begin
                                VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                                VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                                if not VendLedgEntry.FindFirst() then begin
                                    VendLedgEntry.SetRange("Document Type");
                                    VendLedgEntry.SetRange("Document No.");
                                end;
                            end;
                            if "Applies-to ID" <> '' then begin
                                VendLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                                if not VendLedgEntry.FindFirst() then
                                    VendLedgEntry.SetRange("Applies-to ID");
                            end;
                            if "Applies-to Doc. Type" <> "Applies-to Doc. Type"::" " then begin
                                VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                                if not VendLedgEntry.FindFirst() then
                                    VendLedgEntry.SetRange("Document Type");
                            end;
                            if "Applies-to Doc. No." <> '' then begin
                                VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                                if not VendLedgEntry.FindFirst() then
                                    VendLedgEntry.SetRange("Document No.");
                            end;
                            if Amount <> 0 then begin
                                VendLedgEntry.SetRange(Positive, Amount < 0);
                                if VendLedgEntry.FindFirst() then;
                                VendLedgEntry.SetRange(Positive);
                            end;
                            SetGenJnlLine(Rec);
                            ApplyVendEntries.SetGenJnlLine(GenJnlLine, GenJnlLine.FieldNo("Applies-to Doc. No."));
                            ApplyVendEntries.SetTableView(VendLedgEntry);
                            ApplyVendEntries.SetRecord(VendLedgEntry);
                            ApplyVendEntries.LookupMode(true);
                            if ApplyVendEntries.RunModal() = ACTION::LookupOK then begin
                                ApplyVendEntries.GetRecord(VendLedgEntry);
                                Clear(ApplyVendEntries);
                                if "Currency Code" <> VendLedgEntry."Currency Code" then
                                    if Amount = 0 then begin
                                        FromCurrencyCode := GetShowCurrencyCode("Currency Code");
                                        ToCurrencyCode := GetShowCurrencyCode(VendLedgEntry."Currency Code");
                                        if not
                                           Confirm(
                                             Text003 +
                                             Text004, true,
                                             FieldCaption("Currency Code"), TableCaption(), FromCurrencyCode,
                                             ToCurrencyCode)
                                        then
                                            Error(Text005);
                                        Validate("Currency Code", VendLedgEntry."Currency Code");
                                    end else
                                        GenJnlApply.CheckAgainstApplnCurrency(
                                          "Currency Code", VendLedgEntry."Currency Code", GenJnlLine."Account Type"::Vendor, true);
                                if Amount = 0 then begin
                                    VendLedgEntry.CalcFields("Remaining Amount");
                                    if PaymentToleranceMgt.CheckCalcPmtDiscGenJnlVend(GenJnlLine, VendLedgEntry, 0, false) then
                                        Amount := -(VendLedgEntry."Remaining Amount" -
                                                    VendLedgEntry."Remaining Pmt. Disc. Possible")
                                    else
                                        Amount := -VendLedgEntry."Remaining Amount";
                                    Validate(Amount);
                                end;
                                "Applies-to Doc. Type" := VendLedgEntry."Document Type";
                                "Applies-to Doc. No." := VendLedgEntry."Document No.";
                                "Applies-to ID" := '';
                            end else
                                Clear(ApplyVendEntries);
                        end;
                end;
            end;
        }
        field(48; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';

            trigger OnValidate()
            begin
                if ("Applies-to ID" <> xRec."Applies-to ID") and (xRec."Applies-to ID" <> '') then
                    ClearCustVendAppID();
            end;
        }
        field(50; "Bank Payment Type"; Enum "Bank Payment Type")
        {
            Caption = 'Bank Payment Type';
        }
        field(51; "Check Printed"; Boolean)
        {
            Caption = 'Check Printed';
            Editable = false;
        }
        field(52; "Interest Amount"; Decimal)
        {
            Caption = 'Interest Amount';

            trigger OnValidate()
            begin
                if "Currency Code" = '' then
                    "Interest Amount (LCY)" := "Interest Amount"
                else
                    "Interest Amount (LCY)" := Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          "Date Received", "Currency Code",
                          "Interest Amount", "Currency Factor"));
            end;
        }
        field(53; "Interest Amount (LCY)"; Decimal)
        {
            Caption = 'Interest Amount (LCY)';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(1500000; "Template Name"; Code[20])
        {
            Caption = 'Template Name';
        }
    }

    keys
    {
        key(Key1; "Template Name", "Batch Name", "Account Type", "Account No.", "Line Number")
        {
            Clustered = true;
            SumIndexFields = "Amount (LCY)";
        }
        key(Key2; "Check Date")
        {
            SumIndexFields = "Amount (LCY)";
        }
        key(Key3; "Account No.")
        {
            SumIndexFields = "Amount (LCY)";
        }
        key(Key4; "Line Number")
        {
        }
        key(Key5; "Account Type", "Account No.")
        {
            SumIndexFields = "Amount (LCY)";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestField("Check Printed", false);
        ClearCustVendAppID();
    end;

    trigger OnModify()
    begin
        TestField("Check Printed", false);
        if ("Applies-to ID" = '') and (xRec."Applies-to ID" <> '') then
            ClearCustVendAppID();
    end;

    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        CurrExchRate: Record "Currency Exchange Rate";
        CurrencyCode: Code[20];
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
        JournalBatch: Page "General Journal Batches";
        JnlBatch: Record "Gen. Journal Batch";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        CustEntrySetApplID: Codeunit "Cust. Entry-SetAppl.ID";
        VendEntrySetApplID: Codeunit "Vend. Entry-SetAppl.ID";
        TempAmount: Decimal;
        AccNo: Code[20];
        FromCurrencyCode: Code[10];
        ToCurrencyCode: Code[10];
        AccType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset";
        ApplyCustEntries: Page "Apply Customer Entries";
        CustLedgEntry: Record "Cust. Ledger Entry";
        SalesSetup: Record "Sales & Receivables Setup";
        ApplyVendEntries: Page "Apply Vendor Entries";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PurchSetup: Record "Purchases & Payables Setup";
        Text002: Label 'cannot be specified without %1';
        Text009: Label 'LCY';
        Text003: Label 'The %1 in the %2 will be changed from %3 to %4.\';
        Text004: Label 'Do you wish to continue?';
        Text005: Label 'The update has been interrupted to respect the warning.';
        Text006: Label 'must be negative';
        Text007: Label 'must be positive';
        DimMgt: Codeunit DimensionManagement;

    local procedure GetCurrency()
    begin
        CurrencyCode := "Currency Code";

        if CurrencyCode = '' then begin
            Clear(Currency);
            Currency.InitRoundingPrecision()
        end else
            if CurrencyCode <> Currency.Code then begin
                Currency.Get(CurrencyCode);
                Currency.TestField("Amount Rounding Precision");
            end;
    end;

    [Scope('OnPrem')]
    procedure SetGenJnlLine(var PostDatedCheck: Record "Post Dated Check Line")
    begin
        GenJnlLine."Line No." := PostDatedCheck."Line Number";
        GenJnlLine."Journal Batch Name" := 'Postdated';
        if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::Customer then
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer
        else
            if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::Vendor then
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor
            else
                if PostDatedCheck."Account Type" = PostDatedCheck."Account Type"::"G/L Account" then
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine."Account No." := PostDatedCheck."Account No.";
        GenJnlLine."Document No." := PostDatedCheck."Document No.";
        GenJnlLine."Posting Date" := PostDatedCheck."Check Date";
        GenJnlLine.Amount := PostDatedCheck.Amount;
        GenJnlLine."Document No." := PostDatedCheck."Document No.";
        GenJnlLine.Description := PostDatedCheck.Description;
        if PostDatedCheck."Currency Code" = '' then
            GenJnlLine."Amount (LCY)" := PostDatedCheck.Amount
        else
            GenJnlLine."Amount (LCY)" := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                  PostDatedCheck."Date Received", PostDatedCheck."Currency Code",
                  PostDatedCheck.Amount, PostDatedCheck."Currency Factor"));
        GenJnlLine."Currency Code" := PostDatedCheck."Currency Code";
        GenJnlLine."Applies-to Doc. Type" := PostDatedCheck."Applies-to Doc. Type";
        GenJnlLine."Applies-to Doc. No." := PostDatedCheck."Applies-to Doc. No.";
        GenJnlLine."Applies-to ID" := PostDatedCheck."Applies-to ID";
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Post Dated Check" := true;
        GenJnlLine."Check No." := PostDatedCheck."Check No.";
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
        GenJnlLine."Bal. Account No." := PostDatedCheck."Bank Account";
    end;

    [Scope('OnPrem')]
    procedure ClearCustVendAppID()
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry";
        TempVendLedgEntry: Record "Vendor Ledger Entry";
        CustEntryEdit: Codeunit "Cust. Entry-Edit";
        VendEntryEdit: Codeunit "Vend. Entry-Edit";
    begin
        if "Account Type" = "Account Type"::Customer then
            AccType := AccType::Customer;
        if "Account Type" = "Account Type"::"G/L Account" then
            AccType := AccType::"G/L Account";
        if "Account Type" = "Account Type"::Vendor then
            AccType := AccType::Vendor;

        AccNo := "Account No.";
        case AccType of
            AccType::Customer:
                if "Applies-to ID" <> '' then begin
                    CustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID", Open);
                    CustLedgEntry.SetRange("Customer No.", AccNo);
                    CustLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                    CustLedgEntry.SetRange(Open, true);
                    if CustLedgEntry.FindFirst() then begin
                        CustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                        CustLedgEntry."Accepted Payment Tolerance" := 0;
                        CustLedgEntry."Amount to Apply" := 0;
                        CustEntrySetApplID.SetApplId(CustLedgEntry, TempCustLedgEntry, '');
                    end;
                end else
                    if "Applies-to Doc. No." <> '' then begin
                        CustLedgEntry.SetCurrentKey("Document No.", "Document Type", "Customer No.");
                        CustLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                        CustLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                        CustLedgEntry.SetRange("Customer No.", AccNo);
                        CustLedgEntry.SetRange(Open, true);
                        if CustLedgEntry.FindFirst() then begin
                            CustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                            CustLedgEntry."Accepted Payment Tolerance" := 0;
                            CustLedgEntry."Amount to Apply" := 0;
                            CustEntryEdit.Run(CustLedgEntry);
                        end;
                    end;
            AccType::Vendor:
                if "Applies-to ID" <> '' then begin
                    VendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open);
                    VendLedgEntry.SetRange("Vendor No.", AccNo);
                    VendLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                    VendLedgEntry.SetRange(Open, true);
                    if VendLedgEntry.FindFirst() then begin
                        VendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                        VendLedgEntry."Accepted Payment Tolerance" := 0;
                        VendLedgEntry."Amount to Apply" := 0;
                        VendEntrySetApplID.SetApplId(VendLedgEntry, TempVendLedgEntry, '');
                    end;
                end else
                    if "Applies-to Doc. No." <> '' then begin
                        VendLedgEntry.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
                        VendLedgEntry.SetRange("Document No.", "Applies-to Doc. No.");
                        VendLedgEntry.SetRange("Document Type", "Applies-to Doc. Type");
                        VendLedgEntry.SetRange("Vendor No.", AccNo);
                        VendLedgEntry.SetRange(Open, true);
                        if VendLedgEntry.FindFirst() then begin
                            VendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                            VendLedgEntry."Accepted Payment Tolerance" := 0;
                            VendLedgEntry."Amount to Apply" := 0;
                            VendEntryEdit.Run(VendLedgEntry);
                        end;
                    end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetShowCurrencyCode(CurrencyCode: Code[10]): Code[10]
    begin
        if CurrencyCode <> '' then
            exit(CurrencyCode);

        exit(Text009);
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        "Dimension Set ID" := DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Document No."));
    end;
}

