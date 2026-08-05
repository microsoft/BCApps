// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

table 473 "Report Inbox Item Buffer"
{
    Caption = 'Report Inbox Item Buffer';
    TableType = Temporary;
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
        }
        field(3; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(4; "Report ID"; Integer)
        {
            Caption = 'Report ID';
        }
        field(5; "Report Name"; Text[250])
        {
            Caption = 'Report Name';
        }
        field(6; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(7; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
        }
        field(8; "Output Type"; Enum "Report Inbox Output Type")
        {
            Caption = 'Output Type';
        }
        field(9; Read; Boolean)
        {
            Caption = 'Read';
        }
        field(10; "File Name"; Text[250])
        {
            Caption = 'File Name';
        }
        field(11; "Company Name Lower"; Text[30])
        {
            Caption = 'Company Name (lower case)';
        }
        field(12; "Include All Companies"; Boolean)
        {
            Caption = 'Include All Companies';
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
