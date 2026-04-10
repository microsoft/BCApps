codeunit 132456 "Job Queue Failed Insert Sample"
{

    trigger OnRun()
    var
        JobQueueSampleLogging: Record "Job Queue Sample Logging";
    begin
        // Uses "Job Queue Sample Logging" test object with the assumption that the primary
        // key is not set to Autoincrement=TRUE.
        JobQueueSampleLogging.DeleteAll();
        Commit();

        // Inserts a record with the same key twice, thereby causing an
        // error when the transaction is committed.
        // We intentionally do not call COMMIT at the end of this method
        // so that COMMIT is called by the parent scope.
        JobQueueSampleLogging.Init();
        JobQueueSampleLogging."No." := 1;
        JobQueueSampleLogging.Insert();
        JobQueueSampleLogging.Insert();
    end;
}

