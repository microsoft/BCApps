codeunit 147558 "SII Recreate Entries Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SII]
    end;

    var
        LibrarySII: Codeunit "Library - SII";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryJobQueue: Codeunit "Library - Job Queue";
        IsInitialized: Boolean;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure JobQueueEntryCreatesWhenAutomaticCheckIsDaily()
    var
        SIISetup: Record "SII Setup";
    begin
        // [FEATURE] [Job Queue]
        // [SCENARIO 263060] Job Queue Entry creates when "Automatic Entries Check" is switched to "Daily"

        Initialize();
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] SII Setup with "Automatic Entries Check" = "Never"
        SIISetup.Get();
        SIISetup.Validate("Auto Missing Entries Check", SIISetup."Auto Missing Entries Check"::Never);

        // [WHEN] Set "Automatic Entries Check" = Daily in SII Setup
        SIISetup.Validate("Auto Missing Entries Check", SIISetup."Auto Missing Entries Check"::Daily);

        // [THEN] Job Queue Entry is created
        VerifySIIJobQueueEntryCreatedAndStarted();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure JobQueueEntryCreatesWhenAutomaticCheckIsWeekly()
    var
        SIISetup: Record "SII Setup";
    begin
        // [FEATURE] [Job Queue]
        // [SCENARIO 263060] Job Queue Entry creates when "Automatic Entries Check" is switched to "Weekly"

        Initialize();
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] SII Setup with "Automatic Entries Check" = "Never"
        SIISetup.Get();
        SIISetup.Validate("Auto Missing Entries Check", SIISetup."Auto Missing Entries Check"::Never);

        // [WHEN] Set "Automatic Entries Check" = Daily in SII Setup
        SIISetup.Validate("Auto Missing Entries Check", SIISetup."Auto Missing Entries Check"::Weekly);

        // [THEN] Job Queue Entry is created
        VerifySIIJobQueueEntryCreatedAndStarted();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure JobQueueEntryRemovesWhenAutomaticCheckIsNever()
    var
        SIISetup: Record "SII Setup";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [Job Queue]
        // [SCENARIO 263060] Job Queue Entry removes when "Automatic Entries Check" is switched to "Never"

        Initialize();
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] Job Queue Entry created when "Automatic List Entries Check" switched from "Never" to "Daily"
        SIISetup.Get();
        SIISetup.Validate("Auto Missing Entries Check", SIISetup."Auto Missing Entries Check"::Never);
        SIISetup.Validate("Auto Missing Entries Check", SIISetup."Auto Missing Entries Check"::Daily);

        // [WHEN] Set "Automatic Entries Check" = Never in SII Setup
        SIISetup.Validate("Auto Missing Entries Check", SIISetup."Auto Missing Entries Check"::Never);

        // [THEN] Job Queue Entry is removed
        FilterSIIJobQueueEntry(JobQueueEntry);
        Assert.RecordIsEmpty(JobQueueEntry);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure JobQueueEntryCreatesWhenSIIHistoryPageOpens()
    var
        SIISetup: Record "SII Setup";
        SIIHistory: TestPage "SII History";
    begin
        // [FEATURE] [Job Queue] [UI]
        // [SCENARIO 263060] Job Queue Entry creates when Stan opens "SII History" page

        Initialize();
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        // [GIVEN] SII Setup with "Automatic Entries Check" = "Never"
        SIISetup.Get();
        SIISetup.Validate("Auto Missing Entries Check", SIISetup."Auto Missing Entries Check"::Never);
        SIISetup.Validate("Auto Missing Entries Check", SIISetup."Auto Missing Entries Check"::Daily);
        SIISetup.Modify(true);

        // [WHEN] Open "SII History" page
        SIIHistory.OpenView();

        // [THEN] Job Queue Entry is created
        VerifySIIJobQueueEntryCreatedAndStarted();

        SIIHistory.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OpenRecreateMissingEntriesPageFromSIIHistoryPage()
    var
        SIIHistory: TestPage "SII History";
        RecreateMissingSIIEntries: TestPage "Recreate Missing SII Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 263060] Stan can open "Recreate Missing Entries" page from "SII History" page

        Initialize();

        // [GIVEN] Opened "SII History" page
        SIIHistory.OpenView();

        RecreateMissingSIIEntries.Trap();

        // [WHEN] Stan press action "Recreate Missing Entries" on "SII History" page
        SIIHistory."Recreate Missing SII Entries".Invoke();

        // [THEN] "Recreate Missing Entries" page is shown
        Assert.IsTrue(RecreateMissingSIIEntries.FromDate.Enabled(), '');

        RecreateMissingSIIEntries.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnlyEntriesPostedFromSIISetupCreationDateConsideres()
    var
        SIISetup: Record "SII Setup";
        SIIMissingEntriesState: Record "SII Missing Entries State";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        CustLedgEntryNo: Integer;
        VendLedgEntryNo: Integer;
        DtldCustLedgEntryNo: Integer;
        DtldVendLedgEntryNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 263060] Only entries with "Posting Date" from "Starting Date" of SII Setup considers for missing entries detection when running codeunit "SII Recreate Missing Entries"

        Initialize();

        // [GIVEN] "Starting Date" is 15.01.2017 in disabled SII Setup
        EnableSIISetup(SIISetup, false);

        // [GIVEN] Sales Payment with "Posting Date" = 14.01.2017
        MockDtldCustLedgEntry(DetailedCustLedgEntry."Document Type"::Payment, SIISetup."Starting Date" - 1);

        // [GIVEN] Sales Payment with "Posting Date" = 15.01.2017
        DtldCustLedgEntryNo := MockDtldCustLedgEntry(DetailedCustLedgEntry."Document Type"::Payment, SIISetup."Starting Date");

        // [GIVEN] Sales Refund with "Posting Date" = 14.01.2017
        MockDtldCustLedgEntry(DetailedCustLedgEntry."Document Type"::Refund, SIISetup."Starting Date" - 1);

        // [GIVEN] Sales Refund with "Posting Date" = 15.01.2017
        DtldCustLedgEntryNo := MockDtldCustLedgEntry(DetailedCustLedgEntry."Document Type"::Refund, SIISetup."Starting Date");

        // [GIVEN] Purchase Payment with "Posting Date" = 14.01.2017
        MockDtldVendLedgEntry(DetailedVendorLedgEntry."Document Type"::Payment, SIISetup."Starting Date" - 1);

        // [GIVEN] Purchase Payment with "Posting Date" = 15.01.2017
        DtldVendLedgEntryNo := MockDtldVendLedgEntry(DetailedVendorLedgEntry."Document Type"::Payment, SIISetup."Starting Date");

        // [GIVEN] Purchase Refund with "Posting Date" = 14.01.2017
        MockDtldVendLedgEntry(DetailedVendorLedgEntry."Document Type"::Refund, SIISetup."Starting Date" - 1);

        // [GIVEN] Purchase Refund with "Posting Date" = 15.01.2017
        DtldVendLedgEntryNo := MockDtldVendLedgEntry(DetailedVendorLedgEntry."Document Type"::Refund, SIISetup."Starting Date");

        // [GIVEN] Sales Invoice with "Posting Date" = 14.01.2017
        MockCustLedgEntry(SIISetup."Starting Date" - 1);

        // [GIVEN] Sales Invoice with "Posting Date" = 15.01.2017
        CustLedgEntryNo := MockCustLedgEntry(SIISetup."Starting Date");

        // [GIVEN] Purchase Invoice with "Posting Date" = 14.01.2017
        MockVendLedgEntry(SIISetup."Starting Date" - 1);

        // [GIVEN] Purchase Invoice with "Posting Date" = 15.01.2017
        VendLedgEntryNo := MockVendLedgEntry(SIISetup."Starting Date");

        // [GIVEN] Enable SII Setup back
        EnableSIISetup(SIISetup, true);

        // [WHEN] Run "SII Recreate Missing Entries" codeunit
        CODEUNIT.Run(CODEUNIT::"SII Recreate Missing Entries");

        // [THEN] "Entries Missing" is 6, "Last Ledger Entry No." is equal to entries posted on 15.01 , "Last Missing Entries Check" is TODAY
        // TFS ID 398897: VAT cash refunds
        SIIMissingEntriesState.Get();
        SIIMissingEntriesState.TestField("Entries Missing", 6);
        SIIMissingEntriesState.TestField("Last CLE No.", CustLedgEntryNo);
        SIIMissingEntriesState.TestField("Last VLE No.", VendLedgEntryNo);
        SIIMissingEntriesState.TestField("Last DCLE No.", DtldCustLedgEntryNo);
        SIIMissingEntriesState.TestField("Last DVLE No.", DtldVendLedgEntryNo);
        SIIMissingEntriesState.TestField("Last Missing Entries Check", Today);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoMissingEntriesIfPostDocumentWithSIISetupEnabled()
    var
        SIISetup: Record "SII Setup";
        SIIMissingEntriesState: Record "SII Missing Entries State";
        LedgEntryNo: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 263060] No missing entries detects from documents posted during enabled SII Setup

        Initialize();

        // [GIVEN] "Starting Date" is 15.01.2017 in enabled SII Setup
        SIISetup.Get();

        // [GIVEN] Sales Invoice with "Posting Date" = 15.01.2017 and "Entry No." = "A"
        LedgEntryNo := MockCustLedgEntry(SIISetup."Starting Date");

        // [WHEN]
        CODEUNIT.Run(CODEUNIT::"SII Recreate Missing Entries");

        // [THEN] "Entries Missing" is 0, "Last Ledger Entry No." is "A", "Last Missing Entries Check" is TODAY
        SIIMissingEntriesState.Get();
        SIIMissingEntriesState.TestField("Entries Missing", 0);
        SIIMissingEntriesState.TestField("Last CLE No.", LedgEntryNo);
        SIIMissingEntriesState.TestField("Last Missing Entries Check", Today);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnlyEntriesAfterLastTrackedConsiders()
    var
        SIISetup: Record "SII Setup";
        SIIMissingEntriesState: Record "SII Missing Entries State";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        RecreateMissingSIIEntries: TestPage "Recreate Missing SII Entries";
        CustLedgEntryNo: Integer;
        VendLedgEntryNo: Integer;
        DtldCustLedgEntryNo: Integer;
        DtldVendLedgEntryNo: Integer;
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 263060] Only entries with "Entry No." after "Last Ledger Entry No." from "SII Missing Entries Tracking" table considers for missing entries detections

        Initialize();

        // [GIVEN] "Starting Date" is 15.01.2017 in disabled SII Setup
        EnableSIISetup(SIISetup, false);

        // [GIVEN] Sales Payment with "Posting Date" = 15.01.2017  and "Entry No." = "C"
        DtldCustLedgEntryNo := MockDtldCustLedgEntry(DetailedCustLedgEntry."Document Type"::Payment, SIISetup."Starting Date");

        // [GIVEN] Sales Refund with "Posting Date" = 15.01.2017  and "Entry No." = "C"
        // TFS ID 398897: VAT cash refunds
        DtldCustLedgEntryNo := MockDtldCustLedgEntry(DetailedCustLedgEntry."Document Type"::Refund, SIISetup."Starting Date");

        // [GIVEN] Purchase Payment with "Posting Date" = 15.01.2017  and "Entry No." = "D"
        DtldVendLedgEntryNo := MockDtldVendLedgEntry(DetailedVendorLedgEntry."Document Type"::Payment, SIISetup."Starting Date");

        // [GIVEN] Purchase Refund with "Posting Date" = 15.01.2017  and "Entry No." = "D"
        DtldVendLedgEntryNo := MockDtldVendLedgEntry(DetailedVendorLedgEntry."Document Type"::Refund, SIISetup."Starting Date");

        // [GIVEN] Sales Invoice with "Posting Date" = 15.01.2017 and "Entry No." = "A"
        CustLedgEntryNo := MockCustLedgEntry(SIISetup."Starting Date");

        // [GIVEN] Purchase Invoice with "Posting Date" = 15.01.2017  and "Entry No." = "B"
        VendLedgEntryNo := MockVendLedgEntry(SIISetup."Starting Date");

        // [GIVEN] SII Missing Entries Tracking with "Last Ledger Entry No." = "A","B","C","D" for different type of entries
        UpdateMissingEntriesTracking(CustLedgEntryNo, VendLedgEntryNo, DtldCustLedgEntryNo, DtldVendLedgEntryNo);

        // [GIVEN] Enable SII Setup back
        EnableSIISetup(SIISetup, true);

        RecreateMissingSIIEntries.Trap();

        // [WHEN] Stan open page "Recreate Missing SII Entries"
        PAGE.Run(PAGE::"Recreate Missing SII Entries");

        // [THEN] "Entries Missing" is 0
        SIIMissingEntriesState.Get();
        SIIMissingEntriesState.TestField("Entries Missing", 0);

        RecreateMissingSIIEntries.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AllEntriesConsidersIfUserSelectScanAll()
    var
        SIISetup: Record "SII Setup";
        SIIMissingEntriesState: Record "SII Missing Entries State";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        RecreateMissingSIIEntries: TestPage "Recreate Missing SII Entries";
        CustLedgEntryNo: Integer;
        VendLedgEntryNo: Integer;
        DtldCustLedgEntryNo: Integer;
        DtldVendLedgEntryNo: Integer;
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 263060] Stan can consider all entries for missing entry detection if he select "Scan All" option on "Recreate Missing SII Entries Page"

        Initialize();

        // [GIVEN] "Starting Date" is 15.01.2017 in disabled SII Setup
        EnableSIISetup(SIISetup, false);

        // [GIVEN] Sales Invoice with "Posting Date" = 15.01.2017 and "Entry No." = "A"
        CustLedgEntryNo := MockCustLedgEntry(SIISetup."Starting Date");

        // [GIVEN] Purchase Invoice with "Posting Date" = 15.01.2017  and "Entry No." = "B"
        VendLedgEntryNo := MockVendLedgEntry(SIISetup."Starting Date");

        // [GIVEN] Sales Payment with "Posting Date" = 15.01.2017  and "Entry No." = "C"
        DtldCustLedgEntryNo := MockDtldCustLedgEntry(DetailedCustLedgEntry."Document Type"::Payment, SIISetup."Starting Date");

        // [GIVEN] Sales Refund with "Posting Date" = 15.01.2017  and "Entry No." = "C"
        DtldCustLedgEntryNo := MockDtldCustLedgEntry(DetailedCustLedgEntry."Document Type"::Refund, SIISetup."Starting Date");

        // [GIVEN] Purchase Payment with "Posting Date" = 15.01.2017  and "Entry No." = "D"
        DtldVendLedgEntryNo := MockDtldVendLedgEntry(DetailedVendorLedgEntry."Document Type"::Payment, SIISetup."Starting Date");

        // [GIVEN] Purchase Refund with "Posting Date" = 15.01.2017  and "Entry No." = "D"
        DtldVendLedgEntryNo := MockDtldVendLedgEntry(DetailedVendorLedgEntry."Document Type"::Refund, SIISetup."Starting Date");

        // [GIVEN] SII Missing Entries Tracking with "Last Ledger Entry No." = "A","B","C","D" for different type of entries
        UpdateMissingEntriesTracking(CustLedgEntryNo, VendLedgEntryNo, DtldCustLedgEntryNo, DtldVendLedgEntryNo);

        // [GIVEN] Enable SII Setup back
        EnableSIISetup(SIISetup, true);

        // [WHEN] Stan open page "Recreate Missing SII Entries" and select "Scan All Entries"
        RecreateMissingSIIEntries.OpenEdit();
        RecreateMissingSIIEntries.ScanAllEntries.DrillDown();

        // [THEN] "Entries Missing" is 6
        // TFS ID 398897: VAT cash refunds
        SIIMissingEntriesState.Get();
        SIIMissingEntriesState.TestField("Entries Missing", 6);

        RecreateMissingSIIEntries.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NoMissingEntriesIfDocsMarkedToNotSendToSII()
    var
        SIISetup: Record "SII Setup";
        SIIMissingEntriesState: Record "SII Missing Entries State";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 433352] No missing entries detects from documents posted during enabled SII Setup

        Initialize();

        // [GIVEN] "Starting Date" is 15.01.2017 in disabled SII Setup
        EnableSIISetup(SIISetup, false);

        // [GIVEN] Sales Invoice with "Posting Date" = 15.01.2017 and "Do Not Send To SII" option enabled
        CustLedgerEntry.Get(MockCustLedgEntry(SIISetup."Starting Date"));
        CustLedgerEntry."Do Not Send To SII" := true;
        CustLedgerEntry.Modify();

        // [GIVEN] Purchase Invoice with "Posting Date" = 15.01.2017 and "Do Not Send To SII" option enabled
        VendorLedgerEntry.Get(MockVendLedgEntry(SIISetup."Starting Date"));
        VendorLedgerEntry."Do Not Send To SII" := true;
        VendorLedgerEntry.Modify();

        EnableSIISetup(SIISetup, true);

        // [WHEN] Run "SII Recreate Missing Entries" codeunit
        CODEUNIT.Run(CODEUNIT::"SII Recreate Missing Entries");

        // [THEN] "Entries Missing" is 0
        SIIMissingEntriesState.Get();
        SIIMissingEntriesState.TestField("Entries Missing", 0);
    end;

    local procedure Initialize()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        LibrarySII.InitSetup(true, false);
        UpdateSIISetupToRecreateMissingEntries();
        FilterSIIJobQueueEntry(JobQueueEntry);
        JobQueueEntry.DeleteAll(true);
        if IsInitialized then
            exit;

        BindSubscription(LibraryJobQueue);
        IsInitialized := true;
    end;

    local procedure UpdateSIISetupToRecreateMissingEntries()
    var
        SIISetup: Record "SII Setup";
        GLRegister: Record "G/L Register";
        LogInManagement: Codeunit LogInManagement;
    begin
        SIISetup.Get();
        SIISetup.Validate("Show Advanced Actions", true);
        GLRegister.SetCurrentKey("Posting Date");
        GLRegister.FindLast();
        SIISetup.Validate("Starting Date", LogInManagement.GetDefaultWorkDate() + 1);
        SIISetup.Modify(true);
    end;

    local procedure MockCustLedgEntry(PostingDate: Date): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Posting Date" := PostingDate;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry.Insert();
        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure MockVendLedgEntry(PostingDate: Date): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Posting Date" := PostingDate;
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry.Insert();
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure MockDtldCustLedgEntry(DocType: Enum "Gen. Journal Document Type"; PostingDate: Date): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Posting Date" := PostingDate;
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::Application;
        DetailedCustLedgEntry."Document Type" := DocType;
        DetailedCustLedgEntry."Document No." := LibraryUtility.GenerateGUID();
        DetailedCustLedgEntry."Transaction No." := LibraryRandom.RandInt(100);
        DetailedCustLedgEntry."Initial Document Type" := DetailedCustLedgEntry."Initial Document Type"::Invoice;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := MockCustLedgEntry(PostingDate);
        DetailedCustLedgEntry.Insert();
        MockVATEntry(
          DetailedCustLedgEntry."Posting Date", DetailedCustLedgEntry."Document No.", DetailedCustLedgEntry."Transaction No.");
        exit(DetailedCustLedgEntry."Entry No.");
    end;

    local procedure MockDtldVendLedgEntry(DocType: Enum "Gen. Journal Document Type"; PostingDate: Date): Integer
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry."Posting Date" := PostingDate;
        DetailedVendorLedgEntry."Entry Type" := DetailedVendorLedgEntry."Entry Type"::Application;
        DetailedVendorLedgEntry."Document Type" := DocType;
        DetailedVendorLedgEntry."Document No." := LibraryUtility.GenerateGUID();
        DetailedVendorLedgEntry."Transaction No." := LibraryRandom.RandInt(100);
        DetailedVendorLedgEntry."Initial Document Type" := DetailedVendorLedgEntry."Initial Document Type"::Invoice;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := MockVendLedgEntry(PostingDate);
        DetailedVendorLedgEntry.Insert();
        MockVATEntry(
          DetailedVendorLedgEntry."Posting Date", DetailedVendorLedgEntry."Document No.", DetailedVendorLedgEntry."Transaction No.");
        exit(DetailedVendorLedgEntry."Entry No.");
    end;

    local procedure MockVATEntry(PostingDate: Date; DocNo: Code[20]; TransactionNo: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry."Posting Date" := PostingDate;
        VATEntry."VAT Reporting Date" := PostingDate;
        VATEntry."Document No." := DocNo;
        VATEntry."Transaction No." := TransactionNo;
        VATEntry."Unrealized Base" := LibraryRandom.RandDec(100, 2);
        VATEntry.Insert();
    end;

    local procedure UpdateMissingEntriesTracking(CustLedgEntryNo: Integer; VendLedgEntryNo: Integer; DtldCustLedgEntryNo: Integer; DtldVendLedgEntryNo: Integer)
    var
        SIIMissingEntriesState: Record "SII Missing Entries State";
    begin
        SIIMissingEntriesState.Initialize();
        SIIMissingEntriesState.Validate("Last CLE No.", CustLedgEntryNo);
        SIIMissingEntriesState.Validate("Last VLE No.", VendLedgEntryNo);
        SIIMissingEntriesState.Validate("Last DCLE No.", DtldCustLedgEntryNo);
        SIIMissingEntriesState.Validate("Last DVLE No.", DtldVendLedgEntryNo);
        SIIMissingEntriesState.Modify(true);
    end;

    local procedure EnableSIISetup(var SIISetup: Record "SII Setup"; NewEnabled: Boolean)
    begin
        SIISetup.Get();
        SIISetup.Enabled := NewEnabled;
        SIISetup.Modify(true);
    end;

    local procedure FilterSIIJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"SII Recreate Missing Entries");
    end;

    local procedure VerifySIIJobQueueEntryCreatedAndStarted()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        FilterSIIJobQueueEntry(JobQueueEntry);
        JobQueueEntry.FindFirst();
        JobQueueEntry.TestField("System Task ID");
    end;
}

