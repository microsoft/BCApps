// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.Address;

table 7428 "EA Corp Card Trans"
{
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
        key(Statement; "Statement Entry No.")
        {
            SumIndexFields = Amount;
        }
        key(Status; Status)
        {
        }
    }

    trigger OnDelete()
    var
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
    begin
        EnsureStatementNotClosed();

        CorpCardTransDetail.SetRange("Trans Entry No.", "Entry No.");
        CorpCardTransDetail.DeleteAll(true);

        CorpCardException.SetRange("Trans Entry No.", "Entry No.");
        CorpCardException.DeleteAll(true);
    end;

    trigger OnModify()
    begin
        EnsureStatementNotClosed();
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

    internal procedure GetAmountInCurrency(TargetCurrencyCode: Code[10]): Decimal
    begin
        if TargetCurrencyCode = "Currency Code" then
            exit(Amount);
        if (TargetCurrencyCode = '') and ("Currency Code" <> '') then begin
            TestField("Amount (LCY)");
            exit("Amount (LCY)");
        end;

        Error(UnsupportedSettlementCurrencyErr, "Entry No.", "Currency Code", TargetCurrencyCode);
    end;

    var
        ClosedStatementTransactionCannotChangeErr: Label 'Corporate card transaction %1 cannot be changed because statement %2 is closed.', Comment = '%1 = transaction entry number, %2 = statement number';
        UnsupportedSettlementCurrencyErr: Label 'Corporate card transaction %1 cannot be settled from currency %2 in currency %3.', Comment = '%1 = transaction entry number, %2 = transaction currency code, %3 = settlement currency code';
}