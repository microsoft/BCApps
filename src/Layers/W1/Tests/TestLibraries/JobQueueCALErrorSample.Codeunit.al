codeunit 132453 "Job Queue CAL Error Sample"
{

    trigger OnRun()
    var
        JobQueueSampleLogging: Record "Job Queue Sample Logging";
    begin
        // Log an entry indicating we are entering the Codeunit.
        JobQueueSampleLogging.LogRecord('COD132453 Sample Codeunit - CAL Error: Starting');

        if true then
            Error(Text001);

        // Log an entry indicating we are exiting the Codeunit.
        // This should not be logged since we throw an error earlier.
        JobQueueSampleLogging.LogRecord('----> COD132453 Sample Codeunit - CAL Error: Done');
    end;

    var
        Text001: Label 'Sample Codeunit reported an error in CAL code.';
}

