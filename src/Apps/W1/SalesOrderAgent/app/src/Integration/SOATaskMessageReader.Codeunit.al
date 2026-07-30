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
        AgentSession: Codeunit "Agent Session";
        AgentMetadataProvider: Enum "Agent Metadata Provider";
        MessageContent: Text;
        InStream: InStream;
        TaskContextMismatchErr: Label 'The requested agent task does not match the current agent session.';
    begin
        if AgentTaskID = 0 then
            exit('');

        if not AgentSession.IsAgentSession(AgentMetadataProvider) then
            Error(TaskContextMismatchErr);
        if AgentMetadataProvider <> "Agent Metadata Provider"::"SO Agent" then
            Error(TaskContextMismatchErr);
        if AgentSession.GetCurrentSessionAgentTaskId() <> AgentTaskID then
            Error(TaskContextMismatchErr);

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