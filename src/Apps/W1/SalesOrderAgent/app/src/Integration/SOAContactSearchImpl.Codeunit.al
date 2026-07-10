// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Agent.SalesOrderAgent;

using Microsoft.CRM.Contact;

codeunit 4419 "SOA Contact Search Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Page, Page::"Contact List", OnBeforeFindRecord, '', false, false)]
    local procedure FindRecordContactFromList(var Rec: Record Contact; Which: Text; var Found: Boolean; var IsHandled: Boolean)
    begin
        FindRecordContact(Rec, Which, Found, IsHandled);
    end;

    procedure FindRecordContact(var Rec: Record Contact; Which: Text; var Found: Boolean; var IsHandled: Boolean)
    var
        SOATaskContactOverride: Record "SOA Task Contact Override";
        SOAKPITrackAll: Codeunit "SOA - KPI Track All";
        AgentTaskID: BigInteger;
        IsAgentSession: Boolean;
    begin
        IsAgentSession := SOAKPITrackAll.IsOrderTakerAgentSession(AgentTaskID);
        if (not IsAgentSession) or (AgentTaskID = 0) then
            exit;

        SOATaskContactOverride.SetLoadFields("Contact No.");
        SOATaskContactOverride.SetRange("Task ID", AgentTaskID);
        SOATaskContactOverride.ReadIsolation := IsolationLevel::ReadUncommitted;
        if SOATaskContactOverride.FindFirst() then begin
            Rec.Reset();
            Rec.SetRange("No.", SOATaskContactOverride."Contact No.");
            Found := Rec.Find(Which);
            IsHandled := true;
        end;
    end;
}

