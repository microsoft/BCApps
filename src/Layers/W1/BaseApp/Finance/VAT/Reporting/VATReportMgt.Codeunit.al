// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Environment.Configuration;
using System.Threading;

codeunit 737 "VAT Report Mgt."
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0470
        CreateVATReturnQst: Label 'VAT Return %1 has been created. Do you want to open the VAT return card?', Comment = '1 - VAT Return No.';
        AlreadyExistVATReturnQst: Label 'VAT Return %1 associated with this VAT return period already exists. Do you want to open the VAT return card?', Comment = '1 - VAT Return No.';
#pragma warning restore AA0470
        NoVATReturnQst: Label 'There is no VAT return for this period. Do you want to create a new one?';
        JobTraceCategoryTxt: Label 'Auto update of VAT return period job.', Locked = true;
        JobTraceStartTxt: Label 'A job for an automatic update of the VAT return period has started with frequency %1.', Locked = true;
#pragma warning disable AA0470
        FailedJobNotificationMsg: Label 'Auto receive job has failed (executed on %1).', Comment = '1 - datetime';
#pragma warning restore AA0470
        OpenJobCardMsg: Label 'Open the job card';
        ManualInsertNotificationMsg: Label 'Insert is only allowed with the Get VAT Return Periods action.';
        ManualInsertNotificationNameTxt: Label 'VAT return period manual insert notification.';
        ManualInsertNotificationDescriptionTxt: Label 'Warn about VAT return period manual insertion in case the Manual Receive Period CU ID field in the VAT Report Setup window is filled in.';
        DontShowAgainTxt: Label 'Do not show again';

    [EventSubscriber(ObjectType::Page, Page::"VAT Return Period List", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenVATReturnPeriodListPageEvent(var Rec: Record "VAT Return Period")
    var
        VATReportSetup: Record "VAT Report Setup";
        ManualInsertNotification: Notification;
    begin
        if not VATReportSetup.Get() then
            exit;

        if VATReportSetup."Manual Receive Period CU ID" = 0 then
            exit;

        if not IsManualInsertNotificationEnabled() then
            exit;

        ManualInsertNotification.Id := GetManualInsertNotificationGUID();
        ManualInsertNotification.Recall();
        ManualInsertNotification.Message := ManualInsertNotificationMsg;
        ManualInsertNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        ManualInsertNotification.AddAction(DontShowAgainTxt, CODEUNIT::"VAT Report Mgt.", 'DontShowAgainManualInsertNotification');
        ManualInsertNotification.Send();
    end;

    [Scope('OnPrem')]
    procedure DontShowAgainManualInsertNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetManualInsertNotificationGUID()) then
            MyNotifications.InsertDefault(
              GetManualInsertNotificationGUID(), ManualInsertNotificationNameTxt, ManualInsertNotificationDescriptionTxt, false);
    end;

    local procedure IsManualInsertNotificationEnabled(): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabled(GetManualInsertNotificationGUID()));
    end;

    local procedure GetManualInsertNotificationGUID(): Guid
    begin
        exit('93003212-76EA-490F-A5C6-6961656A7CF8');
    end;

    [Scope('OnPrem')]
    procedure GetVATReturnPeriods()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup.TestField("Manual Receive Period CU ID");
        CODEUNIT.Run(VATReportSetup."Manual Receive Period CU ID");
    end;

    [Scope('OnPrem')]
    procedure GetSubmittedVATReturns(VATReturnPeriod: Record "VAT Return Period")
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup.TestField("Receive Submitted Return CU ID");
        CODEUNIT.Run(VATReportSetup."Receive Submitted Return CU ID", VATReturnPeriod);
    end;

    [Scope('OnPrem')]
    procedure CreateVATReturnFromVATPeriod(VATReturnPeriod: Record "VAT Return Period")
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        if not VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReturnPeriod."VAT Return No.") then begin
            CreateVATReturn(VATReportHeader, VATReturnPeriod);
            if Confirm(StrSubstNo(CreateVATReturnQst, VATReportHeader."No.")) then
                OpenVATReturnCardFromVATPeriod(VATReturnPeriod);
        end else
            if Confirm(StrSubstNo(AlreadyExistVATReturnQst, VATReportHeader."No.")) then
                OpenVATReturnCard(VATReportHeader);
    end;

    [Scope('OnPrem')]
    procedure OpenVATReturnCardFromVATPeriod(VATReturnPeriod: Record "VAT Return Period")
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        if VATReportHeader.Get(VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReturnPeriod."VAT Return No.") then
            OpenVATReturnCard(VATReportHeader)
        else
            if Confirm(NoVATReturnQst) then begin
                CreateVATReturn(VATReportHeader, VATReturnPeriod);
                OpenVATReturnCard(VATReportHeader);
            end;
    end;

    local procedure OpenVATReturnCard(VATReportHeader: Record "VAT Report Header")
    begin
        Commit();
        PAGE.RunModal(PAGE::"VAT Report", VATReportHeader);
    end;

    [Scope('OnPrem')]
    procedure OpenVATPeriodCardFromVATReturn(VATReportHeader: Record "VAT Report Header")
    var
        VATReturnPeriod: Record "VAT Return Period";
    begin
        Commit();
        if VATReturnPeriod.Get(VATReportHeader."Return Period No.") then
            PAGE.RunModal(PAGE::"VAT Return Period Card", VATReturnPeriod);
    end;

    local procedure CreateVATReturn(var VATReportHeader: Record "VAT Report Header"; var VATReturnPeriod: Record "VAT Return Period")
    begin
        InsertNewVATReturn(VATReportHeader);
        UpdateVATReturn(VATReportHeader, VATReturnPeriod);
    end;

    local procedure InsertNewVATReturn(var VATReportHeader: Record "VAT Report Header")
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup.TestField("Report Version");
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATReportHeader."VAT Report Version" := VATReportSetup."Report Version";
        VATReportHeader.Insert(true);
    end;

    local procedure UpdateVATReturn(var VATReportHeader: Record "VAT Report Header"; var VATReturnPeriod: Record "VAT Return Period")
    begin
        VATReturnPeriod.CopyToVATReturn(VATReportHeader);
        VATReportHeader.Modify();

        VATReturnPeriod."VAT Return No." := VATReportHeader."No.";
        VATReturnPeriod.Modify();
    end;

    [Scope('OnPrem')]
    procedure CreateAndStartAutoUpdateVATReturnPeriodJob(VATReportSetup: Record "VAT Report Setup")
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueMgt: Codeunit "Job Queue Management";
    begin
        if VATReportSetup."Update Period Job Frequency" <> VATReportSetup."Update Period Job Frequency"::Never then
            VATReportSetup.TestField("Auto Receive Period CU ID");
        JobQueueMgt.DeleteJobQueueEntries(JobQueueEntry."Object Type to Run"::Codeunit, VATReportSetup."Auto Receive Period CU ID");
        if VATReportSetup."Update Period Job Frequency" = VATReportSetup."Update Period Job Frequency"::Never then
            exit;

        JobQueueEntry."No. of Minutes between Runs" := GetJobNoOfMinutes(VATReportSetup);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := VATReportSetup."Auto Receive Period CU ID";
        JobQueueMgt.CreateJobQueueEntry(JobQueueEntry);
        JobQueueEntry."Run on Saturdays" := false;
        JobQueueEntry."Run on Sundays" := false;
        JobQueueEntry."Maximum No. of Attempts to Run" := 1;
        JobQueueEntry.Modify();

        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        Session.LogMessage('00008WN', StrSubstNo(JobTraceStartTxt, Format(VATReportSetup."Update Period Job Frequency")), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', JobTraceCategoryTxt);
    end;

    local procedure GetJobNoOfMinutes(VATReportSetup: Record "VAT Report Setup"): Integer
    begin
        case VATReportSetup."Update Period Job Frequency" of
            VATReportSetup."Update Period Job Frequency"::Never:
                exit(0);
            VATReportSetup."Update Period Job Frequency"::Daily:
                exit(60 * 24);
            VATReportSetup."Update Period Job Frequency"::Weekly:
                exit(60 * 24 * 7);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"VAT Return Period List", 'OnOpenPageEvent', '', false, false)]
    local procedure CheckJobStatusOnOpenVATReturnPeriods(var Rec: Record "VAT Return Period")
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        if IsLastVATReturnPeriodJobQueueLogEntryHasError(JobQueueLogEntry) then
            SendJobErrorNotification(JobQueueLogEntry);
    end;

    local procedure IsLastVATReturnPeriodJobQueueLogEntryHasError(var JobQueueLogEntry: Record "Job Queue Log Entry"): Boolean
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        if (VATReportSetup."Auto Receive Period CU ID" = 0) or
           (VATReportSetup."Update Period Job Frequency" = VATReportSetup."Update Period Job Frequency"::Never)
        then
            exit(false);

        JobQueueLogEntry.SetRange("Object Type to Run", JobQueueLogEntry."Object Type to Run"::Codeunit);
        JobQueueLogEntry.SetRange("Object ID to Run", VATReportSetup."Auto Receive Period CU ID");
        if JobQueueLogEntry.FindLast() then
            exit(JobQueueLogEntry.Status = JobQueueLogEntry.Status::Error);

        exit(false);
    end;

    local procedure SendJobErrorNotification(JobQueueLogEntry: Record "Job Queue Log Entry")
    var
        JobErrorNotification: Notification;
    begin
        JobErrorNotification.Message := StrSubstNo(FailedJobNotificationMsg, JobQueueLogEntry."Start Date/Time");
        JobErrorNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        JobErrorNotification.AddAction(OpenJobCardMsg, CODEUNIT::"VAT Report Mgt.", 'OpenVATReturnPeriodJobCard');
        JobErrorNotification.Send();
    end;

    [Scope('OnPrem')]
    procedure OpenVATReturnPeriodJobCard(JobErrorNotification: Notification)
    var
        VATReportSetup: Record "VAT Report Setup";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        VATReportSetup.Get();
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", VATReportSetup."Auto Receive Period CU ID");
        if not JobQueueEntry.IsEmpty() then
            PAGE.RunModal(PAGE::"Job Queue Entry Card", JobQueueEntry);
    end;

    [EventSubscriber(ObjectType::Page, Page::"VAT Report", 'OnBeforeValidateEvent', 'VAT Report Version', false, false)]
    local procedure OnBeforeValidateVATReportVersion(var Rec: Record "VAT Report Header")
    var
        VATReportSetup: Record "VAT Report Setup";
        VATReturnPeriod: Record "VAT Return Period";
    begin
        if VATReportSetup.Get() then
            if (Rec."VAT Report Version" <> '') and (Rec."VAT Report Version" = VATReportSetup."Report Version") then
                if PAGE.RunModal(0, VATReturnPeriod) = ACTION::LookupOK then
                    UpdateVATReturn(Rec, VATReturnPeriod);
    end;
}

