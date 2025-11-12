// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.EMail;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.History;
using System.Utilities;

codeunit 6753 "Send Reminder Event Handler"
{
    EventSubscriberInstance = Manual;

    var
        GlobalReminderAction: Record "Reminder Action";
        SendRemindersSetup: Record "Send Reminders Setup";
        ReminderAutomationLogError: Codeunit "Reminder Automation Log Errors";
        EmailsSentSuccessfully: List of [Text];
        EmailsFailed: List of [Text];
        RemindersPrintedSuccessfully: List of [Text];
        RemindersPrintedFailed: List of [Text];
        NumberOfRecordsProcessed: Integer;
        PendingOutboxMessageId: BigInteger;
        NoRemindersSentTxt: Label 'No reminders were sent.';
        RemindersEmailedTxt: Label ' %1 reminders were emailed.', Comment = '%1 number of reminders emailed';
        RemindersEmailFailedTxt: Label ' Sending email failed for %1 reminders.', Comment = '%1 number of reminders failed to email';
        RemindersPrintingFailedTxt: Label ' Printing failed for %1 reminders.', Comment = '%1 number of reminders failed to print';
        NoRemindersEmailedTxt: Label ' No reminders were emailed.';
        RemindersPritedTxt: Label ' %1 reminders were printed.', Comment = '%1 number of reminders printed';
        NoRemindersPrintedTxt: Label ' No reminders were printed.';

    internal procedure SetGlobalReminderAction(ReminderAction: Record "Reminder Action")
    var
        ReminderActionGroupLog: Record "Reminder Action Group Log";
        ReminderActionProgress: Codeunit "Reminder Action Progress";
        ReminderActionLogErrorsImplementation: Codeunit "Reminder Automation Log Errors";
    begin
        GlobalReminderAction.Copy(ReminderAction);

        ReminderActionProgress.GetLastEntryForGroup(GlobalReminderAction."Reminder Action Group Code", ReminderActionGroupLog);
        ReminderAutomationLogError := ReminderActionLogErrorsImplementation;
        ReminderAutomationLogError.Initialize(ReminderAction);
        if SendRemindersSetup.Get(ReminderAction.Code, ReminderAction."Reminder Action Group Code") then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Send Reminder Action Job", 'OnSendReminderSafe', '', false, false)]
    local procedure HandleSendReminderSafe(var IssuedReminderHeader: Record "Issued Reminder Header"; var SendReminderSetup: Record "Send Reminders Setup"; var Success: Boolean)
    var
        SendReminder: Codeunit "Reminder-Send";
    begin
        Clear(PendingOutboxMessageId);
        SendReminder.Set(IssuedReminderHeader, SendReminderSetup);
        SendReminder.Run();
        Success := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Email, 'OnAfterEmailSendFailed', '', false, false)]
    local procedure UpdateAfterEmailSendFailed(EmailOutbox: Record "Email Outbox")
    begin
        PendingOutboxMessageId := EmailOutbox.Id;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Mailing", 'OnBeforeSendEmail', '', false, false)]
    local procedure DeleteFailedEmailsBeforeSendingEmail(var TempEmailItem: Record "Email Item" temporary; var IsFromPostedDoc: Boolean; var PostedDocNo: Code[20]; var HideDialog: Boolean; var ReportUsage: Integer; var EmailSentSuccesfully: Boolean; var IsHandled: Boolean; EmailDocName: Text[250]; SenderUserID: Code[50]; EmailScenario: Enum "Email Scenario")
    var
        SendReminder: Codeunit "Send Reminder";
    begin
        SendReminder.DeleteFailedOutboxMessageIfExists(PostedDocNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Mailing", 'OnAfterEmailSent', '', false, false)]
    local procedure UpdateStatusAfterEmailSent(var TempEmailItem: Record "Email Item" temporary; PostedDocNo: Code[20]; ReportUsage: Integer; EmailSentSuccesfully: Boolean)
    var
        SendReminder: Codeunit "Send Reminder";
        ReportUsageEnum: Enum "Report Selection Usage";
    begin
        ReportUsageEnum := Enum::"Report Selection Usage"::Reminder;
        if ReportUsage <> ReportUsageEnum.AsInteger() then
            exit;

        if not EmailSentSuccesfully then begin
            ReminderAutomationLogError.LogLastError(Enum::"Reminder Automation Error Type"::"Email Reminder");
            SendReminder.SetFailedOutboxMessageID(PendingOutboxMessageId, PostedDocNo);
            EmailsFailed.Add(PostedDocNo);
            Clear(PendingOutboxMessageId);
            exit;
        end;

        if EmailSentSuccesfully then
            EmailsSentSuccessfully.Add(PostedDocNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reminder-Send", 'OnAfterSendReminder', '', false, false)]
    local procedure UpdateStatusWhenReminderIsSend(var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        ReminderActionProgress: Codeunit "Reminder Action Progress";
    begin
        NumberOfRecordsProcessed += 1;
        ReminderActionProgress.UpdateStatusAndTotalRecordsProcessed(GlobalReminderAction, NumberOfRecordsProcessed, GetStatusText());
    end;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnGetSendToCustomerDirectly', '', false, false)]
    local procedure HandleGetSendToCustomerDirectly(ReportUsageEnum: Enum "Report Selection Usage"; RecordVariant: Variant; CustNo: Code[20]; var ShowDialog: Boolean; var SendToCustomerDirectly: Boolean; var Handled: Boolean)
    begin
        if Handled then
            exit;

        if ReportUsageEnum <> ReportUsageEnum::Reminder then
            exit;

        SendToCustomerDirectly := true;
        Handled := true;
    end;

    procedure GetEmailsSent(): List of [Text]
    begin
        exit(EmailsSentSuccessfully);
    end;

    procedure GetEmailsFailed(): List of [Text]
    begin
        exit(EmailsFailed);
    end;

    procedure UpdateStatusAfterRun()
    var
        ReminderActionLog: Record "Reminder Action Log";
        ReminderActionProgress: Codeunit "Reminder Action Progress";
    begin
        if not ReminderActionProgress.GetLastActionEntry(GlobalReminderAction, ReminderActionLog) then
            ReminderActionProgress.CreateNewActionEntry(GlobalReminderAction, Enum::"Reminder Log Status"::Completed, ReminderActionLog);
        ReminderActionLog."Status summary" := CopyStr(GetStatusText(), 1, MaxStrLen(ReminderActionLog."Status summary"));
        ReminderActionLog.Modify();
    end;

    local procedure GetStatusText(): Text
    var
        StatusText: Text;
    begin
        if NumberOfRecordsProcessed = 0 then
            exit(NoRemindersSentTxt);

        if (EmailsSentSuccessfully.Count() = 0) and (EmailsFailed.Count() = 0) then
            StatusText += NoRemindersEmailedTxt
        else begin
            if EmailsSentSuccessfully.Count() > 0 then
                StatusText += StrSubstNo(RemindersEmailedTxt, EmailsSentSuccessfully.Count());

            if EmailsFailed.Count() > 0 then
                StatusText += StrSubstNo(RemindersEmailFailedTxt, EmailsFailed.Count());
        end;

        if (RemindersPrintedSuccessfully.Count() = 0) and (RemindersPrintedFailed.Count() = 0) then
            StatusText += NoRemindersPrintedTxt
        else begin
            if RemindersPrintedSuccessfully.Count() > 0 then
                StatusText += StrSubstNo(RemindersPritedTxt, RemindersPrintedSuccessfully.Count());

            if RemindersPrintedFailed.Count() > 0 then
                StatusText += StrSubstNo(RemindersPrintingFailedTxt, RemindersPrintedFailed.Count());
        end;

        exit(StatusText);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Issued Reminder Header", 'OnGetReportParameters', '', false, false)]
    local procedure HandleOnGetReportParameters(var LogInteraction: Boolean; var ShowNotDueAmounts: Boolean; var ShowMIRLines: Boolean; ReportID: Integer; var Handled: Boolean)
    begin
        if Handled then
            exit;

        ShowMIRLines := SendRemindersSetup."Show Multiple Interest Rates";
        LogInteraction := SendRemindersSetup."Log Interaction";
        ShowNotDueAmounts := SendRemindersSetup."Show Amounts Not Due";
        Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Mailing", 'OnBeforeEmailItemPreparation', '', false, false)]
    local procedure AttachRelatedDocumentsBeforeEmailFileInternal(var TempEmailItem: Record "Email Item" temporary; var PostedDocNo: Code[20]; var ReportUsage: Integer)
    var
        SourceTableList: List of [Integer];
        SourceIDList: List of [Guid];
        SourceRelationTypeList: List of [Integer];
        SourceTableID: Integer;
        SourceRelationID: Integer;
        SourceID: Guid;
        AttachRelatedDocument: Boolean;
        I: Integer;
    begin
        if ReportUsage <> Enum::"Report Selection Usage"::Reminder.AsInteger() then
            exit;

        if SendRemindersSetup."Attach Invoice Documents" = SendRemindersSetup."Attach Invoice Documents"::No then
            exit;

        TempEmailItem.GetSourceDocuments(SourceTableList, SourceIDList, SourceRelationTypeList);

        for I := 1 to SourceTableList.Count() do begin
            SourceTableID := SourceTableList.Get(I);
            SourceRelationID := SourceRelationTypeList.Get(I);
            SourceID := SourceIDList.Get(I);

            if SourceTableID = Database::"Sales Invoice Header" then
                if SendRemindersSetup."Attach Invoice Documents" = SendRemindersSetup."Attach Invoice Documents"::All then
                    AttachRelatedDocument := true
                else
                    AttachRelatedDocument := IsInvoiceOverdue(PostedDocNo, SourceID);

            if AttachRelatedDocument then
                AttachDocument(TempEmailItem, SourceTableID, SourceRelationID, SourceID);
        end;
    end;

    local procedure IsInvoiceOverdue(PostedDocNo: Code[20]; SalesInvoiceHeaderID: Guid): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        SalesInvoiceHeader.SetAutoCalcFields(Cancelled, Closed);
        if not SalesInvoiceHeader.GetBySystemId(SalesInvoiceHeaderID) then
            exit(false);

        if SalesInvoiceHeader.Cancelled or SalesInvoiceHeader.Closed then
            exit;

        IssuedReminderLine.SetRange("Reminder No.", PostedDocNo);
        IssuedReminderLine.SetRange("Document Type", IssuedReminderLine."Document Type"::Invoice);
        IssuedReminderLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        IssuedReminderLine.SetRange("Line Type", IssuedReminderLine."Line Type"::"Reminder Line");
        exit(not IssuedReminderLine.IsEmpty());
    end;

    local procedure AttachDocument(var TempEmailItem: Record "Email Item" temporary; SourceTableID: Integer; SourceRelationID: Integer; SourceID: Guid)
    var
        ReportSelections: Record "Report Selections";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempAttachementReportSelections: Record "Report Selections" temporary;
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        DocumentMailing: Codeunit "Document-Mailing";
        TempBlob: Codeunit "Temp Blob";
        AttachmentStream: InStream;
        AttachmentFileName: Text[250];
        DocumentName: Text[250];
    begin
        if SourceRelationID <> Enum::"Email Relation Type"::"Related Entity".AsInteger() then
            exit;

        if SourceTableID <> Database::"Sales Invoice Header" then
            exit;

        if not SalesInvoiceHeader.GetBySystemId(SourceID) then
            exit;

        if not ReportSelections.FindEmailAttachmentUsageForCust(ReportSelections.Usage::"S.Invoice", SalesInvoiceHeader."Bill-to Customer No.", TempAttachementReportSelections) then
            exit;

        SalesInvoiceHeader.SetRecFilter();
        DocumentName := ReportDistributionManagement.GetFullDocumentTypeText(SalesInvoiceHeader);
        DocumentMailing.GetAttachmentFileName(AttachmentFileName, SalesInvoiceHeader."No.", DocumentName, ReportSelections.Usage::"S.Invoice".AsInteger());
        repeat
            TempAttachementReportSelections.SaveReportAsPDFInTempBlob(TempBlob, TempAttachementReportSelections."Report ID", SalesInvoiceHeader, TempAttachementReportSelections."Custom Report Layout Code", ReportSelections.Usage::"S.Invoice");
            TempBlob.CreateInStream(AttachmentStream);

            TempEmailItem.AddAttachment(AttachmentStream, AttachmentFileName);
        until ReportSelections.Next() = 0;
    end;
}