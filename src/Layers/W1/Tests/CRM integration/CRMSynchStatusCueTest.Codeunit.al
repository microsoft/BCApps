codeunit 139170 "CRM Synch. Status Cue Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Job Queue] [CRM Integration] [CRM Synch. Job Status Cue]
    end;

    var
        Assert: Codeunit Assert;
        CRMSynchJobManagement: Codeunit "CRM Synch. Job Management";

    [Test]
    [Scope('OnPrem')]
    procedure TestSetInitialState()
    var
        CRMSynchJobStatusCue: Record "CRM Synch. Job Status Cue";
        TestDate: DateTime;
        DefaultObjectToRun: Integer;
    begin
        CRMSynchJobStatusCue.DeleteAll();
        CRMSynchJobManagement.SetInitialState(CRMSynchJobStatusCue);
        Assert.IsTrue(CRMSynchJobStatusCue.Code = '0', 'Expected ''0'' as the default value for the synch. status record');
        Assert.IsTrue(CRMSynchJobStatusCue.GetFilter("Date Filter") = '>''''',
          'Invalid filter. It should be the default date time, for empyt dates.');
        TestDate := CreateDateTime(Today, Time);
        CRMSynchJobStatusCue."Reset Date" := TestDate;
        CRMSynchJobStatusCue.Modify();
        CRMSynchJobManagement.SetInitialState(CRMSynchJobStatusCue);
        DefaultObjectToRun := CRMSynchJobManagement.GetDefaultJobRunner();
        EvaluateFilters(CRMSynchJobStatusCue, TestDate, DefaultObjectToRun);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnResetNoFailedJobQueue()
    var
        JobQueueEntry: Record "Job Queue Entry";
        CRMSynchJobStatusCue: Record "CRM Synch. Job Status Cue";
        JobToRun: Integer;
    begin
        JobToRun := 5339;
        PrepareResetTest(JobQueueEntry, CRMSynchJobStatusCue, 5339, JobQueueEntry.Status::Ready);
        Assert.IsTrue(DT2Date(CRMSynchJobStatusCue."Reset Date") = Today,
          'If no failed records are found, we should look for records starting from now');
        EvaluateFilters(CRMSynchJobStatusCue, CRMSynchJobStatusCue."Reset Date", JobToRun);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOnResetWithFailedJobQueue()
    var
        JobQueueEntry: Record "Job Queue Entry";
        CRMSynchJobStatusCue: Record "CRM Synch. Job Status Cue";
        JobToRun: Integer;
    begin
        JobToRun := 5339;
        PrepareResetTest(JobQueueEntry, CRMSynchJobStatusCue, 5339, JobQueueEntry.Status::Error);
        Assert.IsTrue(Abs(CRMSynchJobStatusCue."Reset Date" - JobQueueEntry."Last Ready State") < 500,
          'For failed records we should process from the last ready state.');
        EvaluateFilters(CRMSynchJobStatusCue, CRMSynchJobStatusCue."Reset Date", JobToRun);
    end;

    local procedure EvaluateFilters(var CRMSynchJobStatusCue: Record "CRM Synch. Job Status Cue"; TestDate: DateTime; ObjectIDToRun: Integer)
    var
        ComputedDate: DateTime;
        Pos: Integer;
        "Filter": Text;
        ObjectIDToRunFilterValue: Integer;
    begin
        Filter := CRMSynchJobStatusCue.GetFilter("Date Filter");
        Pos := StrPos(Filter, '>');
        Evaluate(ComputedDate, CopyStr(Filter, Pos + 1));
        Assert.IsTrue(Format(ComputedDate) = Format(TestDate),
          StrSubstNo('Invalid filter. Expected:%1 Received:%2', Format(ComputedDate), Format(TestDate)));
        Filter := CRMSynchJobStatusCue.GetFilter("Object ID to Run");
        Evaluate(ObjectIDToRunFilterValue, Filter);
        Assert.IsTrue(ObjectIDToRun = ObjectIDToRunFilterValue,
          StrSubstNo('Invalid filter. Expected:%1 Received:%2', Format(ObjectIDToRun), Format(ObjectIDToRunFilterValue)))
    end;

    local procedure CreateJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; CodeUnitToRun: Integer; Status: Option)
    begin
        JobQueueEntry.DeleteAll();
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(Today, 0T);
        JobQueueEntry."Last Ready State" := CreateDateTime(Today, 0T);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CodeUnitToRun;
        JobQueueEntry."Record ID to Process" := JobQueueEntry.RecordId;
        JobQueueEntry."Run in User Session" := true;
        JobQueueEntry.Status := Status;
        JobQueueEntry.Insert(true);
    end;

    local procedure PrepareResetTest(var JobQueueEntry: Record "Job Queue Entry"; var CRMSynchJobStatusCue: Record "CRM Synch. Job Status Cue"; JobToRun: Integer; Status: Option)
    begin
        CreateJobQueueEntry(JobQueueEntry, JobToRun, Status);
        Assert.IsTrue(JobQueueEntry.Count = 1, 'There should be 1 JobQueueEntry Record');
        CRMSynchJobStatusCue.DeleteAll();
        CRMSynchJobManagement.SetInitialState(CRMSynchJobStatusCue);
        CRMSynchJobManagement.OnReset(CRMSynchJobStatusCue);
    end;
}

