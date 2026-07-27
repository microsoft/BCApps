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
        }
        field(2; "Batch No."; Integer)
        {
            Caption = 'Batch No.';
            TableRelation = EACorpCardBatch."Batch No.";
        }
        field(3; "Provider Code"; Code[20])
        {
            Caption = 'Provider Code';
            TableRelation = EACorpCardProvider.Code;
        }
        field(4; "Card Id"; Code[50])
        {
            Caption = 'Card Id';
            TableRelation = EACorpCard."Card Id";
        }
        field(5; "Provider Trans Id"; Code[100])
        {
            Caption = 'Provider Transaction Id';
        }
        field(6; "Trans Date"; Date)
        {
            Caption = 'Transaction Date';
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(8; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
            AutoFormatExpression = "Currency Code";
        }
        field(9; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        field(10; "Merchant Raw"; Text[100])
        {
            Caption = 'Merchant Name';
        }
        field(11; "Merchant Norm"; Text[100])
        {
            Caption = 'Normalized Merchant Name';
        }
        field(12; MCC; Code[4])
        {
            Caption = 'Merchant Category Code';
        }
        field(13; Country; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region".Code;
        }
        field(14; Status; Enum EACorpCardTransStatus)
        {
            Caption = 'Status';
        }
        field(15; "Match Type"; Enum EACorpCardMatchType)
        {
            Caption = 'Match Type';
        }
        field(16; "Match Score"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Match Score';
            DecimalPlaces = 0 : 5;
        }
        field(17; "Expense No."; Code[20])
        {
            Caption = 'Expense No.';
            TableRelation = Expense."No.";
        }
        field(18; "Reject Reason"; Text[250])
        {
            Caption = 'Reject Reason';
        }
        field(19; "Source Payload Hash"; Text[100])
        {
            Caption = 'Source Payload Hash';
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