// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

table 5372 "CDS Av. Virtual Table Buffer"
{
    TableType = Temporary;
    Caption = 'CDS Available Virtual Table Buffer';
    Extensible = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Business Central Entity Id"; GUID)
        {
            DataClassification = SystemMetadata;
            Caption = 'Business Central Table';
        }
        field(2; "Phsyical Name"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Name';
        }
        field(3; "API Route"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'API Route';
        }
        field(4; "CDS Entity Logical Name"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Dataverse Table Logical Name';
        }
        field(5; "Display Name"; Text[200])
        {
            DataClassification = SystemMetadata;
            Caption = 'Display Name';
        }
        field(6; "Visible"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Visible';
        }
        field(7; "In Process"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'In Process';
        }
    }
    keys
    {
        key(PK; "Business Central Entity Id")
        {
            Clustered = true;
        }
        key(Name; "Phsyical Name")
        {
        }
    }
}