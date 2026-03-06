// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;
using System.Agents;

/// <summary>
/// Makes the Tax Area List page non-editable during agent sessions
/// to prevent the agent from renaming or modifying existing Tax Areas.
/// The agent can still open the Tax Area card via New to create new ones.
/// </summary>
pageextension 30475 "Shpfy Tax Area List" extends "Tax Area List"
{
    trigger OnOpenPage()
    var
        AgentSession: Codeunit "Agent Session";
        AgentMetadataProvider: Enum "Agent Metadata Provider";
    begin
        if AgentSession.IsAgentSession(AgentMetadataProvider) then
            CurrPage.Editable(false);
    end;
}
