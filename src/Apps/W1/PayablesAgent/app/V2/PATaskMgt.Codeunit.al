// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Utilities;
using System.Email;

/// <summary>
/// Lifecycle of the Payables Agent v2 task anchor: create, bind to the current agent session, record the outcome, complete,
/// and describe/open what the task came from.
/// </summary>
codeunit 3331 "PA Task Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Email Inbox" = r;

    /// <summary>
    /// Finds the Payables Agent Task bound to the Agent-framework task of the current Payables Agent session.
    /// </summary>
    /// <returns>False when the session is not a Payables Agent session or no task is bound to its agent task.</returns>
    procedure GetCurrentSessionTask(var PayablesAgentTask: Record "Payables Agent Task"): Boolean
    var
        PayablesAgent: Codeunit "Payables Agent";
        AgentTaskID: BigInteger;
    begin
        if not PayablesAgent.IsPayablesAgentSession(AgentTaskID) then
            exit(false);
        if AgentTaskID = 0 then
            exit(false);

        PayablesAgentTask.Reset();
        PayablesAgentTask.SetCurrentKey("Agent Task ID");
        PayablesAgentTask.SetRange("Agent Task ID", AgentTaskID);
        exit(PayablesAgentTask.FindFirst());
    end;

    /// <summary>
    /// Creates a task for a received email that has no PDF to process.
    /// </summary>
    procedure CreateTask(EmailInboxId: BigInteger; var PayablesAgentTask: Record "Payables Agent Task")
    begin
        InsertTask(InsertTaskSource(EmailInboxId), 0, PayablesAgentTask);
    end;

    /// <summary>
    /// Creates a task for a PDF that did not arrive by email, such as an upload.
    /// </summary>
    procedure CreateTask(FileName: Text[250]; PdfInStream: InStream; var PayablesAgentTask: Record "Payables Agent Task")
    begin
        InsertTask(0, InsertTaskData(FileName, PdfInStream), PayablesAgentTask);
    end;

    /// <summary>
    /// Creates a task for a PDF received as an attachment of an email.
    /// </summary>
    procedure CreateTask(EmailInboxId: BigInteger; FileName: Text[250]; PdfInStream: InStream; var PayablesAgentTask: Record "Payables Agent Task")
    begin
        InsertTask(InsertTaskSource(EmailInboxId), InsertTaskData(FileName, PdfInStream), PayablesAgentTask);
    end;

    procedure RegisterOutcome(var PayablesAgentTask: Record "Payables Agent Task"; OutcomeRecordId: RecordId)
    begin
        PayablesAgentTask.Outcome := OutcomeRecordId;
        PayablesAgentTask.Modify();
    end;

    procedure Complete(var PayablesAgentTask: Record "Payables Agent Task")
    begin
        PayablesAgentTask."Completed At" := CurrentDateTime();
        PayablesAgentTask.Modify();
    end;

    /// <summary>
    /// Opens the default page of the record registered as the task outcome.
    /// </summary>
    procedure OpenOutcome(PayablesAgentTask: Record "Payables Agent Task")
    var
        PageManagement: Codeunit "Page Management";
        OutcomeRecordRef: RecordRef;
    begin
        if PayablesAgentTask.Outcome.TableNo = 0 then
            Error(NoOutcomeErr);
        if not OutcomeRecordRef.Get(PayablesAgentTask.Outcome) then
            Error(NoOutcomeErr);

        PageManagement.PageRun(OutcomeRecordRef);
    end;

    /// <summary>
    /// Describes what the task came from. An email source takes precedence over the PDF, because a PDF received by email
    /// is described by its email.
    /// </summary>
    procedure DescribeSource(PayablesAgentTask: Record "Payables Agent Task"): Text
    begin
        if PayablesAgentTask."Source Data No." <> 0 then
            exit(DescribeEmailSource(PayablesAgentTask."Source Data No."));
        if PayablesAgentTask."Task Data No." <> 0 then
            exit(DescribePdfSource(PayablesAgentTask."Task Data No."));
        exit('');
    end;

    /// <summary>
    /// Opens what the task came from, using the same precedence as DescribeSource.
    /// </summary>
    procedure OpenSource(PayablesAgentTask: Record "Payables Agent Task")
    begin
        if PayablesAgentTask."Source Data No." <> 0 then begin
            OpenSourceEmail(PayablesAgentTask);
            exit;
        end;
        if PayablesAgentTask."Task Data No." <> 0 then begin
            OpenSourcePdf(PayablesAgentTask);
            exit;
        end;
    end;

    procedure OpenSourceEmail(PayablesAgentTask: Record "Payables Agent Task")
    var
        PayablesAgentTaskSource: Record "Payables Agent Task Source";
    begin
        if not PayablesAgentTaskSource.Get(PayablesAgentTask."Source Data No.") then
            Error(SourceNotAvailableErr);
        PayablesAgentTaskSource.SetRecFilter();
        Page.Run(Page::"PA Email Review", PayablesAgentTaskSource);
    end;

    procedure OpenSourcePdf(PayablesAgentTask: Record "Payables Agent Task")
    var
        PayablesAgentTaskData: Record "Payables Agent Task Data";
    begin
        if not PayablesAgentTaskData.Get(PayablesAgentTask."Task Data No.") then
            Error(SourceNotAvailableErr);
        PayablesAgentTaskData.SetRecFilter();
        Page.Run(Page::"PDF Viewer", PayablesAgentTaskData);
    end;

    procedure DownloadSourcePdf(PayablesAgentTask: Record "Payables Agent Task")
    var
        PayablesAgentTaskData: Record "Payables Agent Task Data";
    begin
        if not PayablesAgentTaskData.Get(PayablesAgentTask."Task Data No.") then
            Error(SourceNotAvailableErr);
        PayablesAgentTaskData.DownloadFileContent();
    end;

    /// <summary>
    /// Returns the Outlook on the web link of the email the task came from.
    /// </summary>
    /// <returns>Blank when the task has no email source or the email has no external (Outlook) message id.</returns>
    procedure GetSourceEmailWebLink(PayablesAgentTask: Record "Payables Agent Task"): Text
    var
        PayablesAgentTaskSource: Record "Payables Agent Task Source";
        EmailInbox: Record "Email Inbox";
    begin
        if PayablesAgentTask."Source Data No." = 0 then
            exit('');
        if not PayablesAgentTaskSource.Get(PayablesAgentTask."Source Data No.") then
            exit('');
        EmailInbox.SetLoadFields("External Message Id");
        if not EmailInbox.Get(PayablesAgentTaskSource."Email Inbox Id") then
            exit('');
        if EmailInbox."External Message Id" = '' then
            exit('');
        exit(StrSubstNo(OutlookWebLinkTok, EmailInbox."External Message Id"));
    end;

    local procedure InsertTask(SourceDataNo: BigInteger; TaskDataNo: BigInteger; var PayablesAgentTask: Record "Payables Agent Task")
    begin
        PayablesAgentTask.Init();
        PayablesAgentTask."Entry No." := 0;
        PayablesAgentTask."Source Data No." := SourceDataNo;
        PayablesAgentTask."Task Data No." := TaskDataNo;
        PayablesAgentTask."Received At" := CurrentDateTime();
        PayablesAgentTask.Insert();
    end;

    local procedure InsertTaskSource(EmailInboxId: BigInteger): BigInteger
    var
        PayablesAgentTaskSource: Record "Payables Agent Task Source";
    begin
        PayablesAgentTaskSource.Init();
        PayablesAgentTaskSource."Entry No." := 0;
        PayablesAgentTaskSource."Email Inbox Id" := GetSurvivingEmailInboxId(EmailInboxId);
        PayablesAgentTaskSource.Insert();
        exit(PayablesAgentTaskSource."Entry No.");
    end;

    /// <summary>
    /// Returns the Email Inbox row that "PA Email Cleanup" keeps for this email: the lowest Id among rows with the same
    /// "Account Id" and "External Message Id". The cleanup deletes the other copies, so only this row stays resolvable.
    /// </summary>
    local procedure GetSurvivingEmailInboxId(EmailInboxId: BigInteger): BigInteger
    var
        EmailInbox: Record "Email Inbox";
        SurvivingEmailInbox: Record "Email Inbox";
    begin
        EmailInbox.SetLoadFields("Account Id", "External Message Id");
        if not EmailInbox.Get(EmailInboxId) then
            exit(EmailInboxId);
        if EmailInbox."External Message Id" = '' then
            exit(EmailInboxId);

        SurvivingEmailInbox.ReadIsolation(IsolationLevel::ReadCommitted);
        SurvivingEmailInbox.SetCurrentKey(Id);
        SurvivingEmailInbox.SetAscending(Id, true);
        SurvivingEmailInbox.SetRange("Account Id", EmailInbox."Account Id");
        SurvivingEmailInbox.SetRange("External Message Id", EmailInbox."External Message Id");
        SurvivingEmailInbox.SetLoadFields(Id);
        if not SurvivingEmailInbox.FindFirst() then
            exit(EmailInboxId);
        exit(SurvivingEmailInbox.Id);
    end;

    local procedure InsertTaskData(FileName: Text[250]; PdfInStream: InStream): BigInteger
    var
        PayablesAgentTaskData: Record "Payables Agent Task Data";
    begin
        PayablesAgentTaskData.Init();
        PayablesAgentTaskData."Entry No." := 0;
        PayablesAgentTaskData."File Name" := FileName;
        PayablesAgentTaskData."File Content".ImportStream(PdfInStream, FileName, PdfMimeTypeTok);
        PayablesAgentTaskData.Insert();
        exit(PayablesAgentTaskData."Entry No.");
    end;

    local procedure DescribeEmailSource(SourceDataNo: BigInteger): Text
    var
        PayablesAgentTaskSource: Record "Payables Agent Task Source";
        EmailInbox: Record "Email Inbox";
    begin
        if not PayablesAgentTaskSource.Get(SourceDataNo) then
            exit(SourceNotAvailableTxt);
        EmailInbox.SetLoadFields("Sender Address", Description);
        if not EmailInbox.Get(PayablesAgentTaskSource."Email Inbox Id") then
            exit(SourceNotAvailableTxt);
        exit(StrSubstNo(EmailSourceTxt, EmailInbox."Sender Address", EmailInbox.Description));
    end;

    local procedure DescribePdfSource(TaskDataNo: BigInteger): Text
    var
        PayablesAgentTaskData: Record "Payables Agent Task Data";
    begin
        PayablesAgentTaskData.SetLoadFields("File Name");
        if not PayablesAgentTaskData.Get(TaskDataNo) then
            exit(SourceNotAvailableTxt);
        exit(StrSubstNo(PdfSourceTxt, PayablesAgentTaskData."File Name"));
    end;

    var
        NoOutcomeErr: Label 'This task has no outcome to open.';
        EmailSourceTxt: Label 'Email from %1: %2', Comment = '%1 = sender email address, %2 = email subject';
        PdfSourceTxt: Label 'PDF file %1', Comment = '%1 = file name';
        SourceNotAvailableTxt: Label 'The source of this task is no longer available.';
        SourceNotAvailableErr: Label 'The source of this task is no longer available.';
        OutlookWebLinkTok: Label 'https://outlook.office365.com/owa/?ItemID=%1&exvsurl=1&viewmodel=ReadMessageItem', Locked = true;
        PdfMimeTypeTok: Label 'application/pdf', Locked = true;
}
