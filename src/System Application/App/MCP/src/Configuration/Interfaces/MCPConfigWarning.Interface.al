// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

interface "MCP Config Warning"
{
    Access = Internal;

    procedure CheckForWarnings(ConfigId: Guid; var TempMCPConfigWarning: Record "MCP Config Warning"; var EntryNo: Integer);
    procedure WarningMessage(TempMCPConfigWarning: Record "MCP Config Warning"): Text;
    procedure RecommendedAction(TempMCPConfigWarning: Record "MCP Config Warning"): Text;
    procedure ApplyRecommendedAction(var TempMCPConfigWarning: Record "MCP Config Warning");
}
