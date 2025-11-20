// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

using Microsoft.Finance.GeneralLedger.Account;

table 371 "Budget Buffer"
{
    Caption = 'Budget Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account";
        }
        field(2; "Dimension Value Code 1"; Code[20])
        {
            Caption = 'Dimension Value Code 1';
            DataClassification = SystemMetadata;
        }
        field(3; "Dimension Value Code 2"; Code[20])
        {
            Caption = 'Dimension Value Code 2';
            DataClassification = SystemMetadata;
        }
        field(4; "Dimension Value Code 3"; Code[20])
        {
            Caption = 'Dimension Value Code 3';
            DataClassification = SystemMetadata;
        }
        field(5; "Dimension Value Code 4"; Code[20])
        {
            Caption = 'Dimension Value Code 4';
            DataClassification = SystemMetadata;
        }
        field(6; "Dimension Value Code 5"; Code[20])
        {
            Caption = 'Dimension Value Code 5';
            DataClassification = SystemMetadata;
        }
        field(7; "Dimension Value Code 6"; Code[20])
        {
            Caption = 'Dimension Value Code 6';
            DataClassification = SystemMetadata;
        }
        field(8; "Dimension Value Code 7"; Code[20])
        {
            Caption = 'Dimension Value Code 7';
            DataClassification = SystemMetadata;
        }
        field(9; "Dimension Value Code 8"; Code[20])
        {
            Caption = 'Dimension Value Code 8';
            DataClassification = SystemMetadata;
        }
        field(10; Date; Date)
        {
            Caption = 'Date';
            DataClassification = SystemMetadata;
        }
        field(11; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "G/L Account No.", "Dimension Value Code 1", "Dimension Value Code 2", "Dimension Value Code 3", "Dimension Value Code 4", "Dimension Value Code 5", "Dimension Value Code 6", "Dimension Value Code 7", "Dimension Value Code 8", Date)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
