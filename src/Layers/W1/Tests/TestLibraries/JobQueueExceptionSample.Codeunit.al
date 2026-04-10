codeunit 132454 "Job Queue Exception Sample"
{

    trigger OnRun()
    var
        JobQueueSampleLogging: Record "Job Queue Sample Logging";
        DotNetInvoke: DotNet XmlTextReader;
    begin
        // Log an entry indicating we are entering the Codeunit.
        JobQueueSampleLogging.LogRecord('COD132454 Sample Codeunit - Exception: Starting');

        // Invoke some .net call which throws an exception, in this case FileNotFoundException
        DotNetInvoke.Create('MyNonExistantFile.MyFile');

        // Log an entry indicating we are exiting the Codeunit
        // Note that this should not be logged since we exit the trigger earlier.
        JobQueueSampleLogging.LogRecord('----> COD132454 Sample Codeunit - Exception: Done');
    end;
}

