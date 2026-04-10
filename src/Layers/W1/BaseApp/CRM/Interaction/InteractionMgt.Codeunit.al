// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

using Microsoft.CRM.Opportunity;

codeunit 5067 "Interaction Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        OpportunityCreatedFromIntLogEntryMsg: Label 'Opportunity %1 was created based on selected interaction log entry.', Comment = '%1 - opportunity code';
        OpenOpportunityTxt: Label 'Open Opportunity.';

    procedure ShowNotificationOpportunityCreated(InteractionLogEntry: Record "Interaction Log Entry")
    var
        Notification: Notification;
    begin
        Notification.Scope(NOTIFICATIONSCOPE::LocalScope);
        Notification.AddAction(OpenOpportunityTxt, CODEUNIT::"Interaction Mgt.", 'ShowCreatedOpportunity');
        Notification.Message(StrSubstNo(OpportunityCreatedFromIntLogEntryMsg, InteractionLogEntry."Opportunity No."));
        Notification.SetData('OpportunityNo', InteractionLogEntry."Opportunity No.");
        Notification.Send();
    end;

    procedure ShowCreatedOpportunity(Notification: Notification)
    var
        Opportunity: Record Opportunity;
    begin
        Opportunity.Get(Notification.GetData('OpportunityNo'));
        PAGE.Run(PAGE::"Opportunity Card", Opportunity);
    end;
}

