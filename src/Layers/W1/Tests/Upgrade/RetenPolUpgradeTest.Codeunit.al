codeunit 135952 "Reten. Pol. Upgrade Test"
{
    Subtype = Test;

    var
        LibraryAssert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    [Test]
    procedure TestSentNotificationEntryRetentionPolicyUpdated()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetentionPeriod: Record "Retention Period";
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
    begin
        // Init
        Initialize();

        // Setup
        RetentionPolicySetup.SetRange("Table Id", Database::"Sent Notification Entry");
        RetentionPolicySetup.DeleteAll();

        // Exercise
        RetentionPolicySetup.Init();
        RetentionPolicySetup.Validate("Table Id", Database::"Sent Notification Entry");
        RetentionPolicySetup.Insert(true);

        // Verify
        RetentionPolicySetupLine.Get(Database::"Sent Notification Entry", 10000);
        LibraryAssert.IsFalse(RetentionPolicySetupLine.IsLocked(), 'Retention Policy Line shouldn''t be locked');
        RetentionPeriod.Get(RetentionPolicySetupLine."Retention Period");
        LibraryAssert.AreEqual(Format(Enum::"Retention Period Enum"::"6 Months"), Format(RetentionPeriod."Retention Period"), 'Incorrect period for retention policy setup line');
    end;

    [Test]
    procedure TestRegisteredWhseActivityHdrRetentionPolicyUpdated()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
    begin
        // Init
        Initialize();

        // Setup
        RetentionPolicySetup.SetRange("Table Id", Database::"Registered Whse. Activity Hdr.");
        RetentionPolicySetup.DeleteAll();

        // Exercise
        Clear(RetentionPolicySetup);
        RetentionPolicySetup.Validate("Table Id", Database::"Registered Whse. Activity Hdr.");
        RetentionPolicySetup.Insert(true);

        // Verify
        LibraryAssert.AreEqual(RegisteredWhseActivityHdr.FieldNo("Registering Date"), RetentionPolicySetup."Date Field No.", 'Date Field No. is incorrect initialized');
    end;

    [Test]
    procedure TestPostedWhseShipmentHeaderRetentionPolicyUpdated()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
    begin
        // Init
        Initialize();

        // Setup
        RetentionPolicySetup.SetRange("Table Id", Database::"Posted Whse. Shipment Header");
        RetentionPolicySetup.DeleteAll();

        // Exercise
        Clear(RetentionPolicySetup);
        RetentionPolicySetup.Validate("Table Id", Database::"Posted Whse. Shipment Header");
        RetentionPolicySetup.Insert(true);

        // Verify
        LibraryAssert.AreEqual(PostedWhseShipmentHeader.FieldNo("Posting Date"), RetentionPolicySetup."Date Field No.", 'Date Field No. is incorrect initialized');
    end;

    [Test]
    procedure TestDataExchRetentionPolicyUpdated()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        DataExch: Record "Data Exch.";
    begin
        Initialize();

        // [GIVEN] The retention policy setup for Data Exch. is empty
        RetentionPolicySetup.SetRange("Table Id", Database::"Data Exch.");
        RetentionPolicySetup.DeleteAll();

        // [WHEN] The retention policy setup for Data Exch. is created
        Clear(RetentionPolicySetup);
        RetentionPolicySetup.Validate("Table Id", Database::"Data Exch.");
        RetentionPolicySetup.Insert(true);

        // [THEN] The retention policy setup line for Data Exch. is created with the correct date field
        LibraryAssert.AreEqual(DataExch.FieldNo(SystemCreatedAt), RetentionPolicySetup."Date Field No.", 'Date Field No. is incorrect initialized');
    end;

    [Test]
    procedure TestFinancialReportExportLogRetentionPolicyUpdated()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        FinancialReportExportLog: Record "Financial Report Export Log";
        RetenPolInstallBaseApp: Codeunit "Reten. Pol. Install - BaseApp";
    begin
        // [FEATURE] [AI test 0.4]
        Initialize();

        // [GIVEN] The allowed tables are refreshed
        RetenPolInstallBaseApp.AddAllowedTables(true);

        // [GIVEN] The retention policy setup for Financial Report Export Log is empty
        RetentionPolicySetup.SetRange("Table Id", Database::"Financial Report Export Log");
        RetentionPolicySetup.DeleteAll();

        // [WHEN] The retention policy setup for Financial Report Export Log is created
        Clear(RetentionPolicySetup);
        RetentionPolicySetup.Validate("Table Id", Database::"Financial Report Export Log");
        RetentionPolicySetup.Insert(true);

        // [THEN] The retention policy setup line for Financial Report Export Log is created with the correct date field
        LibraryAssert.AreEqual(FinancialReportExportLog.FieldNo("Start Date/Time"), RetentionPolicySetup."Date Field No.", 'Date Field No. is incorrect initialized');
    end;

    [Test]
    procedure TestEnableRetentionPolicySetupSkipsExistingSetupWithBlankRetentionPeriod()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetenPolInstallBaseApp: Codeunit "Reten. Pol. Install - BaseApp";
        TableId: Integer;
    begin
        // [SCENARIO 653144] Install/upgrade must not fail when an existing retention policy applies to all records but has no retention period
        Initialize();
        RetenPolInstallBaseApp.AddAllowedTables(true);

        foreach TableId in GetTablesEnabledOnInitialSetup() do begin
            // [GIVEN] An existing, disabled retention policy setup that applies to all records with a blank retention period
            CreateDisabledRetentionPolicySetup(TableId, true);

            // [WHEN] The install code tries to enable the retention policy
            RetenPolInstallBaseApp.EnableRetentionPolicySetup(TableId);

            // [THEN] No error is thrown and the retention policy setup is left untouched
            RetentionPolicySetup.Get(TableId);
            LibraryAssert.IsFalse(RetentionPolicySetup.Enabled, 'Retention policy setup should not be enabled');
            LibraryAssert.AreEqual('', RetentionPolicySetup."Retention Period", 'Retention period should not be changed');
        end;
    end;

    [Test]
    procedure TestEnableRetentionPolicySetupSkipsExistingSetupWithoutEnabledLines()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
        RetenPolInstallBaseApp: Codeunit "Reten. Pol. Install - BaseApp";
        TableId: Integer;
    begin
        // [SCENARIO 653144] Install/upgrade must not fail when an existing retention policy uses filters but has no enabled lines
        Initialize();
        RetenPolInstallBaseApp.AddAllowedTables(true);

        foreach TableId in GetTablesEnabledOnInitialSetup() do begin
            // [GIVEN] An existing, disabled retention policy setup that does not apply to all records and has no enabled lines
            CreateDisabledRetentionPolicySetup(TableId, false);
            RetentionPolicySetupLine.SetRange("Table ID", TableId);
            RetentionPolicySetupLine.DeleteAll();

            // [WHEN] The install code tries to enable the retention policy
            RetenPolInstallBaseApp.EnableRetentionPolicySetup(TableId);

            // [THEN] No error is thrown and the retention policy setup stays disabled
            RetentionPolicySetup.Get(TableId);
            LibraryAssert.IsFalse(RetentionPolicySetup.Enabled, 'Retention policy setup should not be enabled');
        end;
    end;

    local procedure CreateDisabledRetentionPolicySetup(TableId: Integer; ApplyToAllRecords: Boolean)
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        RetentionPolicySetup.SetRange("Table Id", TableId);
        RetentionPolicySetup.DeleteAll();

        Clear(RetentionPolicySetup);
        RetentionPolicySetup.Validate("Table Id", TableId);
        RetentionPolicySetup.Validate("Apply to all records", ApplyToAllRecords);
        RetentionPolicySetup."Retention Period" := '';
        RetentionPolicySetup.Enabled := false;
        RetentionPolicySetup.Insert(true);
    end;

    local procedure GetTablesEnabledOnInitialSetup() TableIds: List of [Integer]
    begin
        TableIds.Add(Database::"Dataverse Entity Change");
        TableIds.Add(Database::"Integration Synch. Job");
        TableIds.Add(Database::"Integration Synch. Job Errors");
    end;

    [Test]
    procedure TestPostedInvtPickPutawayRetentionPolicyProtectsBinMandatoryLocations()
    begin
        // [SCENARIO 592028] New retention policies for posted inventory picks and put-aways never delete headers at bin mandatory locations
        Initialize();

        // [GIVEN] The allowed tables are refreshed
        RefreshAllowedTables();

        // [WHEN] The retention policies for Posted Invt. Pick Header and Posted Invt. Put-away Header are created
        // [THEN] Each policy applies to a subset of records with a locked "Never Delete" line and an editable "1 Year" line
        VerifyPostedInvtRetentionPolicyDefaults(Database::"Posted Invt. Pick Header");
        VerifyPostedInvtRetentionPolicyDefaults(Database::"Posted Invt. Put-away Header");
    end;

    [Test]
    procedure TestApplyPostedInvtPickPutawayRetentionPolicyKeepsBinMandatoryLocations()
    var
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
        PostedInvtPutawayHeader: Record "Posted Invt. Put-away Header";
        BinLocationCode: Code[10];
        NoBinLocationCode: Code[10];
    begin
        // [SCENARIO 592028] Applying the retention policies on posted inventory picks and put-aways does not fail on bin mandatory locations
        Initialize();

        // [GIVEN] The allowed tables are refreshed
        RefreshAllowedTables();

        // [GIVEN] A location with "Bin Mandatory" and a location without bins
        BinLocationCode := CreateLocation(true);
        NoBinLocationCode := CreateLocation(false);

        // [GIVEN] Expired posted inventory picks and put-aways at both locations
        CreateExpiredPostedInvtPickHeader(PostedInvtPickHeader, 'PICKBIN', BinLocationCode);
        CreateExpiredPostedInvtPickHeader(PostedInvtPickHeader, 'PICKNOBIN', NoBinLocationCode);
        CreateExpiredPostedInvtPutawayHeader(PostedInvtPutawayHeader, 'PUTBIN', BinLocationCode);
        CreateExpiredPostedInvtPutawayHeader(PostedInvtPutawayHeader, 'PUTNOBIN', NoBinLocationCode);

        // [WHEN] The enabled default retention policies are applied
        ApplyDefaultRetentionPolicy(Database::"Posted Invt. Pick Header");
        ApplyDefaultRetentionPolicy(Database::"Posted Invt. Put-away Header");

        // [THEN] No error occurs, headers at the bin mandatory location are kept and the others are deleted
        LibraryAssert.IsTrue(PostedInvtPickHeader.Get('PICKBIN'), 'Posted inventory pick at a bin mandatory location must not be deleted');
        LibraryAssert.IsFalse(PostedInvtPickHeader.Get('PICKNOBIN'), 'Expired posted inventory pick must be deleted');
        LibraryAssert.IsTrue(PostedInvtPutawayHeader.Get('PUTBIN'), 'Posted inventory put-away at a bin mandatory location must not be deleted');
        LibraryAssert.IsFalse(PostedInvtPutawayHeader.Get('PUTNOBIN'), 'Expired posted inventory put-away must be deleted');
    end;

    local procedure RefreshAllowedTables()
    var
        RetenPolInstallBaseApp: Codeunit "Reten. Pol. Install - BaseApp";
    begin
        RetenPolInstallBaseApp.AddAllowedTables(true);
    end;

    local procedure CreateDefaultRetentionPolicySetup(var RetentionPolicySetup: Record "Retention Policy Setup"; TableId: Integer)
    begin
        RetentionPolicySetup.SetRange("Table Id", TableId);
        RetentionPolicySetup.DeleteAll(true);

        Clear(RetentionPolicySetup);
        RetentionPolicySetup.Validate("Table Id", TableId);
        RetentionPolicySetup.Insert(true);
        RetentionPolicySetup.Get(TableId);
    end;

    local procedure VerifyPostedInvtRetentionPolicyDefaults(TableId: Integer)
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
        RetentionPeriod: Record "Retention Period";
        LockedLineCount: Integer;
    begin
        CreateDefaultRetentionPolicySetup(RetentionPolicySetup, TableId);

        LibraryAssert.IsFalse(RetentionPolicySetup."Apply to all records", 'Retention policy must not apply to all records');
        RetentionPolicySetupLine.SetRange("Table ID", TableId);
        LibraryAssert.AreEqual(2, RetentionPolicySetupLine.Count(), 'Incorrect number of retention policy setup lines');
        RetentionPolicySetupLine.FindSet();
        repeat
            RetentionPeriod.Get(RetentionPolicySetupLine."Retention Period");
            if RetentionPolicySetupLine.IsLocked() then begin
                LockedLineCount += 1;
                LibraryAssert.AreEqual(Format(Enum::"Retention Period Enum"::"Never Delete"), Format(RetentionPeriod."Retention Period"), 'Incorrect period for locked retention policy setup line');
            end else
                LibraryAssert.AreEqual(Format(Enum::"Retention Period Enum"::"1 Year"), Format(RetentionPeriod."Retention Period"), 'Incorrect period for retention policy setup line');
        until RetentionPolicySetupLine.Next() = 0;
        LibraryAssert.AreEqual(1, LockedLineCount, 'Incorrect number of locked retention policy setup lines');
    end;

    local procedure ApplyDefaultRetentionPolicy(TableId: Integer)
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        CreateDefaultRetentionPolicySetup(RetentionPolicySetup, TableId);
        RetentionPolicySetup.Validate(Enabled, true);
        RetentionPolicySetup.Modify(true);
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);
    end;

    local procedure CreateLocation(BinMandatory: Boolean): Code[10]
    var
        Location: Record Location;
    begin
        Location.Code := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(Location.Code));
        Location."Bin Mandatory" := BinMandatory;
        Location.Insert();
        exit(Location.Code);
    end;

    local procedure CreateExpiredPostedInvtPickHeader(var PostedInvtPickHeader: Record "Posted Invt. Pick Header"; DocumentNo: Code[20]; LocationCode: Code[10])
    begin
        if PostedInvtPickHeader.Get(DocumentNo) then
            PostedInvtPickHeader.Delete();
        PostedInvtPickHeader.Init();
        PostedInvtPickHeader."No." := DocumentNo;
        PostedInvtPickHeader."Location Code" := LocationCode;
        PostedInvtPickHeader."Registering Date" := CalcDate('<-2Y>', Today());
        PostedInvtPickHeader.Insert();
    end;

    local procedure CreateExpiredPostedInvtPutawayHeader(var PostedInvtPutawayHeader: Record "Posted Invt. Put-away Header"; DocumentNo: Code[20]; LocationCode: Code[10])
    begin
        if PostedInvtPutawayHeader.Get(DocumentNo) then
            PostedInvtPutawayHeader.Delete();
        PostedInvtPutawayHeader.Init();
        PostedInvtPutawayHeader."No." := DocumentNo;
        PostedInvtPutawayHeader."Location Code" := LocationCode;
        PostedInvtPutawayHeader."Registering Date" := CalcDate('<-2Y>', Today());
        PostedInvtPutawayHeader.Insert();
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        Commit();
        IsInitialized := true;
    end;
}