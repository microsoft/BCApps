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
        SOAKPITrackAll: Codeunit "SOA - KPI Track All";
        AgentTaskID: BigInteger;
    begin
        IsAgentSession := SOAKPITrackAll.IsOrderTakerAgentSession(AgentTaskID);
    end;

    var
        IsAgentSession: Boolean;
}
