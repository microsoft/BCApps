// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

using System.Agents;
using System.AI;
using System.Azure.Identity;
using System.Environment;
using System.Environment.Consumption;
using System.Security.User;
using System.Telemetry;
using System.Utilities;

codeunit 4586 "SOA Dispatcher"
{
    Access = Internal;
    TableNo = "SOA Setup";
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "User AI Consumption Data" = r;

    var
        SOAImpl: Codeunit "SOA Impl";
        SOASetupCU: Codeunit "SOA Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryAgentNotEnabledLbl: Label 'Sales order agent is not enabled', Locked = true;
        TelemetryAgentCapabilityNotEnabledLbl: Label 'Sales order agent capability is not enabled', Locked = true;
        TelemetryAgentEmailMonitoringNotEnabledLbl: Label 'Sales order agent email monitoring is not enabled', Locked = true;
        TelemetryRetrieveEmailsSuccessLbl: Label 'Emails retrieved successfully', Locked = true;
        TelemetryRetrieveEmailsFailedLbl: Label 'Emails failed to be retrieved', Locked = true;
        TelemetrySendEmailRepliesSuccessLbl: Label 'Email replies sent successfully', Locked = true;
        TelemetrySendEmailRepliesFailedLbl: Label 'Email replies failed to be sent', Locked = true;
        TelemetryAgentDeactivatedUnattendedLbl: Label 'Sales order agent deactivated because the company is unattended', Locked = true;

    trigger OnRun()
    begin
        RunSOAgent(Rec);
    end;

    procedure RunSOAgent(Setup: Record "SOA Setup")
    var
        SOATask: Record "SOA Task";
        SOAEmailSetup: Codeunit "SOA Email Setup";
        CopilotQuota: Codeunit "Copilot Quota";
        SOASendReplies: Codeunit "SOA Send Replies";
        QuotaCanConsume: Boolean;
        RetrievalSuccess: Boolean;
        ReplySuccess: Boolean;
        TaskSuccess: Boolean;
        TelemetryDimensions: Dictionary of [Text, Text];
        LastSync: DateTime;
    begin
        // An agent that is deactivated or archived must not keep scheduled tasks alive.
        if SOAImpl.RemoveScheduledTasksIfAgentNotActive(Setup) then
            exit;
        if not SOASetupCU.CheckSOASetupStillValid(Setup) then
            exit;

        TelemetryDimensions.Add('SOASetupId', Format(Setup.ID));
        if not CanRunTask(Setup) then
            exit;
        if DeactivateAgentIfUnattended(Setup) then
            exit;

        AddTask(SOATask);
        if not SOASetupCU.CheckSOASetupStillValid(Setup) then
            exit;

        QuotaCanConsume := CopilotQuota.CanConsume();
        if QuotaCanConsume then begin
            // Retrieve emails
            LastSync := CurrentDateTime();
            RetrievalSuccess := Codeunit.Run(Codeunit::"SOA Retrieve Emails", Setup);
            if RetrievalSuccess then
                FeatureTelemetry.LogUsage('0000NIU', SOASetupCU.GetFeatureName(), TelemetryRetrieveEmailsSuccessLbl, TelemetryDimensions)
            else
                FeatureTelemetry.LogError('0000NIV', SOASetupCU.GetFeatureName(), 'Retrieve emails', TelemetryRetrieveEmailsFailedLbl, GetLastErrorCallStack(), TelemetryDimensions);
        end;

        // Send emails
        if not SOASetupCU.CheckSOASetupStillValid(Setup) then
            exit;

        ReplySuccess := SOASendReplies.Run(Setup);
        if ReplySuccess then
            FeatureTelemetry.LogUsage('0000NIW', SOASetupCU.GetFeatureName(), TelemetrySendEmailRepliesSuccessLbl, TelemetryDimensions)
        else
            FeatureTelemetry.LogError('0000NIX', SOASetupCU.GetFeatureName(), 'Send email replies', TelemetrySendEmailRepliesFailedLbl, GetLastErrorCallStack(), TelemetryDimensions);

        TaskSuccess := (RetrievalSuccess or not QuotaCanConsume) and ReplySuccess;

        // Reschedule
        if not SOASetupCU.CheckSOASetupStillValid(Setup) then
            exit;

        SOAImpl.ScheduleSOAgent(Setup);
        Commit();
        if RetrievalSuccess then
            UpdateLastSync(Setup, LastSync);
        if TaskSuccess then
            UpdateTaskSucceeded(SOATask, SOASendReplies.GetAllSentSuccessfully());

        // Remove processed emails that are outside limit
        SOAEmailSetup.RemoveProcessedEmailsOutsideLast24hrs();
        // Remove processed tasks older than 24 hours
        SOAImpl.RemoveTaskLogsOlderThan24hrs();
    end;

    local procedure CanRunTask(var Setup: Record "SOA Setup"): Boolean
    var
        Agent: Codeunit Agent;
        AzureOpenAI: Codeunit "Azure OpenAI";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions.Add('SOASetupId', Format(Setup.ID));
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Sales Order Agent", true) then begin
            FeatureTelemetry.LogError('0000NF5', SOASetupCU.GetFeatureName(), 'Sales order agent capability check', TelemetryAgentCapabilityNotEnabledLbl, GetLastErrorCallStack(), TelemetryDimensions);
            exit(false);
        end;

        // Check if the agent is enabled
        if not Agent.IsActive(Setup."User Security ID") then begin
            FeatureTelemetry.LogError('0000NDL', SOASetupCU.GetFeatureName(), 'Agent enable check', TelemetryAgentNotEnabledLbl, GetLastErrorCallStack(), TelemetryDimensions);
            exit(false);
        end;
        if not Setup."Email Monitoring" then begin
            FeatureTelemetry.LogError('0000NGL', SOASetupCU.GetFeatureName(), 'Email monitoring check', TelemetryAgentEmailMonitoringNotEnabledLbl, GetLastErrorCallStack(), TelemetryDimensions);
            exit(false);
        end;

        exit(true);
    end;

    // #TODO
    /*local*/
    internal procedure DeactivateAgentIfUnattended(var Setup: Record "SOA Setup"): Boolean
    var
        Agent: Codeunit Agent;
        UserLoginTimeTracker: Codeunit "User Login Time Tracker";
        TelemetryDimensions: Dictionary of [Text, Text];
        InactivityPeriodStart: DateTime;
        NoRecentUserLogin: Boolean;
    begin
        InactivityPeriodStart := CurrentDateTime() - SOASetupCU.GetUnattendedPeriodDays() * 24 * 60 * 60 * 1000 / (14 * 24 * 60) * 5;

        // Only interactive (user and device) sessions update the login information of the company.
        NoRecentUserLogin := not UserLoginTimeTracker.AnyUserLoggedInSinceDate(DT2Date(InactivityPeriodStart));
        if not NoRecentUserLogin then
            // "Activated At" is refreshed every time the setup is saved, unlike SystemModifiedAt which changes on each sync.
            if (Setup."Activated At" >= InactivityPeriodStart) or ItemAvailabilityCheckedSince(Setup, InactivityPeriodStart) then
                exit(false);

        Agent.Deactivate(Setup."User Security ID");
        Setup.Get(Setup.ID);
        Setup."Auto-Deactivated At" := CurrentDateTime();
        Setup.Modify();
        SOAImpl.RemoveScheduledTasksIfAgentNotActive(Setup);

        TelemetryDimensions.Add('SOASetupId', Format(Setup.ID));
        TelemetryDimensions.Add('NoRecentUserLogin', Format(NoRecentUserLogin));
        FeatureTelemetry.LogUsage('0000V9A', SOASetupCU.GetFeatureName(), TelemetryAgentDeactivatedUnattendedLbl, TelemetryDimensions);
        exit(true);
    end;

    local procedure ItemAvailabilityCheckedSince(var Setup: Record "SOA Setup"; FromDateTime: DateTime): Boolean
    var
        UserAIConsumptionData: Record "User AI Consumption Data";
    begin
        // Logged by "SOA Billing" when the agent checks item availability. The unique ID ends with the operation ordinal, which, unlike captions, is language independent.
        UserAIConsumptionData.SetRange("User Id", Setup."User Security ID");
        UserAIConsumptionData.SetFilter("Consumption DateTime", '>=%1', FromDateTime);
        UserAIConsumptionData.SetFilter("Unique Id", '*-%1', Format("SOA Billing Operation"::"Item Availability".AsInteger(), 0, 9));
        exit(not UserAIConsumptionData.IsEmpty());
    end;

    local procedure UpdateLastSync(var Setup: Record "SOA Setup"; DT: DateTime)
    begin
        Setup.Get(Setup.ID);
        Setup."Last Sync At" := DT;
        Setup.Modify();
        Commit();
    end;

    local procedure AddTask(var SOATask: Record "SOA Task")
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        EnvironmentInformation: Codeunit "Environment Information";
        UrlHelper: Codeunit "Url Helper";
    begin
        Clear(SOATask);
        SOATask.Status := SOATask.Status::"In Progress";
        if EnvironmentInformation.IsSaaSInfrastructure() then
            SOATask."Access Token Retrieved" := not AzureAdMgt.GetAccessTokenAsSecretText(UrlHelper.GetGraphUrl(), '', false).IsEmpty()
        else
            SOATask."Access Token Retrieved" := true;
        SOATask.Insert();
        Commit();
    end;

    local procedure UpdateTaskSucceeded(var SOATask: Record "SOA Task"; SendRepliesSuccessful: Boolean)
    begin
        SOATask."Send Replies Successful" := SendRepliesSuccessful;
        SOATask.Status := SOATask.Status::Succeeded;
        SOATask.Modify();
        Commit();
    end;
}