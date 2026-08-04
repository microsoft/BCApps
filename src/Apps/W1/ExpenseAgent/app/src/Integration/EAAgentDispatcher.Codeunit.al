// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

using System.AI;
using System.Azure.Identity;
using System.Email;
using System.Environment;
using System.Telemetry;
using System.Utilities;

codeunit 6938 "EA Agent Dispatcher"
{
    Access = Internal;
    TableNo = "Expense Agent Setup";
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        EAAgentScheduler: Codeunit "EA Agent Scheduler";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        MaxEmailSendRetryCount: Integer;
        MaxEmailSendsPerRun: Integer;
        TelemetryRetrieveEmailsSuccessLbl: Label 'Emails retrieved successfully', Locked = true;
        TelemetryRetrieveEmailsFailedLbl: Label 'Emails failed to be retrieved', Locked = true;
        TelemetryEmailSendFailedLbl: Label 'Outbox email send failed.', Locked = true;
        TelemetryEmailSendRunCompleteLbl: Label 'Email send dispatcher run completed.', Locked = true;
        TelemetryNotifRunCompleteLbl: Label 'Notification dispatcher run completed.', Locked = true;
        TelemetryNotifMissingUserLbl: Label 'Open report references a missing Expense User.', Locked = true;
        TelemetryNotifReminderFailedLbl: Label 'Open report reminder notification failed.', Locked = true;
        TelemetryWelcomeSuccessLbl: Label 'Welcome email: All handed to outbox.', Locked = true;
        TelemetryWelcomePartialLbl: Label 'Welcome email: Some handed to outbox, some failed.', Locked = true;
        TelemetryWelcomeAllFailedLbl: Label 'Welcome email: All failed to hand off.', Locked = true;
        TelemetryWelcomeProcessingErrLbl: Label 'Welcome email: Processing stopped unexpectedly.', Locked = true;
        SendWelcomeEmailsLbl: Label 'Send welcome emails', Locked = true;
        NoEmailRegisteredErr: Label 'No email account or "noreply email" account is registered for the Expense Agent. Set up email accounts from the Expense Agent setup page to continue.', Comment = 'Shown when no email account is configured for the Expense Agent.';
        NoRecipientErr: Label 'At least one recipient must be specified in To line, Cc line, or Bcc line.', Comment = 'Shown when an outbox email has no recipients in any of the address lines.';
        NoSetupErr: Label 'Expense Agent is not set up yet.';
        AgentNotEnabledErr: Label 'Expense Agent is not enabled.';
        NoEmailAccErr: Label 'Expense Agent has no email account specified.';
        CapabilityNotEnabledErr: Label 'The Expense Agent capability is not enabled.';

    trigger OnRun()
    begin
        MaxEmailSendRetryCount := 5;
        MaxEmailSendsPerRun := 25;
        RunEAAgent(Rec);
    end;

    procedure RunEAAgent(var Setup: Record "Expense Agent Setup")
    var
        EASchedulerTask: Record "EA Scheduler Task";
        ExpenseAgentStatus: Record "Expense Agent Status";
        EAEmailSetup: Codeunit "EA Email Setup";
        EARetrieveEmails: Codeunit "EA Retrieve Emails";
        RetrievalSuccess: Boolean;
        TelemetryDimensions: Dictionary of [Text, Text];
        LastSync: DateTime;
        ErrorMessage: Text;
    begin
        TelemetryDimensions.Add('EASetupId', Format(Setup.SystemId));

        AddTask(EASchedulerTask);
        ExpenseAgentStatus.ReadIsolation(IsolationLevel::UpdLock);
        ExpenseAgentStatus.Get();
        ExpenseAgentStatus."EA Scheduler Task ID" := EASchedulerTask.ID;
        ExpenseAgentStatus.Modify();
        Commit();

        if not CanRunTask(Setup, ErrorMessage) then begin
            EASchedulerTask.Status := EASchedulerTask.Status::Failed;
            EASchedulerTask."Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(EASchedulerTask."Error Message"));
            EASchedulerTask.Modify();
            exit;
        end;

        // === Phase 1: Email Read ===
        if Setup."Enable Email with Receipts" and not IsNullGuid(Setup."Email Account ID") then begin
            LastSync := CurrentDateTime();
            RetrievalSuccess := EARetrieveEmails.Run(Setup);
            if RetrievalSuccess then begin
                TelemetryDimensions.Set('EmailsFound', Format(EARetrieveEmails.GetEmailsFound()));
                TelemetryDimensions.Set('EmailsProcessed', Format(EARetrieveEmails.GetEmailsProcessed()));
                FeatureTelemetry.LogUsage('0000QKT', Setup.GetFeatureName(), TelemetryRetrieveEmailsSuccessLbl, TelemetryDimensions);
                TelemetryDimensions.Remove('EmailsFound');
                TelemetryDimensions.Remove('EmailsProcessed');
                UpdateLastSync(LastSync);
            end else
                FeatureTelemetry.LogError('0000QKS', Setup.GetFeatureName(), 'Retrieve emails', TelemetryRetrieveEmailsFailedLbl, GetLastErrorCallStack(), TelemetryDimensions);
            Commit();
        end;

        // === Phase 2: Email Send ===
        // Deliver pending outbound emails (welcome, reminder, reimbursement, approval
        // notifications) only while outgoing communication is configured: the master
        // "Enable Communication" toggle is on and a Noreply account is set. This is
        // independent of "Enable Email with Receipts", which only governs the inbound
        // receipts feature (Phase 1). Outbound emails are always sent from the Noreply account.
        if Setup.IsOutgoingCommunicationConfigured() then begin
            SendPendingEmails(Setup);
            Commit();
        end;

        // === Phase 3: Reminder Notifications ===
        if ShouldRunNotifications(Setup) then begin
            if not TrySendOpenReportReminders(Setup) then
                FeatureTelemetry.LogError('0000SJG', Setup.GetFeatureName(), 'Send notifications', TelemetryNotifReminderFailedLbl, GetLastErrorCallStack(), TelemetryDimensions)
            else
                UpdateLastNotifRunAt();
            Commit();
        end;

        // === Phase 4: Welcome Emails ===
        if Setup.IsOutgoingCommunicationConfigured() then
            SendQueuedWelcomeEmails(Setup, TelemetryDimensions);

        // === Reschedule ===
        Setup.Get();
        EAAgentScheduler.ScheduleAgent(Setup);
        Commit();

        // === Cleanup ===
        UpdateTaskSucceeded(EASchedulerTask);
        EAEmailSetup.RemoveProcessedEmailsOutsideLast24hrs();
        RemoveSentEmailsOlderThan1Day();
    end;

    local procedure CanRunTask(var Setup: Record "Expense Agent Setup"; var ErrorMessage: Text): Boolean
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
    begin
        if IsNullGuid(Setup.SystemId) then begin
            ErrorMessage := NoSetupErr;
            exit(false);
        end;

        if not Setup."Enable Agent" then begin
            ErrorMessage := AgentNotEnabledErr;
            exit(false);
        end;

        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Expense Agent", true) then begin
            ErrorMessage := CapabilityNotEnabledErr;
            exit(false);
        end;

        if Setup."Enable Email with Receipts" and IsNullGuid(Setup."Email Account ID") then begin
            ErrorMessage := NoEmailAccErr;
            exit(false);
        end;

        ErrorMessage := '';
        exit(true);
    end;

    local procedure UpdateLastSync(DT: DateTime)
    var
        ExpenseAgentStatus: Record "Expense Agent Status";
    begin
        ExpenseAgentStatus.GetOrCreate();
        ExpenseAgentStatus."Last Sync At" := DT;
        ExpenseAgentStatus.Modify();
        Commit();
    end;

    local procedure AddTask(var EASchedulerTask: Record "EA Scheduler Task")
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        EnvironmentInformation: Codeunit "Environment Information";
        UrlHelper: Codeunit "Url Helper";
    begin
        Clear(EASchedulerTask);
        EASchedulerTask.Status := EASchedulerTask.Status::"In Progress";
        if EnvironmentInformation.IsSaaSInfrastructure() then
            EASchedulerTask."Access Token Retrieved" := not AzureAdMgt.GetAccessTokenAsSecretText(UrlHelper.GetGraphUrl(), '', false).IsEmpty()
        else
            EASchedulerTask."Access Token Retrieved" := true;
        EASchedulerTask.Insert();
    end;

    local procedure UpdateTaskSucceeded(var EASchedulerTask: Record "EA Scheduler Task")
    begin
        EASchedulerTask.ReadIsolation(IsolationLevel::UpdLock);
        if EASchedulerTask.Get(EASchedulerTask.ID) then begin
            EASchedulerTask."Send Replies Successful" := true;
            EASchedulerTask.Status := EASchedulerTask.Status::Succeeded;
            EASchedulerTask."Error Message" := '';
            EASchedulerTask.Modify();
        end;
        Commit();
    end;

    // ===== Email Send Logic =====
    local procedure SendPendingEmails(Setup: Record "Expense Agent Setup")
    var
        OutboxEmail: Record "EA Outbox Email";
        TelemetryDimensions: Dictionary of [Text, Text];
        ProcessedCount: Integer;
        SentCount: Integer;
        RejectedCount: Integer;
        FailedCount: Integer;
    begin
        TelemetryDimensions.Add('EASetupId', Format(Setup.SystemId));

        OutboxEmail.SetRange(Status, OutboxEmail.Status::Pending);
        if OutboxEmail.FindSet() then
            repeat
                if not AreAllRecipientsExpenseUsers(OutboxEmail) then begin
                    OutboxEmail.Status := OutboxEmail.Status::Rejected;
                    OutboxEmail.Modify();
                    UpdateWelcomeStatusFromOutbox(OutboxEmail, false);
                    RejectedCount += 1;
                end else
                    if SendEmail(OutboxEmail, Setup) then begin
                        OutboxEmail.Status := OutboxEmail.Status::Sent;
                        OutboxEmail.Modify();
                        UpdateWelcomeStatusFromOutbox(OutboxEmail, true);
                        SentCount += 1;
                    end else begin
                        OutboxEmail."Retry Count" += 1;
                        if OutboxEmail."Retry Count" >= MaxEmailSendRetryCount then
                            OutboxEmail.Status := OutboxEmail.Status::Failed;
                        OutboxEmail.Modify();
                        if OutboxEmail.Status = OutboxEmail.Status::Failed then begin
                            UpdateWelcomeStatusFromOutbox(OutboxEmail, false);
                            FailedCount += 1;
                        end;
                        FeatureTelemetry.LogError('0000SI6', Setup.GetFeatureName(), 'Send email', TelemetryEmailSendFailedLbl, GetLastErrorCallStack(), TelemetryDimensions);
                    end;
                Commit();

                ProcessedCount += 1;
            until (ProcessedCount >= MaxEmailSendsPerRun) or (OutboxEmail.Next() = 0);

        TelemetryDimensions.Set('Processed', Format(ProcessedCount));
        TelemetryDimensions.Set('Sent', Format(SentCount));
        TelemetryDimensions.Set('Rejected', Format(RejectedCount));
        TelemetryDimensions.Set('Failed', Format(FailedCount));
        FeatureTelemetry.LogUsage('0000SI7', Setup.GetFeatureName(), TelemetryEmailSendRunCompleteLbl, TelemetryDimensions);
    end;

    /// <summary>
    /// Maps a terminal outbox delivery result back to the originating Expense User's
    /// welcome status via the correlation id (hop-2). Only welcome notifications are
    /// tracked per-user; other notification types (and rows without a correlation id,
    /// e.g. from an older service) are ignored so their status stays as-is. The service
    /// is deployed ahead of this extension, so welcome rows always carry a correlation id.
    /// </summary>
    local procedure UpdateWelcomeStatusFromOutbox(OutboxEmail: Record "EA Outbox Email"; Delivered: Boolean)
    var
        ExpenseUser: Record "Expense User";
    begin
        if IsNullGuid(OutboxEmail."Correlation Id") then
            exit;

        if OutboxEmail."Notification Type" = OutboxEmail."Notification Type"::Welcome then
            ExpenseUser.ApplyWelcomeDeliveryResult(OutboxEmail."Correlation Id", Delivered);
    end;

    local procedure RemoveSentEmailsOlderThan1Day()
    var
        OutboxEmail: Record "EA Outbox Email";
        Cutoff: DateTime;
    begin
        Cutoff := CreateDateTime(CalcDate('<-1D>', Today()), 0T);
        OutboxEmail.SetRange(Status, OutboxEmail.Status::Sent);
        OutboxEmail.SetFilter(SystemModifiedAt, '<%1', Cutoff);
        if not OutboxEmail.IsEmpty() then
            OutboxEmail.DeleteAll();
    end;

    local procedure AreAllRecipientsExpenseUsers(OutboxEmail: Record "EA Outbox Email"): Boolean
    begin
        if not AreAllRecipientsInLineExpenseUsers(OutboxEmail.ToLine) then
            exit(false);
        if not AreAllRecipientsInLineExpenseUsers(OutboxEmail.CCLine) then
            exit(false);
        if not AreAllRecipientsInLineExpenseUsers(OutboxEmail.BCCLine) then
            exit(false);
        exit(true);
    end;

    local procedure AreAllRecipientsInLineExpenseUsers(RecipientLine: Text): Boolean
    var
        ExpenseUser: Record "Expense User";
        Recipients: List of [Text];
        Recipient: Text;
    begin
        Recipients := RecipientLine.Split(';', ',');

        foreach Recipient in Recipients do begin
            Recipient := Recipient.Trim();
            if Recipient <> '' then begin
                ExpenseUser.SetRange("E-mail", Recipient);
                if ExpenseUser.IsEmpty() then
                    exit(false);
            end;
        end;

        exit(true);
    end;

    local procedure SendEmail(var OutboxEmail: Record "EA Outbox Email"; Setup: Record "Expense Agent Setup"): Boolean
    var
        EmailAccount: Codeunit "Email Account";
        EmailMessage: Codeunit "Email Message";
        Email: Codeunit Email;
        ToRecipients: List of [Text];
        CCRecipients: List of [Text];
        BCCRecipients: List of [Text];
        SendAccountID: Guid;
        SendConnector: Enum "Email Connector";
    begin
        GetSendEmailAccount(Setup, SendAccountID, SendConnector);

        if not EmailAccount.IsAccountRegistered(SendAccountID, SendConnector) then
            Error(NoEmailRegisteredErr);

        ToRecipients := ExtractAndValidateRecipients(OutboxEmail.ToLine);
        CCRecipients := ExtractAndValidateRecipients(OutboxEmail.CCLine);
        BCCRecipients := ExtractAndValidateRecipients(OutboxEmail.BCCLine);

        if (ToRecipients.Count() = 0) and (CCRecipients.Count() = 0) and (BCCRecipients.Count() = 0) then
            Error(NoRecipientErr);

        EmailMessage.Create(ToRecipients, OutboxEmail.Subject, OutboxEmail.ReadBody(), true, CCRecipients, BCCRecipients);
        exit(Email.Send(EmailMessage, SendAccountID, SendConnector));
    end;

    local procedure GetSendEmailAccount(Setup: Record "Expense Agent Setup"; var AccountID: Guid; var Connector: Enum "Email Connector")
    begin
        // Outbound Expense Agent emails are always sent from the Noreply account; If the Noreply account is not set or registered, SendEmail surfaces NoEmailRegisteredErr.
        AccountID := Setup."Noreply Email Account ID";
        Connector := Setup."Noreply Email Connector";
    end;

    local procedure ExtractAndValidateRecipients(RecipientsLine: Text): List of [Text]
    var
        EmailAccount: Codeunit "Email Account";
        TempRecipients: List of [Text];
        Recipients: List of [Text];
        TempRecipient: Text;
    begin
        TempRecipients := RecipientsLine.Split(';', ',');

        foreach TempRecipient in TempRecipients do begin
            TempRecipient := TempRecipient.Trim();
            if TempRecipient <> '' then begin
                EmailAccount.ValidateEmailAddress(TempRecipient);
                Recipients.Add(TempRecipient);
            end;
        end;

        exit(Recipients);
    end;

    // ===== Notification Logic =====

    local procedure ShouldRunNotifications(Setup: Record "Expense Agent Setup"): Boolean
    var
        ExpenseAgentStatus: Record "Expense Agent Status";
        NextRunDT: DateTime;
    begin
        if not Setup."Enable Communication" then
            exit(false);
        if not Setup."Enable Open Report Notif." then
            exit(false);
        if IsNullGuid(Setup."Noreply Email Account ID") then
            exit(false);
        if Setup."Open Report Notif. Freq." = "Expense Report Frequency"::" " then
            exit(false);

        ExpenseAgentStatus.GetOrCreate();
        if ExpenseAgentStatus."Last Notif. Run At" = 0DT then begin
            // First time: initialize last run to now so the next notification fires on the proper schedule
            ExpenseAgentStatus."Last Notif. Run At" := CurrentDateTime();
            ExpenseAgentStatus.Modify();
            Commit();
            exit(false);
        end;

        NextRunDT := CalcNextRunDateTime(Setup, ExpenseAgentStatus."Last Notif. Run At");
        if CurrentDateTime() < NextRunDT then
            exit(false);

        exit(true);
    end;

    [TryFunction]
    local procedure TrySendOpenReportReminders(Setup: Record "Expense Agent Setup")
    begin
        SendOpenReportReminders(Setup);
    end;

    local procedure SendOpenReportReminders(Setup: Record "Expense Agent Setup")
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: Record "Expense User";
        EAHttpClient: Codeunit "EA Http Client";
        ExpenseUserNos: List of [Code[20]];
        ExpenseUserNo: Code[20];
        TelemetryDimensions: Dictionary of [Text, Text];
        OpenReportsCount: Integer;
        SentCount: Integer;
        SkippedCount: Integer;
    begin
        TelemetryDimensions.Add('EASetupId', Format(Setup.SystemId));

        ExpenseReportHeader.SetLoadFields("Expense User No.");
        ExpenseReportHeader.SetRange(Status, "Expense Report Status"::Open);
        if not ExpenseReportHeader.FindSet() then begin
            TelemetryDimensions.Set('OpenReports', '0');
            TelemetryDimensions.Set('Sent', '0');
            TelemetryDimensions.Set('Skipped', '0');
            FeatureTelemetry.LogUsage('0000RNC', Setup.GetFeatureName(), TelemetryNotifRunCompleteLbl, TelemetryDimensions);
            UpdateLastNotifRunAt();
            exit;
        end;

        // Collect distinct expense user numbers
        repeat
            OpenReportsCount += 1;
            if not ExpenseUserNos.Contains(ExpenseReportHeader."Expense User No.") then
                ExpenseUserNos.Add(ExpenseReportHeader."Expense User No.");
        until ExpenseReportHeader.Next() = 0;

        // Send one notification per expense user via gateway API
        foreach ExpenseUserNo in ExpenseUserNos do
            if not ExpenseUser.Get(ExpenseUserNo) then begin
                SkippedCount += 1;
                FeatureTelemetry.LogError('0000UTV', Setup.GetFeatureName(), 'Send notification', TelemetryNotifMissingUserLbl, '', TelemetryDimensions);
            end else
                if ExpenseUser."E-mail" = '' then
                    SkippedCount += 1
                else
                    if EAHttpClient.SendOpenReportReminderNotification(ExpenseUser."E-mail") then
                        SentCount += 1
                    else
                        FeatureTelemetry.LogError('0000SJH', Setup.GetFeatureName(), 'Send notification', TelemetryNotifReminderFailedLbl, GetLastErrorCallStack(), TelemetryDimensions);

        TelemetryDimensions.Set('OpenReports', Format(OpenReportsCount));
        TelemetryDimensions.Set('Sent', Format(SentCount));
        TelemetryDimensions.Set('Skipped', Format(SkippedCount));
        FeatureTelemetry.LogUsage('0000RNC', Setup.GetFeatureName(), TelemetryNotifRunCompleteLbl, TelemetryDimensions);
    end;

    local procedure SendQueuedWelcomeEmails(var Setup: Record "Expense Agent Setup"; TelemetryDimensions: Dictionary of [Text, Text])
    var
        ExpenseUser: Record "Expense User";
        QueuedUserNos: List of [Code[20]];
        UserNo: Code[20];
        CorrelationId: Guid;
        HandedOffCount: Integer;
        FailedCount: Integer;
        Sent: Boolean;
    begin
        ExpenseUser.SetRange("Welcome Email Status", ExpenseUser."Welcome Email Status"::Queued);
        ExpenseUser.SetFilter("E-mail", '<>%1', '');
        if not ExpenseUser.FindSet() then
            exit;
        repeat
            QueuedUserNos.Add(ExpenseUser."No.");
        until ExpenseUser.Next() = 0;

        // Process each queued user
        foreach UserNo in QueuedUserNos do begin
            if not ExpenseUser.Get(UserNo) then
                continue;
            if ExpenseUser."Welcome Email Status" <> ExpenseUser."Welcome Email Status"::Queued then
                continue;

            // Correlation id lets Phase 2 map the eventual outbox delivery back to this user.
            CorrelationId := CreateGuid();

            // TryFunction wraps only the HTTP call; the MODIFY happens outside the try.
            if TrySendWelcomeEmail(ExpenseUser."E-mail", CorrelationId, Sent) then begin
                ExpenseUser.SetWelcomeEmailHandoffResult(Sent, CorrelationId); // success -> In Outbox (awaiting delivery)
                if Sent then
                    HandedOffCount += 1
                else
                    FailedCount += 1;
            end else begin
                ExpenseUser.SetWelcomeEmailHandoffResult(false, CorrelationId); // mark Failed so it isn't retried endlessly
                FailedCount += 1;
                FeatureTelemetry.LogError('0000UE3', Setup.GetFeatureName(), SendWelcomeEmailsLbl, TelemetryWelcomeProcessingErrLbl, GetLastErrorCallStack(), TelemetryDimensions);
            end;
            Commit(); // persist each send so a later failure can't re-queue an already-handed-off user
        end;

        // Telemetry: log the outcome of the hop-1 handoff to the Expense Agent service
        if (HandedOffCount = 0) and (FailedCount = 0) then
            exit;

        if HandedOffCount = 0 then
            FeatureTelemetry.LogError('0000UE4', Setup.GetFeatureName(), SendWelcomeEmailsLbl, TelemetryWelcomeAllFailedLbl, GetLastErrorCallStack(), TelemetryDimensions)
        else
            if FailedCount > 0 then
                FeatureTelemetry.LogUsage('0000UE5', Setup.GetFeatureName(), TelemetryWelcomePartialLbl, TelemetryDimensions)
            else
                FeatureTelemetry.LogUsage('0000UE6', Setup.GetFeatureName(), TelemetryWelcomeSuccessLbl, TelemetryDimensions);
    end;

    [TryFunction]
    local procedure TrySendWelcomeEmail(EmailAddress: Text; CorrelationId: Guid; var Sent: Boolean)
    var
        EAHttpClient: Codeunit "EA Http Client";
    begin
        Sent := EAHttpClient.SendWelcomeEmailNotification(EmailAddress, CorrelationId);
    end;

    local procedure UpdateLastNotifRunAt()
    var
        ExpenseAgentStatus: Record "Expense Agent Status";
    begin
        ExpenseAgentStatus.GetOrCreate();
        ExpenseAgentStatus."Last Notif. Run At" := CurrentDateTime();
        ExpenseAgentStatus.Modify();
        Commit();
    end;

    internal procedure CalcNextRunDateTime(EASetup: Record "Expense Agent Setup"; LastRunAt: DateTime): DateTime
    var
        NextDate: Date;
        BaseDate: Date;
        DayOfWeekInt: Integer;
        BaseDOW: Integer;
        DaysUntil: Integer;
    begin
        BaseDate := DT2Date(LastRunAt);

        case EASetup."Open Report Notif. Freq." of
            "Expense Report Frequency"::Daily:
                NextDate := BaseDate + 1;
            "Expense Report Frequency"::Weekly:
                begin
                    DayOfWeekInt := EASetup."Notif. Day of Week".AsInteger();
                    BaseDOW := Date2DWY(BaseDate, 1) mod 7; // Date2DWY returns 1=Monday..7=Sunday; mod 7 converts to 0=Sunday, 1=Monday..6=Saturday

                    DaysUntil := DayOfWeekInt - BaseDOW;
                    if DaysUntil <= 0 then
                        DaysUntil += 7;
                    NextDate := BaseDate + DaysUntil;
                end;
            "Expense Report Frequency"::Monthly:
                NextDate := CalcNextMonthlyDate(BaseDate, EASetup."Notif. Day In A Month");
            "Expense Report Frequency"::Custom:
                NextDate := CalcNextCustomDate(BaseDate, EASetup."Custom Notif. Formula");
            else
                exit(LastRunAt + 86400000); // Fallback: 24 hours
        end;

        exit(CreateDateTime(NextDate, 090000T));
    end;

    local procedure CalcNextMonthlyDate(TodayDate: Date; DayInMonth: Integer): Date
    var
        TargetDay: Integer;
        NextMonth: Date;
        MaxDaysInMonth: Integer;
    begin
        if DayInMonth = 0 then
            DayInMonth := 1;

        TargetDay := DayInMonth;

        // Try current month first
        MaxDaysInMonth := Date2DMY(CalcDate('<CM>', TodayDate), 1);
        if TargetDay > MaxDaysInMonth then
            TargetDay := MaxDaysInMonth;

        if DMY2Date(TargetDay, Date2DMY(TodayDate, 2), Date2DMY(TodayDate, 3)) > TodayDate then
            exit(DMY2Date(TargetDay, Date2DMY(TodayDate, 2), Date2DMY(TodayDate, 3)));

        // Move to next month
        NextMonth := CalcDate('<+1M>', TodayDate);
        TargetDay := DayInMonth;
        MaxDaysInMonth := Date2DMY(CalcDate('<CM>', NextMonth), 1);
        if TargetDay > MaxDaysInMonth then
            TargetDay := MaxDaysInMonth;

        exit(DMY2Date(TargetDay, Date2DMY(NextMonth, 2), Date2DMY(NextMonth, 3)));
    end;

    local procedure CalcNextCustomDate(TodayDate: Date; Formula: DateFormula): Date
    var
        NextDate: Date;
    begin
        NextDate := CalcDate(Formula, TodayDate);
        if NextDate <= TodayDate then
            NextDate := TodayDate + 1;
        exit(NextDate);
    end;
}
