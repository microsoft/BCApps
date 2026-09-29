// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

using System.Agents;

/// <summary>
/// Sets an output message to the terminal Failed status in its own error scope.
/// </summary>
/// <remarks>
/// The transition writes to the database, so it cannot run inside a try function. It is isolated with
/// Codeunit.Run instead, so that a rejected transition, for example because the message was concurrently
/// discarded, is trappable and does not abort the whole send run.
/// The caller passes the target message in Rec, using the status reason it wants recorded.
/// </remarks>
codeunit 4408 "SOA Set Reply Failed"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    TableNo = "Agent Task Message";

    trigger OnRun()
    var
        AgentMessage: Codeunit "Agent Message";
    begin
        AgentMessage.SetStatusToFailed(Rec."Task ID", Rec.ID, Rec."Status Reason");
    end;
}
