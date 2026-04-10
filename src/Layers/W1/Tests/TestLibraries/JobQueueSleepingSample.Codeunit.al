codeunit 132452 "Job Queue Sleeping Sample"
{

    trigger OnRun()
    var
        JobQueueSampleLogging: Record "Job Queue Sample Logging";
    begin
        // Log an entry indicating we are entering the Codeunit.
        JobQueueSampleLogging.LogRecord('COD132452 Sample Codeunit - Sleeping: Starting');

        // Sleep for 10s to simulate some work happening
        Sleep(10000);
        Message(Text001);

        // Log an entry indicating we are exiting the Codeunit
        JobQueueSampleLogging.LogRecord('----> COD132452 Sample Codeunit - Sleeping: Done');
    end;

    var
        Text001: Label 'Slept 10s and now exiting successfully.';
}

