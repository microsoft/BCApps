// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

table 596 "Exch. Rate Adjmt. Parameters"
{
    Caption = 'Exch. Rate Adjmt. Parameters';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Start Date"; Date)
        {
            Caption = 'Start Date';
            DataClassification = SystemMetadata;
        }
        field(3; "End Date"; Date)
        {
            Caption = 'End Date';
            DataClassification = SystemMetadata;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(5; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
            DataClassification = SystemMetadata;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(7; "Adjust Bank Accounts"; Boolean)
        {
            Caption = 'Adjust Bank Accounts';
            DataClassification = SystemMetadata;
        }
        field(8; "Adjust Customers"; Boolean)
        {
            Caption = 'Adjust Customers';
            DataClassification = SystemMetadata;
        }
        field(9; "Adjust Vendors"; Boolean)
        {
            Caption = 'Adjust Vendors';
            DataClassification = SystemMetadata;
        }
        field(10; "Adjust G/L Accounts"; Boolean)
        {
            Caption = 'Adjust G/L Accounts';
            DataClassification = SystemMetadata;
        }
        field(11; "Adjust VAT Entries"; Boolean)
        {
            Caption = 'Adjust VAT Entries';
            DataClassification = SystemMetadata;
        }
        field(12; "Adjust Per Entry"; Boolean)
        {
            Caption = 'Adjust Per Entry';
            DataClassification = SystemMetadata;
        }
        field(13; "Adjust Employees"; Boolean)
        {
            Caption = 'Adjust Employees';
            DataClassification = SystemMetadata;
        }
        field(14; "Dimension Posting"; Enum "Exch. Rate Adjmt. Dimensions")
        {
            Caption = 'Dimension Posting';
            DataClassification = SystemMetadata;
        }
        field(20; "Currency Filter"; Text[2048])
        {
            FieldClass = FlowFilter;
        }
        field(21; "Bank Account Filter"; Text[2048])
        {
            FieldClass = FlowFilter;
        }
        field(22; "Customer Filter"; Text[2048])
        {
            FieldClass = FlowFilter;
        }
        field(23; "Vendor Filter"; Text[2048])
        {
            FieldClass = FlowFilter;
        }
        field(24; "Employee Filter"; Text[2048])
        {
            FieldClass = FlowFilter;
        }
        field(27; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = SystemMetadata;
        }
        field(28; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = SystemMetadata;
        }
        field(29; "Hide UI"; Boolean)
        {
            Caption = 'Hide UI';
            DataClassification = SystemMetadata;
        }
        field(30; "Preview Posting"; Boolean)
        {
            Caption = 'Preview Posting';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(key1; "Primary Key")
        {
            Clustered = true;
        }
    }
}
