// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

table 5499 "Aged Report Entity"
{
    Caption = 'Aged Report Entity';
    DataClassification = CustomerContent;

    fields
    {
        field(1; AccountId; Guid)
        {
            Caption = 'AccountId';
            ToolTip = 'Specifies the Account Id.';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the Customer No..';
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the Customer Name.';
        }
        field(4; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the Currency Code.';
        }
        field(5; Before; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Before';
            ToolTip = 'Specifies the period Before.';
        }
        field(6; "Period 1"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Period 1';
            ToolTip = 'Specifies Period 1.';
        }
        field(7; "Period 2"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Period 2';
            ToolTip = 'Specifies Period 2.';
        }
        field(8; "Period 3"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Period 3';
            ToolTip = 'Specifies Period 3.';
        }
        field(9; After; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'After';
        }
        field(10; Balance; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Balance';
            ToolTip = 'Specifies the Balance Due.';
        }
        field(11; "Period Start Date"; Date)
        {
            Caption = 'Period Start Date';
            ToolTip = 'Specifies the Period Start Date.';
        }
        field(12; "Period Length"; Text[10])
        {
            Caption = 'Period Length';
            ToolTip = 'Specifies the Period Length.';
        }
        field(13; "Display Order"; Integer)
        {
            Caption = 'Display Order';
        }
        field(14; "Period 1 Label"; Text[30])
        {
            Caption = 'Period 1 Label';
        }
        field(15; "Period 2 Label"; Text[30])
        {
            Caption = 'Period 2 Label';
        }

        field(16; "Period 3 Label"; Text[30])
        {
            Caption = 'Period 3 Label';
        }

    }

    keys
    {
        key(Key1; AccountId)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

