#pragma warning disable AA0247
codeunit 139933 "MDM Cross-Env Detector Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure DetectorNudgesChangedEnabledTable()
    var
        Mapping: Record "Integration Table Mapping";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        DetectorProbe: Codeunit "MDM Test Detector Probe";
    begin
        // [FEATURE] [AI test 0.4] [Master Data Management] [Cross-Environment]
        // [SCENARIO] A table changed since its watermark gets its synchronization job nudged.
        Initialize();
        CreateMapping(Mapping, Database::Customer, WatermarkDateTime(), true);
        InsertSynchJob(Mapping, false); // an idle (Ready) job exists

        InProcessTransport.Activate();
        InProcessTransport.SetCannedResponse(CannedLastModified(Database::Customer, true, ChangedDateTime(), true));
        DetectorProbe.Activate();

        LibraryMasterDataMgt.RunChangeDetector();

        Assert.IsTrue(DetectorProbe.WasNudged(Database::Customer), 'A changed enabled table should be nudged');
        CleanUp();
    end;

    [Test]
    procedure DetectorSkipsUnchangedTable()
    var
        Mapping: Record "Integration Table Mapping";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        DetectorProbe: Codeunit "MDM Test Detector Probe";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A table whose source timestamp is not past the watermark is not nudged.
        Initialize();
        CreateMapping(Mapping, Database::Customer, WatermarkDateTime(), true);
        InsertSynchJob(Mapping, false);

        InProcessTransport.Activate();
        InProcessTransport.SetCannedResponse(CannedLastModified(Database::Customer, true, UnchangedDateTime(), true));
        DetectorProbe.Activate();

        LibraryMasterDataMgt.RunChangeDetector();

        Assert.IsFalse(DetectorProbe.WasNudged(Database::Customer), 'An unchanged table should not be nudged');
        CleanUp();
    end;

    [Test]
    procedure DetectorSkipsDisabledTable()
    var
        Mapping: Record "Integration Table Mapping";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        DetectorProbe: Codeunit "MDM Test Detector Probe";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A disabled table is never polled or nudged, even if the source reports a change.
        Initialize();
        CreateMapping(Mapping, Database::Customer, WatermarkDateTime(), false); // disabled
        InsertSynchJob(Mapping, false);

        InProcessTransport.Activate();
        InProcessTransport.SetCannedResponse(CannedLastModified(Database::Customer, true, ChangedDateTime(), true));
        DetectorProbe.Activate();

        LibraryMasterDataMgt.RunChangeDetector();

        Assert.IsFalse(DetectorProbe.WasNudged(Database::Customer), 'A disabled table should not be nudged');
        CleanUp();
    end;

    [Test]
    procedure DetectorLeavesInProcessJobAlone()
    var
        Mapping: Record "Integration Table Mapping";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        DetectorProbe: Codeunit "MDM Test Detector Probe";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A changed table whose job is already In Process is left alone (no idle job to nudge).
        Initialize();
        CreateMapping(Mapping, Database::Customer, WatermarkDateTime(), true);
        InsertSynchJob(Mapping, true); // job In Process

        InProcessTransport.Activate();
        InProcessTransport.SetCannedResponse(CannedLastModified(Database::Customer, true, ChangedDateTime(), true));
        DetectorProbe.Activate();

        LibraryMasterDataMgt.RunChangeDetector();

        Assert.IsFalse(DetectorProbe.WasNudged(Database::Customer), 'A table whose job is In Process should be left alone');
        CleanUp();
    end;

    [Test]
    procedure DetectorSkipsUnavailableTable()
    var
        Mapping: Record "Integration Table Mapping";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        DetectorProbe: Codeunit "MDM Test Detector Probe";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A table the source reports as unavailable is not nudged (the sync job reports the error).
        Initialize();
        CreateMapping(Mapping, Database::Customer, WatermarkDateTime(), true);
        InsertSynchJob(Mapping, false);

        InProcessTransport.Activate();
        InProcessTransport.SetCannedResponse(CannedLastModified(Database::Customer, false, ChangedDateTime(), false));
        DetectorProbe.Activate();

        LibraryMasterDataMgt.RunChangeDetector();

        Assert.IsFalse(DetectorProbe.WasNudged(Database::Customer), 'An unavailable table should not be nudged');
        CleanUp();
    end;

    [Test]
    procedure DetectorNudgesAvailableTableWithoutTimestamp()
    var
        Mapping: Record "Integration Table Mapping";
        LibraryMasterDataMgt: Codeunit "Library - Master Data Mgt.";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        DetectorProbe: Codeunit "MDM Test Detector Probe";
    begin
        // [FEATURE] [Master Data Management] [Cross-Environment]
        // [SCENARIO] A table the source reports available but WITHOUT a lastModifiedAt (keyless/unindexed) is nudged
        //            so the sync job scans it, rather than being silently skipped.
        Initialize();
        CreateMapping(Mapping, Database::Customer, WatermarkDateTime(), true);
        InsertSynchJob(Mapping, false);

        InProcessTransport.Activate();
        InProcessTransport.SetCannedResponse(CannedLastModified(Database::Customer, true, 0DT, false)); // available, no timestamp
        DetectorProbe.Activate();

        LibraryMasterDataMgt.RunChangeDetector();

        Assert.IsTrue(DetectorProbe.WasNudged(Database::Customer), 'An available table without a timestamp should be nudged to scan');
        CleanUp();
    end;

    local procedure Initialize()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        InProcessTransport: Codeunit "MDM In-Process Transport";
        DetectorProbe: Codeunit "MDM Test Detector Probe";
    begin
        InProcessTransport.Deactivate();
        DetectorProbe.Deactivate();
        // RunChangeDetector calls DetectChanges() directly (no Codeunit.Run) and the detector never commits, so it runs
        // inside the test transaction; DeleteTestArtifacts() defensively clears any residue from an aborted prior run.
        DeleteTestArtifacts();
        if not MasterDataManagementSetup.Get() then begin
            MasterDataManagementSetup.Init();
            MasterDataManagementSetup.Insert();
        end;
        // Direct assignment avoids the OnValidate that (de)provisions the detector job.
        MasterDataManagementSetup."Is Enabled" := true;
        MasterDataManagementSetup."Source Environment Name" := 'PROD';
        MasterDataManagementSetup.Modify(false);
    end;

    local procedure CleanUp()
    var
        InProcessTransport: Codeunit "MDM In-Process Transport";
        DetectorProbe: Codeunit "MDM Test Detector Probe";
    begin
        InProcessTransport.Deactivate();
        DetectorProbe.Deactivate();
        DeleteTestArtifacts();
    end;

    local procedure DeleteTestArtifacts()
    var
        Mapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        Mapping.SetFilter(Name, 'MDMXD*');
        if Mapping.FindSet() then
            repeat
                JobQueueEntry.SetRange("Record ID to Process", Mapping.RecordId());
                JobQueueEntry.DeleteAll();
            until Mapping.Next() = 0;
        Mapping.DeleteAll();
    end;

    local procedure CreateMapping(var Mapping: Record "Integration Table Mapping"; TableId: Integer; Watermark: DateTime; Enabled: Boolean)
    var
        LibraryRandom: Codeunit "Library - Random";
    begin
        Mapping.Init();
        Mapping.Name := CopyStr('MDMXD' + Format(LibraryRandom.RandIntInRange(1, 999999)), 1, MaxStrLen(Mapping.Name));
        Mapping.Type := Mapping.Type::"Master Data Management";
        Mapping."Table ID" := TableId;
        Mapping."Integration Table ID" := TableId;
        Mapping."Integration Table UID Fld. No." := 2000000000; // SystemId
        Mapping."Int. Tbl. Modified On Fld. No." := 2000000003; // SystemModifiedAt
        Mapping."Synch. Modified On Filter" := Watermark;
        Mapping."Delete After Synchronization" := false;
        if Enabled then
            Mapping.Status := Mapping.Status::Enabled
        else
            Mapping.Status := Mapping.Status::Disabled;
        Mapping.Insert();
    end;

    // Insert-only (no scheduling): the test lab can't schedule background jobs, and the detector only reads status.
    local procedure InsertSynchJob(Mapping: Record "Integration Table Mapping"; InProcess: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Integration Synch. Job Runner";
        JobQueueEntry."Record ID to Process" := Mapping.RecordId();
        JobQueueEntry."Recurring Job" := true;
        if InProcess then
            JobQueueEntry.Status := JobQueueEntry.Status::"In Process"
        else
            JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Insert(false);
    end;

    local procedure CannedLastModified(TableId: Integer; TableAvailable: Boolean; LastModifiedAt: DateTime; IncludeTimestamp: Boolean) ResultText: Text
    var
        Response: JsonObject;
        Entry: JsonObject;
        Tables: JsonArray;
    begin
        Entry.Add('tableId', TableId);
        Entry.Add('tableAvailable', TableAvailable);
        if IncludeTimestamp then
            Entry.Add('lastModifiedAt', Format(LastModifiedAt, 0, 9));
        Tables.Add(Entry);
        Response.Add('tables', Tables);
        Response.WriteTo(ResultText);
    end;

    local procedure WatermarkDateTime(): DateTime
    begin
        exit(CreateDateTime(DMY2Date(1, 1, 2020), 0T));
    end;

    local procedure ChangedDateTime(): DateTime
    begin
        exit(CreateDateTime(DMY2Date(1, 1, 2030), 0T));
    end;

    local procedure UnchangedDateTime(): DateTime
    begin
        exit(CreateDateTime(DMY2Date(1, 1, 2019), 0T));
    end;
}
