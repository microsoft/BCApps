// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

// Temporary buffer that unifies API pages and API queries into a single list so the "Select APIs"
// lookup can show both in one page. Populated by MCPConfigImplementation.LookupAPIObjects; never
// persisted (used as temporary only).
table 8357 "MCP API Object Buffer"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Object Type"; Option)
        {
            Caption = 'Object Type';
            OptionMembers = Page,Query;
            OptionCaption = 'Page,Query';
        }
        field(2; "Object ID"; Integer)
        {
            Caption = 'ID';
        }
        field(3; "Name"; Text[250])
        {
            Caption = 'Name';
        }
        field(4; "Entity Name"; Text[250])
        {
            Caption = 'Entity Name';
        }
        field(5; "API Publisher"; Text[250])
        {
            Caption = 'API Publisher';
        }
        field(6; "API Group"; Text[250])
        {
            Caption = 'API Group';
        }
        field(7; "API Version"; Text[250])
        {
            Caption = 'API Version';
        }
    }

    keys
    {
        key(PK; "Object Type", "Object ID")
        {
            Clustered = true;
        }
    }
}
