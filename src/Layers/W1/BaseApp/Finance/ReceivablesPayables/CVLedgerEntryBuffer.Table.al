// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Security.AccessControl;

table 382 "CV Ledger Entry Buffer"
{
    Caption = 'CV Ledger Entry Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(3; "CV No."; Code[20])
        {
            Caption = 'CV No.';
            DataClassification = SystemMetadata;
            TableRelation = Customer;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            DataClassification = SystemMetadata;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(10; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
            DataClassification = SystemMetadata;
        }
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(13; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(14; "Remaining Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Amount';
            DataClassification = SystemMetadata;
        }
        field(15; "Original Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Original Amt. (LCY)';
            DataClassification = SystemMetadata;
        }
        field(16; "Remaining Amt. (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Remaining Amt. (LCY)';
            DataClassification = SystemMetadata;
        }
        field(17; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(18; "Sales/Purchase (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Sales/Purchase (LCY)';
            DataClassification = SystemMetadata;
        }
        field(19; "Profit (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Profit (LCY)';
            DataClassification = SystemMetadata;
        }
        field(20; "Inv. Discount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Inv. Discount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(21; "Bill-to/Pay-to CV No."; Code[20])
        {
            Caption = 'Bill-to/Pay-to CV No.';
            DataClassification = SystemMetadata;
            TableRelation = Customer;
        }
        field(22; "CV Posting Group"; Code[20])
        {
            Caption = 'CV Posting Group';
            DataClassification = SystemMetadata;
            TableRelation = "Customer Posting Group";
        }
        field(23; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(25; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            DataClassification = SystemMetadata;
            TableRelation = "Salesperson/Purchaser";
        }
        field(27; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = SystemMetadata;
            TableRelation = User."User Name";
        }
        field(28; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            DataClassification = SystemMetadata;
            TableRelation = "Source Code";
        }
        field(33; "On Hold"; Code[3])
        {
            Caption = 'On Hold';
            DataClassification = SystemMetadata;
        }
        field(34; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
            DataClassification = SystemMetadata;
        }
        field(35; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
            DataClassification = SystemMetadata;
        }
        field(36; Open; Boolean)
        {
            Caption = 'Open';
            DataClassification = SystemMetadata;
        }
        field(37; "Due Date"; Date)
        {
            Caption = 'Due Date';
            DataClassification = SystemMetadata;
        }
        field(38; "Pmt. Discount Date"; Date)
        {
            Caption = 'Pmt. Discount Date';
            DataClassification = SystemMetadata;
        }
        field(39; "Original Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Original Pmt. Disc. Possible';
            DataClassification = SystemMetadata;
        }
        field(40; "Pmt. Disc. Given (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Pmt. Disc. Given (LCY)';
            DataClassification = SystemMetadata;
        }
        field(42; "Orig. Pmt. Disc. Possible(LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Orig. Pmt. Disc. Possible (LCY)';
            DataClassification = SystemMetadata;
        }
        field(43; Positive; Boolean)
        {
            Caption = 'Positive';
            DataClassification = SystemMetadata;
        }
        field(44; "Closed by Entry No."; Integer)
        {
            Caption = 'Closed by Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "Cust. Ledger Entry";
        }
        field(45; "Closed at Date"; Date)
        {
            Caption = 'Closed at Date';
            DataClassification = SystemMetadata;
        }
        field(46; "Closed by Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Closed by Amount';
            DataClassification = SystemMetadata;
        }
        field(47; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
            DataClassification = SystemMetadata;
        }
        field(48; "Journal Templ. Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = SystemMetadata;
        }
        field(49; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = SystemMetadata;
        }
        field(50; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            DataClassification = SystemMetadata;
            TableRelation = "Reason Code";
        }
        field(51; "Bal. Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
            DataClassification = SystemMetadata;
        }
        field(52; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            DataClassification = SystemMetadata;
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
        field(53; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            DataClassification = SystemMetadata;
        }
        field(54; "Closed by Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Closed by Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(58; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Debit Amount';
            DataClassification = SystemMetadata;
        }
        field(59; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Credit Amount';
            DataClassification = SystemMetadata;
        }
        field(60; "Debit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Debit Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(61; "Credit Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            BlankZero = true;
            Caption = 'Credit Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(62; "Document Date"; Date)
        {
            Caption = 'Document Date';
            DataClassification = SystemMetadata;
        }
        field(63; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = SystemMetadata;
        }
        field(64; "Calculate Interest"; Boolean)
        {
            Caption = 'Calculate Interest';
            DataClassification = SystemMetadata;
        }
        field(65; "Closing Interest Calculated"; Boolean)
        {
            Caption = 'Closing Interest Calculated';
            DataClassification = SystemMetadata;
        }
        field(66; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            DataClassification = SystemMetadata;
            TableRelation = "No. Series";
        }
        field(67; "Closed by Currency Code"; Code[10])
        {
            Caption = 'Closed by Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(68; "Closed by Currency Amount"; Decimal)
        {
            AutoFormatExpression = "Closed by Currency Code";
            AutoFormatType = 1;
            Caption = 'Closed by Currency Amount';
            DataClassification = SystemMetadata;
        }
        field(70; "Rounding Currency"; Code[10])
        {
            Caption = 'Rounding Currency';
            DataClassification = SystemMetadata;
        }
        field(71; "Rounding Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Rounding Amount';
            DataClassification = SystemMetadata;
        }
        field(72; "Rounding Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Rounding Amount (LCY)';
            DataClassification = SystemMetadata;
        }
        field(73; "Adjusted Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Adjusted Currency Factor';
            DataClassification = SystemMetadata;
        }
        field(74; "Original Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Original Currency Factor';
            DataClassification = SystemMetadata;
        }
        field(75; "Original Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Original Amount';
            DataClassification = SystemMetadata;
        }
        field(77; "Remaining Pmt. Disc. Possible"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Pmt. Disc. Possible';
            DataClassification = SystemMetadata;
        }
        field(78; "Pmt. Disc. Tolerance Date"; Date)
        {
            Caption = 'Pmt. Disc. Tolerance Date';
            DataClassification = SystemMetadata;
        }
        field(79; "Max. Payment Tolerance"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Max. Payment Tolerance';
            DataClassification = SystemMetadata;
        }
        field(81; "Accepted Payment Tolerance"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Accepted Payment Tolerance';
            DataClassification = SystemMetadata;
        }
        field(82; "Accepted Pmt. Disc. Tolerance"; Boolean)
        {
            Caption = 'Accepted Pmt. Disc. Tolerance';
            DataClassification = SystemMetadata;
        }
        field(83; "Pmt. Tolerance (LCY)"; Decimal)
        {
            Caption = 'Pmt. Tolerance (LCY)';
            AutoFormatType = 1;
            AutoFormatExpression = '';
            DataClassification = SystemMetadata;
        }
        field(84; "Amount to Apply"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount to Apply';
            DataClassification = SystemMetadata;
        }
        field(90; Prepayment; Boolean)
        {
            Caption = 'Prepayment';
            DataClassification = SystemMetadata;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure CopyFromCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        TransferFields(CustLedgEntry);
        Amount := CustLedgEntry.Amount;
        "Amount (LCY)" := CustLedgEntry."Amount (LCY)";
        "Remaining Amount" := CustLedgEntry."Remaining Amount";
        "Remaining Amt. (LCY)" := CustLedgEntry."Remaining Amt. (LCY)";
        "Original Amount" := CustLedgEntry."Original Amount";
        "Original Amt. (LCY)" := CustLedgEntry."Original Amt. (LCY)";

        OnAfterCopyFromCustLedgerEntry(Rec, CustLedgEntry);
    end;

    procedure CopyFromVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        "Entry No." := VendLedgEntry."Entry No.";
        "CV No." := VendLedgEntry."Vendor No.";
        "Posting Date" := VendLedgEntry."Posting Date";
        "Document Type" := VendLedgEntry."Document Type";
        "Document No." := VendLedgEntry."Document No.";
        Description := VendLedgEntry.Description;
        "Currency Code" := VendLedgEntry."Currency Code";
        Amount := VendLedgEntry.Amount;
        "Remaining Amount" := VendLedgEntry."Remaining Amount";
        "Original Amount" := VendLedgEntry."Original Amount";
        "Original Amt. (LCY)" := VendLedgEntry."Original Amt. (LCY)";
        "Remaining Amt. (LCY)" := VendLedgEntry."Remaining Amt. (LCY)";
        "Amount (LCY)" := VendLedgEntry."Amount (LCY)";
        "Sales/Purchase (LCY)" := VendLedgEntry."Purchase (LCY)";
        "Inv. Discount (LCY)" := VendLedgEntry."Inv. Discount (LCY)";
        "Bill-to/Pay-to CV No." := VendLedgEntry."Buy-from Vendor No.";
        "CV Posting Group" := VendLedgEntry."Vendor Posting Group";
        "Global Dimension 1 Code" := VendLedgEntry."Global Dimension 1 Code";
        "Global Dimension 2 Code" := VendLedgEntry."Global Dimension 2 Code";
        "Dimension Set ID" := VendLedgEntry."Dimension Set ID";
        "Salesperson Code" := VendLedgEntry."Purchaser Code";
        "User ID" := VendLedgEntry."User ID";
        "Source Code" := VendLedgEntry."Source Code";
        "On Hold" := VendLedgEntry."On Hold";
        "Applies-to Doc. Type" := VendLedgEntry."Applies-to Doc. Type";
        "Applies-to Doc. No." := VendLedgEntry."Applies-to Doc. No.";
        Open := VendLedgEntry.Open;
        "Due Date" := VendLedgEntry."Due Date";
        "Pmt. Discount Date" := VendLedgEntry."Pmt. Discount Date";
        "Original Pmt. Disc. Possible" := VendLedgEntry."Original Pmt. Disc. Possible";
        "Orig. Pmt. Disc. Possible(LCY)" := VendLedgEntry."Orig. Pmt. Disc. Possible(LCY)";
        "Remaining Pmt. Disc. Possible" := VendLedgEntry."Remaining Pmt. Disc. Possible";
        "Pmt. Disc. Given (LCY)" := VendLedgEntry."Pmt. Disc. Rcd.(LCY)";
        Positive := VendLedgEntry.Positive;
        "Closed by Entry No." := VendLedgEntry."Closed by Entry No.";
        "Closed at Date" := VendLedgEntry."Closed at Date";
        "Closed by Amount" := VendLedgEntry."Closed by Amount";
        "Applies-to ID" := VendLedgEntry."Applies-to ID";
        "Journal Templ. Name" := VendLedgEntry."Journal Templ. Name";
        "Journal Batch Name" := VendLedgEntry."Journal Batch Name";
        "Reason Code" := VendLedgEntry."Reason Code";
        "Bal. Account Type" := VendLedgEntry."Bal. Account Type";
        "Bal. Account No." := VendLedgEntry."Bal. Account No.";
        "Transaction No." := VendLedgEntry."Transaction No.";
        "Closed by Amount (LCY)" := VendLedgEntry."Closed by Amount (LCY)";
        "Debit Amount" := VendLedgEntry."Debit Amount";
        "Credit Amount" := VendLedgEntry."Credit Amount";
        "Debit Amount (LCY)" := VendLedgEntry."Debit Amount (LCY)";
        "Credit Amount (LCY)" := VendLedgEntry."Credit Amount (LCY)";
        "Document Date" := VendLedgEntry."Document Date";
        "External Document No." := VendLedgEntry."External Document No.";
        "No. Series" := VendLedgEntry."No. Series";
        "Closed by Currency Code" := VendLedgEntry."Closed by Currency Code";
        "Closed by Currency Amount" := VendLedgEntry."Closed by Currency Amount";
        "Adjusted Currency Factor" := VendLedgEntry."Adjusted Currency Factor";
        "Original Currency Factor" := VendLedgEntry."Original Currency Factor";
        "Pmt. Disc. Tolerance Date" := VendLedgEntry."Pmt. Disc. Tolerance Date";
        "Max. Payment Tolerance" := VendLedgEntry."Max. Payment Tolerance";
        "Accepted Payment Tolerance" := VendLedgEntry."Accepted Payment Tolerance";
        "Accepted Pmt. Disc. Tolerance" := VendLedgEntry."Accepted Pmt. Disc. Tolerance";
        "Pmt. Tolerance (LCY)" := VendLedgEntry."Pmt. Tolerance (LCY)";
        "Amount to Apply" := VendLedgEntry."Amount to Apply";
        Prepayment := VendLedgEntry.Prepayment;

        OnAfterCopyFromVendLedgerEntry(Rec, VendLedgEntry);
    end;

    procedure CopyFromEmplLedgEntry(EmplLedgEntry: Record "Employee Ledger Entry")
    begin
        "Entry No." := EmplLedgEntry."Entry No.";
        "CV No." := EmplLedgEntry."Employee No.";
        "Posting Date" := EmplLedgEntry."Posting Date";
        "Document Type" := EmplLedgEntry."Document Type";
        "Document No." := EmplLedgEntry."Document No.";
        Description := EmplLedgEntry.Description;
        "Currency Code" := EmplLedgEntry."Currency Code";
        Amount := EmplLedgEntry.Amount;
        "Remaining Amount" := EmplLedgEntry."Remaining Amount";
        "Original Amount" := EmplLedgEntry."Original Amount";
        "Original Amt. (LCY)" := EmplLedgEntry."Original Amt. (LCY)";
        "Remaining Amt. (LCY)" := EmplLedgEntry."Remaining Amt. (LCY)";
        "Amount (LCY)" := EmplLedgEntry."Amount (LCY)";
        "CV Posting Group" := EmplLedgEntry."Employee Posting Group";
        "Global Dimension 1 Code" := EmplLedgEntry."Global Dimension 1 Code";
        "Global Dimension 2 Code" := EmplLedgEntry."Global Dimension 2 Code";
        "Dimension Set ID" := EmplLedgEntry."Dimension Set ID";
        "Salesperson Code" := EmplLedgEntry."Salespers./Purch. Code";
        "User ID" := EmplLedgEntry."User ID";
        "Source Code" := EmplLedgEntry."Source Code";
        "Applies-to Doc. Type" := EmplLedgEntry."Applies-to Doc. Type";
        "Applies-to Doc. No." := EmplLedgEntry."Applies-to Doc. No.";
        Open := EmplLedgEntry.Open;
        Positive := EmplLedgEntry.Positive;
        "Closed by Entry No." := EmplLedgEntry."Closed by Entry No.";
        "Closed at Date" := EmplLedgEntry."Closed at Date";
        "Closed by Amount" := EmplLedgEntry."Closed by Amount";
        "Applies-to ID" := EmplLedgEntry."Applies-to ID";
        "Journal Templ. Name" := EmplLedgEntry."Journal Templ. Name";
        "Journal Batch Name" := EmplLedgEntry."Journal Batch Name";
        "Bal. Account Type" := EmplLedgEntry."Bal. Account Type";
        "Bal. Account No." := EmplLedgEntry."Bal. Account No.";
        "Transaction No." := EmplLedgEntry."Transaction No.";
        "Closed by Amount (LCY)" := EmplLedgEntry."Closed by Amount (LCY)";
        "Closed by Currency Code" := EmplLedgEntry."Closed by Currency Code";
        "Closed by Currency Amount" := EmplLedgEntry."Closed by Currency Amount";
        if EmplLedgEntry."Adjusted Currency Factor" <> 0 then
            "Adjusted Currency Factor" := EmplLedgEntry."Adjusted Currency Factor"
        else
            "Adjusted Currency Factor" := 1;
        if EmplLedgEntry."Original Currency Factor" <> 0 then
            "Original Currency Factor" := EmplLedgEntry."Original Currency Factor"
        else
            "Original Currency Factor" := 1;
        "Debit Amount" := EmplLedgEntry."Debit Amount";
        "Credit Amount" := EmplLedgEntry."Credit Amount";
        "Debit Amount (LCY)" := EmplLedgEntry."Debit Amount (LCY)";
        "Credit Amount (LCY)" := EmplLedgEntry."Credit Amount (LCY)";
        "No. Series" := EmplLedgEntry."No. Series";
        "Amount to Apply" := EmplLedgEntry."Amount to Apply";

        OnAfterCopyFromEmplLedgerEntry(Rec, EmplLedgEntry);
    end;

    procedure RecalculateAmounts(FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; PostingDate: Date)
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if ToCurrencyCode = FromCurrencyCode then
            exit;

        "Remaining Amount" :=
          CurrExchRate.ExchangeAmount("Remaining Amount", FromCurrencyCode, ToCurrencyCode, PostingDate);
        "Remaining Pmt. Disc. Possible" :=
          CurrExchRate.ExchangeAmount("Remaining Pmt. Disc. Possible", FromCurrencyCode, ToCurrencyCode, PostingDate);
        "Amount to Apply" :=
          CurrExchRate.ExchangeAmount("Amount to Apply", FromCurrencyCode, ToCurrencyCode, PostingDate);

        OnAfterRecalculateAmounts(Rec, FromCurrencyCode, ToCurrencyCode, PostingDate);
    end;

    procedure SetClosedFields(EntryNo: Integer; PostingDate: Date; NewAmount: Decimal; AmountLCY: Decimal; CurrencyCode: Code[10]; CurrencyAmount: Decimal)
    begin
        "Closed by Entry No." := EntryNo;
        "Closed at Date" := PostingDate;
        "Closed by Amount" := NewAmount;
        "Closed by Amount (LCY)" := AmountLCY;
        "Closed by Currency Code" := CurrencyCode;
        "Closed by Currency Amount" := CurrencyAmount;
        OnAfterSetClosedFields(Rec);
    end;

    procedure GetPmtDiscountDate(ReferenceDate: Date) PmtDiscountDate: Date
    begin
        PmtDiscountDate := "Pmt. Discount Date";

        OnAfterGetPmtDiscountDate(Rec, ReferenceDate, PmtDiscountDate);
    end;

    procedure GetRemainingPmtDiscPossible(ReferenceDate: Date) RemainingPmtDiscPossible: Decimal
    begin
        RemainingPmtDiscPossible := "Remaining Pmt. Disc. Possible";

        OnAfterGetRemainingPmtDiscPossible(Rec, ReferenceDate, RemainingPmtDiscPossible);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromCustLedgerEntry(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromVendLedgerEntry(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromEmplLedgerEntry(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetClosedFields(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPmtDiscountDate(CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; ReferenceDate: Date; var PmtDiscountDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRemainingPmtDiscPossible(CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; ReferenceDate: Date; var RemainingPmtDiscPossible: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculateAmounts(var CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; FromCurrencyCode: Code[10]; ToCurrencyCode: Code[10]; PostingDate: Date)
    begin
    end;
}
