// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;

table 7421 "EA Corp Card"
{
    Access = Internal;
    Caption = 'Corp Card';
    DataClassification = CustomerContent;
    LookupPageId = "EA Corp Card Cards";
    DrillDownPageId = "EA Corp Card Cards";
    ReplicateData = false;

    fields
    {
        field(1; "Card Id"; Code[50])
        {
            Caption = 'Card Id';
            DataClassification = AccountData;
            ToolTip = 'Specifies the internal Business Central identifier for the card, not its card number. Statement files must not contain this identifier.';
        }
        field(2; "Provider Code"; Code[20])
        {
            Caption = 'Provider Code';
            DataClassification = SystemMetadata;
            TableRelation = "EA Corp Card Provider".Code;
            ToolTip = 'Specifies the provider code for the card.';
        }
        field(3; "External Card Ref"; Code[50])
        {
            Caption = 'External Card Reference';
            DataClassification = AccountData;
            ToolTip = 'Specifies the external reference for the card.';
        }
        field(4; "Masked Card No."; Text[30])
        {
            Caption = 'Masked Card No.';
            DataClassification = AccountData;
            ToolTip = 'Specifies the masked card number ending in its last four digits. Imports use those digits together with the provider to identify the internal card.';
        }
        field(5; "Expense User No."; Code[20])
        {
            Caption = 'Expense User No.';
            DataClassification = EndUserPseudonymousIdentifiers;
            TableRelation = "Expense User"."No.";
            ToolTip = 'Specifies the expense user number associated with the card.';
        }
        field(6; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = AccountData;
            TableRelation = Currency.Code;
            ToolTip = 'Specifies the currency code for the card.';
        }
        field(7; Blocked; Boolean)
        {
            Caption = 'Blocked';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the card is blocked.';
        }
        field(8; "Valid From"; Date)
        {
            Caption = 'Valid From';
            DataClassification = AccountData;
            ToolTip = 'Specifies the date from which the card is valid.';
        }
        field(9; "Valid To"; Date)
        {
            Caption = 'Valid To';
            DataClassification = AccountData;
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

    trigger OnDelete()
    var
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        CorpCardTrans.SetRange("Card Id", "Card Id");
        if not CorpCardTrans.IsEmpty() then
            Error(CardHasTransactionsErr, "Card Id");
    end;

    var
        CardHasTransactionsErr: Label 'Corporate card %1 cannot be deleted because one or more transactions exist.', Comment = '%1 = Card Id';
}