// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 7215 "EA Corp Card Merchant Rule"
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
            ToolTip = 'Specifies the unique identifier for the corporate card merchant rule.';
        }
        field(2; Pattern; Text[100])
        {
            Caption = 'Pattern';
            ToolTip = 'Specifies the pattern to match against the merchant name for the corporate card transaction.';
        }
        field(3; "Normalized Name"; Text[100])
        {
            Caption = 'Normalized Name';
            ToolTip = 'Specifies the normalized name for the corporate card merchant rule.';
        }
        field(4; "Expense Category"; Code[20])
        {
            Caption = 'Expense Category';
            TableRelation = "Expense Category".Code;
            ToolTip = 'Specifies the expense category for the corporate card merchant rule.';
        }
        field(5; Priority; Integer)
        {
            Caption = 'Priority';
            MinValue = 0;
            ToolTip = 'Specifies the priority of the corporate card merchant rule. Lower numbers indicate higher priority.';
        }
        field(6; Active; Boolean)
        {
            Caption = 'Active';
            ToolTip = 'Specifies whether the corporate card merchant rule is active.';
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