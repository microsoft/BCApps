// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

/// <summary>
/// Page to display and manage registered Entra applications for MCP client connections.
/// </summary>
page 8357 "MCP Entra Application List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "MCP Entra Application";
    Caption = 'Model Context Protocol (MCP) Server Entra Applications';
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;
    AboutTitle = 'About MCP Server Entra applications';
    AboutText = 'Register Entra applications for third-party MCP clients that need to authenticate with Business Central. Users need the Client ID when configuring their third-party MCP client to connect to this environment.';

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Client ID"; Rec."Client ID")
                {
                    ToolTip = 'Specifies the Entra application (client) ID. Copy this value to use in your MCP client configuration.';
                }
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the friendly name for the Entra application.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description for the Entra application.';
                }
            }
        }
    }
}
