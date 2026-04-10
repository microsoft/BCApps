codeunit 132451 "Job Queue Working Sample"
{

    trigger OnRun()
    var
        JobQueueSampleLogging: Record "Job Queue Sample Logging";
        Counter: Integer;
    begin
        // Log an entry indicating we are entering the Codeunit.
        JobQueueSampleLogging.LogRecord('COD132451 Sample Codeunit - Working: Starting');

        // Do some work which should take between 10 and 40s depending on machine resources
        Counter := 0;
        while Counter < 5000000 do begin
            JobQueueSampleLogging.SetFilter("No.", Format(Counter));
            if not JobQueueSampleLogging.Find() then;

            Counter := Counter + 1;
        end;

        Message(Text001);

        JobQueueSampleLogging.Reset();

        // Log an entry indicating we are exiting the Codeunit
        JobQueueSampleLogging.LogRecord('----> COD132451 Sample Codeunit - Working: Done');
    end;

    var
        Text001: Label 'Did some work and now exiting successfully.';
}

