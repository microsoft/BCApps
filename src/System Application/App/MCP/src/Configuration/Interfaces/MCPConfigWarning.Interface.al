// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

interface "MCP Config Warning"
{
    Access = Internal;

    procedure WarningMessage(MCPConfigWarning: Record "MCP Config Warning"): Text;
    procedure RecommendedAction(MCPConfigWarning: Record "MCP Config Warning"): Text;
    procedure ApplyRecommendedAction(var MCPConfigWarning: Record "MCP Config Warning");
}
