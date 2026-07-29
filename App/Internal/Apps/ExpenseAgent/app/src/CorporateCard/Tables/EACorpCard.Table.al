// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;

table 7211 EACorpCard
{
    Access = Internal;
    Caption = 'Corp Card';
    DataClassification = CustomerContent;
    LookupPageId = EACorpCardCards;
    DrillDownPageId = EACorpCardCards;
    ReplicateData = false;

    fields
    {
        field(1; "Card Id"; Code[50])
        {
            Caption = 'Card Id';
            ToolTip = 'Specifies the unique identifier for the card.';
        }
        field(2; "Provider Code"; Code[20])
        {
            Caption = 'Provider Code';
            TableRelation = EACorpCardProvider.Code;
            ToolTip = 'Specifies the provider code for the card.';
        }
        field(3; "External Card Ref"; Code[50])
        {
            Caption = 'External Card Reference';
            ToolTip = 'Specifies the external reference for the card.';
        }
        field(4; "Masked Card No."; Text[30])
        {
            Caption = 'Masked Card No.';
            ToolTip = 'Specifies the masked card number.';
        }
        field(5; "Expense User No."; Code[20])
        {
            Caption = 'Expense User No.';
            TableRelation = "Expense User"."No.";
            ToolTip = 'Specifies the expense user number associated with the card.';
        }
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
            ToolTip = 'Specifies the currency code for the card.';
        }
        field(7; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Indicates whether the card is blocked.';
        }
        field(8; "Valid From"; Date)
        {
            Caption = 'Valid From';
            ToolTip = 'Specifies the date from which the card is valid.';
        }
        field(9; "Valid To"; Date)
        {
            Caption = 'Valid To';
            ToolTip = 'Specifies the date until which the card is valid.';
        }
    }

    keys
    {
        key(PK; "Card Id")
        {
            Clustered = true;
        }
        key(ProviderCardRef; "Provider Code", "External Card Ref")
        {
        }
        key(ExpenseUser; "Expense User No.")
        {
        }
    }
}