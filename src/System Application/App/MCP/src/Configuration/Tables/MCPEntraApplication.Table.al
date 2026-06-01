// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

/// <summary>
/// Table to store registered third-party Entra applications that can be used to connect MCP clients to Business Central.
/// </summary>
table 8351 "MCP Entra Application"
{
    Access = Internal;
    DataPerCompany = false;
    DataClassification = SystemMetadata;
    Caption = 'Model Context Protocol (MCP) Server Entra Application';
    LookupPageId = "MCP Entra Application List";
    DrillDownPageId = "MCP Entra Application List";

    fields
    {
        field(1; Name; Text[100])
        {
            Caption = 'Name';
            NotBlank = true;
            ToolTip = 'Specifies the friendly name for the Entra application registration.';
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description for the Entra application registration.';
        }
        field(3; "Client ID"; Guid)
        {
            Caption = 'Client ID';
            ToolTip = 'Specifies the Entra application (client) ID. Copy this value to use in your third-party MCP client configuration.';
        }
    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }
}
