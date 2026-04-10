codeunit 134132 "Data Administration Page Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        JobScheduledMsg: Label 'A job queue entry that runs daily to refresh the table information cache was created.';
        OtherCompanyJQQst: Label 'Do you want to delete the entry and create a new entry in the current company';
        ActionCancelledMsg: Label 'The action was cancelled by the user.';

    local procedure Initialize()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Table Information Cache");
        JobQueueEntry.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('JobScheduledMessageHandler')]
    procedure TestScheduleFirstTableInfoRefreshJobQueue()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ScheduleTableInfoRefreshJQ: Codeunit "Schedule Table Info Refresh JQ";
    begin
        // [Scenario] Given no JQ to refresh table info, schedule the JQ
        Initialize();

        // setup

        // exercise
        ScheduleTableInfoRefreshJQ.ScheduleTableInfoRefreshJobQueue();

        // verify
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Table Information Cache");
        Assert.RecordIsNotEmpty(JobQueueEntry);
    end;

    [Test]
    [HandlerFunctions('JobScheduledMessageHandler')]
    procedure TestScheduleSecondTableInfoRefreshJobQueue()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ScheduleTableInfoRefreshJQ: Codeunit "Schedule Table Info Refresh JQ";
    begin
        // [Scenario] Given a JQ to refresh table info exists, don't schedule a second JQ
        Initialize();

        // setup
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Table Information Cache";
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Insert();

        // exercise
        ScheduleTableInfoRefreshJQ.ScheduleTableInfoRefreshJobQueue();

        // verify
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Table Information Cache");
        Assert.AreEqual(1, JobQueueEntry.Count(), 'Only one Job Queue entry should exist.');
    end;

    [Test]
    [HandlerFunctions('JobScheduledMessageHandler')]
    procedure TestScheduleTableInfoRefreshJobQueueNotReady()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ScheduleTableInfoRefreshJQ: Codeunit "Schedule Table Info Refresh JQ";
    begin
        // [Scenario] Given a JQ to refresh table info exists in not ready state, set to ready
        Initialize();

        // setup
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Table Information Cache";
        JobQueueEntry.Status := JobQueueEntry.Status::Error;
        JobQueueEntry.Insert();

        // exercise
        ScheduleTableInfoRefreshJQ.ScheduleTableInfoRefreshJobQueue();

        // verify
        JobQueueEntry.GetBySystemId(JobQueueEntry.SystemId);
        Assert.AreEqual(JobQueueEntry.Status::Ready, JobQueueEntry.Status, 'The Job Queue Entry should have Status::Ready');
    end;

    [Test]
    [HandlerFunctions('OtherCompanyConfirmHandlerTrue,JobScheduledMessageHandler')]
    procedure TestScheduleSecondTableInfoRefreshJobQueueOtherCompanyReschedule()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Company: Record Company;
        ScheduleTableInfoRefreshJQ: Codeunit "Schedule Table Info Refresh JQ";
    begin
        // [Scenario] Given a JQ to refresh table info exists in another company, reschedule the JQ in this company
        Initialize();

        // setup
        Company.Name := CopyStr(LibraryRandom.RandText(MaxStrLen(Company.Name)), 1, MaxStrLen(Company.Name));
        Company."Evaluation Company" := true;
        Company.Insert();
        JobQueueEntry.ChangeCompany(Company.Name);
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Table Information Cache";
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Insert();

        // exercise
        ScheduleTableInfoRefreshJQ.ScheduleTableInfoRefreshJobQueue();

        // verify
        // other company
        JobQueueEntry.ChangeCompany(Company.Name);
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Table Information Cache");
        Assert.RecordIsEmpty(JobQueueEntry, Company.Name);
        // current company
        JobQueueEntry.ChangeCompany(CompanyName());
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Table Information Cache");
        Assert.RecordIsNotEmpty(JobQueueEntry);
    end;

    [Test]
    [HandlerFunctions('OtherCompanyConfirmHandlerFalse,ActionCancelledMessageHandler')]
    procedure TestScheduleSecondTableInfoRefreshJobQueueOtherCompanyCancel()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Company: Record Company;
        ScheduleTableInfoRefreshJQ: Codeunit "Schedule Table Info Refresh JQ";
    begin
        // [Scenario] Given a JQ to refresh table info exists in another company, don't reschedule the JQ
        Initialize();

        // setup
        Company.Name := CopyStr(LibraryRandom.RandText(MaxStrLen(Company.Name)), 1, MaxStrLen(Company.Name));
        Company."Evaluation Company" := true;
        Company.Insert();
        JobQueueEntry.ChangeCompany(Company.Name);
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Table Information Cache";
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Insert();

        // exercise
        ScheduleTableInfoRefreshJQ.ScheduleTableInfoRefreshJobQueue();

        // verify
        // other company
        JobQueueEntry.ChangeCompany(Company.Name);
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Table Information Cache");
        Assert.RecordIsNotEmpty(JobQueueEntry, Company.Name);
        // current company
        JobQueueEntry.ChangeCompany(CompanyName());
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Table Information Cache");
        Assert.RecordIsEmpty(JobQueueEntry);
    end;

    [MessageHandler]
    procedure JobScheduledMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(JobScheduledMsg, Message);
    end;

    [MessageHandler]
    procedure ActionCancelledMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ActionCancelledMsg, Message);
    end;

    [ConfirmHandler]
    procedure OtherCompanyConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedConfirm(OtherCompanyJQQst, Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure OtherCompanyConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedConfirm(OtherCompanyJQQst, Question);
        Reply := false;
    end;
}