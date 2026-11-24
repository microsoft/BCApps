// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Staged itemization line from a receipt. Added to the expense report line when it has no itemization, and to the expense when it has none and its category requires itemization.
/// </summary>
table 7433 "EA Card Receipt Item"
{
    Access = Internal;
    Caption = 'Card Receipt Item';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Receipt Data Id"; Guid)
        {
            Caption = 'Receipt Data Id';
            ToolTip = 'Specifies the receipt data that the itemization line belongs to.';
            TableRelation = "EA Card Receipt Data".Id;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number of the itemization line.';
        }
        field(10; "Expense Subcategory Code"; Code[20])
        {
            Caption = 'Expense Subcategory Code';
            ToolTip = 'Specifies the expense subcategory of the itemization line.';
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the itemization line.';
        }
        field(12; "Start Date"; Date)
        {
            Caption = 'Start Date';
            ToolTip = 'Specifies the start date of the itemization line.';
        }
        field(13; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the quantity of the itemization line.';
            InitValue = 1;
            MinValue = 0;
        }
        field(14; "Daily Rate"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Daily Rate';
            ToolTip = 'Specifies the rate per unit of the itemization line.';
        }
        field(15; Amount; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Amount';
            ToolTip = 'Specifies the amount of the itemization line. Used when no daily rate is given.';
        }
    }

    keys
    {
        key(PK; "Receipt Data Id", "Line No.")
        {
            Clustered = true;
        }
    }
}
