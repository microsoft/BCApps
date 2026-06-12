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

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        Commit();
        IsInitialized := true;
    end;
}