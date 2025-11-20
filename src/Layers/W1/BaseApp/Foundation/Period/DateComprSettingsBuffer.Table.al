// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Period;

table 9040 "Date Compr. Settings Buffer"
{
    TableType = Temporary;
    Access = Public;
    Extensible = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Compress G/L Entries"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'G/L Entries';
        }
        field(3; "Compress VAT Entries"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'VAT Entries';
        }
        field(4; "Compr. Bank Acc. Ledg Entries"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Bank Account Ledger Entries';
        }
        field(5; "Compress G/L Budget Entries"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'G/L Budget Entries';
        }
        field(6; "Compr. Customer Ledger Entries"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Customer Ledger Entries';
        }
        field(7; "Compress Vendor Ledger Entries"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Vendor Ledger Entries';
        }
        field(8; "Compr. Resource Ledger Entries"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Resource Ledger Entries';
        }
        field(9; "Compress FA Ledger Entries"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'FA Ledger Entries';
        }
        field(10; "Compr. Maintenance Ledg. Entr."; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Maintenance Ledger Entries';
        }
        field(11; "Compr. Insurance Ledg. Entries"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Insurance Ledger Entries';
        }
        field(12; "Compress Warehouse Entries"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Warehouse Entries';
        }
        field(13; "Compress Item Budget Entries"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Item budget Entries';
        }
        field(100; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ClosingDates = true;
            DataClassification = SystemMetadata;
        }
        field(101; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            ClosingDates = true;
            DataClassification = SystemMetadata;
        }
        field(102; "Period Length"; Enum "Date Compression Period Length")
        {
            Caption = 'Period Length';
            DataClassification = SystemMetadata;
        }
        field(103; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(104; "Retain Dimensions"; Text[250])
        {
            Caption = 'Retain Dimensions';
            DataClassification = SystemMetadata;
        }
        field(200; "Delete Empty Registers"; Boolean)
        {
            Caption = 'Delete Empty Registers';
            DataClassification = SystemMetadata;
        }
        field(1000; "No. of Records Removed"; Integer)
        {
            Caption = 'Record Count Difference';
            DataClassification = SystemMetadata;
        }
        field(1001; "Saved Space (MB)"; Decimal)
        {
            Caption = 'Saved Space (MB)';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
