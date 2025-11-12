// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Foundation.Reporting;
using System.Threading;

codeunit 8810 "Customer Layout - Statement"
{

    trigger OnRun()
    begin
    end;

    var
        StatementFileNameTxt: Label 'Statement', Comment = 'Shortened form of ''Customer Statement''';
        StatementReportNotFoundErr: Label 'No customer statement report has been set up.';
        RunCustomerStatementsTxt: Label 'Run Customer Statements from Job Queue.';
        DuplicateJobQueueRecordErr: Label 'Customer statements are already scheduled to run in the job queue.';
        ConfirmRunRepInBackgroundQst: Label 'Do you want to set the job queue entry up to run immediately?';

    procedure RunReport()
    var
        Customer: Record Customer;
        ReportSelections: Record "Report Selections";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::Customer);
        CustomLayoutReporting.SetOutputFileBaseName(StatementFileNameTxt);
        CustomLayoutReporting.ProcessReportData(
          ReportSelections.Usage::"C.Statement", RecRef, Customer.FieldName("No."), DATABASE::Customer, Customer.FieldName("No."), true);
    end;

    procedure RunReportWithParameters(Parameters: Text)
    var
        Customer: Record Customer;
        ReportSelections: Record "Report Selections";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::Customer);
        CustomLayoutReporting.SetOutputFileBaseName(StatementFileNameTxt);
        CustomLayoutReporting.SetPredefinedRequestParameters(Parameters);
        CustomLayoutReporting.ProcessReportData(
          ReportSelections.Usage::"C.Statement", RecRef, Customer.FieldName("No."), DATABASE::Customer, Customer.FieldName("No."), true);
    end;

    procedure RunReportWithoutRequestPage()
    var
        Customer: Record Customer;
        ReportSelections: Record "Report Selections";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::Customer);
        CustomLayoutReporting.SetOutputFileBaseName(StatementFileNameTxt);
        CustomLayoutReporting.SetIgnoreRequestParameters(true);
        CustomLayoutReporting.ProcessReportData(
          ReportSelections.Usage::"C.Statement", RecRef, Customer.FieldName("No."), DATABASE::Customer, Customer.FieldName("No."), true);
    end;

    procedure EnqueueReport()
    var
        JobQueueEntry: Record "Job Queue Entry";
        LocalReportSelections: Record "Report Selections";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        RequestParameters: Text;
        RunImmediately: Boolean;
        LocalRepId: Integer;
    begin
        LocalReportSelections.SetRange(Usage, LocalReportSelections.Usage::"C.Statement");
        if not LocalReportSelections.FindFirst() then
            Error(StatementReportNotFoundErr);

        LocalRepId := LocalReportSelections."Report ID";
        RequestParameters := CustomLayoutReporting.RunRequestPage(LocalRepId);
        if RequestParameters = '' then
            exit;

        RunImmediately := Confirm(ConfirmRunRepInBackgroundQst);
        CheckReportRunningInBackground();
        JobQueueEntry.Init();
        JobQueueEntry.Scheduled := false;
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Description := RunCustomerStatementsTxt;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Customer Statement via Queue";
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry.Insert(true);
        // it is required due to MODIFY called inside SetReportParameters
        JobQueueEntry.SetXmlContent(RequestParameters);
        if RunImmediately then
            JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
    end;

    procedure CheckReportRunningInBackground()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        SetJobQueueEntryFilter(JobQueueEntry);
        if JobQueueEntry.FindFirst() then
            if JobQueueEntry.DoesExistLocked() then
                Error(DuplicateJobQueueRecordErr);
    end;

    local procedure SetJobQueueEntryFilter(var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Customer Statement via Queue");
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("User ID", UserId);
    end;
}

