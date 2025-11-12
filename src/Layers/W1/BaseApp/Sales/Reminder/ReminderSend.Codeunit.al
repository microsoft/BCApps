// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;

codeunit 6762 "Reminder-Send"
{
    var
        GlobalIssuedReminderHeader: Record "Issued Reminder Header";
        GlobalSendReminderSetup: Record "Send Reminders Setup";
        CannotFindDocumentSendingProfileErr: Label 'Cannot find document sending profile for customer %1.', Comment = '%1 = Customer Number';

    trigger OnRun()
    begin
        SendReminder();
    end;

    procedure SendReminder()
    begin
        SendReminderImplementation(GlobalIssuedReminderHeader, false, true, true);
        OnAfterSendReminder(GlobalIssuedReminderHeader);
    end;

    procedure Set(var IssuedReminderHeader: Record "Issued Reminder Header"; var SendReminderSetup: Record "Send Reminders Setup")
    begin
        GlobalIssuedReminderHeader.Copy(IssuedReminderHeader);
        GlobalSendReminderSetup.Copy(SendReminderSetup);
    end;

    local procedure SendReminderImplementation(var Rec: Record "Issued Reminder Header"; ShowRequestForm: Boolean; SendAsEmail: Boolean; HideDialog: Boolean)
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DummyReportSelections: Record "Report Selections";
        IssuedReminderHeaderToSend: Record "Issued Reminder Header";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintRecords(Rec, ShowRequestForm, SendAsEmail, HideDialog, IsHandled);
        if IsHandled then
            exit;

        IssuedReminderHeaderToSend.Copy(Rec);
        IssuedReminderHeaderToSend.SetRecFilter();

        IntializeDocumentSendingProfile(Rec, DocumentSendingProfile);

        if DocumentSendingProfile."E-Mail" <> DocumentSendingProfile."E-Mail"::No then
            DocumentSendingProfile.TrySendToEMail(
              DummyReportSelections.Usage::Reminder.AsInteger(), IssuedReminderHeaderToSend, IssuedReminderHeaderToSend.FieldNo("No."),
              ReportDistributionMgt.GetFullDocumentTypeText(Rec), IssuedReminderHeaderToSend.FieldNo("Customer No."), not HideDialog);

        if DocumentSendingProfile.Printer <> DocumentSendingProfile.Printer::No then
            DocumentSendingProfile.TrySendToPrinter(
              DummyReportSelections.Usage::Reminder.AsInteger(), Rec,
              IssuedReminderHeaderToSend.FieldNo("Customer No."), ShowRequestForm);

        OnAfterPrintRecords(Rec, ShowRequestForm, SendAsEmail, HideDialog, DocumentSendingProfile);
    end;

    local procedure GetDocumentSendingProfile(var IssuedReminderHeader: Record "Issued Reminder Header"; var DocumentSendingProfile: Record "Document Sending Profile") DocumentSendingProfileFound: Boolean
    var
        DefaultDocumentSendingProfile: Record "Document Sending Profile";
        Customer: Record Customer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDocumentSendingProfile(IssuedReminderHeader, DocumentSendingProfile, DocumentSendingProfileFound, IsHandled);
        if IsHandled then
            exit(DocumentSendingProfileFound);
        Clear(DocumentSendingProfile);
        Customer.Get(IssuedReminderHeader."Customer No.");

        if Customer."Document Sending Profile" <> '' then
            if DocumentSendingProfile.Get(Customer."Document Sending Profile") then
                exit(true);

        DefaultDocumentSendingProfile.SetRange(Default, true);
        if not DefaultDocumentSendingProfile.FindFirst() then
            exit(false);

        exit(DocumentSendingProfile.GetBySystemId(DefaultDocumentSendingProfile.SystemId));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var IssuedReminderHeader: Record "Issued Reminder Header"; ShowRequestForm: Boolean; SendAsEmail: Boolean; HideDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrintRecords(var IssuedReminderHeader: Record "Issued Reminder Header"; ShowRequestForm: Boolean; SendAsEmail: Boolean; HideDialog: Boolean; var DocumentSendingProfile: Record "Document Sending Profile")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendReminder(var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
    end;

    local procedure IntializeDocumentSendingProfile(var IssuedReminderHeader: Record "Issued Reminder Header"; var DocumentSendingProfile: Record "Document Sending Profile")
    begin
        if GlobalSendReminderSetup."Use Document Sending Profile" then begin
            if not GetDocumentSendingProfile(IssuedReminderHeader, DocumentSendingProfile) then
                Error(CannotFindDocumentSendingProfileErr);
        end else begin
            if GlobalSendReminderSetup.Print then
                DocumentSendingProfile.Printer := DocumentSendingProfile.Printer::"Yes (Use Default Settings)";

            if GlobalSendReminderSetup."Send by Email" then
                DocumentSendingProfile."E-Mail" := DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDocumentSendingProfile(var IssuedReminderHeader: Record "Issued Reminder Header"; var DocumentSendingProfile: Record "Document Sending Profile"; var DocumentSendingProfileFound: Boolean; var IsHandled: Boolean)
    begin
    end;
}

