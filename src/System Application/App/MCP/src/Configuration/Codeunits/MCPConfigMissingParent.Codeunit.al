// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

codeunit 8354 "MCP Config Missing Parent" implements "MCP Config Warning"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        MissingParentWarningLbl: Label 'This API page has a parent page that is not included in the configuration.';
        MissingParentFixLbl: Label 'Add the parent API pages to the configuration.';

    procedure WarningMessage(MCPConfigWarning: Record "MCP Config Warning"): Text
    begin
        exit(MissingParentWarningLbl); // TODO: Enhance message with specific parent details.
    end;

    procedure RecommendedAction(MCPConfigWarning: Record "MCP Config Warning"): Text
    begin
        exit(MissingParentFixLbl);
    end;

    procedure ApplyRecommendedAction(var MCPConfigWarning: Record "MCP Config Warning")
    begin
        // TODO: Implement logic to add the parent API page to the configuration.
    end;
}
