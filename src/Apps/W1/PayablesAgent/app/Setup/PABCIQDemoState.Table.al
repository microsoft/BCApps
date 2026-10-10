// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Finance.Dimension;

table 3322 "PA BC IQ Demo State"
{
    Caption = 'Payables Agent BC IQ Demo State';
    DataClassification = CustomerContent;
    Access = Internal;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Primary Key"; Code[20])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Vendor 20000 VAT Reg. No."; Text[20])
        {
            Caption = 'Vendor 20000 VAT Registration No.';
        }
        field(3; "Vendor 20000 Payment Terms"; Code[10])
        {
            Caption = 'Vendor 20000 Payment Terms';
        }
        field(4; "Vendor 40000 VAT Reg. No."; Text[20])
        {
            Caption = 'Vendor 40000 VAT Registration No.';
        }
        field(5; "Vendor 40000 Payment Terms"; Code[10])
        {
            Caption = 'Vendor 40000 Payment Terms';
        }
        field(10; "Line Classification Skill ID"; BigInteger)
        {
            Caption = 'Line Classification Skill ID';
            DataClassification = SystemMetadata;
        }
        field(11; "Electricity Meter Skill ID"; BigInteger)
        {
            Caption = 'Electricity Meter Skill ID';
            DataClassification = SystemMetadata;
        }
        field(12; "Service Class. Skill ID"; BigInteger)
        {
            Caption = 'Service Classification Skill ID';
            DataClassification = SystemMetadata;
        }
        field(13; "Effective Date Skill ID"; BigInteger)
        {
            Caption = 'Effective Date Skill ID';
            DataClassification = SystemMetadata;
        }
        field(14; "Maintenance Cost Type Created"; Boolean)
        {
            Caption = 'Maintenance Cost Type Created';
            DataClassification = SystemMetadata;
        }
        field(15; "Training Cost Type Created"; Boolean)
        {
            Caption = 'Training Cost Type Created';
            DataClassification = SystemMetadata;
        }
        field(16; "Setup Version"; Integer)
        {
            Caption = 'Setup Version';
            DataClassification = SystemMetadata;
        }
        field(17; "Original Use BC IQ"; Boolean)
        {
            Caption = 'Original Use Business Central IQ';
            DataClassification = SystemMetadata;
        }
        field(18; "Account 8120 VAT Prod. Group"; Code[20])
        {
            Caption = 'Account 8120 Original VAT Product Posting Group';
        }
        field(19; "Account 8130 VAT Prod. Group"; Code[20])
        {
            Caption = 'Account 8130 Original VAT Product Posting Group';
        }
        field(20; "Account 8210 VAT Prod. Group"; Code[20])
        {
            Caption = 'Account 8210 Original VAT Product Posting Group';
        }
        field(21; "Account 8320 VAT Prod. Group"; Code[20])
        {
            Caption = 'Account 8320 Original VAT Product Posting Group';
        }
        field(22; "Account 8630 VAT Prod. Group"; Code[20])
        {
            Caption = 'Account 8630 Original VAT Product Posting Group';
        }
        field(23; "Vendor 20000 Dept. Existed"; Boolean)
        {
            Caption = 'Vendor 20000 Department Default Existed';
            DataClassification = SystemMetadata;
        }
        field(24; "Vendor 20000 Dept. Value"; Code[20])
        {
            Caption = 'Vendor 20000 Original Department Value';
        }
        field(25; "Vendor 20000 Dept. Posting"; Enum "Default Dimension Value Posting Type")
        {
            Caption = 'Vendor 20000 Original Department Value Posting';
        }
        field(26; "Electricity Cost Type Created"; Boolean)
        {
            Caption = 'Metered Electricity Cost Type Created';
            DataClassification = SystemMetadata;
        }
        field(27; "Repair Mat. Cost Type Created"; Boolean)
        {
            Caption = 'Repair Materials Cost Type Created';
            DataClassification = SystemMetadata;
        }
        field(28; "Office Cons. Cost Type Created"; Boolean)
        {
            Caption = 'Office Consumables Cost Type Created';
            DataClassification = SystemMetadata;
        }
        field(30; "Repair Material Mapping Line"; Integer)
        {
            Caption = 'Repair Material Mapping Line';
            DataClassification = SystemMetadata;
        }
        field(31; "Office Consum. Mapping Line"; Integer)
        {
            Caption = 'Office Consumables Mapping Line';
            DataClassification = SystemMetadata;
        }
        field(32; "Maintenance Mapping Line"; Integer)
        {
            Caption = 'Maintenance Labour Mapping Line';
            DataClassification = SystemMetadata;
        }
        field(33; "Electricity Mapping Line"; Integer)
        {
            Caption = 'Electricity Mapping Line';
            DataClassification = SystemMetadata;
        }
        field(34; "Accounting Mapping Line"; Integer)
        {
            Caption = 'Accounting Mapping Line';
            DataClassification = SystemMetadata;
        }
        field(35; "Training Mapping Line"; Integer)
        {
            Caption = 'Training Mapping Line';
            DataClassification = SystemMetadata;
        }
        field(36; "Consulting Mapping Line"; Integer)
        {
            Caption = 'Consulting Mapping Line';
            DataClassification = SystemMetadata;
        }
        field(37; "Monthly Books Mapping Line"; Integer)
        {
            Caption = 'Monthly Bookkeeping Mapping Line';
            DataClassification = SystemMetadata;
        }
        field(40; "June History System ID"; Guid)
        {
            Caption = 'June History Purchase Invoice System ID';
            DataClassification = SystemMetadata;
        }
        field(41; "July History System ID"; Guid)
        {
            Caption = 'July History Purchase Invoice System ID';
            DataClassification = SystemMetadata;
        }
        field(42; "August History System ID"; Guid)
        {
            Caption = 'August History Purchase Invoice System ID';
            DataClassification = SystemMetadata;
        }
        field(43; "September History System ID"; Guid)
        {
            Caption = 'September History Purchase Invoice System ID';
            DataClassification = SystemMetadata;
        }
        field(44; "June History Document No."; Code[20])
        {
            Caption = 'June History Purchase Invoice No.';
            DataClassification = SystemMetadata;
        }
        field(45; "July History Document No."; Code[20])
        {
            Caption = 'July History Purchase Invoice No.';
            DataClassification = SystemMetadata;
        }
        field(46; "August History Document No."; Code[20])
        {
            Caption = 'August History Purchase Invoice No.';
            DataClassification = SystemMetadata;
        }
        field(47; "September History Document No."; Code[20])
        {
            Caption = 'September History Purchase Invoice No.';
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
