// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 7215 EACorpCardMerchantRule
{
    Access = Internal;
    Caption = 'Corp Card Merchant Rule';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Rule Id"; Integer)
        {
            Caption = 'Rule Id';
            AutoIncrement = true;
        }
        field(2; Pattern; Text[100])
        {
            Caption = 'Pattern';
        }
        field(3; "Normalized Name"; Text[100])
        {
            Caption = 'Normalized Name';
        }
        field(4; "Expense Category"; Code[20])
        {
            Caption = 'Expense Category';
            TableRelation = "Expense Category".Code;
        }
        field(5; Priority; Integer)
        {
            Caption = 'Priority';
            MinValue = 0;
        }
        field(6; Active; Boolean)
        {
            Caption = 'Active';
        }
    }

    keys
    {
        key(PK; "Rule Id")
        {
            Clustered = true;
        }
        key(Priority; Priority)
        {
        }
    }
}