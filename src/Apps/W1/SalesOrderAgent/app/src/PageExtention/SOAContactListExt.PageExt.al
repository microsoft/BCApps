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
            field(MappedEmail; MappedEmail)
            {
                Caption = 'Mapped Email';
                ToolTip = 'Specifies the email address mapped to this contact from an unknown sender during the current agent task.';
                Visible = IsAgentSession;
                Editable = false;
                ApplicationArea = Basic, Suite;
            }
            field("E-Mail 2"; Rec."E-Mail 2")
            {
                Caption = 'Email 2';
                ToolTip = 'Specifies an alternative email address for the contact.';
                Visible = IsAgentSession;
                ApplicationArea = Basic, Suite;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        SOAKPITrackAll: Codeunit "SOA - KPI Track All";
    begin
        if not IsAgentSessionInitialized then begin
            IsAgentSession := SOAKPITrackAll.IsOrderTakerAgentSession(AgentTaskID);
            IsAgentSessionInitialized := true;
        end;

        PopulateMappedEmail();
    end;

    local procedure PopulateMappedEmail()
    var
        SOATaskContactOverride: Record "SOA Task Contact Override";
        SOAEmail: Record "SOA Email";
    begin
        if IsAgentSession then begin
            SOATaskContactOverride.SetRange("Task ID", AgentTaskID);
            SOATaskContactOverride.SetRange("Contact No.", Rec."No.");
            SOATaskContactOverride.ReadIsolation := IsolationLevel::ReadUncommitted;

            if SOATaskContactOverride.FindFirst() then begin
                SOAEmail.SetRange("Task ID", AgentTaskID);
                SOAEmail.SetRange("Task Message ID", SOATaskContactOverride."Task Message ID");
                SOAEmail.ReadIsolation := IsolationLevel::ReadUncommitted;

                if SOAEmail.FindFirst() then
                    MappedEmail := SOAEmail."Sender Address"
                else
                    MappedEmail := '';
            end else
                MappedEmail := '';
        end else
            MappedEmail := '';
    end;

    var
        MappedEmail: Text[250];
        AgentTaskID: BigInteger;
        IsAgentSession: Boolean;
        IsAgentSessionInitialized: Boolean;
}
