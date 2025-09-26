namespace Microsoft.SubscriptionBilling;

using System.Telemetry;
using System.Threading;

codeunit 8034 SubBillingBackgroundJobs
{
    procedure ScheduleRecurrentImportJob(var BillingTemplate: Record "Billing Template")
    var
        JobQueueEntry: Record "Job Queue Entry";
        Telemetry: Codeunit Telemetry;
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        if BillingTemplate.Code = '' then
            exit;

        if not IsRecurrentJobScheduledForAService(BillingTemplate."Batch Recurrent Job Id") then begin
            JobQueueEntry.ScheduleRecurrentJobQueueEntryWithFrequency(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"Auto Contract Billing", BillingTemplate.RecordId, BillingTemplate."Minutes between runs", BillingTemplate."Automation Start Time");
            BillingTemplate."Batch Recurrent Job Id" := JobQueueEntry.ID;
            BillingTemplate.Modify();

            JobQueueEntry."Rerun Delay (sec.)" := 600;
            JobQueueEntry."No. of Attempts to Run" := 0;
            JobQueueEntry."Job Queue Category Code" := JobQueueCategoryTok;
            JobQueueEntry.Modify();
        end else begin
            JobQueueEntry.Get(BillingTemplate."Batch Recurrent Job Id");
            JobQueueEntry."Starting Time" := BillingTemplate."Automation Start Time";
            JobQueueEntry."No. of Minutes between Runs" := BillingTemplate."Minutes between runs";
            JobQueueEntry."No. of Attempts to Run" := 0;
            JobQueueEntry.Modify();
            if not JobQueueEntry.IsReadyToStart() then
                JobQueueEntry.Restart();
        end;
        TelemetryDimensions.Add('Job Queue Id', JobQueueEntry.ID);
        TelemetryDimensions.Add('Codeunit Id', Format(Codeunit::"Auto Contract Billing"));
        TelemetryDimensions.Add('Record Id', Format(BillingTemplate.RecordId));
        TelemetryDimensions.Add('User Session ID', Format(JobQueueEntry."User Session ID"));
        TelemetryDimensions.Add('Earliest Start Date/Time', Format(JobQueueEntry."Earliest Start Date/Time"));
        Telemetry.LogMessage('0000LC5', SubBillingJobTelemetryLbl, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All, TelemetryDimensions);
    end;


    procedure HandleRecurrentImportJob(var BillingTemplate: Record "Billing Template")
    begin
        if BillingTemplate.Automation = BillingTemplate.Automation::"Create Billing Proposal and Documents" then begin
            BillingTemplate.TestField("Minutes between runs");
            ScheduleRecurrentImportJob(BillingTemplate);
        end else
            RemoveJob(BillingTemplate);
    end;

    procedure RemoveJob(var BillingTemplate: Record "Billing Template")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntry.Get(BillingTemplate."Batch Recurrent Job Id") then
            JobQueueEntry.Delete();
        Clear(BillingTemplate."Batch Recurrent Job Id");
        BillingTemplate.Modify();
    end;

    local procedure IsRecurrentJobScheduledForAService(JobId: Guid): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if IsNullGuid(JobId) then
            exit(false);

        exit(JobQueueEntry.Get(JobId));
    end;

    var
        JobQueueCategoryTok: Label 'SubBilling', Locked = true, Comment = 'Max Length 10';
        SubBillingJobTelemetryLbl: Label 'Subscription Billing Background Job Scheduled', Locked = true;
}
