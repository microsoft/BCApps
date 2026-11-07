// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

using System.Email;
using System.Telemetry;

codeunit 6940 "EA Retrieve Emails"
{
    Access = Internal;
    Permissions = tabledata "Email Inbox" = rd;
    InherentEntitlements = X;
    InherentPermissions = X;
    TableNo = "Expense Agent Setup";

    trigger OnRun()
    begin
        RetrieveEmails(Rec);
    end;

    var
        EAAgentScheduler: Codeunit "EA Agent Scheduler";
        EAMailSetup: Codeunit "EA Email Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        EmailsFoundCount: Integer;
        EmailsProcessedCount: Integer;
        TelemetryEmailInboxNotFoundLbl: Label 'Email inbox not found.', Locked = true;
        MessageTemplateLbl: Label '<b>Subject:</b> %1<br/><b>Body:</b> %2', Comment = '%1 = Subject, %2 = Body';
        TelemetryEAEmailNotModifiedLbl: Label 'EA Email record not modified.', Locked = true;
        TelemetryProcessingLimitReachedLbl: Label 'Processing limit of emails reached.', Locked = true;

    local procedure RetrieveEmails(var EASetup: Record "Expense Agent Setup")
    var
        ExpenseAgentStatus: Record "Expense Agent Status";
        EmailInbox: Record "Email Inbox";
        TempFilters: Record "Email Retrieval Filters" temporary;
        EAEmail: Record "EA Email";
        Email: Codeunit "Email";
        Processed: Integer;
        ProcessLimit: Integer;
        TelemetryDimensions: Dictionary of [Text, Text];
        StartDateTime: DateTime;
    begin
        ProcessLimit := EAAgentScheduler.GetProcessLimitPerDay(EASetup);
        Processed := EAMailSetup.GetEmailCountProcessedWithin24hrs();
        if Processed >= ProcessLimit then begin
            TelemetryDimensions.Set('Processed', Format(Processed));
            TelemetryDimensions.Set('ProcessLimit', Format(ProcessLimit));
            FeatureTelemetry.LogUsage('0000QKV', EASetup.GetFeatureName(), StrSubstNo(TelemetryProcessingLimitReachedLbl), TelemetryDimensions);
            exit;
        end;

        ExpenseAgentStatus.GetOrCreate();

        TempFilters."Unread Emails" := true;
        TempFilters."Load Attachments" := true;
        TempFilters."Max No. of Emails" := EAMailSetup.GetMaxNoOfEmails();
        TempFilters."Last Message Only" := true;
        TempFilters."Body Type" := TempFilters."Body Type"::HTML;
        TempFilters."Folder Id" := EASetup."Email Folder Id";
        TempFilters."Earliest Email" := ExpenseAgentStatus."Earliest Sync At";
        TempFilters.Insert();

        Email.RetrieveEmails(EASetup."Email Account ID", EASetup."Email Connector", EmailInbox, TempFilters);

        EmailsFoundCount := EmailInbox.Count();

        RemoveEmailsOutsideSyncRange(EmailInbox);
        AddEmailInboxToEAEmails(EASetup, EmailInbox);
        // Only update sync time if we're not syncing from a specific folder
        // Specifying a folder means we may miss emails if they are moved into the folder after we sync
        if TempFilters."Folder Id" = '' then
            UpdateEarliestSyncAt(EmailInbox.Count());
        Commit();

        EAEmail.SetRange(Processed, false);
        if not EAEmail.FindSet() then
            exit;

        StartDateTime := CurrentDateTime();
        repeat
            AddEmailToAgentTask(EASetup, EAEmail);
            EmailsProcessedCount += 1;
            // Prevent locks from being held for too long
            if CurrentDateTime() - StartDateTime > 25000 then begin
                Commit();
                StartDateTime := CurrentDateTime();
            end;

            Processed += 1;
            if Processed >= ProcessLimit then begin
                TelemetryDimensions.Set('Processed', Format(Processed));
                TelemetryDimensions.Set('ProcessLimit', Format(ProcessLimit));
                FeatureTelemetry.LogUsage('0000QKY', EASetup.GetFeatureName(), StrSubstNo(TelemetryProcessingLimitReachedLbl), TelemetryDimensions);
                break;
            end;
        until EAEmail.Next() = 0;
    end;

    internal procedure GetEmailsFound(): Integer
    begin
        exit(EmailsFoundCount);
    end;

    internal procedure GetEmailsProcessed(): Integer
    begin
        exit(EmailsProcessedCount);
    end;

    local procedure UpdateEarliestSyncAt(EmailsProcessed: Integer)
    var
        ExpenseAgentStatus: Record "Expense Agent Status";
    begin
        ExpenseAgentStatus.GetOrCreate();
        // Only move the earliest sync time forward if we processed fewer emails than the limit
        // This ensures we'll re-query and get any we missed
        if EmailsProcessed < EAMailSetup.GetMaxNoOfEmails() then
            ExpenseAgentStatus."Earliest Sync At" := CurrentDateTime();

        ExpenseAgentStatus.Modify();
    end;

    local procedure AddEmailToAgentTask(EASetup: Record "Expense Agent Setup"; var EAEmail: Record "EA Email")
    var
        EmailInbox: Record "Email Inbox";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        if not EmailInbox.Get(EAEmail."Email Inbox ID") then begin
            TelemetryDimensions.Set('EmailInboxID', Format(EAEmail."Email Inbox ID"));
            FeatureTelemetry.LogError('0000UTX', EASetup.GetFeatureName(), 'Retrieve emails', TelemetryEmailInboxNotFoundLbl, '', TelemetryDimensions);
            EAEmail.Delete(true);
            exit;
        end;

        AddEmailToNewAgentTask(EASetup, EmailInbox, EAEmail);
        OnAfterProcessEmail(EAEmail."Email Inbox ID");
    end;

    local procedure RemoveEmailsOutsideSyncRange(var EmailInbox: Record "Email Inbox")
    begin
        if EmailInbox.FindSet() then
            repeat
                if EmailInbox."Is Read" then
                    EmailInbox.Delete(true);
            until EmailInbox.Next() = 0;
    end;

    procedure AddEmailInboxToEAEmails(EASetup: Record "Expense Agent Setup"; var EmailInbox: Record "Email Inbox")
    var
        EAEmail: Record "EA Email";
        Email: Codeunit "Email";
    begin
        if not EmailInbox.FindSet() then
            exit;

        repeat
            EAEmail."Email Inbox ID" := EmailInbox.Id;
            EAEmail."Sender Name" := EmailInbox."Sender Name";
            EAEmail."Sender Address" := EmailInbox."Sender Address";
            EAEmail."Sent DateTime" := EmailInbox."Sent DateTime";
            EAEmail."Received DateTime" := EmailInbox."Received DateTime";

            if EAEmail.Insert() then
                Email.MarkAsRead(EASetup."Email Account ID", EASetup."Email Connector", EmailInbox."External Message Id");
        until EmailInbox.Next() = 0;
    end;

    procedure AddEmailToNewAgentTask(var EASetup: Record "Expense Agent Setup"; var EmailInbox: Record "Email Inbox"; var EAEmail: Record "EA Email")
    var
        TempAttachment: Record "EA Email Attachment" temporary;
        EAHttpClient: Codeunit "EA Http Client";
        EAKPITrack: Codeunit "EA KPI Track";
        EmailMessage: Codeunit "Email Message";
        TelemetryDimensions: Dictionary of [Text, Text];
        MessageText: Text;
        ConversationId: Text;
        IsSuccess: Boolean;
    begin
        EmailMessage.Get(EmailInbox."Message Id");
        MessageText := StrSubstNo(MessageTemplateLbl, EmailMessage.GetSubject(), EmailMessage.GetBody());

        GetEmailAttachments(EmailMessage, TempAttachment);

        // Prepare request data
        ConversationId := Format(CreateGuid());

        // Send email to expense agent with attachments
        IsSuccess := EAHttpClient.SubmitExpenseWithAttachments(
            ConversationId,
            MessageText,
            EAEmail."Sender Address",
            TempAttachment
        );

        if IsSuccess then
            EAKPITrack.UpdateAttachmentKPIs(TempAttachment.Count())
        else
            FeatureTelemetry.LogError('0000QKU', EASetup.GetFeatureName(), 'Failed to submit expense to agent', '', GetLastErrorCallStack(), TelemetryDimensions);
    end;

    local procedure GetEmailAttachments(var EmailMessage: Codeunit "Email Message"; var TempAttachment: Record "EA Email Attachment" temporary)
    var
        EAEmailSetup: Codeunit "EA Email Setup";
        InStream: InStream;
        OutStream: OutStream;
        FileMIMEType: Text[100];
        FileName: Text[250];
        IsFileMimeTypeSupported: Boolean;
    begin
        if not EmailMessage.Attachments_First() then
            exit;

        repeat
            FileMIMEType := CopyStr(EmailMessage.Attachments_GetContentType(), 1, 100);
            IsFileMimeTypeSupported := EAEmailSetup.SupportedAttachmentContentType(FileMIMEType);
            if IsFileMimeTypeSupported then begin
                Clear(TempAttachment);
                TempAttachment."Entry No." := TempAttachment.Count() + 1;
                FileName := CopyStr(EmailMessage.Attachments_GetName(), 1, 250);
                TempAttachment.FileName := FileName;
                TempAttachment.ContentType := FileMIMEType;

                // Copy attachment content to temp record
                EmailMessage.Attachments_GetContent(InStream);
                TempAttachment.Content.CreateOutStream(OutStream);
                CopyStream(OutStream, InStream);

                TempAttachment.Insert(true);
            end;
        until EmailMessage.Attachments_Next() = 0;
    end;

    [InternalEvent(false, true)]
    local procedure OnAfterProcessEmail(EmailInboxId: BigInteger)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EA Retrieve Emails", 'OnAfterProcessEmail', '', false, false)]
    local procedure OnAfterEmailProcessed(EmailInboxId: BigInteger)
    var
        EAEmail: Record "EA Email";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        EAEmail.Get(EmailInboxId);
        EAEmail.Processed := true;
        if not EAEmail.Modify() then begin
            TelemetryDimensions.Set('EmailInboxID', Format(EmailInboxId));
            FeatureTelemetry.LogError('0000UTY', ExpenseAgentSetup.GetFeatureName(), 'Mark email processed', TelemetryEAEmailNotModifiedLbl, '', TelemetryDimensions);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"EA Email", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDeleteEAEmailEvent(var Rec: Record "EA Email"; RunTrigger: Boolean)
    var
        EmailInbox: Record "Email Inbox";
    begin
        EmailInbox.Id := Rec."Email Inbox ID";
        if EmailInbox.Delete(true) then;
    end;
}