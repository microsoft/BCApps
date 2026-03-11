// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

using System.Telemetry;

codeunit 8888 "Email Dispatcher"
{
    Access = Internal;
    TableNo = "Email Outbox";
    Permissions = tabledata "Sent Email" = ri,
                  tabledata "Email Outbox" = rimd,
                  tabledata "Email Message" = r,
                  tabledata "Email Error" = ri,
                  tabledata "Email Rate Limit" = r;

    var
        EmailMessageImpl: Codeunit "Email Message Impl.";
        Success: Boolean;
        EmailCategoryLbl: Label 'Email', Locked = true;
        EmailFeatureNameLbl: Label 'Emailing', Locked = true;
        FailedToFindEmailMessageMsg: Label 'Failed to find email message %1', Comment = '%1 - Email Message Id', Locked = true;
        FailedToFindEmailMessageErrorMsg: Label 'The email message has been deleted by another user.';
        AttachmentMsg: Label 'Sending email with attachment file size: %1, Content type: %2', Comment = '%1 - File size, %2 - Content type', Locked = true;

    trigger OnRun()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        EmailRateLimitImpl: Codeunit "Email Rate Limit Impl.";
        Dimensions: Dictionary of [Text, Text];
        RateLimitDuration: Duration;
    begin
        Dimensions.Add('Connector', Format(Rec.Connector));
        Dimensions.Add('EmailMessageID', Format(Rec."Message Id", 0, 4));
        Dimensions.Add('EmailAccountID', Format(Rec."Account Id", 0, 4));
        FeatureTelemetry.LogUptake('0000CTM', EmailFeatureNameLbl, Enum::"Feature Uptake Status"::Used, Dimensions);

        // -----------
        // NB: Avoid adding events here as any error would cause a roll-back and possibly an inconsistent state of the Email Outbox.
        // -----------

        Rec.LockTable(true);
        if EmailRateLimitImpl.IsRateLimitExceeded(Rec."Account Id", Rec.Connector, Rec."Send From", RateLimitDuration) or EmailRateLimitImpl.IsConcurrencyLimitExceeded(Rec."Account Id", Rec.Connector, Rec."Send From") then
            RescheduleEmail(RateLimitDuration, Dimensions, Rec)
        else
            SendEmail(Rec);
    end;

    local procedure SendEmail(var EmailOutbox: Record "Email Outbox")
    var
        EmailMessage: Record "Email Message";
        SentEmail: Record "Sent Email";
        SendEmailCodeunit: Codeunit "Send Email";
        EmailRetryImpl: Codeunit "Email Retry Impl.";
        Email: Codeunit Email;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Dimensions: Dictionary of [Text, Text];
        LastErrorText: Text;
    begin
        // -----------
        // NB: Avoid adding events here as any error would cause a roll-back and possibly an inconsistent state of the Email Outbox.
        // -----------
        UpdateOutboxStatus(EmailOutbox, EmailOutbox.Status::Processing);

        if EmailMessageImpl.Get(EmailOutbox."Message Id") then begin
            LogAttachments();

            SendEmailCodeunit.SetConnector(EmailOutbox.Connector);
            SendEmailCodeunit.SetAccount(EmailOutbox."Account Id");

            EmailMessageImpl.GetEmailMessage(EmailMessage);
            Success := SendEmailCodeunit.Run(EmailMessage);

            if Success then begin
                FeatureTelemetry.LogUsage('0000CTV', EmailFeatureNameLbl, 'Email sent', Dimensions);
                InsertToSentEmail(EmailOutbox, SentEmail);
                EmailRetryImpl.CleanEmailRetry(EmailOutbox."Message Id");
                EmailOutbox.Delete();
                EmailMessageImpl.MarkAsRead();
                Commit();
            end else begin
                FeatureTelemetry.LogError('0000CTP', EmailFeatureNameLbl, 'Failed to send email', GetLastErrorText(true), GetLastErrorCallStack(), Dimensions);
                LastErrorText := GetLastErrorText();
                UpdateOutboxError(LastErrorText, EmailOutbox);
                UpdateOutboxStatus(EmailOutbox, EmailOutbox.Status::Failed);

                if EmailOutbox."Is Background Task" then begin
                    if EmailOutbox."Retry No." = 1 then
                        EmailRetryImpl.CreateEmailRetry(EmailOutbox);

                    EmailRetryImpl.UpdateEmailRetryRecord(EmailOutbox."Message Id", EmailOutbox."Retry No.", EmailOutbox.Status::Failed, LastErrorText, EmailOutbox."Date Queued", EmailOutbox."Date Failed", EmailOutbox."Date Sending");

                    // if email is not rescheduled, it means it has exceeded the retry limit, stop retrying
                    if RetrySendEmail(EmailOutbox) then exit;
                end;
            end;
        end else begin
            FeatureTelemetry.LogError('0000CTR', EmailFeatureNameLbl, 'Failed to find email', StrSubstNo(FailedToFindEmailMessageMsg, EmailOutbox."Message Id"), '', Dimensions);
            UpdateOutboxError(FailedToFindEmailMessageErrorMsg, EmailOutbox);
            UpdateOutboxStatus(EmailOutbox, EmailOutbox.Status::Failed);
        end;

        if Success then
            Email.OnAfterEmailSent(SentEmail)
        else
            Email.OnAfterEmailSendFailed(EmailOutbox);
    end;

    local procedure GetMaximumRetryCount(var EmailOutbox: Record "Email Outbox"): Integer
    var
        EmailRateLimit: Record "Email Rate Limit";
    begin
        if EmailRateLimit.Get(EmailOutbox."Account Id", EmailOutbox.Connector) then
            exit(EmailRateLimit."Max. Retry Limit");

        exit(0);
    end;

    local procedure RetrySendEmail(var EmailOutbox: Record "Email Outbox"): Boolean
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        EmailRetryImpl: Codeunit "Email Retry Impl.";
        Dimensions: Dictionary of [Text, Text];
        TaskId: Guid;
        RetryTime: DateTime;
        RandomDelay: Integer;
    begin
        FeatureTelemetry.LogUsage('0000PMT', EmailFeatureNameLbl, 'Email Retry - Start to retry failed email', Dimensions);
        EmailOutbox.Validate("Retry No.", EmailOutbox."Retry No." + 1);

        if EmailOutbox."Retry No." > GetMaximumRetryCount(EmailOutbox) then begin
            FeatureTelemetry.LogError('0000PMU', EmailFeatureNameLbl, 'Email Retry - Retry reached maximum times', '', '', Dimensions);
            exit(false);
        end;

        EmailOutbox.Status := EmailOutbox.Status::Queued;
        EmailOutbox.Modify();

        // Jitter - Random delay between 0 and 5000 milliseconds (5 seconds)
        RandomDelay := Random(5000);
        // Base interval: 1.5 minutes, plus a random delay of up to 5 seconds
        RetryTime := CurrentDateTime() + EmailOutbox."Retry No." * 1.5 * 60000 + RandomDelay;

        FeatureTelemetry.LogUsage('0000PMV', EmailFeatureNameLbl, 'Email Retry - Rescheduling email', Dimensions);
        TaskId := TaskScheduler.CreateTask(Codeunit::"Email Dispatcher", Codeunit::"Email Error Handler", true, CompanyName(), RetryTime, EmailOutbox.RecordId());
        EmailOutbox.Validate("Task Scheduler Id", TaskId);
        EmailOutbox.Validate("Date Sending", RetryTime);
        EmailOutbox.Modify();

        EmailRetryImpl.CreateEmailRetry(EmailOutbox);
    end;

    local procedure RescheduleEmail(Delay: Duration; Dimensions: Dictionary of [Text, Text]; var EmailOutbox: Record "Email Outbox")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TaskId: Guid;
        RandomDelay: Integer;
        RescheduleTime: DateTime;
    begin
        // -----------
        // NB: Avoid adding events here as any error would cause a roll-back and possibly an inconsistent state of the Email Outbox.
        // -----------

        // Jitter - Random delay between 0 and 10000 milliseconds (10 seconds)
        RandomDelay := Random(10000);
        RescheduleTime := CurrentDateTime() + Delay + RandomDelay;

        TaskId := TaskScheduler.CreateTask(Codeunit::"Email Dispatcher", Codeunit::"Email Error Handler", true, CompanyName(), RescheduleTime, EmailOutbox.RecordId());

        EmailOutbox."Task Scheduler Id" := TaskId;
        EmailOutbox."Date Sending" := RescheduleTime;
        EmailOutbox.Status := EmailOutbox.Status::Queued;
        EmailOutbox.Modify();

        Dimensions.Add('TaskId', Format(TaskId));
        FeatureTelemetry.LogUsage('0000CTK', EmailFeatureNameLbl, 'Email being rescheduled for exceeding currency limitation', Dimensions);
        Success := true;
    end;

    local procedure InsertToSentEmail(EmailOutbox: Record "Email Outbox"; var SentEmail: Record "Sent Email")
    begin
        Clear(SentEmail);
        SentEmail.TransferFields(EmailOutbox);
        Clear(SentEmail.Id);
        SentEmail."Date Time Sent" := CurrentDateTime();
        SentEmail.Insert();

        Commit();
    end;

    local procedure UpdateOutboxStatus(var EmailOutbox: Record "Email Outbox"; Status: Enum "Email Status")
    begin
        EmailOutbox.Status := Status;
        EmailOutbox.Modify();
        Commit();
    end;

    local procedure UpdateOutboxError(LastError: Text; var EmailOutbox: Record "Email Outbox")
    var
        EmailError: Record "Email Error";
        ErrorOutStream: OutStream;
    begin
        EmailError."Outbox Id" := EmailOutbox.Id;
        EmailError."Error Message".CreateOutStream(ErrorOutStream, TextEncoding::UTF8);
        ErrorOutStream.WriteText(LastError);
        EmailError."Error Callstack".CreateOutStream(ErrorOutStream, TextEncoding::UTF8);
        ErrorOutStream.WriteText(GetLastErrorCallStack());
        EmailError.Validate("Error Timestamp", CurrentDateTime());
        EmailError.Validate("Retry No.", EmailOutbox."Retry No.");
        EmailError.Insert();

        EmailOutbox."Error Message" := CopyStr(LastError, 1, MaxStrLen(EmailOutbox."Error Message"));
        EmailOutbox."Date Failed" := CurrentDateTime();
        EmailOutbox.Modify();
    end;

    local procedure LogAttachments()
    begin
        if not EmailMessageImpl.Attachments_First() then
            exit;

        repeat
            Session.LogMessage('0000CTS', StrSubstNo(AttachmentMsg, EmailMessageImpl.Attachments_GetLength(), EmailMessageImpl.Attachments_GetContentType()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailCategoryLbl, 'EmailMessageID', EmailMessageImpl.GetId());
        until EmailMessageImpl.Attachments_Next() = 0;
    end;

    procedure GetSuccess(): Boolean
    begin
        exit(Success);
    end;
}