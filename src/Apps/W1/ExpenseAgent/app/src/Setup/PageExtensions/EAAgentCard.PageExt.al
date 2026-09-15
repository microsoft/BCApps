// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Agents;

pageextension 6995 "EA Agent Card" extends "Agent Card"
{
    layout
    {
        modify(State)
        {
            Enabled = Rec."Agent Metadata Provider" <> Enum::"Agent Metadata Provider"::"Expense Agent";
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        ExpenseAgentNotification: Notification;
    begin
        // Fires on initial load and on every record change (next/previous, CurrPage.Update, field validation).
        // Recall any previously sent notification to avoid stacking duplicates.
        if not IsNullGuid(ExpenseAgentNotificationId) then begin
            ExpenseAgentNotification.Id := ExpenseAgentNotificationId;
            ExpenseAgentNotification.Recall();
            Clear(ExpenseAgentNotificationId);
        end;

        if Rec."Agent Metadata Provider" <> Enum::"Agent Metadata Provider"::"Expense Agent" then
            exit;

        ExpenseAgentNotificationId := CreateGuid();
        ExpenseAgentNotification.Id := ExpenseAgentNotificationId;
        ExpenseAgentNotification.Message(ExpenseAgentInfoMsg);
        ExpenseAgentNotification.Scope := NotificationScope::LocalScope;
        ExpenseAgentNotification.AddAction(OpenSetupLbl, Codeunit::"EA Agent Card Notif. Handler", 'OpenExpenseAgentSetup');
        ExpenseAgentNotification.Send();
    end;

    var
        ExpenseAgentNotificationId: Guid;
        ExpenseAgentInfoMsg: Label 'Additional options are available in the Setup page.';
        OpenSetupLbl: Label 'Open Expense Agent Setup';
}
