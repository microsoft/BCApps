// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

table 478 "Report Inbox Company Buffer"
{
    Caption = 'Report Inbox Company Buffer';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
        }
        field(6; Id; Guid)
        {
            Caption = 'Id';
        }
        field(2; "Entry Count"; Integer)
        {
            Caption = 'Entry Count';
        }
        field(3; "Unread Count"; Integer)
        {
            Caption = 'Unread Count';
        }
        field(4; "Last Modified Date-Time"; DateTime)
        {
            Caption = 'Last Modified Date-Time';
        }
        field(5; "Company Name Lower"; Text[30])
        {
            Caption = 'Company Name (lower case)';
        }
    }

    keys
    {
        key(PK; "Company Name")
        {
            Clustered = true;
        }
    }
}
