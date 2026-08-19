namespace System.Threading;

pageextension 682 "Schedule a Report Ext" extends "Schedule a Report"
{
    layout
    {
        modify("Printer Name")
        {
            Enabled = Rec."Report Output Type" = Rec."Report Output Type"::Print;
        }
    }

    var
        ReportScheduledMsg: Label 'The report has been scheduled. It will appear in the Report Inbox part when it is completed.';

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if CloseAction <> ACTION::OK then
            exit(true);

        if Rec."Object ID to Run" = 0 then
            exit(false);

        if JobQueueEntry.IsToReportInbox() then
            Message(ReportScheduledMsg);
        exit(true);
    end;
}
