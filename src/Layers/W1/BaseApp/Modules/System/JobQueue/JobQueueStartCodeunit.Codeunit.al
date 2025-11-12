namespace System.Threading;

using System.Environment.Configuration;
using System.Utilities;

codeunit 449 "Job Queue Start Codeunit"
{
    Permissions = TableData "Job Queue Entry" = rm, tabledata "Report Settings Override" = rim;
    TableNo = "Job Queue Entry";

    var
        JobQueueStartContextTxt: Label 'Job Queue Start', Locked = true;

    trigger OnRun()
    var
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageRegisterId: Guid;
        Success: Boolean;
        LastError: DotNet LastError;
    begin
        OnBeforeRun(Rec);

        if Rec."User Language ID" <> 0 then
            GlobalLanguage(Rec."User Language ID");

        ErrorMessageManagement.PushContext(ErrorContextElement, Rec.RecordId(), 0, JobQueueStartContextTxt);
        case Rec."Object Type to Run" of
            Rec."Object Type to Run"::Codeunit:
                Success := Codeunit.Run(Rec."Object ID to Run", Rec);
            Rec."Object Type to Run"::Report:
                Success := RunReport(Rec."Object ID to Run", Rec);
        end;

        if not success then begin
            if ErrorMessageManagement.GetErrorsInContext(ErrorContextElement, TempErrorMessage) then begin
                ErrorMessageRegisterId := ErrorMessageHandler.RegisterErrorMessages(false);
                Rec."Error Message Register Id" := ErrorMessageRegisterId;
                Rec.Modify();
                Commit();
            end;
            ErrorMessageManagement.PopContext(ErrorContextElement);

            // throw last error
            LastError.Rethrow();
        end;

        // Commit any remaining transactions from the target codeunit\report. This is necessary due
        // to buffered record insertion which may not have surfaced errors in CODEUNIT.RUN above.
        Commit();
        OnAfterRun(Rec);
    end;

    local procedure RunReport(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunReport(ReportID, JobQueueEntry, IsHandled);
        if IsHandled then
            exit(true);

        exit(Codeunit.Run(Codeunit::"Job Queue Start Report Base", JobQueueEntry));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunReport(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Not needed anymore', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeActivateErrorMessageHandler(var JobQueueEntry: Record "Job Queue Entry"; var ErrorMessageHandler: Codeunit "Error Message Handler"; var ErrorMessageManagement: Codeunit "Error Message Management"; var SuppressErrorLogging: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;
}

