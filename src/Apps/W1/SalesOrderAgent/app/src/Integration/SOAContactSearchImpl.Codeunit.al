// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Agent.SalesOrderAgent;

using Microsoft.CRM.Contact;
using System.Agents;

codeunit 4411 "SOA Contact Search Impl"
{
    Access = Internal;
    EventSubscriberInstance = Manual;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AgentTaskID: BigInteger;

    internal procedure SetAgentTaskID(NewAgentTaskID: BigInteger)
    begin
        AgentTaskID := NewAgentTaskID;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Contact List", OnBeforeFindRecord, '', false, false)]
    local procedure FindRecordContactFromList(var Rec: Record Contact; Which: Text; var Found: Boolean; var IsHandled: Boolean)
    begin
        FindRecordContact(Rec, Which, Found, IsHandled);
    end;

    local procedure FindRecordContact(var Rec: Record Contact; Which: Text; var Found: Boolean; var IsHandled: Boolean)
    var
        AgentTaskMessage: Record "Agent Task Message";
        SOATaskContactOverride: Record "SOA Task Contact Override";
        OriginalFilterGroup: Integer;
    begin
        if AgentTaskID = 0 then
            exit;

        AgentTaskMessage.SetLoadFields(ID);
        AgentTaskMessage.SetRange("Task ID", AgentTaskID);
        AgentTaskMessage.SetRange(Type, AgentTaskMessage.Type::Input);
        AgentTaskMessage.SetFilter(Status, '<>%1&<>%2', AgentTaskMessage.Status::Discarded, AgentTaskMessage.Status::Rejected);
        AgentTaskMessage.SetCurrentKey("Task ID", SystemCreatedAt);
        AgentTaskMessage.Ascending(false);
        if not AgentTaskMessage.FindFirst() then
            exit;

        if not SOATaskContactOverride.Get(AgentTaskID, AgentTaskMessage.ID) then
            exit;

        OriginalFilterGroup := Rec.FilterGroup();
        Rec.FilterGroup(11);
        Rec.SetRange("No.", SOATaskContactOverride."Contact No.");
        Rec.FilterGroup(OriginalFilterGroup);
        Found := Rec.Find(Which);
        IsHandled := true;
    end;
}