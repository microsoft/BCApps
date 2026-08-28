// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

table 473 "Report Inbox Item Buffer"
{
    Caption = 'Report Inbox Item Buffer';
    TableType = Temporary;
    Access = Internal;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(2; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(3; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            DataClassification = SystemMetadata;
        }
        field(5; "Report Name"; Text[250])
        {
            Caption = 'Report Name';
            DataClassification = CustomerContent;
        }
        field(6; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(7; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
            DataClassification = SystemMetadata;
        }
        field(8; "Output Type"; Enum "Report Inbox Output Type")
        {
            Caption = 'Output Type';
            DataClassification = SystemMetadata;
        }
        field(9; Read; Boolean)
        {
            Caption = 'Read';
            DataClassification = SystemMetadata;
        }
        field(10; "File Name"; Text[250])
        {
            Caption = 'File Name';
            DataClassification = CustomerContent;
        }
        field(11; "Company Name Lower"; Text[30])
        {
            Caption = 'Company Name (lower case)';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(12; "Include All Companies"; Boolean)
        {
            Caption = 'Include All Companies';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
        key(Key2; "Company Name", "Created Date-Time")
        {
        }
    }
}
