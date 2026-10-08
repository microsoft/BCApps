// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

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
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
