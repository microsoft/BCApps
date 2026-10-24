// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Bank.Ledger;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.Address;

table 7428 "EA Corp Card Trans"
{
    Access = Internal;
    Caption = 'Corp Card Transaction';
    DataClassification = CustomerContent;
    LookupPageId = "EA Corp Card Trans List";
    DrillDownPageId = "EA Corp Card Trans List";
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the unique entry number of the corporate card transaction.';
        }
        field(2; "Statement Entry No."; Integer)
        {
            Caption = 'Statement Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "EA Corp Card Statement"."Statement Entry No.";
            Tooltip = 'Specifies the corporate card statement that contains this transaction.';
        }
        field(3; "Provider Code"; Code[20])
        {
            Caption = 'Provider Code';
            DataClassification = SystemMetadata;
            TableRelation = "EA Corp Card Provider".Code;
            Tooltip = 'Specifies the provider code of the corporate card provider that provided this transaction.';
        }
        field(4; "Card Id"; Code[50])
        {
            Caption = 'Card Id';
            DataClassification = AccountData;
            TableRelation = "EA Corp Card"."Card Id";
            Tooltip = 'Specifies the card id of the corporate card that was used for this transaction.';
        }
        field(5; "Provider Trans Id"; Code[100])
        {
            Caption = 'Provider Transaction Id';
            DataClassification = AccountData;
            Tooltip = 'Specifies the unique transaction id provided by the corporate card provider.';
        }
        field(6; "Trans Date"; Date)
        {
            Caption = 'Transaction Date';
            DataClassification = AccountData;
            ToolTip = 'Specifies the date of the corporate card transaction.';
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = AccountData;
            ToolTip = 'Specifies the posting date of the corporate card transaction.';
        }
        field(8; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            DataClassification = AccountData;
            ToolTip = 'Specifies the amount of the corporate card transaction.';
        }
        field(9; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = AccountData;
            TableRelation = Currency.Code;
            ToolTip = 'Specifies the currency code of the corporate card transaction.';
        }
        field(10; "Merchant Raw"; Text[100])
        {
            Caption = 'Merchant Name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the merchant name of the corporate card transaction as provided by the corporate card provider.';
        }
        field(11; "Merchant Norm"; Text[100])
        {
            Caption = 'Normalized Merchant Name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the normalized merchant name of the corporate card transaction.';
        }
        field(12; MCC; Code[4])
        {
            Caption = 'Merchant Category Code';
            DataClassification = AccountData;
            TableRelation = "EA Corp Card MCC Map".MCC;
            ToolTip = 'Specifies the merchant category code of the corporate card transaction.';
        }
        field(13; Country; Code[10])
        {
            Caption = 'Country/Region Code';
            DataClassification = AccountData;
            TableRelation = "Country/Region".Code;
            ToolTip = 'Specifies the country/region code of the corporate card transaction.';
        }
        field(14; Status; Enum "EA Corp Card Trans Status")
        {
            Caption = 'Status';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the status of the corporate card transaction.';
        }
        field(15; "Match Type"; Enum "EA Corp Card Match Type")
        {
            Caption = 'Match Type';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the match type of the corporate card transaction.';
        }
        field(16; "Match Score"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Match Score';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the match score of the corporate card transaction.';
        }
        field(17; "Expense No."; Code[20])
        {
            Caption = 'Expense No.';
            DataClassification = AccountData;
            TableRelation = Expense."No.";
            ToolTip = 'Specifies the expense document number of the expense document that was created from this corporate card transaction.';
        }
        field(18; "Reject Reason"; Text[250])
        {
            Caption = 'Reject Reason';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the reason why the corporate card transaction was rejected.';
        }
        field(19; "Source Payload Hash"; Text[100])
        {
            Caption = 'Source Payload Hash';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the hash of the source payload of the corporate card transaction.';
        }
        field(23; "Posted Expense Report No."; Code[20])
        {
            Caption = 'Posted Expense Report No.';
            DataClassification = AccountData;
            Editable = false;
            TableRelation = "Posted Expense Report Header"."No.";
            ToolTip = 'Specifies the posted expense report linked to this corporate card transaction.';
        }
        field(24; "Provider Statement No."; Code[50])
        {
            Caption = 'Provider Statement No.';
            CalcFormula = lookup("EA Corp Card Statement"."Statement No." where("Statement Entry No." = field("Statement Entry No.")));
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the corporate card provider statement linked to this transaction.';
        }
        field(25; "Amount (LCY)"; Decimal)
        {
            Caption = 'Amount (LCY)';
            AutoFormatType = 1;
            AutoFormatExpression = '';
            DataClassification = AccountData;
            Editable = false;
            ToolTip = 'Specifies the transaction amount posted to the corporate card liability in the local currency.';
        }
        field(26; "Card Last 4"; Code[4])
        {
            Caption = 'Card Last 4';
            DataClassification = AccountData;
            Editable = false;
            ToolTip = 'Specifies the last four card-number digits supplied by the provider. The internal card identifier is resolved in Business Central.';
        }
        field(27; "Expense Match No."; Code[20])
        {
            Caption = 'Expense Match No.';
            DataClassification = AccountData;
            Editable = false;
            TableRelation = Expense."No.";
            ToolTip = 'Specifies the unique existing expense used to identify the card when no last-four value was supplied. The match is checked again before linking.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Dedup; "Provider Code", "Provider Trans Id", "Card Id", "Trans Date", Amount, "Currency Code")
        {
            Unique = true;
        }
        key(Statement; "Statement Entry No.", "Expense No.")
        {
            SumIndexFields = Amount;
        }
        key(Status; Status)
        {
        }
    }

    trigger OnInsert()
    begin
        if ("Amount (LCY)" = 0) and ("Currency Code" <> '') then
            "Amount (LCY)" := CalcAmountLCY();
    end;

    trigger OnDelete()
    var
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
    begin
        LockTable();
        Get("Entry No.");
        EnsureStatementNotClosed();
        EnsureTransactionCanBeDeleted();

        CorpCardTransDetail.SetRange("Trans Entry No.", "Entry No.");
        CorpCardTransDetail.DeleteAll(true);

        CorpCardException.SetRange("Trans Entry No.", "Entry No.");
        CorpCardException.DeleteAll(true);
    end;

    trigger OnModify()
    begin
        EnsureStatementNotClosed();
    end;

    local procedure EnsureTransactionCanBeDeleted()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        if (Status = Status::Posted) or ("Posted Expense Report No." <> '') then
            Error(PostedTransactionCannotDeleteErr, "Entry No.");

        PostedExpenseReportLine.SetRange("Credit Card Feed No.", "Entry No.");
        if not PostedExpenseReportLine.IsEmpty() then
            Error(PostedTransactionCannotDeleteErr, "Entry No.");

        BankAccountLedgerEntry.SetRange("EA Corp Card Trans Entry No.", "Entry No.");
        if not BankAccountLedgerEntry.IsEmpty() then
            Error(PostedTransactionCannotDeleteErr, "Entry No.");

        if "Expense No." <> '' then
            Error(LinkedTransactionCannotDeleteErr, "Entry No.");

        Expense.SetRange("Credit Card Feed No.", "Entry No.");
        if not Expense.IsEmpty() then
            Error(LinkedTransactionCannotDeleteErr, "Entry No.");

        ExpenseReportLine.SetRange("Credit Card Feed No.", "Entry No.");
        if not ExpenseReportLine.IsEmpty() then
            Error(LinkedTransactionCannotDeleteErr, "Entry No.");
    end;

    local procedure EnsureStatementNotClosed()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
    begin
        if "Statement Entry No." = 0 then
            exit;
        if not CorpCardStatement.Get("Statement Entry No.") then
            exit;
        if CorpCardStatement.Status = CorpCardStatement.Status::Closed then
            Error(ClosedStatementTransactionCannotChangeErr, "Entry No.", CorpCardStatement."Statement No.");
    end;

    local procedure CalcAmountLCY(): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        RateDate: Date;
    begin
        if "Currency Code" = '' then
            exit(Amount);

        RateDate := "Posting Date";
        if RateDate = 0D then
            RateDate := "Trans Date";
        if RateDate = 0D then
            RateDate := WorkDate();

        exit(CurrencyExchangeRate.ExchangeAmtFCYToLCY(RateDate, "Currency Code", Amount, CurrencyExchangeRate.ExchangeRate(RateDate, "Currency Code")));
    end;

    internal procedure GetAmountInCurrency(TargetCurrencyCode: Code[10]): Decimal
    begin
        if TargetCurrencyCode = "Currency Code" then
            exit(Amount);
        if (TargetCurrencyCode = '') and ("Currency Code" <> '') then begin
            if "Amount (LCY)" <> 0 then
                exit("Amount (LCY)");
            exit(CalcAmountLCY());
        end;

        Error(UnsupportedSettlementCurrencyErr, "Entry No.", "Currency Code", TargetCurrencyCode);
    end;

    var
        PostedTransactionCannotDeleteErr: Label 'Corporate card transaction %1 cannot be deleted because it has been posted or is referenced by a posted expense report or bank account ledger entry.', Comment = '%1 = transaction entry number';
        LinkedTransactionCannotDeleteErr: Label 'Corporate card transaction %1 cannot be deleted because it is linked to an expense or expense report.', Comment = '%1 = transaction entry number';
        ClosedStatementTransactionCannotChangeErr: Label 'Corporate card transaction %1 cannot be changed because statement %2 is closed.', Comment = '%1 = transaction entry number, %2 = statement number';
        UnsupportedSettlementCurrencyErr: Label 'Corporate card transaction %1 cannot be settled from currency %2 in currency %3.', Comment = '%1 = transaction entry number, %2 = transaction currency code, %3 = settlement currency code';
}