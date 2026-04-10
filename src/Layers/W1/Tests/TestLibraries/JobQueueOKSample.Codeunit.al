codeunit 132450 "Job Queue OK Sample"
{

    trigger OnRun()
    var
        JobQueueSampleLogging: Record "Job Queue Sample Logging";
    begin
        // Log an entry indicating we are entering the Codeunit.
        JobQueueSampleLogging.LogRecord('COD132450 Sample Codeunit - OK: Starting');

        Message(Text001);

        // Log an entry indicating we are exiting the Codeunit
        JobQueueSampleLogging.LogRecord('----> COD132450 Sample Codeunit - OK: Done');
    end;

    var
        Text001: Label 'Sample Codeunit reported this message which should be suppressed when running silently on the Queue.';
}

