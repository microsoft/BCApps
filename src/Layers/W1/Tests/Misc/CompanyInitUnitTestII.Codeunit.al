codeunit 134164 "Company Init Unit Test II"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Company-Initialize] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyInit()
    var
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
    begin
        // [FEATURE] [Job Queue Entry]
        // [SCENARIO 212633] Job Queue Entry for codeunit "O365 Sync. Management" must be created zero times when "Company-Initialize" has been ran
        // in the test gate.
        Initialize();

        BindSubscription(LibraryJobQueue);

        // [GIVEN] Job Queue Entry for codeunit "O365 Sync. Management" doesn't exist
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"O365 Sync. Management");
        JobQueueEntry.DeleteAll();

        // [GIVEN] Invoke "Company-Initialize" at the first time
        CODEUNIT.Run(CODEUNIT::"Company-Initialize");

        Assert.RecordCount(JobQueueEntry, 0);

        // [WHEN] Invoke "Company-Initialize" at the second time
        CODEUNIT.Run(CODEUNIT::"Company-Initialize");

        // [THEN] Job Queue Entry for codeunit "O365 Sync. Management" exists once
        Assert.RecordCount(JobQueueEntry, 0);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Company Init Unit Test II");

        if IsInitialized then
            exit;

        IsInitialized := false;
        Commit();
    end;
}

