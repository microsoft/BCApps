// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.EServices.EDocument;
using System.Email;
using System.IO;
using System.Security.AccessControl;
using System.Security.User;
using System.Utilities;

codeunit 8361 "Financial Report Export Job"
{
    Access = Internal;

    trigger OnRun()
    begin
        ExportSchedules();
    end;

    var
        FileMgt: Codeunit "File Management";
        FinReportMgt: Codeunit "Financial Report Mgt.";
        EmailSubjectLbl: Label 'Financial Report: %1', Comment = '%1 = report description.';
        ExcelContentTypeTxt: Label 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', Locked = true;
        ExcelExtTok: Label 'xlsx', Locked = true;
        PDFContentTypeTxt: Label 'application/pdf', Locked = true;
        PDFExtTok: Label 'pdf', Locked = true;
        SendingFailedErr: Label 'The email was not sent because of the following error: "%1"', Comment = '%1 = the error that occurred.';

    local procedure ExportSchedules()
    var
        FinancialReportSchedule: Record "Financial Report Schedule";
    begin
        FinancialReportSchedule.SetFilter("Next Run Date/Time", '<>%1&<=%2', 0DT, CurrentDateTime());
        if FinancialReportSchedule.FindSet(true) then
            repeat
                ExportSchedule(FinancialReportSchedule);
            until FinancialReportSchedule.Next() = 0;
    end;

    local procedure ExportSchedule(FinancialReportSchedule: Record "Financial Report Schedule")
    var
        FinancialReport: Record "Financial Report";
        FinancialReportExportLog: Record "Financial Report Export Log";
        FinancialReportRecipient: Record "Financial Report Recipient";
        User: Record User;
        UserSetup: Record "User Setup";
        Email: Codeunit Email;
        EmailMessage: Codeunit "Email Message";
        UserNames: List of [Text[65]];
        UserEmails: List of [Text];
        ReportDescription: Text[250];
        SendEmailField: Boolean;
    begin
        FinancialReportExportLog."Financial Report Name" := FinancialReportSchedule."Financial Report Name";
        FinancialReportExportLog."Financial Report Schedule Code" := FinancialReportSchedule.Code;
        FinancialReportExportLog."Start Date/Time" := CurrentDateTime();
        FinancialReportExportLog.Insert();

        FinancialReportRecipient.SetRange("Financial Report Name", FinancialReportSchedule."Financial Report Name");
        FinancialReportRecipient.SetRange("Financial Report Schedule Code", FinancialReportSchedule.Code);
        if FinancialReportRecipient.FindSet() then
            repeat
                User.SetRange("User Name", FinancialReportRecipient."User ID");
                if not User.FindFirst() then
                    continue;

                if User.State = User.State::Disabled then
                    continue;

                UserNames.Add(FinancialReportRecipient."User ID");
                if FinancialReportSchedule."Send Email" then begin
                    UserSetup.Get(FinancialReportRecipient."User ID");
                    UserSetup.TestField("E-Mail");
                    UserEmails.Add(UserSetup."E-Mail");
                end;
            until FinancialReportRecipient.Next() = 0
        else
            exit;

        if not (FinancialReportSchedule."Export to Excel" or FinancialReportSchedule."Export to PDF") then
            exit;

        FinancialReport.Get(FinancialReportSchedule."Financial Report Name");
        if (Format(FinancialReportSchedule."Start Date Filter Formula") <> '') or
            (Format(FinancialReportSchedule."End Date Filter Formula") <> '') or
            (FinancialReportSchedule."Date Filter Period Formula" <> '')
        then begin
            FinancialReport.StartDateFilterFormula := FinancialReportSchedule."Start Date Filter Formula";
            FinancialReport.EndDateFilterFormula := FinancialReportSchedule."End Date Filter Formula";
            FinancialReport.DateFilterPeriodFormula := FinancialReportSchedule."Date Filter Period Formula";
            FinancialReport.DateFilterPeriodFormulaLID := FinancialReportSchedule."Date Filter Period Formula LID";
        end;

        ReportDescription := StrSubstNo(
            '%1 - %2', FinancialReport.Description = '' ? Format(FinancialReport.Name) : FinancialReport.Description,
            FinancialReportSchedule.Description = '' ? Format(FinancialReportSchedule.Code) : FinancialReportSchedule.Description);

        SendEmailField := FinancialReportSchedule."Send Email";
        FinancialReportSchedule."Send Email" := FinancialReportSchedule."Send Email" and (UserEmails.Count() > 0);

        if FinancialReportSchedule."Send Email" then
            CreateEmailMessage(FinancialReportSchedule, ReportDescription, UserEmails, EmailMessage);

        if FinancialReportSchedule."Export to Excel" then
            ExportExcel(FinancialReportSchedule, FinancialReport, ReportDescription, FinancialReportExportLog.SystemId, UserNames, EmailMessage);

        if FinancialReportSchedule."Export to PDF" then
            ExportPdf(FinancialReportSchedule, FinancialReport, ReportDescription, FinancialReportExportLog.SystemId, UserNames, EmailMessage);

        if FinancialReportSchedule."Send Email" then begin
            Email.AddRelation(
                EmailMessage, Database::"Financial Report Export Log", FinancialReportExportLog.SystemId,
                Enum::"Email Relation Type"::"Primary Source", Enum::"Email Relation Origin"::"Compose Context");
            if not Email.Send(EmailMessage, Enum::"Email Scenario"::"Financial Report") then
                Error(SendingFailedErr, GetLastErrorText());
        end;

        FinancialReportSchedule."Send Email" := SendEmailField;
        FinancialReportSchedule.CalcNextRunDate();
        FinancialReportSchedule.Modify();

        Commit();
    end;

    local procedure CreateEmailMessage(
        FinancialReportSchedule: Record "Financial Report Schedule"; ReportDescription: Text; var UserEmails: List of [Text]; var EmailMessage: Codeunit "Email Message")
    var
        FinancialReportExportEmail: Report "Financial Report Export Email";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        InStr: InStream;
        OutStr: OutStream;
        EmailBody: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        RecRef.GetTable(FinancialReportSchedule);
        RecRef.SetRecFilter();
        FinancialReportExportEmail.SaveAs('', ReportFormat::Html, OutStr, RecRef);
        TempBlob.CreateInStream(InStr);
        InStr.ReadText(EmailBody);
        EmailMessage.Create(UserEmails, StrSubstNo(EmailSubjectLbl, ReportDescription), EmailBody, true);
    end;

    internal procedure ExportExcel(
        FinancialReportSchedule: Record "Financial Report Schedule"; FinancialReport: Record "Financial Report";
        ReportDescription: Text[250]; LogSystemId: Guid; var UserNames: List of [Text[65]]; var EmailMessage: Codeunit "Email Message")
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        FinReportExcelTemplate: Record "Fin. Report Excel Template";
        ExportAccSchedToExcel: Report "Export Acc. Sched. to Excel";
        TempBlob: Codeunit "Temp Blob";
        ExcelTemplateCode: Code[20];
        InStr: InStream;
        OutStr: OutStream;
        AccScheduleView: Text;
        IsHandled: Boolean;
    begin
        // Create filtered acc. schedule line
        AccScheduleView := FinancialReportSchedule.GetReportFilters();
        if AccScheduleView = '' then
            FinReportMgt.SetAccScheduleLineFilter(FinancialReport, AccScheduleLine)
        else begin
            AccScheduleLine.SetView(AccScheduleView);
            AccScheduleLine.SetRange("Schedule Name", FinancialReport."Financial Report Row Group");
        end;
        FinReportMgt.CalcAccScheduleLineDateFilter(FinancialReport, AccScheduleLine);
        ExportAccSchedToExcel.SetOptions(AccScheduleLine, FinancialReport."Financial Report Column Group", FinancialReport.UseAmountsInAddCurrency, FinancialReportSchedule."Financial Report Name");

        // Get excel template if any
        ExcelTemplateCode :=
            FinancialReportSchedule."Excel Template Code" <> '' ? FinancialReportSchedule."Excel Template Code" : FinancialReport."Excel Template Code";
        if ExcelTemplateCode <> '' then begin
            FinReportExcelTemplate.Get(FinancialReport.Name, ExcelTemplateCode);
            ExportAccSchedToExcel.SetUseExistingTemplate(FinReportExcelTemplate);
        end;

        TempBlob.CreateOutStream(OutStr);
        OnBeforeSaveExcel(FinancialReportSchedule, FinancialReport, ExportAccSchedToExcel, OutStr, IsHandled);
        if not IsHandled then begin
            ExportAccSchedToExcel.SetSaveToStream(true);
            ExportAccSchedToExcel.Execute('');
            ExportAccSchedToExcel.GetSavedStream(OutStr);
        end;
        TempBlob.CreateInStream(InStr);

        CreateInboxEntries(InStr, UserNames, Report::"Export Acc. Sched. to Excel", ReportDescription, Enum::"Report Inbox Output Type"::Excel, LogSystemId);
        if FinancialReportSchedule."Send Email" then begin
            InStr.ResetPosition();
            EmailMessage.AddAttachment(CopyStr(FileMgt.CreateFileNameWithExtension(ReportDescription, ExcelExtTok), 1, MaxStrLen(ReportDescription)), ExcelContentTypeTxt, InStr);
        end;
    end;

    internal procedure ExportPdf(
        FinancialReportSchedule: Record "Financial Report Schedule"; FinancialReport: Record "Financial Report";
        ReportDescription: Text[250]; LogSystemId: Guid; var UserNames: List of [Text[65]]; var EmailMessage: Codeunit "Email Message")
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        AccountSchedule: Report "Account Schedule";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        AccScheduleParam: Text;
        IsHandled: Boolean;
    begin
        // Get report parameters or fallback to default acc. schedule line filter
        AccScheduleParam := FinancialReportSchedule.GetReportParameters();
        if AccScheduleParam = '' then
            FinReportMgt.SetAccScheduleFilter(FinancialReport, AccountSchedule)
        else begin
            AccountSchedule.SetFinancialReportName(FinancialReport.Name);
            FinReportMgt.CalcAccScheduleLineDateFilter(FinancialReport, AccScheduleLine);
            AccountSchedule.SetDateFilterHidden(AccScheduleLine.GetFilter("Date Filter"));
        end;

        TempBlob.CreateOutStream(OutStr);
        AccountSchedule.SetRunForExport();
        OnBeforeSavePdf(FinancialReportSchedule, FinancialReport, AccScheduleParam, AccountSchedule, OutStr, IsHandled);
        if not IsHandled then
            AccountSchedule.SaveAs(AccScheduleParam, ReportFormat::Pdf, OutStr);
        TempBlob.CreateInStream(InStr);

        CreateInboxEntries(InStr, UserNames, Report::"Account Schedule", ReportDescription, Enum::"Report Inbox Output Type"::PDF, LogSystemId);
        if FinancialReportSchedule."Send Email" then begin
            InStr.ResetPosition();
            EmailMessage.AddAttachment(CopyStr(FileMgt.CreateFileNameWithExtension(ReportDescription, PDFExtTok), 1, MaxStrLen(ReportDescription)), PDFContentTypeTxt, InStr);
        end;
    end;

    local procedure CreateInboxEntries(
        var InStr: InStream; var UserNames: List of [Text[65]];
        ReportId: Integer; ReportDescription: Text[250]; OutputType: Enum "Report Inbox Output Type"; LogSystemId: Guid)
    var
        ReportInbox: Record "Report Inbox";
        OutStr: OutStream;
        UserName: Text[65];
    begin
        ReportInbox.Init();
        ReportInbox."Report ID" := ReportId;
        ReportInbox.Description := ReportDescription;
        ReportInbox."Output Type" := OutputType;
        ReportInbox."Report Output".CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
        ReportInbox."Job Queue Log Entry ID" := LogSystemId;
        ReportInbox."Created Date-Time" := RoundDateTime(CurrentDateTime, 60000);
        foreach UserName in UserNames do begin
            ReportInbox."Entry No." := 0;
            ReportInbox."User ID" := UserName;
            ReportInbox.Insert(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSavePdf(FinancialReportSchedule: Record "Financial Report Schedule"; FinancialReport: Record "Financial Report"; AccScheduleParam: Text; var AccountSchedule: Report "Account Schedule"; var OutStr: OutStream; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveExcel(FinancialReportSchedule: Record "Financial Report Schedule"; FinancialReport: Record "Financial Report"; var ExportAccSchedToExcel: Report "Export Acc. Sched. to Excel"; var OutStr: OutStream; var IsHandled: Boolean)
    begin
    end;
}