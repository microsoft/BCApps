// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.Address;

table 7218 EACorpCardTrans
{
    Caption = 'Corp Card Transaction';
    DataClassification = CustomerContent;
    LookupPageId = EACorpCardTransList;
    DrillDownPageId = EACorpCardTransList;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            ToolTip = 'Specifies the unique entry number of the corporate card transaction.';
        }
        field(2; "Batch No."; Integer)
        {
            Caption = 'Batch No.';
            TableRelation = EACorpCardBatch."Batch No.";
            Tooltip = 'Specifies the batch number of the corporate card transaction batch that this transaction belongs to.';
        }
        field(3; "Provider Code"; Code[20])
        {
            Caption = 'Provider Code';
            TableRelation = EACorpCardProvider.Code;
            Tooltip = 'Specifies the provider code of the corporate card provider that provided this transaction.';
        }
        field(4; "Card Id"; Code[50])
        {
            Caption = 'Card Id';
            TableRelation = EACorpCard."Card Id";
            Tooltip = 'Specifies the card id of the corporate card that was used for this transaction.';
        }
        field(5; "Provider Trans Id"; Code[100])
        {
            Caption = 'Provider Transaction Id';
            Tooltip = 'Specifies the unique transaction id provided by the corporate card provider.';
        }
        field(6; "Trans Date"; Date)
        {
            Caption = 'Transaction Date';
            ToolTip = 'Specifies the date of the corporate card transaction.';
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date of the corporate card transaction.';
        }
        field(8; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
            ToolTip = 'Specifies the amount of the corporate card transaction.';
        }
        field(9; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
            ToolTip = 'Specifies the currency code of the corporate card transaction.';
        }
        field(10; "Merchant Raw"; Text[100])
        {
            Caption = 'Merchant Name';
            ToolTip = 'Specifies the merchant name of the corporate card transaction as provided by the corporate card provider.';
        }
        field(11; "Merchant Norm"; Text[100])
        {
            Caption = 'Normalized Merchant Name';
            ToolTip = 'Specifies the normalized merchant name of the corporate card transaction.';
        }
        field(12; MCC; Code[4])
        {
            Caption = 'Merchant Category Code';
            TableRelation = EACorpCardMCCMap.MCC;
            ToolTip = 'Specifies the merchant category code of the corporate card transaction.';
        }
        field(13; Country; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region".Code;
            ToolTip = 'Specifies the country/region code of the corporate card transaction.';
        }
        field(14; Status; Enum EACorpCardTransStatus)
        {
            Caption = 'Status';
            ToolTip = 'Specifies the status of the corporate card transaction.';
        }
        field(15; "Match Type"; Enum EACorpCardMatchType)
        {
            Caption = 'Match Type';
            ToolTip = 'Specifies the match type of the corporate card transaction.';
        }
        field(16; "Match Score"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Match Score';
            DecimalPlaces = 0 : 5;
            ToolTip = 'Specifies the match score of the corporate card transaction.';
        }
        field(17; "Expense No."; Code[20])
        {
            Caption = 'Expense No.';
            TableRelation = Expense."No.";
            ToolTip = 'Specifies the expense document number of the expense document that was created from this corporate card transaction.';
        }
        field(18; "Reject Reason"; Text[250])
        {
            Caption = 'Reject Reason';
            ToolTip = 'Specifies the reason why the corporate card transaction was rejected.';
        }
        field(19; "Source Payload Hash"; Text[100])
        {
            Caption = 'Source Payload Hash';
            ToolTip = 'Specifies the hash of the source payload of the corporate card transaction.';
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
        key(Batch; "Batch No.")
        {
        }
        key(Status; Status)
        {
        }
    }
}