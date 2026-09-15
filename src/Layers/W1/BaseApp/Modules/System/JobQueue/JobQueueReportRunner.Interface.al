namespace System.Threading;

interface "Job Queue Report Runner"
{
    procedure RunReport(ReportID: Integer; var JobQueueEntry: Record "Job Queue Entry");
}