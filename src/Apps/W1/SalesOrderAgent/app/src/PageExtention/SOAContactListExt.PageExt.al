// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Agent.SalesOrderAgent;

using Microsoft.CRM.Contact;

pageextension 4411 "SOA Contact List Ext" extends "Contact List"
{
    layout
    {
        addafter("E-Mail")
        {
            field("E-Mail 2"; Rec."E-Mail 2")
            {
                Caption = 'Email 2';
                ToolTip = 'Specifies an alternative email address for the contact.';
                Visible = IsAgentSession;
                ApplicationArea = Basic, Suite;
            }
        }
    }

    trigger OnOpenPage()
    var
        SOATaskContactOverride: Record "SOA Task Contact Override";
        SOAKPITrackAll: Codeunit "SOA - KPI Track All";
        AgentTaskID: BigInteger;
    begin
        if SOAKPITrackAll.IsOrderTakerAgentSession(AgentTaskID) then begin
            IsAgentSession := true;

            // Filter Contact List to mapped contacts for this agent session
            SOATaskContactOverride.SetRange("Task ID", AgentTaskID);
            SOATaskContactOverride.SetLoadFields("Contact No.");
            SOATaskContactOverride.ReadIsolation := IsolationLevel::ReadUncommitted;

            if SOATaskContactOverride.FindFirst() then begin
                Rec.SetFilter("No.", SOATaskContactOverride."Contact No.");
                Rec.Find('-');
            end;
        end;
    end;

    var
        IsAgentSession: Boolean;
}
