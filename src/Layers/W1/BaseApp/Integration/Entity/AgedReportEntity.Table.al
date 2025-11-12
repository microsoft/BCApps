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
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(4; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(5; Before; Decimal)
        {
            Caption = 'Before';
        }
        field(6; "Period 1"; Decimal)
        {
            Caption = 'Period 1';
        }
        field(7; "Period 2"; Decimal)
        {
            Caption = 'Period 2';
        }
        field(8; "Period 3"; Decimal)
        {
            Caption = 'Period 3';
        }
        field(9; After; Decimal)
        {
            Caption = 'After';
        }
        field(10; Balance; Decimal)
        {
            Caption = 'Balance';
        }
        field(11; "Period Start Date"; Date)
        {
            Caption = 'Period Start Date';
        }
        field(12; "Period Length"; Text[10])
        {
            Caption = 'Period Length';
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

