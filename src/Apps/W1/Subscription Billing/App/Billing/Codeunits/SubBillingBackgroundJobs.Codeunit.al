namespace Microsoft.SubscriptionBilling;

using System.Telemetry;
using System.Threading;

codeunit 8034 "Sub. Billing Background Jobs"
{
    procedure ScheduleAutomatedBillingJob(var BillingTemplate: Record "Billing Template")
    var
        JobQueueEntry: Record "Job Queue Entry";
        Telemetry: Codeunit Telemetry;
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        if BillingTemplate.Code = '' then
            exit;

        if not IsAutomatedBillingJobScheduled(BillingTemplate."Batch Recurrent Job Id") then
            CreateJobQueueEntryForAutomatedBilling(BillingTemplate, JobQueueEntry)
        else
            UpdateJobQueueEntryForAutomatedBilling(BillingTemplate, JobQueueEntry);
        TelemetryDimensions.Add('Job Queue Id', JobQueueEntry.ID);
        TelemetryDimensions.Add('Codeunit Id', Format(Codeunit::"Auto Contract Billing"));
        TelemetryDimensions.Add('Record Id', Format(BillingTemplate.RecordId));
        TelemetryDimensions.Add('User Session ID', Format(JobQueueEntry."User Session ID"));
        TelemetryDimensions.Add('Earliest Start Date/Time', Format(JobQueueEntry."Earliest Start Date/Time"));
        Telemetry.LogMessage('0000LC5', SubBillingJobTelemetryLbl, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All, TelemetryDimensions);
    end;


    procedure HandleAutomatedBillingJob(var BillingTemplate: Record "Billing Template")
    begin
        if BillingTemplate.Automation = BillingTemplate.Automation::"Create Billing Proposal and Documents" then begin
            BillingTemplate.TestField("Minutes between runs");
            ScheduleAutomatedBillingJob(BillingTemplate);
        end else
            RemoveAutomatedBillingJob(BillingTemplate);
    end;

    procedure RemoveAutomatedBillingJob(var BillingTemplate: Record "Billing Template")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not JobQueueEntry.Get(BillingTemplate."Batch Recurrent Job Id") then
            exit;

        JobQueueEntry.Delete();
        Clear(BillingTemplate."Batch Recurrent Job Id");
        BillingTemplate.Modify();
    end;

    local procedure IsAutomatedBillingJobScheduled(JobId: Guid): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if IsNullGuid(JobId) then
            exit(false);

        exit(JobQueueEntry.Get(JobId));
    end;

    local procedure CreateJobQueueEntryForAutomatedBilling(var BillingTemplate: Record "Billing Template"; var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry.ScheduleRecurrentJobQueueEntryWithFrequency(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"Auto Contract Billing", BillingTemplate.RecordId, BillingTemplate."Minutes between runs");
        BillingTemplate."Batch Recurrent Job Id" := JobQueueEntry.ID;
        BillingTemplate.Modify();

        JobQueueEntry."Rerun Delay (sec.)" := 600;
        JobQueueEntry."No. of Attempts to Run" := 0;
        JobQueueEntry."Job Queue Category Code" := JobQueueCategoryTok;
        JobQueueEntry.Description := BillingTemplate.Description;
        JobQueueEntry.Modify();
    end;

    local procedure UpdateJobQueueEntryForAutomatedBilling(var BillingTemplate: Record "Billing Template"; var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry.Get(BillingTemplate."Batch Recurrent Job Id");
        JobQueueEntry."No. of Minutes between Runs" := BillingTemplate."Minutes between runs";
        JobQueueEntry."No. of Attempts to Run" := 0;
        JobQueueEntry.Description := BillingTemplate.Description;
        JobQueueEntry.Modify();
        if not JobQueueEntry.IsReadyToStart() then
            JobQueueEntry.Restart();
    end;

    var
        JobQueueCategoryTok: Label 'SubBilling', Locked = true, Comment = 'Max Length 10';
        SubBillingJobTelemetryLbl: Label 'Subscription Billing Background Job Scheduled', Locked = true;
}
