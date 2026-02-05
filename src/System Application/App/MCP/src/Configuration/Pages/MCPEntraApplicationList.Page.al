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
    AboutText = 'Your administrator can configure Entra applications so you can connect with third-party MCP clients.';

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field(Name; Rec.Name) { }
                field(Description; Rec.Description) { }
                field("Client ID"; Rec."Client ID") { }
            }
        }
    }
}
