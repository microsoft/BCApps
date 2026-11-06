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

    [Test]
    procedure TestMigrateAllRecordsPostedInvtPickPutawayRetentionPolicyKeepsCustomerSettings()
    var
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
        PostedInvtPutawayHeader: Record "Posted Invt. Put-away Header";
        RetentionPeriodCode: Code[20];
    begin
        // [SCENARIO 592028] Existing "Apply to all records" policies are migrated to the default subset policy and keep the customer's settings
        Initialize();
        RefreshAllowedTables();
        RetentionPeriodCode := FindOrCreateRetentionPeriod(Enum::"Retention Period Enum"::"3 Years");

        // [GIVEN] Pre-fix "Apply to all records" policies with a custom retention period and date field, one enabled and one disabled
        // [GIVEN] Each policy has a leftover line 10000 that was not in effect while the policy applied to all records
        CreatePreFixAllRecordsRetentionPolicy(Database::"Posted Invt. Pick Header", RetentionPeriodCode, PostedInvtPickHeader.FieldNo("Posting Date"), true);
        CreatePreFixAllRecordsRetentionPolicy(Database::"Posted Invt. Put-away Header", RetentionPeriodCode, PostedInvtPutawayHeader.FieldNo("Posting Date"), false);

        // [WHEN] The allowed tables are refreshed
        RefreshAllowedTables();

        // [THEN] The policies apply to a subset of records with a locked "Never Delete" line
        // [THEN] The customer's retention period and date field are carried over to the editable default line and the header enabled state is preserved
        // [THEN] The leftover lines are kept but disabled, as they were not in effect before
        VerifyMigratedAllRecordsRetentionPolicy(Database::"Posted Invt. Pick Header", RetentionPeriodCode, PostedInvtPickHeader.FieldNo("Posting Date"), PostedInvtPickHeader.FieldNo("Registering Date"), true);
        VerifyMigratedAllRecordsRetentionPolicy(Database::"Posted Invt. Put-away Header", RetentionPeriodCode, PostedInvtPutawayHeader.FieldNo("Posting Date"), PostedInvtPutawayHeader.FieldNo("Registering Date"), false);
    end;

    [Test]
    procedure TestMigrateSubsetPostedInvtPickPutawayRetentionPolicyKeepsCustomerLines()
    var
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
        PostedInvtPutawayHeader: Record "Posted Invt. Put-away Header";
        PickCustomerLinesSnapshot: Text;
        PutawayCustomerLinesSnapshot: Text;
    begin
        // [SCENARIO 592028] Existing subset policies keep the customer's lines and get the default lines without adding a new deletion rule
        Initialize();
        RefreshAllowedTables();

        // [GIVEN] Pre-fix subset policies with an enabled and a disabled customer line, one policy enabled and one disabled
        CreatePreFixSubsetRetentionPolicy(Database::"Posted Invt. Pick Header", PostedInvtPickHeader.FieldNo("Posting Date"), PostedInvtPickHeader.FieldNo("Registering Date"), true);
        CreatePreFixSubsetRetentionPolicy(Database::"Posted Invt. Put-away Header", PostedInvtPutawayHeader.FieldNo("Posting Date"), PostedInvtPutawayHeader.FieldNo("Registering Date"), false);
        PickCustomerLinesSnapshot := GetRetentionPolicySetupLineSnapshot(Database::"Posted Invt. Pick Header", 10000) + GetRetentionPolicySetupLineSnapshot(Database::"Posted Invt. Pick Header", 20000);
        PutawayCustomerLinesSnapshot := GetRetentionPolicySetupLineSnapshot(Database::"Posted Invt. Put-away Header", 10000) + GetRetentionPolicySetupLineSnapshot(Database::"Posted Invt. Put-away Header", 20000);

        // [WHEN] The allowed tables are refreshed
        RefreshAllowedTables();

        // [THEN] The customer lines are unchanged and the header enabled state is preserved
        // [THEN] A locked "Never Delete" line is added and the new editable "1 Year" line is disabled
        VerifyMigratedSubsetRetentionPolicy(Database::"Posted Invt. Pick Header", true, PickCustomerLinesSnapshot);
        VerifyMigratedSubsetRetentionPolicy(Database::"Posted Invt. Put-away Header", false, PutawayCustomerLinesSnapshot);
    end;

    [Test]
    procedure TestMigratePostedInvtPickPutawayRetentionPolicyIsIdempotent()
    var
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
        PostedInvtPutawayHeader: Record "Posted Invt. Put-away Header";
        RetentionPeriodCode: Code[20];
        PickSnapshot: Text;
        PutawaySnapshot: Text;
    begin
        // [SCENARIO 592028] Refreshing the allowed tables again does not change already migrated policies
        Initialize();
        RefreshAllowedTables();
        RetentionPeriodCode := FindOrCreateRetentionPeriod(Enum::"Retention Period Enum"::"3 Years");

        // [GIVEN] A pre-fix "Apply to all records" policy and a pre-fix subset policy that were migrated
        CreatePreFixAllRecordsRetentionPolicy(Database::"Posted Invt. Pick Header", RetentionPeriodCode, PostedInvtPickHeader.FieldNo("Posting Date"), true);
        CreatePreFixSubsetRetentionPolicy(Database::"Posted Invt. Put-away Header", PostedInvtPutawayHeader.FieldNo("Posting Date"), PostedInvtPutawayHeader.FieldNo("Registering Date"), true);
        RefreshAllowedTables();
        PickSnapshot := GetRetentionPolicySnapshot(Database::"Posted Invt. Pick Header");
        PutawaySnapshot := GetRetentionPolicySnapshot(Database::"Posted Invt. Put-away Header");

        // [WHEN] The allowed tables are refreshed a second time
        RefreshAllowedTables();

        // [THEN] The policies and their lines are unchanged
        LibraryAssert.AreEqual(PickSnapshot, GetRetentionPolicySnapshot(Database::"Posted Invt. Pick Header"), 'Posted Invt. Pick Header retention policy must not change on a second refresh');
        LibraryAssert.AreEqual(PutawaySnapshot, GetRetentionPolicySnapshot(Database::"Posted Invt. Put-away Header"), 'Posted Invt. Put-away Header retention policy must not change on a second refresh');
    end;

    [Test]
    procedure TestApplyMigratedPostedInvtPickPutawayRetentionPolicyKeepsBinMandatoryLocations()
    var
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
        PostedInvtPutawayHeader: Record "Posted Invt. Put-away Header";
        RetentionPeriodCode: Code[20];
        BinLocationCode: Code[10];
        NoBinLocationCode: Code[10];
    begin
        // [SCENARIO 592028] Applying a migrated "Apply to all records" policy uses the customer's settings and keeps headers at bin mandatory locations
        Initialize();
        RefreshAllowedTables();
        RetentionPeriodCode := FindOrCreateRetentionPeriod(Enum::"Retention Period Enum"::"6 Months");

        // [GIVEN] Enabled pre-fix "Apply to all records" policies that delete records older than 6 months based on "Posting Date"
        CreatePreFixAllRecordsRetentionPolicy(Database::"Posted Invt. Pick Header", RetentionPeriodCode, PostedInvtPickHeader.FieldNo("Posting Date"), true);
        CreatePreFixAllRecordsRetentionPolicy(Database::"Posted Invt. Put-away Header", RetentionPeriodCode, PostedInvtPutawayHeader.FieldNo("Posting Date"), true);

        // [GIVEN] A location with "Bin Mandatory" and a location without bins
        BinLocationCode := CreateLocation(true);
        NoBinLocationCode := CreateLocation(false);

        // [GIVEN] Posted inventory picks and put-aways at both locations, posted a year ago and registered today
        // [GIVEN] so that they are only expired according to the customer's retention period and date field
        CreatePostedInvtPickHeader(PostedInvtPickHeader, 'MPICKBIN', BinLocationCode, Today(), CalcDate('<-1Y>', Today()));
        CreatePostedInvtPickHeader(PostedInvtPickHeader, 'MPICKNOBIN', NoBinLocationCode, Today(), CalcDate('<-1Y>', Today()));
        CreatePostedInvtPutawayHeader(PostedInvtPutawayHeader, 'MPUTBIN', BinLocationCode, Today(), CalcDate('<-1Y>', Today()));
        CreatePostedInvtPutawayHeader(PostedInvtPutawayHeader, 'MPUTNOBIN', NoBinLocationCode, Today(), CalcDate('<-1Y>', Today()));

        // [WHEN] The allowed tables are refreshed and the migrated policies are applied
        RefreshAllowedTables();
        ApplyExistingRetentionPolicy(Database::"Posted Invt. Pick Header");
        ApplyExistingRetentionPolicy(Database::"Posted Invt. Put-away Header");

        // [THEN] Headers at the bin mandatory location are kept and the others are deleted
        LibraryAssert.IsTrue(PostedInvtPickHeader.Get('MPICKBIN'), 'Posted inventory pick at a bin mandatory location must not be deleted');
        LibraryAssert.IsFalse(PostedInvtPickHeader.Get('MPICKNOBIN'), 'Expired posted inventory pick must be deleted');
        LibraryAssert.IsTrue(PostedInvtPutawayHeader.Get('MPUTBIN'), 'Posted inventory put-away at a bin mandatory location must not be deleted');
        LibraryAssert.IsFalse(PostedInvtPutawayHeader.Get('MPUTNOBIN'), 'Expired posted inventory put-away must be deleted');
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
        CreatePostedInvtPickHeader(PostedInvtPickHeader, DocumentNo, LocationCode, CalcDate('<-2Y>', Today()), 0D);
    end;

    local procedure CreateExpiredPostedInvtPutawayHeader(var PostedInvtPutawayHeader: Record "Posted Invt. Put-away Header"; DocumentNo: Code[20]; LocationCode: Code[10])
    begin
        CreatePostedInvtPutawayHeader(PostedInvtPutawayHeader, DocumentNo, LocationCode, CalcDate('<-2Y>', Today()), 0D);
    end;

    local procedure CreatePostedInvtPickHeader(var PostedInvtPickHeader: Record "Posted Invt. Pick Header"; DocumentNo: Code[20]; LocationCode: Code[10]; RegisteringDate: Date; PostingDate: Date)
    begin
        if PostedInvtPickHeader.Get(DocumentNo) then
            PostedInvtPickHeader.Delete();
        PostedInvtPickHeader.Init();
        PostedInvtPickHeader."No." := DocumentNo;
        PostedInvtPickHeader."Location Code" := LocationCode;
        PostedInvtPickHeader."Registering Date" := RegisteringDate;
        PostedInvtPickHeader."Posting Date" := PostingDate;
        PostedInvtPickHeader.Insert();
    end;

    local procedure CreatePostedInvtPutawayHeader(var PostedInvtPutawayHeader: Record "Posted Invt. Put-away Header"; DocumentNo: Code[20]; LocationCode: Code[10]; RegisteringDate: Date; PostingDate: Date)
    begin
        if PostedInvtPutawayHeader.Get(DocumentNo) then
            PostedInvtPutawayHeader.Delete();
        PostedInvtPutawayHeader.Init();
        PostedInvtPutawayHeader."No." := DocumentNo;
        PostedInvtPutawayHeader."Location Code" := LocationCode;
        PostedInvtPutawayHeader."Registering Date" := RegisteringDate;
        PostedInvtPutawayHeader."Posting Date" := PostingDate;
        PostedInvtPutawayHeader.Insert();
    end;

    local procedure ApplyExistingRetentionPolicy(TableId: Integer)
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        RetentionPolicySetup.Get(TableId);
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);
    end;

    local procedure CreatePreFixRetentionPolicySetup(var RetentionPolicySetup: Record "Retention Policy Setup"; TableId: Integer)
    var
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
        RetentionPolicySetupLineRecRef: RecordRef;
    begin
        // Before the fix the table was allowed without default table filters, so existing policies have no system-defined (locked) lines.
        CreateDefaultRetentionPolicySetup(RetentionPolicySetup, TableId);
        RetentionPolicySetupLine.SetRange("Table ID", TableId);
        while RetentionPolicySetupLine.FindFirst() do begin
            // The Locked field is internal to the Retention Policy module, so clear it through a RecordRef to allow the delete.
            RetentionPolicySetupLineRecRef.GetTable(RetentionPolicySetupLine);
            RetentionPolicySetupLineRecRef.Field(LockedFieldNo()).Value := false;
            RetentionPolicySetupLineRecRef.Delete(true);
            RetentionPolicySetupLineRecRef.Close();
        end;
        RetentionPolicySetup.Get(TableId);
    end;

    local procedure LockedFieldNo(): Integer
    begin
        // Field 12 "Locked" in table 3902 "Retention Policy Setup Line"
        exit(12);
    end;

    local procedure CreatePreFixAllRecordsRetentionPolicy(TableId: Integer; RetentionPeriodCode: Code[20]; DateFieldNo: Integer; Enabled: Boolean)
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        CreatePreFixRetentionPolicySetup(RetentionPolicySetup, TableId);

        // a line that is ignored while the policy applies to all records
        CreateRetentionPolicySetupLine(TableId, 10000, FindOrCreateRetentionPeriod(Enum::"Retention Period Enum"::"1 Month"), RetentionPolicySetup."Date Field No.", true);

        RetentionPolicySetup.Validate("Apply to all records", true);
        RetentionPolicySetup.Validate("Retention Period", RetentionPeriodCode);
        RetentionPolicySetup.Validate("Date Field No.", DateFieldNo);
        RetentionPolicySetup.Validate(Enabled, Enabled);
        RetentionPolicySetup.Modify(true);
    end;

    local procedure CreatePreFixSubsetRetentionPolicy(TableId: Integer; EnabledLineDateFieldNo: Integer; DisabledLineDateFieldNo: Integer; Enabled: Boolean)
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        CreatePreFixRetentionPolicySetup(RetentionPolicySetup, TableId);

        CreateRetentionPolicySetupLine(TableId, 10000, FindOrCreateRetentionPeriod(Enum::"Retention Period Enum"::"5 Years"), EnabledLineDateFieldNo, true);
        CreateRetentionPolicySetupLine(TableId, 20000, FindOrCreateRetentionPeriod(Enum::"Retention Period Enum"::"1 Month"), DisabledLineDateFieldNo, false);

        RetentionPolicySetup.Validate("Apply to all records", false);
        RetentionPolicySetup.Validate(Enabled, Enabled);
        RetentionPolicySetup.Modify(true);
    end;

    local procedure CreateRetentionPolicySetupLine(TableId: Integer; LineNo: Integer; RetentionPeriodCode: Code[20]; DateFieldNo: Integer; Enabled: Boolean)
    var
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
    begin
        RetentionPolicySetupLine."Table ID" := TableId;
        RetentionPolicySetupLine."Line No." := LineNo;
        RetentionPolicySetupLine.Validate("Retention Period", RetentionPeriodCode);
        RetentionPolicySetupLine.Validate("Date Field No.", DateFieldNo);
        RetentionPolicySetupLine.Validate(Enabled, Enabled);
        RetentionPolicySetupLine.Insert(true);
    end;

    local procedure FindOrCreateRetentionPeriod(RetentionPeriodEnum: Enum "Retention Period Enum"): Code[20]
    var
        RetentionPeriod: Record "Retention Period";
    begin
        RetentionPeriod.SetRange("Retention Period", RetentionPeriodEnum);
        if RetentionPeriod.FindFirst() then
            exit(RetentionPeriod.Code);

        RetentionPeriod.Code := CopyStr(UpperCase(Format(RetentionPeriodEnum)), 1, MaxStrLen(RetentionPeriod.Code));
        RetentionPeriod.Validate("Retention Period", RetentionPeriodEnum);
        RetentionPeriod.Insert(true);
        exit(RetentionPeriod.Code);
    end;

    local procedure VerifyMigratedAllRecordsRetentionPolicy(TableId: Integer; RetentionPeriodCode: Code[20]; DateFieldNo: Integer; LeftoverLineDateFieldNo: Integer; ExpectedEnabled: Boolean)
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
        LockedLineCount: Integer;
    begin
        RetentionPolicySetup.Get(TableId);
        LibraryAssert.IsFalse(RetentionPolicySetup."Apply to all records", 'Migrated retention policy must not apply to all records');
        LibraryAssert.AreEqual(ExpectedEnabled, RetentionPolicySetup.Enabled, 'Migrated retention policy must keep its enabled state');

        RetentionPolicySetupLine.Get(TableId, 10000);
        LibraryAssert.IsFalse(RetentionPolicySetupLine.IsLocked(), 'Leftover retention policy setup line must not be locked');
        LibraryAssert.IsFalse(RetentionPolicySetupLine.Enabled, 'Leftover retention policy setup line must stay inactive');
        LibraryAssert.AreEqual(FindOrCreateRetentionPeriod(Enum::"Retention Period Enum"::"1 Month"), RetentionPolicySetupLine."Retention Period", 'Leftover retention policy setup line must keep its retention period');
        LibraryAssert.AreEqual(LeftoverLineDateFieldNo, RetentionPolicySetupLine."Date Field No.", 'Leftover retention policy setup line must keep its date field');

        RetentionPolicySetupLine.SetRange("Table ID", TableId);
        RetentionPolicySetupLine.SetFilter("Line No.", '>%1', 10000);
        LibraryAssert.AreEqual(2, RetentionPolicySetupLine.Count(), 'Incorrect number of default retention policy setup lines');
        RetentionPolicySetupLine.FindSet();
        repeat
            if RetentionPolicySetupLine.IsLocked() then begin
                LockedLineCount += 1;
                VerifyNeverDeleteLockedLine(RetentionPolicySetupLine);
            end else begin
                LibraryAssert.AreEqual(RetentionPeriodCode, RetentionPolicySetupLine."Retention Period", 'Customer retention period must be carried over');
                LibraryAssert.AreEqual(DateFieldNo, RetentionPolicySetupLine."Date Field No.", 'Customer date field must be carried over');
                LibraryAssert.IsTrue(RetentionPolicySetupLine.Enabled, 'Line replacing "Apply to all records" must be enabled');
            end;
        until RetentionPolicySetupLine.Next() = 0;
        LibraryAssert.AreEqual(1, LockedLineCount, 'Incorrect number of locked retention policy setup lines');
    end;

    local procedure VerifyMigratedSubsetRetentionPolicy(TableId: Integer; ExpectedEnabled: Boolean; CustomerLinesSnapshot: Text)
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
        RetentionPeriod: Record "Retention Period";
        LockedLineCount: Integer;
    begin
        RetentionPolicySetup.Get(TableId);
        LibraryAssert.IsFalse(RetentionPolicySetup."Apply to all records", 'Migrated retention policy must not apply to all records');
        LibraryAssert.AreEqual(ExpectedEnabled, RetentionPolicySetup.Enabled, 'Migrated retention policy must keep its enabled state');

        LibraryAssert.AreEqual(
            CustomerLinesSnapshot,
            GetRetentionPolicySetupLineSnapshot(TableId, 10000) + GetRetentionPolicySetupLineSnapshot(TableId, 20000),
            'Customer retention policy setup lines must not change');

        RetentionPolicySetupLine.SetRange("Table ID", TableId);
        RetentionPolicySetupLine.SetFilter("Line No.", '>%1', 20000);
        LibraryAssert.AreEqual(2, RetentionPolicySetupLine.Count(), 'Incorrect number of default retention policy setup lines');
        RetentionPolicySetupLine.FindSet();
        repeat
            if RetentionPolicySetupLine.IsLocked() then begin
                LockedLineCount += 1;
                VerifyNeverDeleteLockedLine(RetentionPolicySetupLine);
            end else begin
                RetentionPeriod.Get(RetentionPolicySetupLine."Retention Period");
                LibraryAssert.AreEqual(Format(Enum::"Retention Period Enum"::"1 Year"), Format(RetentionPeriod."Retention Period"), 'Incorrect period for default retention policy setup line');
                LibraryAssert.IsFalse(RetentionPolicySetupLine.Enabled, 'Default deletion line must not be enabled for an existing subset policy');
            end;
        until RetentionPolicySetupLine.Next() = 0;
        LibraryAssert.AreEqual(1, LockedLineCount, 'Incorrect number of locked retention policy setup lines');
    end;

    local procedure VerifyNeverDeleteLockedLine(RetentionPolicySetupLine: Record "Retention Policy Setup Line")
    var
        RetentionPeriod: Record "Retention Period";
    begin
        RetentionPeriod.Get(RetentionPolicySetupLine."Retention Period");
        LibraryAssert.AreEqual(Format(Enum::"Retention Period Enum"::"Never Delete"), Format(RetentionPeriod."Retention Period"), 'Incorrect period for locked retention policy setup line');
        LibraryAssert.IsTrue(RetentionPolicySetupLine.Enabled, 'Locked retention policy setup line must be enabled');
        LibraryAssert.AreNotEqual('', RetentionPolicySetupLine.GetTableFilterText(), 'Locked retention policy setup line must filter on bin mandatory locations');
    end;

    local procedure GetRetentionPolicySnapshot(TableId: Integer) Snapshot: Text
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
    begin
        RetentionPolicySetup.Get(TableId);
        Snapshot := StrSubstNo('%1|%2|%3|%4;', RetentionPolicySetup.Enabled, RetentionPolicySetup."Apply to all records", RetentionPolicySetup."Retention Period", RetentionPolicySetup."Date Field No.");
        RetentionPolicySetupLine.SetRange("Table ID", TableId);
        if RetentionPolicySetupLine.FindSet() then
            repeat
                Snapshot += GetRetentionPolicySetupLineSnapshot(TableId, RetentionPolicySetupLine."Line No.");
            until RetentionPolicySetupLine.Next() = 0;
    end;

    local procedure GetRetentionPolicySetupLineSnapshot(TableId: Integer; LineNo: Integer): Text
    var
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
    begin
        RetentionPolicySetupLine.Get(TableId, LineNo);
        exit(StrSubstNo('%1|%2|%3|%4|%5|%6;', RetentionPolicySetupLine."Line No.", RetentionPolicySetupLine."Retention Period", RetentionPolicySetupLine."Date Field No.", RetentionPolicySetupLine.Enabled, RetentionPolicySetupLine.IsLocked(), RetentionPolicySetupLine.GetTableFilterText()));
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        Commit();
        IsInitialized := true;
    end;
}