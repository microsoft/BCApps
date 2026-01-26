// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Setup;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;

table 32000002 "Ref. Payment - Exported"
{
    Caption = 'Ref. Payment - Exported';
    DrillDownPageID = "Ref. Payment - Export";
    LookupPageID = "Ref. Payment - Export";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor."No.";

            trigger OnValidate()
            begin
                if "Vendor No." <> '' then begin
                    if (xRec."Vendor No." <> '') and (xRec."Vendor No." <> "Vendor No.") and ("Entry No." <> 0) then
                        if Confirm(ChangeVendorNoQst) then
                            Validate("Entry No.", 0)
                        else
                            Error('');

                    Vend.Get("Vendor No.");
                    "Description 2" := CopyStr(Vend.Name, 1, MaxStrLen("Description 2"));
                    "Vendor Account" := Vend."Preferred Bank Account Code";
                    Validate("Vendor Account");
                    Vend.CheckBlockedVendOnJnls(Vend, "Gen. Journal Document Type"::Payment, false);
                end;
            end;
        }
        field(4; "Payment Account"; Code[20])
        {
            Caption = 'Payment Account';
            TableRelation = "Bank Account"."No." where("Country/Region Code" = filter('' | 'FI'));

            trigger OnValidate()
            begin
                SetDefaultTypes();
            end;
        }
        field(5; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(6; "Payment Date"; Date)
        {
            Caption = 'Payment Date';

            trigger OnValidate()
            begin
                if "Payment Date" < WorkDate() then
                    Error(Text1090002, FieldCaption("Payment Date"), WorkDate());
            end;
        }
#pragma warning disable AS0044
        field(7; "Document Type"; Option)
        {
            Caption = 'Document Type';
            Editable = false;
            OptionCaption = ' ,Payment,Invoice,Credit Memo';
            OptionMembers = " ",Payment,Invoice,"Credit Memo";
        }
#pragma warning restore AS0044
        field(8; "Document No."; Code[20])
        {
            Caption = 'Document No.';

            trigger OnValidate()
            begin
                TestField("Entry No.", 0);
            end;
        }
        field(9; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;

            trigger OnValidate()
            begin
                if "Currency Code" <> '' then begin
                    GetCurrency();
                    if ("Currency Code" <> xRec."Currency Code") or
                       ("Posting Date" <> xRec."Posting Date") or
                       (CurrFieldNo = FieldNo("Currency Code")) or
                       ("Currency Factor" = 0)
                    then
                        "Currency Factor" := CurrExchRate.ExchangeRate("Posting Date", "Currency Code");
                end else
                    "Currency Factor" := 0;
                Validate("Currency Factor");
            end;
        }
        field(10; Amount; Decimal)
        {
            Caption = 'Amount';

            trigger OnValidate()
            begin
                GetCurrency();
                if "Currency Code" = '' then
                    "Amount (LCY)" := Amount
                else
                    "Amount (LCY)" := Round(
                        CurrExchRate.ExchangeAmtFCYToLCY(
                          "Posting Date", "Currency Code",
                          Amount, "Currency Factor"));

                Amount := Round(Amount, Currency."Amount Rounding Precision");
            end;
        }
        field(11; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';

            trigger OnValidate()
            begin
                if "Currency Code" = '' then begin
                    Amount := "Amount (LCY)";
                    Validate(Amount);
                end else
                    if CheckFixedCurrency() then
                        Amount := Round(
                            CurrExchRate.ExchangeAmtLCYToFCY(
                              "Posting Date", "Currency Code",
                              "Amount (LCY)", "Currency Factor"),
                            Currency."Amount Rounding Precision")
                    else begin
                        TestField("Amount (LCY)");
                        TestField(Amount);
                        "Currency Factor" := Amount / "Amount (LCY)";
                    end;
            end;
        }
        field(12; "Vendor Account"; Code[20])
        {
            Caption = 'Vendor Account';
            TableRelation = "Vendor Bank Account".Code where("Vendor No." = field("Vendor No."));

            trigger OnValidate()
            var
                CompanyInfo: Record "Company Information";
            begin
                "Foreign Payment" := false;
                "Foreign Payment Method" := '';
                "Foreign Banks Service Fee" := '';

                if "Vendor Account" <> '' then begin
                    TestField("Vendor No.");
                    VendBankAcc.Get("Vendor No.", "Vendor Account");
                    "SEPA Payment" := VendBankAcc."SEPA Payment";
                    CompanyInfo.Get();
                    if not (VendBankAcc."Country/Region Code" in ['', CompanyInfo."Country/Region Code"]) then begin
                        "Foreign Payment" := true;
                        SetDefaultTypes();
                    end;
                end;
            end;
        }
        field(13; "Message Type"; Option)
        {
            Caption = 'Message Type';
            InitValue = "Reference No.";
            OptionCaption = 'Reference No.,Invoice Information,Message,Long Message,Tax Message';
            OptionMembers = "Reference No.","Invoice Information",Message,"Long Message","Tax Message";

            trigger OnValidate()
            begin
                UpdateRemittanceInfo();
            end;
        }
        field(14; "Invoice Message"; Text[250])
        {
            Caption = 'Invoice Message';
        }
        field(15; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
        }
        field(16; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(17; "Batch Code"; Code[35])
        {
            Caption = 'Batch Code';
        }
        field(18; Transferred; Boolean)
        {
            Caption = 'Transferred';
            InitValue = false;
        }
        field(19; "Transfer Date"; Date)
        {
            Caption = 'Transfer Date';
        }
        field(20; "Transfer Time"; Time)
        {
            Caption = 'Transfer Time';
        }
        field(21; "Foreign Payment"; Boolean)
        {
            Caption = 'Foreign Payment';
            Editable = false;
        }
        field(22; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(23; "Foreign Payment Method"; Code[1])
        {
            Caption = 'Foreign Payment Method';
            TableRelation = "Foreign Payment Types".Code where("Code Type" = const("Payment Method"));
        }
        field(24; "Foreign Banks Service Fee"; Code[1])
        {
            Caption = 'Foreign Banks Service Fee';
            TableRelation = "Foreign Payment Types".Code where("Code Type" = const("Service Fee"));
        }
        field(25; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            TableRelation = "Vendor Ledger Entry"."Entry No." where("Vendor No." = field("Vendor No."),
                                                                     Open = const(true));

            trigger OnValidate()
            begin
                if "Entry No." = 0 then begin
                    ClearVendLedgerEntryRelatedFieds();
                    exit;
                end;

                VendLedgEntry.Get("Entry No.");
                "Document No." := VendLedgEntry."Document No.";
                if not InsertConfirmed() then begin
                    Init();
                    Validate("Vendor No.", xRec."Vendor No.");
                    "Payment Account" := xRec."Payment Account";
                    exit;
                end;

                Validate("Vendor No.", VendLedgEntry."Vendor No.");

                if VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::"Credit Memo" then begin
                    Validate("Message Type", "Message Type"::Message);
                    "Invoice Message" := VendLedgEntry."External Document No.";
                end else begin
                    Validate("Message Type", VendLedgEntry."Message Type");
                    "Invoice Message" := VendLedgEntry."Invoice Message";
                end;
                "Invoice Message 2" := VendLedgEntry."Invoice Message 2";

                "Posting Date" := VendLedgEntry."Posting Date";
                "External Document No." := VendLedgEntry."External Document No.";
                "Currency Code" := VendLedgEntry."Currency Code";

                VendLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
                if ((VendLedgEntry."Pmt. Discount Date" >= WorkDate()) and UsePaymentDisc) or
                   ((VendLedgEntry."Pmt. Disc. Tolerance Date" >= WorkDate()) and UsePmtDiscTolerance)
                then begin
                    if VendLedgEntry."Original Pmt. Disc. Possible" = 0 then
                        "Payment Date" := GetAdjustedPaymentDate(VendLedgEntry."Payment Date")
                    else
                        "Payment Date" := VendLedgEntry."Pmt. Discount Date";

                    Amount := -(VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible");
                    if VendLedgEntry."Currency Code" = '' then
                        "Amount (LCY)" := -(VendLedgEntry."Remaining Amt. (LCY)" - VendLedgEntry."Original Pmt. Disc. Possible")
                    else
                        "Amount (LCY)" :=
                          -(VendLedgEntry."Remaining Amt. (LCY)" -
                            ChangeExchangeRate.ExchangeAmtFCYToLCY(
                              WorkDate(), VendLedgEntry."Currency Code",
                              VendLedgEntry."Original Pmt. Disc. Possible",
                              VendLedgEntry."Adjusted Currency Factor"));
                end else begin
                    "Payment Date" := GetAdjustedPaymentDate(VendLedgEntry."Payment Date");

                    Amount := -VendLedgEntry."Remaining Amount";
                    "Amount (LCY)" := -VendLedgEntry."Remaining Amt. (LCY)";
                end;

                case VendLedgEntry."Document Type" of
                    VendLedgEntry."Document Type"::Invoice:
                        begin
                            "Document Type" := "Document Type"::Invoice;
                            "Due Date" := VendLedgEntry."Payment Date";
                        end;
                    VendLedgEntry."Document Type"::"Credit Memo":
                        begin
                            "Document Type" := "Document Type"::"Credit Memo";
                            "Due Date" := 0D;
                            "Payment Date" := 0D;
                            "Payment Account" := '';
                        end;
                end;
            end;
        }
        field(26; "Applied Payments"; Boolean)
        {
            Caption = 'Applied Payments';
        }
        field(27; "Exchange Rate"; Decimal)
        {
            Caption = 'Exchange Rate';
        }
        field(28; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            begin
                if ("Currency Code" = '') and ("Currency Factor" <> 0) then
                    FieldError("Currency Factor", StrSubstNo(Text1090001, FieldCaption("Currency Code")));
                Validate(Amount);
            end;
        }
        field(29; "Posted to G/L"; Boolean)
        {
            Caption = 'Posted to G/L';
            Editable = false;
        }
        field(30; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Payment,Detail,Message';
            OptionMembers = Payment,Detail,Message;
        }
        field(31; "Affiliated to Line"; Integer)
        {
            Caption = 'Affiliated to Line';
        }
        field(32; "Invoice Message 2"; Text[250])
        {
            Caption = 'Invoice Message 2';
        }
        field(33; "Picked to Journal"; Boolean)
        {
            Caption = 'Picked to Journal';
        }
        field(34; "Payment Execution Date"; Date)
        {
            Caption = 'Payment Execution Date';
        }
        field(35; "File Name"; Text[250])
        {
            Caption = 'File Name';
        }
        field(36; "SEPA Payment"; Boolean)
        {
            Caption = 'SEPA Payment';
        }
        field(37; "Remittance Information"; Option)
        {
            Caption = 'Remittance Information';
            OptionCaption = 'Structured,Unstructured';
            OptionMembers = Structured,Unstructured;
        }
        field(38; "Description 2"; Text[250])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; Transferred, "Applied Payments", "Foreign Payment", "SEPA Payment")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key3; "Payment Date", "Vendor No.", "Entry No.")
        {
            SumIndexFields = Amount, "Amount (LCY)";
        }
        key(Key4; "Payment Account", "Payment Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        Vend: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendBankAcc: Record "Vendor Bank Account";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        ChangeExchangeRate: Record "Currency Exchange Rate";
        RefFileSetup: Record "Reference File Setup";
        CurrencyCode: Code[10];
        Text1090000: Label 'Transactions have been transferred to bank file.\Do you wish to re-send this transaction?\Vendor No. =%1 Document No. = %2';
        Text1090001: Label 'cannot be specified without %1.';
        Text1090002: Label '%1 cannot be earlier than %2.';
        UsePaymentDisc: Boolean;
        ChangeVendorNoQst: Label 'If you change the vendor, the existing link to the vendor ledger entry will be deleted. \Are you sure that you want to change the vendor?';
        UsePmtDiscTolerance: Boolean;

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

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("No.")))
    end;

    procedure SetDefaultTypes()
    begin
        if ("Foreign Payment Method" = '') or ("Foreign Banks Service Fee" = '') then
            if ("Payment Account" <> '') and "Foreign Payment" then begin
                RefFileSetup.Get("Payment Account");
                if "Foreign Payment Method" = '' then
                    "Foreign Payment Method" := RefFileSetup."Default Payment Method";
                if "Foreign Banks Service Fee" = '' then
                    "Foreign Banks Service Fee" := RefFileSetup."Default Service Fee Code";
            end;
    end;

    procedure CheckFixedCurrency(): Boolean
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate.SetRange("Currency Code", "Currency Code");
        CurrExchRate.SetRange("Starting Date", 0D, "Posting Date");

        if not CurrExchRate.FindLast() then
            exit(false);

        if CurrExchRate."Relational Currency Code" = '' then
            exit(
              CurrExchRate."Fix Exchange Rate Amount" =
              CurrExchRate."Fix Exchange Rate Amount"::Both);

        if CurrExchRate."Fix Exchange Rate Amount" <>
           CurrExchRate."Fix Exchange Rate Amount"::Both
        then
            exit(false);

        CurrExchRate.SetRange("Currency Code", CurrExchRate."Relational Currency Code");
        if CurrExchRate.FindLast() then
            exit(
              CurrExchRate."Fix Exchange Rate Amount" =
              CurrExchRate."Fix Exchange Rate Amount"::Both);

        exit(false);
    end;

    local procedure ClearVendLedgerEntryRelatedFieds()
    begin
        "Payment Account" := '';
        "Due Date" := 0D;
        "Payment Date" := 0D;
        "Document No." := '';
        "Document Type" := "Document Type"::" ";
        "Currency Code" := '';
        "Currency Factor" := 0;
        Amount := 0;
        "Amount (LCY)" := 0;
        "Vendor Account" := '';
        "Message Type" := "Message Type"::"Reference No.";
        "Invoice Message" := '';
        "Invoice Message 2" := '';
        "Applies-to ID" := '';
        "External Document No." := '';
        "Posting Date" := 0D;
        "Foreign Payment Method" := '';
        "Foreign Banks Service Fee" := '';
    end;

    procedure UpdateLines()
    begin
        if FindSet(true) then
            repeat
                VendLedgEntry.Get("Entry No.");
                if VendLedgEntry.Open then begin
                    VendLedgEntry.CalcFields("Remaining Amt. (LCY)");
                    Validate(Amount, -VendLedgEntry."Remaining Amt. (LCY)");
                    Validate("Amount (LCY)", -VendLedgEntry."Remaining Amt. (LCY)");
                    Modify();
                end else
                    Delete();
            until Next() = 0;
    end;

    procedure UpdateRemittanceInfo()
    begin
        case "Message Type" of
            "Message Type"::"Reference No.",
          "Message Type"::"Tax Message":
                "Remittance Information" := "Remittance Information"::Structured;
            "Message Type"::"Invoice Information",
          "Message Type"::Message,
          "Message Type"::"Long Message":
                "Remittance Information" := "Remittance Information"::Unstructured;
        end;
    end;

    procedure ExistsNotTransferred(): Boolean
    var
        RefPaymentExported: Record "Ref. Payment - Exported";
    begin
        RefPaymentExported.SetRange("Entry No.", "Entry No.");
        RefPaymentExported.SetRange(Transferred, false);
        exit(not RefPaymentExported.IsEmpty);
    end;

    local procedure InsertConfirmed(): Boolean
    var
        RefPaymentExported: Record "Ref. Payment - Exported";
    begin
        RefPaymentExported.SetRange("Entry No.", "Entry No.");
        RefPaymentExported.SetRange(Transferred, true);
        RefPaymentExported.SetRange("Posted to G/L", false);
        if not RefPaymentExported.IsEmpty() then
            if not Confirm(Text1090000, false, "Vendor No.", "Document No.") then
                exit(false);
        exit(true);
    end;

    procedure SetUsePaymentDisc(NewUsePaymentDisc: Boolean)
    begin
        UsePaymentDisc := NewUsePaymentDisc;
    end;

    procedure SetUsePaymentDiscTolerance(NewUsePmtDiscTolerance: Boolean)
    begin
        UsePmtDiscTolerance := NewUsePmtDiscTolerance;
    end;

    procedure GetLastLineNo(): Integer
    var
        RefPaymentExported: Record "Ref. Payment - Exported";
    begin
        RefPaymentExported.Reset();
        if RefPaymentExported.FindLast() then
            exit(RefPaymentExported."No.");
    end;

    local procedure GetAdjustedPaymentDate(PaymentDate: Date): Date
    begin
        if PaymentDate >= Today then
            exit(PaymentDate);
        exit(WorkDate());
    end;

    procedure MarkAffiliatedAsTransferred()
    var
        RefPaymentExported: Record "Ref. Payment - Exported";
    begin
        if ("Entry No." = 0) and ("Affiliated to Line" <> 0) then begin
            RefPaymentExported.SetFilter("No.", '<>%1', "No.");
            RefPaymentExported.SetRange("Affiliated to Line", "Affiliated to Line");
            RefPaymentExported.ModifyAll(Transferred, Transferred);
        end;
    end;

    procedure ExportToFile()
    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get("Payment Account");
        GenJnlLine."Bal. Account No." := BankAccount."No.";
        GenJnlLine.SetRange("Journal Template Name", '');
        GenJnlLine.SetRange("Journal Batch Name", '');
        CODEUNIT.Run(BankAccount.GetPaymentExportCodeunitID(), GenJnlLine);
    end;
}
