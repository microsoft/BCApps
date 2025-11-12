// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

table 47 "Aging Band Buffer"
{
    Caption = 'Aging Band Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Currency Code"; Code[20])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
        }
        field(2; "Column 1 Amt."; Decimal)
        {
            Caption = 'Column 1 Amt.';
            DataClassification = SystemMetadata;
        }
        field(3; "Column 2 Amt."; Decimal)
        {
            Caption = 'Column 2 Amt.';
            DataClassification = SystemMetadata;
        }
        field(4; "Column 3 Amt."; Decimal)
        {
            Caption = 'Column 3 Amt.';
            DataClassification = SystemMetadata;
        }
        field(5; "Column 4 Amt."; Decimal)
        {
            Caption = 'Column 4 Amt.';
            DataClassification = SystemMetadata;
        }
        field(6; "Column 5 Amt."; Decimal)
        {
            Caption = 'Column 5 Amt.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Currency Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

