namespace System.Threading;

using Microsoft.EServices.EDocument;

codeunit 487 "Job Queue Start Report" implements "Job Queue Report Runner"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        JobQueueStartReportBase: Codeunit "Job Queue Start Report Base";
    begin
        JobQueueStartReportBase.RunReport(Rec."Object ID to Run", Rec);
    end;

    procedure RunReport(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry")
    var
        ReportInbox: Record "Report Inbox";
        JobQueueStartReport: Codeunit "Job Queue Start Report";
        RecRef: RecordRef;
        OutStr: OutStream;
        RunOnRec: Boolean;
        IsHandled: Boolean;
        ShouldModifyNotifyOnSuccess: Boolean;
    begin
        ReportInbox.Init();
        ReportInbox."User ID" := JobQueueEntry."User ID";
        ReportInbox."Job Queue Log Entry ID" := JobQueueEntry.ID;
        ReportInbox."Report ID" := ReportID;
        ReportInbox.Description := JobQueueEntry.Description;
        ReportInbox."Report Output".CreateOutStream(OutStr);
        JobQueueStartReport.OnRunReportOnAfterAssignFields(ReportInbox, JobQueueEntry);
        RunOnRec := RecRef.Get(JobQueueEntry."Record ID to Process");
        if RunOnRec then
            RecRef.SetRecFilter();

        case JobQueueEntry."Report Output Type" of
            JobQueueEntry."Report Output Type"::Print:
                ProcessPrint(ReportID, JobQueueEntry, RunOnRec, RecRef);
            JobQueueEntry."Report Output Type"::PDF:
                begin
                    ProcessSaveAs(ReportID, JobQueueEntry, RunOnRec, RecRef, REPORTFORMAT::Pdf, OutStr);
                    ReportInbox."Output Type" := ReportInbox."Output Type"::PDF;
                end;
            JobQueueEntry."Report Output Type"::Word:
                begin
                    ProcessSaveAs(ReportID, JobQueueEntry, RunOnRec, RecRef, REPORTFORMAT::Word, OutStr);
                    ReportInbox."Output Type" := ReportInbox."Output Type"::Word;
                end;
            JobQueueEntry."Report Output Type"::Excel:
                begin
                    ProcessSaveAs(ReportID, JobQueueEntry, RunOnRec, RecRef, REPORTFORMAT::Excel, OutStr);
                    ReportInbox."Output Type" := ReportInbox."Output Type"::Excel;
                end;
        end;

        OnRunReportOnAfterProcessDifferentReportOutputTypes(ReportID, JobQueueEntry);

        case JobQueueEntry."Report Output Type" of
            JobQueueEntry."Report Output Type"::"None (Processing only)":
                begin
                    ShouldModifyNotifyOnSuccess := JobQueueEntry."Notify On Success" = false;
                    OnRunReportOnAfterCalcShouldModifyNotifyOnSuccess(ReportID, JobQueueEntry, ShouldModifyNotifyOnSuccess);
                    if ShouldModifyNotifyOnSuccess then begin
                        JobQueueEntry."Notify On Success" := true;
                        JobQueueEntry.Modify();
                    end;
                end;

            JobQueueEntry."Report Output Type"::Print:
                ;
            else begin
                IsHandled := false;
                OnRunReportOnBeforeReportInboxInsert(ReportInbox, JobQueueEntry, IsHandled);
                if not IsHandled then begin
                    ReportInbox."Created Date-Time" := RoundDateTime(CurrentDateTime, 60000);
                    ReportInbox.Insert(true);
                end;
            end;
        end;
    end;

    local procedure ProcessJobQueueRun(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; var ReportInbox: Record "Report Inbox")
    var
        ShouldModifyNotifyOnSuccess: Boolean;
        IsHandled: Boolean;
    begin
        case JobQueueEntry."Report Output Type" of
            JobQueueEntry."Report Output Type"::"None (Processing only)":
                begin
                    ShouldModifyNotifyOnSuccess := JobQueueEntry."Notify On Success" = false;
                    OnRunReportOnAfterCalcShouldModifyNotifyOnSuccess(ReportID, JobQueueEntry, ShouldModifyNotifyOnSuccess);
                    if ShouldModifyNotifyOnSuccess then begin
                        JobQueueEntry."Notify On Success" := true;
                        JobQueueEntry.Modify();
                    end;
                end;

            JobQueueEntry."Report Output Type"::Print:
                ;
            else begin
                IsHandled := false;
                OnRunReportOnBeforeReportInboxInsert(ReportInbox, JobQueueEntry, IsHandled);
                if not IsHandled then begin
                    ReportInbox."Created Date-Time" := RoundDateTime(CurrentDateTime, 60000);
                    ReportInbox.Insert(true);
                end;
            end;
        end;
        OnRunReportOnBeforeCommit(ReportInbox, JobQueueEntry);
        Commit();
    end;

    local procedure ProcessPrint(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; RunOnRec: Boolean; var RecRef: RecordRef)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessPrint(ReportID, JobQueueEntry, IsHandled, RecRef);
        if IsHandled then
            exit;

        if RunOnRec then
            REPORT.Print(ReportID, JobQueueEntry.GetReportParameters(), JobQueueEntry."Printer Name", RecRef)
        else
            REPORT.Print(ReportID, JobQueueEntry.GetReportParameters(), JobQueueEntry."Printer Name");

        OnAfterProcessPrint(ReportId, JobQueueEntry, RunOnRec);
    end;

    local procedure ProcessSaveAs(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; RunOnRec: Boolean; var RecordRef: RecordRef; RepFormat: ReportFormat; var OutStream: OutStream)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessSaveAs(ReportID, JobQueueEntry, RunOnRec, RecordRef, RepFormat, OutStream, IsHandled);
        if IsHandled then
            exit;

        if RunOnRec then
            REPORT.SaveAs(ReportID, JobQueueEntry.GetReportParameters(), RepFormat, OutStream, RecordRef)
        else
            REPORT.SaveAs(ReportID, JobQueueEntry.GetReportParameters(), RepFormat, OutStream);
    end;

#if not CLEAN27
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Start Report Base", OnBeforeRunReport, '', false, false)]
    local procedure OnBeforeRunReportBase(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
        OnBeforeRunReport(ReportID, JobQueueEntry, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Start Report Base", OnBeforeRunReportInterface, '', false, false)]
    local procedure OnBeforeRunReportInterfaceBase(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry")
    var
        ReportInbox: Record "Report Inbox";
    begin
        ReportInbox.Init();
        ReportInbox."User ID" := JobQueueEntry."User ID";
        ReportInbox."Job Queue Log Entry ID" := JobQueueEntry.ID;
        ReportInbox."Report ID" := ReportID;
        ReportInbox.Description := JobQueueEntry.Description;
        OnRunReportOnAfterAssignFields(ReportInbox, JobQueueEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Start Report Runner", OnAfterRunReport, '', false, false)]
    local procedure OnAfterRunReportInterface(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry")
    var
        ReportInbox: Record "Report Inbox";
    begin
        ReportInbox.Init();
        ReportInbox."User ID" := JobQueueEntry."User ID";
        ReportInbox."Job Queue Log Entry ID" := JobQueueEntry.ID;
        ReportInbox."Report ID" := ReportID;
        ReportInbox.Description := JobQueueEntry.Description;
        OnRunReportOnBeforeCommit(ReportInbox, JobQueueEntry);
    end;
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Start Report Runner", OnAfterExecuteReport, '', false, false)]
    local procedure OnAfterExecuteReportBaseRunner(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; var ShouldModifyNotifyOnSuccess: Boolean)
    var
        ReportInbox: Record "Report Inbox";
        OriginalReportOutputType: Enum "Job Queue Report Output Type";
    begin
        OriginalReportOutputType := JobQueueEntry."Report Output Type";
        OnRunReportOnAfterProcessDifferentReportOutputTypes(ReportID, JobQueueEntry);
        if JobQueueEntry."Report Output Type" = OriginalReportOutputType then
            OnRunReportOnAfterCalcShouldModifyNotifyOnSuccess(ReportID, JobQueueEntry, ShouldModifyNotifyOnSuccess)
        else begin
            ReportInbox.Init();
            ReportInbox."User ID" := JobQueueEntry."User ID";
            ReportInbox."Job Queue Log Entry ID" := JobQueueEntry.ID;
            ReportInbox."Report ID" := ReportID;
            ReportInbox.Description := JobQueueEntry.Description;
            ProcessJobQueueRun(ReportID, JobQueueEntry, ReportInbox);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessPrint(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean; var RecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessSaveAs(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; RunOnRec: Boolean; var RecordRef: RecordRef; RepFormat: ReportFormat; var OutStream: OutStream; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    [IntegrationEvent(false, false)]
    [Obsolete('This event has been moved to "Job Queue Start Report Base".', '27.0')]
    local procedure OnBeforeRunReport(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnRunReportOnAfterCalcShouldModifyNotifyOnSuccess(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; var ShouldModifyNotifyOnSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
#if not CLEAN27 // Warn users about breaking change even though event still exists
    [Obsolete('This event will continue existing but only called for Job Queue Entries with output type <> None with this obsoletion. To handle Job Queue Entries of type None, hook into "Job Queue Start Report Base".OnBeforeRunReportInterface.', '27.0')]
#endif
    internal procedure OnRunReportOnAfterAssignFields(var ReportInbox: Record "Report Inbox"; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunReportOnAfterProcessDifferentReportOutputTypes(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunReportOnBeforeReportInboxInsert(ReportInbox: Record "Report Inbox"; var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
#if not CLEAN27 // Warn users about breaking change even though event still exists
    [Obsolete('This event will continue existing but only called for Job Queue Entries with output type <> None with this obsoletion. To handle Job Queue Entries of type None, hook into "Job Queue Start Report Runner".OnAfterRunReport.', '27.0')]
#endif
    local procedure OnRunReportOnBeforeCommit(ReportInbox: Record "Report Inbox"; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessPrint(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; RunOnRec: Boolean)
    begin
    end;
}