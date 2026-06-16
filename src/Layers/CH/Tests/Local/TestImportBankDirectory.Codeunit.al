codeunit 144016 "Test Import Bank Directory"
{
    // // [FEATURE] [Import Bank Directory]
    // Bank clearing numbers are used to identify each banking agency with a unique number. This information is a base requirement for electronic payment.
    // You can import the bank clearing number file, and customer and vendor bank information has clearing has clearing number information.
    // When you import the bank clearing number file, the data is imported to the bank clearing number table, and existing data is overwritten.
    // After importing the data, when you create bank information for a new customer, you can enter the clearing number in the customer bank card.
    // All relevant data is retrieved from the clearing number table to populate the form with information such as the bank name and address.
    // There is a table relation between the Bank Branch No. field and the clearing number table ("Bank Directory").

    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        FileManagement: Codeunit "File Management";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        FileNameForHandler: Text;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectory()
    var
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
        NumberOfImportedRows: Integer;
        UpdateClearingNumbers: Boolean;
    begin
        // Setup
        Initialize();

        UpdateClearingNumbers := false;
        LibraryVariableStorage.Enqueue(UpdateClearingNumbers);

        CreateBankDirectoryImportFile();
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // Exercise
        REPORT.Run(REPORT::"Import Bank Directory", true, false);

        NumberOfImportedRows := 12;

        // Verify
        VerifyImportedRecords(NumberOfImportedRows);

        VerifyBankDirectoryRecords();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportBankDirectoryCancelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CancelImportBankDirectory()
    var
        BankDirectory: Record "Bank Directory";
        BankDirectoryPage: TestPage "Bank Directory";
    begin
        // Setup
        Initialize();

        // Exercise
        BankDirectoryPage.OpenView();
        BankDirectoryPage."Import Bank Directory".Invoke();
        BankDirectoryPage.Close();

        // Verify
        Assert.AreEqual(0, BankDirectory.Count,
          'No bank directory entries should have been created when cancelling.');
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryUpdatingCustomerBankAccountClearingNumbers()
    begin
        // test import and updating the customer bank account clearing branch numbers
        ImportBankDirectoryWithCustomerBankAccount(true);
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryNotUpdatingCustomerBankAccountClearingNumbers()
    begin
        // test import without updating the customer bank account clearing branch numbers
        ImportBankDirectoryWithCustomerBankAccount(false);
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryUpdatingVendorBankAccountClearingNumbers()
    begin
        // test import and updating the vendor bank account clearing branch numbers
        ImportBankDirectoryWithVendorBankAccount(true);
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryNotUpdatingVendorBankAccountClearingNumbers()
    begin
        // test import without updating the vendor bank account clearing branch numbers
        ImportBankDirectoryWithVendorBankAccount(false);
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryEncodingUT()
    var
        BankDirectory: Record "Bank Directory";
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
        UpdateClearingNumbers: Boolean;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 166131] NAV imports bank directory file containing country specific symbols with correct encoding
        Initialize();

        // [GIVEN] Bank directory file which has address with country specific symbols
        UpdateClearingNumbers := false;
        LibraryVariableStorage.Enqueue(UpdateClearingNumbers);
        CreateBankDirectoryImportFile();
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // [WHEN] Run report Import Bank Directory
        REPORT.Run(REPORT::"Import Bank Directory", true, false);

        // [THEN] Imported record contains country specific symbols in correct encoding
        BankDirectory.Get('100');
        BankDirectory.TestField(Address, 'ÄäÜüöÖß');
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryCsvV3()
    var
        BankDirectory: Record "Bank Directory";
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Importing a SIX V3 CSV bank master file maps all fields correctly
        Initialize();

        // [GIVEN] A CSV V3 bank master file with header and a single bank record
        LibraryVariableStorage.Enqueue(false);
        CreateBankDirectoryCsvV3File();
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // [WHEN] Report "Import Bank Directory" runs
        Report.Run(Report::"Import Bank Directory", true, false);

        // [THEN] Bank Directory record exists with all CSV columns mapped
        Assert.IsTrue(BankDirectory.Get('100'), 'Clearing No. should be imported from column 1.');
        Assert.AreEqual(DMY2Date(12, 6, 2026), BankDirectory."Valid from", 'Valid from should be parsed from column 2.');
        Assert.AreEqual('001008', BankDirectory."SIC No.", 'SIC No. should come from column 5.');
        Assert.AreEqual('100', BankDirectory."Clearing Main Office", 'Clearing Main Office should come from column 6.');
        Assert.AreEqual(BankDirectory."Bank Type"::"Main Office", BankDirectory."Bank Type", 'Bank Type should be Main Office for IID type 1.');
        Assert.AreEqual('Schweizerische Nationalbank', BankDirectory.Name, 'Name should come from column 9.');
        Assert.AreEqual('Börsenstrasse', BankDirectory.Address, 'Street Name should be mapped to Address.');
        Assert.AreEqual('15', BankDirectory."Address 2", 'Building Number should be mapped to Address 2.');
        Assert.AreEqual('8022', BankDirectory."Post Code", 'Post Code should come from column 12.');
        Assert.AreEqual('Zürich', BankDirectory.City, 'Town Name should come from column 13.');
        Assert.AreEqual('CH', BankDirectory.Country, 'Country should come from column 14.');
        Assert.AreEqual('SNBZCHZZXXX', BankDirectory."SWIFT Address", 'BIC should be mapped to SWIFT Address.');
        Assert.AreEqual(BankDirectory."SIC Member"::Yes, BankDirectory."SIC Member", 'SIC Member should be Yes for "Y".');
        Assert.AreEqual(BankDirectory."euroSIC Member"::Yes, BankDirectory."euroSIC Member", 'euroSIC Member should be Yes for "Y".');
        Assert.IsTrue(BankDirectory."Import from File", 'Import from File should be set.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryCsvV3WithNewClearingNo()
    var
        BankDirectory: Record "Bank Directory";
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Importing a CSV V3 row where column "New IID/QR-IID" is populated fills the New Clearing No. field
        Initialize();

        // [GIVEN] A CSV V3 file containing a bank "B1" with a non-empty New IID pointing to "99999"
        LibraryVariableStorage.Enqueue(false);
        CreateBankDirectoryCsvV3FileWithNewClearing();
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // [WHEN] Report "Import Bank Directory" runs
        Report.Run(Report::"Import Bank Directory", true, false);

        // [THEN] The Bank Directory record holds the new clearing number
        Assert.IsTrue(BankDirectory.Get('11111'), 'Source IID should be imported.');
        Assert.AreEqual('99999', BankDirectory."New Clearing No.", 'New Clearing No. should be mapped from column 4.');
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryCsvV3UpdatesCustomerBankAccount()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
        OldClearing: Code[5];
        NewClearing: Code[5];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] When AutoUpdate is enabled, importing a CSV V3 with a successor IID updates customer bank accounts
        Initialize();

        OldClearing := '11111';
        NewClearing := '99999';

        // [GIVEN] A customer bank account "C1" using Bank Branch No. "OldClearing"
        CreateCustomerBankAccountWithClearing(CustomerBankAccount, OldClearing);

        // [GIVEN] A CSV V3 file mapping "OldClearing" to "NewClearing"
        LibraryVariableStorage.Enqueue(true);
        CreateBankDirectoryCsvV3FileWithMapping(OldClearing, NewClearing);
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // [WHEN] Report "Import Bank Directory" runs with AutoUpdate
        Report.Run(Report::"Import Bank Directory", true, false);

        // [THEN] Customer bank account "C1" now uses "NewClearing"
        CustomerBankAccount.Find();
        Assert.AreEqual(NewClearing, CustomerBankAccount."Bank Branch No.", 'Customer Bank Branch No. should be updated.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryCsvV3UpdatesVendorBankAccount()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        NewVendorBankAccount: Record "Vendor Bank Account";
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
        OldClearing: Code[5];
        NewClearing: Code[5];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] When AutoUpdate is enabled, importing a CSV V3 with a successor IID creates a new vendor bank account with the new clearing
        Initialize();

        OldClearing := '11111';
        NewClearing := '99999';

        // [GIVEN] A vendor bank account "V1" using Clearing No. "OldClearing"
        CreateVendorBankAccountWithClearing(VendorBankAccount, OldClearing);

        // [GIVEN] A CSV V3 file mapping "OldClearing" to "NewClearing"
        LibraryVariableStorage.Enqueue(true);
        CreateBankDirectoryCsvV3FileWithMapping(OldClearing, NewClearing);
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // [WHEN] Report "Import Bank Directory" runs with AutoUpdate
        Report.Run(Report::"Import Bank Directory", true, false);

        // [THEN] Original "V1" is kept, a new vendor bank account exists for the same vendor with "NewClearing"
        VendorBankAccount.Find();
        Assert.AreEqual(OldClearing, VendorBankAccount."Clearing No.", 'Original Vendor Clearing No. should be unchanged.');
        NewVendorBankAccount.SetRange("Vendor No.", VendorBankAccount."Vendor No.");
        NewVendorBankAccount.SetRange("Clearing No.", NewClearing);
        Assert.IsFalse(NewVendorBankAccount.IsEmpty(), 'A new vendor bank account with the new clearing should exist.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryCsvV3LegacyTxtStillWorks()
    var
        BankDirectory: Record "Bank Directory";
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] After adding CSV V3 support, the legacy fixed-width TXT format still imports correctly
        Initialize();

        // [GIVEN] A legacy fixed-width TXT bank directory file
        LibraryVariableStorage.Enqueue(false);
        CreateBankDirectoryImportFile();
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // [WHEN] Report "Import Bank Directory" runs
        Report.Run(Report::"Import Bank Directory", true, false);

        // [THEN] Records from the legacy file are imported (12 records, sample check)
        Assert.IsTrue(BankDirectory.Get('100'), 'Legacy TXT clearing "100" should be imported.');
        Assert.AreEqual('8022', BankDirectory."Post Code", 'Legacy TXT Post Code should match.');
        Assert.RecordCount(BankDirectory, 12);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryCsvV3MultipleRecords()
    var
        BankDirectory: Record "Bank Directory";
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Importing a CSV V3 file with multiple records creates one Bank Directory entry per unique IID, with duplicates incrementing No of Outlets
        Initialize();

        // [GIVEN] A CSV V3 file with 3 distinct IIDs and 1 duplicate IID "200" (4 data rows total)
        LibraryVariableStorage.Enqueue(false);
        CreateBankDirectoryCsvV3MultiRowFile();
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // [WHEN] Report "Import Bank Directory" runs
        Report.Run(Report::"Import Bank Directory", true, false);

        // [THEN] Three unique Bank Directory records exist; the duplicated IID has No of Outlets = 1
        Assert.RecordCount(BankDirectory, 3);
        Assert.IsTrue(BankDirectory.Get('100'), 'IID "100" should be imported.');
        Assert.IsTrue(BankDirectory.Get('200'), 'IID "200" should be imported.');
        Assert.AreEqual(1, BankDirectory."No of Outlets", 'Duplicate row should increment No of Outlets for "200".');
        Assert.IsTrue(BankDirectory.Get('300'), 'IID "300" should be imported.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryCsvV3DoesNotLeakFieldsBetweenRows()
    var
        BankDirectory: Record "Bank Directory";
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Importing multiple CSV V3 rows must Init() the record between iterations so that
        // fields whose case-mapping has no else branch (SIC Member, euroSIC Member) do not retain the
        // value assigned by the previous row when the current row carries an unrecognized value.
        Initialize();

        // [GIVEN] A CSV V3 file with two rows: row 1 sets SIC=Y / euroSIC=Y, row 2 has SIC='' / euroSIC=''
        LibraryVariableStorage.Enqueue(false);
        CreateBankDirectoryCsvV3FileWithLeakyParticipation();
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // [WHEN] Report "Import Bank Directory" runs
        Report.Run(Report::"Import Bank Directory", true, false);

        // [THEN] Row 1 keeps its Yes values, row 2 ends up with the default (No) for both fields
        Assert.IsTrue(BankDirectory.Get('500'), 'IID "500" should be imported.');
        Assert.AreEqual(BankDirectory."SIC Member"::Yes, BankDirectory."SIC Member", 'Row 1 SIC Member should be Yes.');
        Assert.AreEqual(BankDirectory."euroSIC Member"::Yes, BankDirectory."euroSIC Member", 'Row 1 euroSIC Member should be Yes.');

        Assert.IsTrue(BankDirectory.Get('501'), 'IID "501" should be imported.');
        Assert.AreEqual(BankDirectory."SIC Member"::No, BankDirectory."SIC Member", 'Row 2 SIC Member must not leak Yes from previous row.');
        Assert.AreEqual(BankDirectory."euroSIC Member"::No, BankDirectory."euroSIC Member", 'Row 2 euroSIC Member must not leak Yes from previous row.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryCsvV3BankTypeOutlet()
    var
        BankDirectory: Record "Bank Directory";
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Importing a CSV V3 row with IID type "3" maps to Bank Type Outlet
        Initialize();

        // [GIVEN] A CSV V3 file with one row having IID type = 3
        LibraryVariableStorage.Enqueue(false);
        CreateBankDirectoryCsvV3FileWithBankType('3');
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // [WHEN] Report "Import Bank Directory" runs
        Report.Run(Report::"Import Bank Directory", true, false);

        // [THEN] The imported Bank Directory record has Bank Type = Outlet
        Assert.IsTrue(BankDirectory.Get('400'), 'IID "400" should be imported.');
        Assert.AreEqual(BankDirectory."Bank Type"::Outlet, BankDirectory."Bank Type", 'Bank Type should be Outlet for IID type 3.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryCsvV3SICMemberNo()
    var
        BankDirectory: Record "Bank Directory";
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Importing a CSV V3 row with SIC participation "N" and euroSIC "N" maps to Member = No
        Initialize();

        // [GIVEN] A CSV V3 file with SIC participation = N and euroSIC participation = N
        LibraryVariableStorage.Enqueue(false);
        CreateBankDirectoryCsvV3FileWithSICNo();
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // [WHEN] Report "Import Bank Directory" runs
        Report.Run(Report::"Import Bank Directory", true, false);

        // [THEN] SIC Member and euroSIC Member are set to No
        Assert.IsTrue(BankDirectory.Get('500'), 'IID "500" should be imported.');
        Assert.AreEqual(BankDirectory."SIC Member"::No, BankDirectory."SIC Member", 'SIC Member should be No.');
        Assert.AreEqual(BankDirectory."euroSIC Member"::No, BankDirectory."euroSIC Member", 'euroSIC Member should be No.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryCsvV3EmptyOptionalFields()
    var
        BankDirectory: Record "Bank Directory";
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Importing a CSV V3 row with empty optional fields (BIC, Street, Building No.) does not error
        Initialize();

        // [GIVEN] A CSV V3 file with empty BIC, empty Street Name, and empty Building Number
        LibraryVariableStorage.Enqueue(false);
        CreateBankDirectoryCsvV3FileWithEmptyFields();
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // [WHEN] Report "Import Bank Directory" runs
        Report.Run(Report::"Import Bank Directory", true, false);

        // [THEN] Record is imported with empty Address, Address 2, and SWIFT Address
        Assert.IsTrue(BankDirectory.Get('600'), 'IID "600" should be imported.');
        Assert.AreEqual('', BankDirectory.Address, 'Address should be empty when Street Name is empty.');
        Assert.AreEqual('', BankDirectory."Address 2", 'Address 2 should be empty when Building Number is empty.');
        Assert.AreEqual('', BankDirectory."SWIFT Address", 'SWIFT Address should be empty when BIC is empty.');
        Assert.AreEqual('Test Bank Minimal', BankDirectory.Name, 'Name should still be imported.');
        Assert.AreEqual('8000', BankDirectory."Post Code", 'Post Code should still be imported.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryCsvV3Utf8Encoding()
    var
        BankDirectory: Record "Bank Directory";
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Importing a CSV V3 file with UTF-8 special characters preserves them correctly
        Initialize();

        // [GIVEN] A CSV V3 file containing names and addresses with German umlauts and French accents
        LibraryVariableStorage.Enqueue(false);
        CreateBankDirectoryCsvV3FileWithUtf8();
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // [WHEN] Report "Import Bank Directory" runs
        Report.Run(Report::"Import Bank Directory", true, false);

        // [THEN] Special characters are preserved in imported fields
        Assert.IsTrue(BankDirectory.Get('700'), 'IID "700" should be imported.');
        Assert.AreEqual('Bänk Zürich Höfe', BankDirectory.Name, 'UTF-8 name with umlauts should be preserved.');
        Assert.AreEqual('Überlandstrasse', BankDirectory.Address, 'UTF-8 street with umlauts should be preserved.');
        Assert.AreEqual('Genève', BankDirectory.City, 'UTF-8 city with accents should be preserved.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ImportHandler')]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryCsvV3FieldTruncation()
    var
        BankDirectory: Record "Bank Directory";
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Importing a CSV V3 file with values exceeding field max length truncates without error
        Initialize();

        // [GIVEN] A CSV V3 file with Name exceeding 30 characters and Post Code exceeding 20 characters
        LibraryVariableStorage.Enqueue(false);
        CreateBankDirectoryCsvV3FileWithLongFields();
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // [WHEN] Report "Import Bank Directory" runs
        Report.Run(Report::"Import Bank Directory", true, false);

        // [THEN] Fields are truncated to their maximum length without error
        Assert.IsTrue(BankDirectory.Get('800'), 'IID "800" should be imported.');
        Assert.AreEqual(30, StrLen(BankDirectory.Name), 'Name should be truncated to 30 characters.');
        Assert.AreEqual('This Very Long Bank Name That ', BankDirectory.Name, 'Name should be truncated at MaxStrLen.');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        BankDirectory: Record "Bank Directory";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryVariableStorage.Clear();
        BankDirectory.DeleteAll();
        Commit();
    end;

    procedure SetFileName(FileName: Text)
    begin
        FileNameForHandler := FileName;
    end;

    local procedure ImportBankDirectoryWithCustomerBankAccount(UpdateClearingNumbers: Boolean)
    var
        CustomerBankAccount1: Record "Customer Bank Account";
        CustomerBankAccount2: Record "Customer Bank Account";
        CustomerBankAccount3: Record "Customer Bank Account";
        BranchNo1: Code[5];
        BranchNo2: Code[5];
        BranchNo3: Code[5];
    begin
        // Setup
        Initialize();

        CreateCustomerBankAccount(CustomerBankAccount1);
        CreateCustomerBankAccount(CustomerBankAccount2);
        CreateCustomerBankAccount(CustomerBankAccount3);

        BranchNo1 := CustomerBankAccount1."Bank Branch No.";
        BranchNo2 := CustomerBankAccount2."Bank Branch No.";
        BranchNo3 := CustomerBankAccount3."Bank Branch No.";

        // Set the request page options
        LibraryVariableStorage.Enqueue(UpdateClearingNumbers);

        ImportBankDirectoryWithClearingNumbers(BranchNo1, BranchNo2, BranchNo3);

        // Verify
        CustomerBankAccount1.Find();
        CustomerBankAccount2.Find();
        CustomerBankAccount3.Find();

        // Verify that the customer bank account branch number is updated when there is a new clearing number in the imported directory
        if UpdateClearingNumbers then
            Assert.AreEqual(BranchNo2, CustomerBankAccount1."Bank Branch No.", 'Customer 1 Bank Branch No should be modified')
        else
            Assert.AreEqual(BranchNo1, CustomerBankAccount1."Bank Branch No.", 'Customer 1 Bank Branch No should be modified');

        // Verify that that other accounts are not updated
        Assert.AreEqual(BranchNo2, CustomerBankAccount2."Bank Branch No.", 'Bank Branch No should not be modified');
        Assert.AreEqual(BranchNo3, CustomerBankAccount3."Bank Branch No.", 'Bank Branch No should not be modified');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure ImportBankDirectoryWithVendorBankAccount(UpdateClearingNumbers: Boolean)
    var
        VendorBankAccount1: Record "Vendor Bank Account";
        VendorBankAccount2: Record "Vendor Bank Account";
        VendorBankAccount3: Record "Vendor Bank Account";
        NewVendorBankAccount: Record "Vendor Bank Account";
        BranchNo1: Code[5];
        BranchNo2: Code[5];
        BranchNo3: Code[5];
    begin
        // Setup
        Initialize();

        CreateVendorBankAccount(VendorBankAccount1);
        CreateVendorBankAccount(VendorBankAccount2);
        CreateVendorBankAccount(VendorBankAccount3);

        BranchNo1 := VendorBankAccount1."Clearing No.";
        BranchNo2 := VendorBankAccount2."Clearing No.";
        BranchNo3 := VendorBankAccount3."Clearing No.";

        // Set the request page options
        LibraryVariableStorage.Enqueue(UpdateClearingNumbers);

        ImportBankDirectoryWithClearingNumbers(BranchNo1, BranchNo2, BranchNo3);

        VendorBankAccount1.Find();
        VendorBankAccount2.Find();
        VendorBankAccount3.Find();

        // Verify that the original Vendor bank account 1 is not modified
        Assert.AreEqual(BranchNo1, VendorBankAccount1."Clearing No.", 'Vendor Bank Account 1 Branch No should be modified');

        // Verify that the a new Vendor bank account is created when there is a new clearing number in the imported directory
        NewVendorBankAccount.SetRange("Vendor No.", VendorBankAccount1."Vendor No.");
        NewVendorBankAccount.SetRange("Clearing No.", BranchNo2);
        Assert.AreEqual(UpdateClearingNumbers, not NewVendorBankAccount.IsEmpty, 'Vendor bank account with New Clearing No.');

        // Verify that that other accounts are not updated
        Assert.AreEqual(BranchNo2, VendorBankAccount2."Clearing No.", 'Vendor Bank Account 2 Clearing No should not be modified');
        Assert.AreEqual(BranchNo3, VendorBankAccount3."Clearing No.", 'Vendor Bank Account 3 Clearing No should not be modified');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure ImportBankDirectoryWithClearingNumbers(BranchNo1: Code[5]; BranchNo2: Code[5]; BranchNo3: Code[5])
    var
        TestImportBankDirectory: Codeunit "Test Import Bank Directory";
        NumberOfImportedRows: Integer;
    begin
        NumberOfImportedRows := WriteBankDirectoryFile(BranchNo1, BranchNo2, BranchNo3, BranchNo2);
        BindSubscription(TestImportBankDirectory);
        TestImportBankDirectory.SetFileName(FileNameForHandler);

        // run the report
        REPORT.Run(REPORT::"Import Bank Directory", true, false);

        // Verify the rows were imported
        VerifyImportedRecords(NumberOfImportedRows);
    end;

    local procedure VerifyImportedRecords(ExpectedRecordCount: Integer)
    var
        BankDirectory: Record "Bank Directory";
        ElementValue: Variant;
        ImportedRecords: Text;
    begin
        // Verify records imported in the report dataset
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsTrue(LibraryReportDataset.GetNextRow(),
          'No rows in the dataset.');

        // Verify the Imported record count from the dataset
        LibraryReportDataset.GetElementValueInCurrentRow('ReadRec', ElementValue);
        ImportedRecords := CopyStr(ElementValue, 1, StrPos(ElementValue, ' ') - 1);
        Assert.AreEqual(Format(ExpectedRecordCount), ImportedRecords,
          'The number of imported records in the dataset should match the number of rows in the file.');

        // Verify records imported in the Bank Directory Table
        Assert.RecordCount(BankDirectory, ExpectedRecordCount);
    end;

    local procedure VerifyBankDirectoryRecords()
    begin
        // Verify the records imported from the file created by WriteFileContent function
        AssertBankDirectoryRecord('100', '8022', '100');
        AssertBankDirectoryRecord('110', '3003', '100');
        AssertBankDirectoryRecord('115', '3003', '100');
        AssertBankDirectoryRecord('140', '1211', '100');
        AssertBankDirectoryRecord('193', '60486', '193');
        AssertBankDirectoryRecord('294', '3940', '230');
        AssertBankDirectoryRecord('298', '8098', '230');
        AssertBankDirectoryRecord('4003', '5001', '4835');
        AssertBankDirectoryRecord('4209', '8820', '4836');
        AssertBankDirectoryRecord('4570', '8808', '4837');
        AssertBankDirectoryRecord('4823', '6301', '4838');
        AssertBankDirectoryRecord('4835', '8070', '4839');
    end;

    local procedure AssertBankDirectoryRecord(ClearingNo: Code[5]; PostCode: Text[20]; ClearingMainOffice: Code[5])
    var
        BankDirectory: Record "Bank Directory";
    begin
        Assert.IsTrue(BankDirectory.Get(ClearingNo), 'Clearing No. was not imported correctly.');
        Assert.AreEqual(PostCode, BankDirectory."Post Code", 'Wrong post code');
        Assert.AreEqual(ClearingMainOffice, BankDirectory."Clearing Main Office", 'Clearing Main Office');
    end;

    local procedure CreateBankDirectoryImportFile()
    begin
        FileNameForHandler := FileManagement.ServerTempFileName('txt');
        WriteFileContent(FileNameForHandler);
    end;

    local procedure WriteFileContent(FileName: Text)
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileHdl.Create(FileName, TEXTENCODING::Windows);
        FileHdl.CreateOutStream(TmpStream);
        WriteLine(TmpStream, '01100  0000     001008100  120060324131SNB            ' +
          'Schweizerische Nationalbank                                 ' +
          'ÄäÜüöÖß                            Postfach 2800                      ' +
          '8022      Zürich                             044 631 31 11                              30-5-5      SNBZCHZZXXX   ');
        WriteLine(TmpStream, '01110  0000     001100100  220071109131SNB            ' +
          'Schweizerische Nationalbank                                 ' +
          'Bundesplatz 1                      Postfach                           ' +
          '3003      Bern                               031 327 02 21                              *30-5-5     SNBZCHZZXXX   ');
        WriteLine(TmpStream, '01115  0000     001158100  220060324131SNB            ' +
          'Schweizerische Nationalbank                                 ' +
          'Bundesverw. / Bundesplatz 1        Postfach                           ' +
          '3003      Bern                               044 631 31 30     044 631 39 34            *30-5-5     SNBZCHZZXXX   ');
        WriteLine(TmpStream, '01140  0000     001403100  220060324132BNS            ' +
          'Banque nationale suisse                                     ' +
          'Rue Diday 8                        Case postale 5355                  ' +
          '1211      Genève 11                          022 311 86 11                              *30-5-5     SNBZCHZZXXX   ');
        WriteLine(TmpStream, '08193  0000     001933193  120020829031SECB           ' +
          'SECB Swiss Euro Clearing Bank                               ' +
          'Solmsstrasse 18                                                       ' +
          '60486     Frankfurt am Main                  69 97 98 98 0     69 97 98 98 98    ++49 DE            SECGDEFFXXX   ');
        WriteLine(TmpStream, '02294  0001     002940230  320050623111UBS            ' +
          'UBS AG                                                      ' +
          'Haus Metropol / Bahnhofstrasse 21  Postfach                           ' +
          '3940      Steg VS                            027 933 93 11                              *80-2-2                   ');
        WriteLine(TmpStream, '02298  0000     002982230  220050305111UBS            ' +
          'UBS AG                                                      ' +
          'Bahnhofstrasse 45                  Corporate Center                   ' +
          '8098      Zürich                             044 234 11 11                              *80-2-2     UBSWCHZH80A   ');
        WriteLine(TmpStream, '044003 00004835 0400354835 120061020111CS             ' +
          'CREDIT SUISSE (4)                                           ' +
          'Bahnhofstrasse 20                  Postfach 2503                      ' +
          '5001      Aarau                              062 836 31 31     062 836 33 00            *30-3200-1  CRESCHZZ50A   ');
        WriteLine(TmpStream, '044209 00004835 0420954836 120061020111CS             ' +
          'CREDIT SUISSE (4)                                           ' +
          'Friedbergstrasse 9                 Postfach 350                       ' +
          '8820      Wädenswil                          044 783 31 11     044 783 33 11            *80-500-4   CRESCHZZ88H   ');
        WriteLine(TmpStream, '044570 00004835 0457034837 120061020111CS             ' +
          'CREDIT SUISSE (4)                                           ' +
          'Schindellegistrasse 3              Postfach 59                        ' +
          '8808      Pfäffikon SZ                       055 416 01 01     055 416 02 02            *80-500-4   CRESCHZZ88F   ');
        WriteLine(TmpStream, '044823 00004835 0482374838 120061020111CS             ' +
          'CREDIT SUISSE (4)                                           ' +
          'Bahnhofstrasse 17                  Postfach 357                       ' +
          '6301      Zug                                041 727 99 22     041 727 99 43            *30-3200-1  CRESCHZZ63A   ');
        WriteLine(TmpStream, '044835 0000     0483584839 120050424111CS             ' +
          'CREDIT SUISSE (4)                                           ' +
          'Paradeplatz 8                      Postfach 100                       ' +
          '8070      Zürich                             044 333 99 11     044 332 55 55            80-500-4    CRESCHZZ80A   ');

        FileHdl.Close();
    end;

    local procedure WriteLine(TmpStream: OutStream; Text: Text)
    begin
        TmpStream.WriteText(Text);
        TmpStream.WriteText();
    end;

    local procedure WriteBankDirectoryFile(ClearingBranchNo1: Code[5]; ClearingBranchNo2: Code[5]; ClearingBranchNo3: Code[5]; NewClearingBranchNo1: Code[5]) RecordCount: Integer
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileNameForHandler := FileManagement.ServerTempFileName('txt');
        FileHdl.Create(FileNameForHandler);
        FileHdl.CreateOutStream(TmpStream);
        WriteLine(TmpStream, '04' + PadStr(ClearingBranchNo1, 5) +
          '0000' + PadStr(NewClearingBranchNo1, 5) + '0400354835 120061020111CS             ' +
          'CREDIT SUISSE (4)                                           ' +
          'Bahnhofstrasse 20                  Postfach 2503                      ' +
          '5001      Aarau                              062 836 31 31     062 836 33 00            *30-3200-1  CRESCHZZ50A   ');
        WriteLine(TmpStream, '04' + PadStr(ClearingBranchNo2, 5) +
          '0000     0483584839 120050424111CS             ' +
          'CREDIT SUISSE (4)                                           ' +
          'Paradeplatz 8                      Postfach 100                       ' +
          '8070      Zürich                             044 333 99 11     044 332 55 55            80-500-4    CRESCHZZ80A   ');
        WriteLine(TmpStream, '01' + PadStr(ClearingBranchNo3, 5) +
          '0000     001008100  120060324131SNB            ' +
          'Schweizerische Nationalbank                                 ' +
          'Börsenstrasse 15                   Postfach 2800                      ' +
          '8022      Zürich                             044 631 31 11                              30-5-5      SNBZCHZZXXX   ');

        FileHdl.Close();
        RecordCount := 3;
    end;

    local procedure CreateBankDirectoryCsvV3File()
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileNameForHandler := FileManagement.ServerTempFileName('csv');
        FileHdl.Create(FileNameForHandler, TEXTENCODING::UTF8);
        FileHdl.CreateOutStream(TmpStream);
        WriteCsvHeader(TmpStream);
        WriteLine(TmpStream, '100;2026-06-12;N;;001008;100;1;;Schweizerische Nationalbank;Börsenstrasse;15;8022;Zürich;CH;SNBZCHZZXXX;Y;Y;Y;Y;Y;N');
        FileHdl.Close();
    end;

    local procedure CreateBankDirectoryCsvV3FileWithNewClearing()
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileNameForHandler := FileManagement.ServerTempFileName('csv');
        FileHdl.Create(FileNameForHandler, TEXTENCODING::UTF8);
        FileHdl.CreateOutStream(TmpStream);
        WriteCsvHeader(TmpStream);
        WriteLine(TmpStream, '11111;2026-06-12;Y;99999;111110;11111;2;;Test Bank;Teststreet;1;8000;Zürich;CH;TESTCHZZXXX;Y;Y;N;Y;N;N');
        FileHdl.Close();
    end;

    local procedure CreateBankDirectoryCsvV3FileWithMapping(OldClearing: Code[5]; NewClearing: Code[5])
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileNameForHandler := FileManagement.ServerTempFileName('csv');
        FileHdl.Create(FileNameForHandler, TEXTENCODING::UTF8);
        FileHdl.CreateOutStream(TmpStream);
        WriteCsvHeader(TmpStream);
        // Old IID has Concatenation=Y and a successor IID
        WriteLine(TmpStream, OldClearing + ';2026-06-12;Y;' + NewClearing + ';111110;' + OldClearing + ';2;;Test Bank Old;Teststreet;1;8000;Zürich;CH;TESTCHZZXXX;Y;Y;N;Y;N;N');
        // Successor IID
        WriteLine(TmpStream, NewClearing + ';2026-06-12;N;;999990;' + NewClearing + ';1;;Test Bank New;Teststreet;1;8000;Zürich;CH;TESTCHZZNEW;Y;Y;N;Y;N;N');
        FileHdl.Close();
    end;

    local procedure CreateBankDirectoryCsvV3MultiRowFile()
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileNameForHandler := FileManagement.ServerTempFileName('csv');
        FileHdl.Create(FileNameForHandler, TEXTENCODING::UTF8);
        FileHdl.CreateOutStream(TmpStream);
        WriteCsvHeader(TmpStream);
        WriteLine(TmpStream, '100;2026-06-12;N;;001008;100;1;;Bank A;Streetname;1;8000;Zürich;CH;BANKACHZZXXX;Y;Y;Y;Y;Y;N');
        WriteLine(TmpStream, '200;2026-06-12;N;;002000;200;1;;Bank B;Streetname;2;8001;Zürich;CH;BANKBCHZZXXX;Y;Y;Y;Y;Y;N');
        // Duplicate IID 200 to test "No of Outlets" increment
        WriteLine(TmpStream, '200;2026-06-12;N;;002000;200;2;;Bank B Branch;Streetname;3;8002;Zürich;CH;BANKBCHZZBRA;Y;Y;Y;Y;Y;N');
        WriteLine(TmpStream, '300;2026-06-12;N;;003000;300;1;;Bank C;Streetname;4;8003;Zürich;CH;BANKCCHZZXXX;Y;Y;Y;Y;Y;N');
        FileHdl.Close();
    end;

    local procedure CreateBankDirectoryCsvV3FileWithLeakyParticipation()
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        // Row 1 sets SIC participation (col 16) and euroSIC participation (col 19) to 'Y'.
        // Row 2 leaves both blank, which is not matched by the Y/N case statements. Without
        // Init() between iterations, row 2 would inherit row 1's Yes values for these fields.
        FileNameForHandler := FileManagement.ServerTempFileName('csv');
        FileHdl.Create(FileNameForHandler, TEXTENCODING::UTF8);
        FileHdl.CreateOutStream(TmpStream);
        WriteCsvHeader(TmpStream);
        WriteLine(TmpStream, '500;2026-06-12;N;;005000;500;1;;Bank D;Streetname;5;8005;Zürich;CH;BANKDCHZZXXX;Y;Y;Y;Y;Y;N');
        WriteLine(TmpStream, '501;2026-06-12;N;;005010;501;1;;Bank E;Streetname;6;8006;Zürich;CH;BANKECHZZXXX;;;;;;');
        FileHdl.Close();
    end;

    local procedure WriteCsvHeader(TmpStream: OutStream)
    begin
        WriteLine(TmpStream,
          'IID/QR-IID;Valid on;Concatenation;New IID/QR-IID;SIC IID;Headquarters;IID type;QR-IID allocation;' +
          'Name of bank/institution;Street Name;Building Number;Post Code;Town Name;Country;BIC;' +
          'SIC participation;RTGS customer payments, CHF;IP customer payments, CHF;euroSIC participation;LSV+/BDD, CHF;LSV+/BDD, EUR');
    end;

    local procedure CreateBankDirectoryCsvV3FileWithBankType(IIDType: Text)
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileNameForHandler := FileManagement.ServerTempFileName('csv');
        FileHdl.Create(FileNameForHandler, TEXTENCODING::UTF8);
        FileHdl.CreateOutStream(TmpStream);
        WriteCsvHeader(TmpStream);
        WriteLine(TmpStream, '400;2026-06-12;N;;004000;400;' + IIDType + ';;Test Bank Outlet;Teststrasse;10;8000;Zürich;CH;TESTCHZZXXX;Y;Y;Y;Y;Y;N');
        FileHdl.Close();
    end;

    local procedure CreateBankDirectoryCsvV3FileWithSICNo()
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileNameForHandler := FileManagement.ServerTempFileName('csv');
        FileHdl.Create(FileNameForHandler, TEXTENCODING::UTF8);
        FileHdl.CreateOutStream(TmpStream);
        WriteCsvHeader(TmpStream);
        WriteLine(TmpStream, '500;2026-06-12;N;;005000;500;1;;Non-SIC Bank;Hauptstrasse;5;3000;Bern;CH;NONSICCHZXXX;N;N;N;N;N;N');
        FileHdl.Close();
    end;

    local procedure CreateBankDirectoryCsvV3FileWithEmptyFields()
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileNameForHandler := FileManagement.ServerTempFileName('csv');
        FileHdl.Create(FileNameForHandler, TEXTENCODING::UTF8);
        FileHdl.CreateOutStream(TmpStream);
        WriteCsvHeader(TmpStream);
        // Empty Street Name (col 10), Building Number (col 11), and BIC (col 15)
        WriteLine(TmpStream, '600;2026-06-12;N;;006000;600;1;;Test Bank Minimal;;;8000;Zürich;CH;;Y;Y;Y;Y;Y;N');
        FileHdl.Close();
    end;

    local procedure CreateBankDirectoryCsvV3FileWithUtf8()
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileNameForHandler := FileManagement.ServerTempFileName('csv');
        FileHdl.Create(FileNameForHandler, TEXTENCODING::UTF8);
        FileHdl.CreateOutStream(TmpStream);
        WriteCsvHeader(TmpStream);
        WriteLine(TmpStream, '700;2026-06-12;N;;007000;700;1;;Bänk Zürich Höfe;Überlandstrasse;42;1211;Genève;CH;BANKCHZZXXX;Y;Y;Y;Y;Y;N');
        FileHdl.Close();
    end;

    local procedure CreateBankDirectoryCsvV3FileWithLongFields()
    var
        TmpStream: OutStream;
        FileHdl: File;
    begin
        FileNameForHandler := FileManagement.ServerTempFileName('csv');
        FileHdl.Create(FileNameForHandler, TEXTENCODING::UTF8);
        FileHdl.CreateOutStream(TmpStream);
        WriteCsvHeader(TmpStream);
        // Name exceeds 30 chars: "This Very Long Bank Name That Exceeds The Maximum" = 50 chars
        WriteLine(TmpStream, '800;2026-06-12;N;;008000;800;1;;This Very Long Bank Name That Exceeds The Maximum;Strasse;1;8000;Zürich;CH;LONGCHZZXXX;Y;Y;Y;Y;Y;N');
        FileHdl.Close();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ImportHandler(var ImportBankDirectory: TestRequestPage "Import Bank Directory")
    var
        UpdateClearingNumbers: Variant;
    begin
        LibraryVariableStorage.Dequeue(UpdateClearingNumbers);
        ImportBankDirectory.AutoUpdate.SetValue(UpdateClearingNumbers);
        ImportBankDirectory.FileName.AssistEdit();

        ImportBankDirectory.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ImportBankDirectoryCancelRequestPageHandler(var ImportBankDirectoryRequestPage: TestRequestPage "Import Bank Directory")
    begin
        ImportBankDirectoryRequestPage.Cancel().Invoke();
    end;

    local procedure CreateCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account")
    var
        Customer: Record Customer;
    begin
        // Create a customer with Bank Account
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccount."Bank Branch No." := Format(LibraryRandom.RandIntInRange(11111, 99999));
        CustomerBankAccount.Modify(true);
        Commit();
    end;

    local procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account")
    var
        Vendor: Record Vendor;
    begin
        // Create a vendor with Bank Account
        LibraryPurchase.CreateVendor(Vendor);
        VendorBankAccount.Init();
        VendorBankAccount.Validate("Vendor No.", Vendor."No.");
        VendorBankAccount.Validate(Code, CopyStr(LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo(Code), DATABASE::"Vendor Bank Account"), 1, 5));
        VendorBankAccount."Clearing No." := Format(LibraryRandom.RandIntInRange(11111, 99999));
        VendorBankAccount."Payment Form" := VendorBankAccount."Payment Form"::"Bank Payment Domestic";
        VendorBankAccount.Insert(true);
        Commit();
    end;

    local procedure CreateCustomerBankAccountWithClearing(var CustomerBankAccount: Record "Customer Bank Account"; ClearingNo: Code[5])
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccount."Bank Branch No." := ClearingNo;
        CustomerBankAccount.Modify(true);
        Commit();
    end;

    local procedure CreateVendorBankAccountWithClearing(var VendorBankAccount: Record "Vendor Bank Account"; ClearingNo: Code[5])
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        VendorBankAccount.Init();
        VendorBankAccount.Validate("Vendor No.", Vendor."No.");
        VendorBankAccount.Validate(Code, CopyStr(LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo(Code), Database::"Vendor Bank Account"), 1, 5));
        VendorBankAccount."Clearing No." := ClearingNo;
        VendorBankAccount."Payment Form" := VendorBankAccount."Payment Form"::"Bank Payment Domestic";
        VendorBankAccount.Insert(true);
        Commit();
    end;

    [EventSubscriber(ObjectType::Report, Report::"Import Bank Directory", 'OnImportFile', '', false, false)]
    procedure OnImportFile(var TempBlob: Codeunit "Temp Blob"; var FileName: Text; var IsHandled: Boolean);
    var
        FileManagement: Codeunit "File Management";
    begin
        FileName := FileNameForHandler;
        FileManagement.BLOBImportFromServerFile(TempBlob, FileName);
        IsHandled := true;
    end;

}

