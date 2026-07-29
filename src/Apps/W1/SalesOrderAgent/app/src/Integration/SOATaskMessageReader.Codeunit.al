// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.SalesOrderAgent;

using System.Agents;

codeunit 4420 "SOA Task Message Reader"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task Message" = r;

    internal procedure GetLastIncomingMessageContent(AgentTaskID: BigInteger): Text
    var
        AgentTaskMessage: Record "Agent Task Message";
        MessageContent: Text;
        InStream: InStream;
    begin
        if AgentTaskID = 0 then
            exit('');

        AgentTaskMessage.ReadIsolation := IsolationLevel::ReadCommitted;
        AgentTaskMessage.SetAutoCalcFields(Content);
        AgentTaskMessage.SetRange("Task ID", AgentTaskID);
        AgentTaskMessage.SetRange(Type, AgentTaskMessage.Type::Input);
        AgentTaskMessage.SetFilter(Status, '<>%1&<>%2', AgentTaskMessage.Status::Discarded, AgentTaskMessage.Status::Rejected);
        AgentTaskMessage.SetCurrentKey(SystemCreatedAt);
        AgentTaskMessage.Ascending(false);
        if not AgentTaskMessage.FindFirst() then
            exit('');

        AgentTaskMessage.Content.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.Read(MessageContent);
        exit(MessageContent);
    end;
}