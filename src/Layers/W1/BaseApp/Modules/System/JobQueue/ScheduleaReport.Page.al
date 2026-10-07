namespace System.Threading;
using Microsoft.Foundation.Reporting;

page 682 "Schedule a Report"
{
    Caption = 'Schedule a Report';
    DataCaptionExpression = Rec.Description;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = "Job Queue Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            field("Object ID to Run"; Rec."Object ID to Run")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Report ID';
                Editable = ReportEditable;
                ToolTip = 'Specifies the ID of the object that is to be run for this job. You can select an ID that is of the object type that you have specified in the Object Type to Run field.';

                trigger OnLookup(var Text: Text): Boolean
                var
                    NewObjectID: Integer;
                begin
                    if Rec.LookupObjectID(NewObjectID) then begin
                        Text := Format(NewObjectID);
                        exit(true);
                    end;
                    exit(false);
                end;

                trigger OnValidate()
                begin
                    if Rec."Object ID to Run" <> 0 then
                        Rec.RunReportRequestPage();
                    OutPutEditable := not ReportManagementHelper.IsProcessingOnly(Rec."Object ID to Run");
                end;
            }
            field("Object Caption to Run"; Rec."Object Caption to Run")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Report Name';
                Enabled = false;
                ToolTip = 'Specifies the name of the object that is selected in the Object ID to Run field.';
            }
            field(Description; Rec.Description)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies a description of the job queue entry. You can edit and update the description on the job queue entry card. The description is also displayed in the Job Queue Entries window, but it cannot be updated there.';
            }
            field("Report Request Page Options"; Rec."Report Request Page Options")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies whether options on the report request page have been set for scheduled report job. If the check box is selected, then options have been set for the scheduled report.';
                Visible = ReportEditable;
            }
            field("Report Output Type"; Rec."Report Output Type")
            {
                ApplicationArea = Basic, Suite;
                Enabled = OutPutEditable;
                ToolTip = 'Specifies the output of the scheduled report.';
            }
            field("Printer Name"; Rec."Printer Name")
            {
                ApplicationArea = Basic, Suite;
                Importance = Additional;
                ToolTip = 'Specifies the printer to use to print the scheduled report.';
            }
            field("Next Run Date Formula"; Rec."Next Run Date Formula")
            {
                ApplicationArea = Basic, Suite;
                Importance = Additional;
                ToolTip = 'Specifies the date formula that is used to calculate the next time the recurring job queue entry will run.';
            }
            field("Earliest Start Date/Time"; Rec."Earliest Start Date/Time")
            {
                ApplicationArea = Basic, Suite;
                Importance = Additional;
                ToolTip = 'Specifies the earliest date and time when the job queue entry should be run.  The format for the date and time must be month/day/year hour:minute, and then AM or PM. For example, 3/10/2021 12:00 AM.';
            }
            field("Expiration Date/Time"; Rec."Expiration Date/Time")
            {
                ApplicationArea = Basic, Suite;
                Importance = Additional;
                ToolTip = 'Specifies the date and time when the job queue entry is to expire, after which the job queue entry will not be run.  The format for the date and time must be month/day/year hour:minute, and then AM or PM. For example, 3/10/2021 12:00 AM.';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        OutPutEditable := true;

        if not Rec.FindFirst() then begin
            Rec.Init();
            ReportEditable := true;
            Rec.Status := Rec.Status::"On Hold";
            Rec.Validate("Object Type to Run", Rec."Object Type to Run"::Report);
            Rec.Insert(true);
        end else
            OutPutEditable := not ReportManagementHelper.IsProcessingOnly(Rec."Object ID to Run");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if CloseAction <> ACTION::OK then
            exit(true);

        if Rec."Object ID to Run" = 0 then begin
            Message(NoIdMsg);
            exit(false);
        end;

        Rec.CalcFields(XML);
        JobQueueEntry := Rec;
        Clear(JobQueueEntry.ID); // "Job Queue - Enqueue" defines it on the real record insert
        JobQueueEntry."Run in User Session" := not JobQueueEntry.IsNextRunDateFormulaSet();
        if JobQueueEntry.Description = '' then
            JobQueueEntry.Description := CopyStr(Rec."Object Caption to Run", 1, MaxStrLen(JobQueueEntry.Description));
        OnOnQueryClosePageOnBeforeJobQueueEnqueue(Rec, JobQueueEntry);
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        exit(true);
    end;

    var
        ReportManagementHelper: Codeunit "Report Management Helper";
        NoIdMsg: Label 'You must specify a report number.';
        ReportEditable: Boolean;
        OutPutEditable: Boolean;

    procedure ScheduleAReport(ReportId: Integer; RequestPageXml: Text): Boolean
    var
        ScheduleAReport: Page "Schedule a Report";
    begin
        ScheduleAReport.SetParameters(ReportId, RequestPageXml);
        exit(ScheduleAReport.RunModal() = ACTION::OK);
    end;

    procedure Schedule(ReportId: Integer; RequestPageXml: Text): Boolean
    begin
        SetParameters(ReportId, RequestPageXml);
        exit(CurrPage.RunModal() = ACTION::OK);
    end;

    procedure SetParameters(ReportId: Integer; RequestPageXml: Text)
    var
        ReportDescription: Text[250];
        IsHandled: Boolean;
    begin
        Rec.Init();
        Rec.Status := Rec.Status::"On Hold";
        Rec.Validate("Object Type to Run", Rec."Object Type to Run"::Report);
        Rec.Validate("Object ID to Run", ReportId);

        OnGetReportDescription(ReportDescription, RequestPageXml, ReportId, IsHandled, Rec);
        if IsHandled then
            Rec.Description := ReportDescription;

        Rec.Insert(true);
        Rec.SetReportParameters(RequestPageXml);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetReportDescription(var ReportDescription: Text[250]; RequestPageXml: Text; ReportId: Integer; var IsHandled: Boolean; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnQueryClosePageOnBeforeJobQueueEnqueue(var JobQueueEntryRec: Record "Job Queue Entry"; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;
}

