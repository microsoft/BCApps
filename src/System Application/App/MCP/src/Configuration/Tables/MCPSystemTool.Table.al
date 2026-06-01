// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

table 8353 "MCP System Tool"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Tool Name"; Text[100])
        {
            Caption = 'Tool Name';
            ToolTip = 'Specifies the name of the system tool.';
        }
        field(2; "Tool Description"; Text[250])
        {
            Caption = 'Tool Description';
            ToolTip = 'Specifies the description of the system tool.';
        }
    }

    keys
    {
        key(Key1; "Tool Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}