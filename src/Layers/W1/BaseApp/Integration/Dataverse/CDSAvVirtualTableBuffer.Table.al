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
            ToolTip = 'Specifies the physical name of the virtual table.';
        }
        field(3; "API Route"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'API Route';
            ToolTip = 'Specifies the API route of the virtual table.';
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
            ToolTip = 'Specifies the display name of the virtual table.';
        }
        field(6; "Visible"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Visible';
            ToolTip = 'Specifies the visibility of the virtual table.';
        }
        field(7; "In Process"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'In Process';
            ToolTip = 'Specifies whether the enabling of virtual table is in process.';
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